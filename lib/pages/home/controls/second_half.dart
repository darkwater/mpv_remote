import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mpv_remote/mpv_socket.dart';
import 'package:mpv_remote/pages/home/controls/chapter_list.dart';
import 'package:mpv_remote/storage.dart';
import 'package:mpv_remote/utils.dart';
import 'package:mpv_remote/widgets/property_builder.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class SecondHalf extends StatelessWidget {
  const SecondHalf({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PropertyBuilder(
        properties: const [
          "pause",
          "playlist-pos",
          "playlist-count",
          "chapter",
          "chapters",
          "chapter-metadata",
        ],
        builder: (context, props) {
          final pause = props.pause ?? true;
          final playlistPos = props.playlistPos;
          final playlistCount = props.playlistCount;
          final chapter = props.chapter ?? 0;
          final chapters = props.chapters ?? 1;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: double.infinity,
                height: 96,
                child: SeekComponent(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    child: const Icon(Icons.first_page),
                    onPressed: () {
                      context.read<MpvSocket>().timePos = 0;
                    },
                  ),
                  const _SeekButton(-60),
                  const _SeekButton(-10),
                  const _SeekButton(10),
                  const _SeekButton(60),
                ],
              ),
              SizedBox(
                height: 96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 42,
                      onPressed: (playlistPos == null || playlistPos == 0)
                          ? null
                          : () => context
                              .read<MpvSocket>()
                              .playlistPlayIndex(playlistPos - 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fast_rewind),
                      iconSize: 42,
                      onPressed: (chapter <= 0)
                          ? null
                          : () =>
                              context.read<MpvSocket>().chapter = chapter - 1,
                    ),
                    IconButton(
                      icon: ImplicitlyAnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress: pause ? 0 : 1,
                      ),
                      iconSize: 64,
                      onPressed: () => context.read<MpvSocket>().pause = !pause,
                    ),
                    IconButton(
                      icon: const Icon(Icons.fast_forward),
                      iconSize: 42,
                      onPressed: (chapter >= chapters - 1)
                          ? null
                          : () =>
                              context.read<MpvSocket>().chapter = chapter + 1,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 42,
                      onPressed: (playlistPos == null ||
                              playlistCount == null ||
                              playlistPos == playlistCount - 1)
                          ? null
                          : () => context
                              .read<MpvSocket>()
                              .playlistPlayIndex(playlistPos + 1),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SeekComponent extends StatelessWidget {
  const SeekComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyBuilder(
      properties: const [
        // TODO: use percentPos
        MpvProperty.timePos,
        MpvProperty.timeRemaining,
        MpvProperty.seekable,
        MpvProperty.seeking,
        MpvProperty.chapters,
        "chapter-metadata/by-key/title",
      ],
      builder: (context, props) {
        final chapterTitle = props["chapter-metadata/by-key/title"];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 80,
                    child: _TimeProgress(
                      timePos: props.timePos,
                      timeRemaining: props.timeRemaining,
                    ),
                  ),
                  if (props.seeking ?? true)
                    Stack(
                      children: const [
                        Center(child: CircularProgressIndicator.adaptive()),
                        Center(child: Text("")), // set baseline correctly
                      ],
                    )
                  else if (chapterTitle != null)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 2 / 3,
                              ),
                              child: ChapterListView(
                                chapters: props.chapters,
                              ),
                            ),
                            backgroundColor: Colors.purple.shade900,
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            chapterTitle!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 80,
                    child: _TimeRemaining(
                      timePos: props.timePos,
                      timeRemaining: props.timeRemaining,
                    ),
                  ),
                ],
              ),
            ),
            SliderTheme(
              data: const SliderThemeData(
                trackHeight: 10,
              ),
              child: SizedBox(
                height: 24,
                child: Slider(
                  value: props.timePos ?? 0,
                  min: min(0, props.timePos ?? 0),
                  max: (props.timeRemaining ?? 0) + (props.timePos ?? 0),
                  onChanged: (props.seekable != false)
                      ? (v) => context.read<MpvSocket>().timePos = v
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeProgress extends StatelessWidget {
  const _TimeProgress({
    Key? key,
    required this.timePos,
    required this.timeRemaining,
  }) : super(key: key);

  final double? timePos;
  final double? timeRemaining;

  @override
  Widget build(BuildContext context) {
    return PreferenceBuilder<bool>(
      preference: Storage.showPercentPos,
      builder: (context, showPercentPos) {
        final timePos = this.timePos ?? 0;

        return TextButton(
          child: SizedBox(
            width: double.infinity,
            child: Text(
              (showPercentPos && timeRemaining != null)
                  ? (timePos / (timePos + timeRemaining!) * 100)
                          .toStringAsFixed(1) +
                      "%"
                  : formatSeconds(timePos),
              textAlign: TextAlign.start,
            ),
          ),
          onPressed: () {
            Storage.showPercentPos.setValue(!showPercentPos);
          },
        );
      },
    );
  }
}

class _TimeRemaining extends StatelessWidget {
  const _TimeRemaining({
    Key? key,
    required this.timePos,
    required this.timeRemaining,
  }) : super(key: key);

  final double? timePos;
  final double? timeRemaining;

  @override
  Widget build(BuildContext context) {
    return PreferenceBuilder<bool>(
      preference: Storage.showRemainingTime,
      builder: (context, showRemainingTime) {
        return TextButton(
          child: SizedBox(
            width: double.infinity,
            child: Text(
              (timePos != null && timeRemaining != null)
                  ? (showRemainingTime
                      ? ("-" + formatSeconds(timeRemaining!))
                      : formatSeconds(timePos! + timeRemaining!))
                  : "",
              textAlign: TextAlign.end,
            ),
          ),
          onPressed: () {
            Storage.showRemainingTime.setValue(!showRemainingTime);
          },
        );
      },
    );
  }
}

class _SeekButton extends StatelessWidget {
  const _SeekButton(this.seconds, {Key? key}) : super(key: key);

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Row(
        children: [
          if (seconds < 0) const Icon(Icons.fast_rewind),
          Text(seconds.abs().toString()),
          if (seconds > 0) const Icon(Icons.fast_forward),
        ],
      ),
      onPressed: () {
        context.read<MpvSocket>().execute("seek", [seconds, "relative"]);
      },
    );
  }
}

class ImplicitlyAnimatedIcon extends StatefulWidget {
  const ImplicitlyAnimatedIcon({
    required this.icon,
    required this.progress,
    Key? key,
  }) : super(key: key);

  final AnimatedIconData icon;
  final double progress;

  @override
  _ImplicitlyAnimatedIconState createState() => _ImplicitlyAnimatedIconState();
}

class _ImplicitlyAnimatedIconState extends State<ImplicitlyAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.progress,
    );
  }

  @override
  Widget build(BuildContext context) {
    _anim.animateTo(widget.progress);

    return AnimatedIcon(
      icon: widget.icon,
      progress: _anim,
    );
  }
}

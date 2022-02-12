import 'package:flutter/material.dart';
import 'package:mpv_remote/mpv_socket.dart';
import 'package:mpv_remote/utils.dart';
import 'package:mpv_remote/widgets/property_builder.dart';
import 'package:provider/provider.dart';

class ChapterListView extends StatelessWidget {
  const ChapterListView({this.chapters, Key? key}) : super(key: key);

  final int? chapters;

  double get predictedHeight => (chapters ?? 0) * 62;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PropertyBuilder(
          properties: const [
            MpvProperty.chapterList,
            MpvProperty.chapter,
            MpvProperty.duration,
            MpvProperty.percentPos,
          ],
          loadingBuilder: (context) => SizedBox(height: predictedHeight),
          builder: (context, props) {
            final chapters = props.chapterList!.chapters;

            if (chapters.isEmpty) {
              return SafeArea(
                child: ListTile(
                  title: Text(
                    "No chapters",
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final list = chapters.asMap().entries.map((entry) {
              final index = entry.key;
              final chapter = entry.value;

              final title = chapter.title ?? "<chapter ${index + 1}>";
              return ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        formatSeconds(chapter.time),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 64,
                      child: Opacity(
                        opacity: 0.7,
                        child: Text(
                          "(" +
                              formatSeconds(
                                ((index < chapters.length - 1)
                                        ? chapters[index + 1].time
                                        : (props.duration ?? chapter.time)) -
                                    chapter.time,
                              ) +
                              ")",
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
                selected: props.chapter == index,
                onTap: () {
                  context.read<MpvSocket>().chapter = index;
                },
              );
            }).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (props.percentPos != null)
                  LinearProgressIndicator(
                    value: props.percentPos! / 100,
                    color: Colors.purpleAccent,
                    backgroundColor: Colors.black,
                    minHeight: 4,
                  ),
                if (predictedHeight >
                    constraints.maxHeight - 10) // bit of buffer
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: list,
                    ),
                  )
                else
                  SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: list,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

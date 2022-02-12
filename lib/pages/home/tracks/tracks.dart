import 'package:flutter/material.dart';
import 'package:mpv_remote/mpv_socket.dart';
import 'package:mpv_remote/widgets/property_builder.dart';
import 'package:provider/provider.dart';

class Tracks extends StatelessWidget {
  const Tracks({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyBuilder(
      properties: const [
        MpvProperty.trackList,
      ],
      builder: (context, props) {
        final tracks = props.trackList ?? [];

        final subs = tracks.where((track) => track.type == 'sub').toList();
        final audios = tracks.where((track) => track.type == 'audio').toList();
        final videos = tracks.where((track) => track.type == 'video').toList();

        final noSub = !subs.any((track) => track.selected);
        final noAudio = !audios.any((track) => track.selected);
        final noVideo = !videos.any((track) => track.selected);

        return ListView(
          children: [
            const ListHeader("Subtitles"),
            ListTile(
              leading: Icon(
                  noSub ? Icons.subtitles_off : Icons.subtitles_off_outlined),
              title: const Text("No subtitles"),
              selected: noSub,
              onTap: () {
                context.read<MpvSocket>().setProperty("sid", "0");
              },
            ),
            for (final track in subs)
              ListTile(
                leading: Icon(track.selected
                    ? Icons.subtitles
                    : Icons.subtitles_outlined),
                title: Text(track.title ?? "Sub ${track.id}"),
                // subtitle: Text(track.data.toString()),
                selected: track.selected,
                onTap: () {
                  context.read<MpvSocket>().setProperty("sid", track.id);
                },
              ),
            const ListHeader("Audio tracks"),
            ListTile(
              leading:
                  Icon(noAudio ? Icons.music_off : Icons.music_off_outlined),
              title: const Text("No audio"),
              selected: noAudio,
              onTap: () {
                context.read<MpvSocket>().setProperty("aid", "0");
              },
            ),
            for (final track in audios)
              ListTile(
                leading: Icon(track.selected
                    ? Icons.music_note
                    : Icons.music_note_outlined),
                title: Text(track.title ?? "Audio ${track.id}"),
                // subtitle: Text(track.data.toString()),
                selected: track.selected,
                onTap: () {
                  context.read<MpvSocket>().setProperty("aid", track.id);
                },
              ),
            const ListHeader("Video tracks"),
            ListTile(
              leading: Icon(
                  noVideo ? Icons.videocam_off : Icons.videocam_off_outlined),
              title: const Text("No video"),
              selected: noVideo,
              onTap: () {
                context.read<MpvSocket>().setProperty("vid", "0");
              },
            ),
            for (final track in videos)
              ListTile(
                leading: Icon(
                    track.selected ? Icons.videocam : Icons.videocam_outlined),
                title: Text(track.title ?? "Video ${track.id}"),
                // subtitle: Text(track.data.toString()),
                selected: track.selected,
                onTap: () {
                  context.read<MpvSocket>().setProperty("vid", track.id);
                },
              ),
          ],
        );
      },
    );
  }
}

class ListHeader extends StatelessWidget {
  const ListHeader(this.title, {Key? key}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, left: 16, bottom: 8),
          child: Text(
            title,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const Divider(height: 0),
      ],
    );
  }
}

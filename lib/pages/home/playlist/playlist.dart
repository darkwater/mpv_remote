import 'package:flutter/material.dart';
import 'package:mpv_remote/mpv_socket.dart';
import 'package:mpv_remote/widgets/property_builder.dart';
import 'package:provider/provider.dart';

class Playlist extends StatelessWidget {
  const Playlist({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyBuilder(
      properties: const ["playlist"],
      builder: (context, props) {
        final playlist = props.playlist!;

        return ListView.builder(
          itemCount: playlist.length,
          itemBuilder: (context, index) {
            final title = playlist[index].title;
            final filename = playlist[index].filename;
            final current = playlist[index].current;

            return ListTile(
              title: Text(title ?? filename),
              selected: current,
              onTap: () {
                context.read<MpvSocket>().playlistPlayIndex(index);
              },
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mpv_remote/remote_connection.dart';
import 'package:provider/provider.dart';

class RemoteAppBarTitle extends StatelessWidget {
  const RemoteAppBarTitle({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (appBarContext) {
      return Tooltip(
        message: "Change remote",
        child: TextButton(
          child: Consumer<RemoteConnection>(
            builder: (context, remote, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 24,
                ),
                child: Text(
                  remote.label,
                  style: DefaultTextStyle.of(appBarContext).style,
                ),
              );
            },
          ),
          onPressed: () {
            context.read<RemoteConnectionSelection>().value = null;
          },
        ),
      );
    });
  }
}

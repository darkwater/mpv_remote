import 'package:flutter/material.dart';
import 'package:mpv_remote/remote_connection.dart';
import 'package:provider/provider.dart';

class RemoteStatusIndicator extends StatefulWidget {
  const RemoteStatusIndicator(
    this.remote, {
    Key? key,
  }) : super(key: key);

  final RemoteConnection remote;

  @override
  State<RemoteStatusIndicator> createState() => _RemoteStatusIndicatorState();
}

class _RemoteStatusIndicatorState extends State<RemoteStatusIndicator> {
  late final Future<bool> _fut;

  @override
  void initState() {
    super.initState();

    _fut = widget.remote.detectMpv();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _fut,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (snapshot.error is MPVConnectionFailed) {
            return const Icon(
              Icons.play_disabled,
              color: Colors.blueGrey,
            );
          }

          return const Icon(
            Icons.error_outline,
            color: Colors.red,
          );
        }

        if (snapshot.hasData) {
          return const Icon(
            Icons.circle,
            color: Colors.green,
          );
        }

        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mpv_remote/remote_connection.dart';
import 'package:provider/provider.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RemoteConnectionSelection>(
      builder: (context, connection, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(connection.value?.label ?? "Loading..."),
          ),
          body: Stack(
            children: [
              const Center(
                child: CircularProgressIndicator(),
              ),
              Align(
                alignment: const Alignment(0, 0.5),
                child: TextButton(
                  onPressed: () => connection.value = null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.close, size: 32),
                        Text("Cancel", textScaleFactor: 1.4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

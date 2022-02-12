import 'package:flutter/material.dart';
import 'package:mpv_remote/remote_connection.dart';
import 'package:mpv_remote/storage.dart';
import 'package:mpv_remote/widgets/remote_status_indicator.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'add_remote.dart';

class RemotesPage extends StatelessWidget {
  const RemotesPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => const RemotesPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Remotes"),
      ),
      body: PreferenceBuilder<List<RemoteConnection>>(
        preference: Storage.remoteConnections,
        builder: (context, remotes) {
          return ListView(
            children: [
              for (final remote in remotes)
                ListTile(
                  title: Text(remote.label),
                  subtitle: Text(remote.host),
                  trailing: RemoteStatusIndicator(remote),
                  onTap: () {
                    context.read<RemoteConnectionSelection>().value = remote;
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text("Add remote"),
                onTap: () {
                  Navigator.push(
                    context,
                    AddRemotePage.route(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

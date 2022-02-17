import 'package:flutter/material.dart';
import 'package:mpv_remote/remote_connection.dart';
import 'package:mpv_remote/preferences.dart';
import 'package:mpv_remote/widgets/remote_status_indicator.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'add_remote.dart';

class RemotesPage extends StatefulWidget {
  const RemotesPage({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => const RemotesPage(),
    );
  }

  @override
  State<RemotesPage> createState() => _RemotesPageState();
}

class _RemotesPageState extends State<RemotesPage> {
  RemoteConnection? _deletedRemote;
  int? _deletedRemoteIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Remotes"),
      ),
      body: PreferenceBuilder<List<RemoteConnection>>(
        preference: Preferences.remoteConnections,
        builder: (context, remotes) {
          return ListView(
            children: [
              for (final remote in remotes)
                Dismissible(
                  key: ValueKey(remote.id),
                  child: ListTile(
                    title: Text(remote.label),
                    subtitle: Text(remote.host),
                    trailing: RemoteStatusIndicator(remote),
                    onTap: () {
                      context.read<RemoteConnectionSelection>().value = remote;
                    },
                  ),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).errorColor,
                    child: const Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.delete),
                      ),
                    ),
                  ),
                  confirmDismiss: (_) async {
                    setState(() {
                      _deletedRemote = remote;
                      _deletedRemoteIndex = remotes.indexOf(remote);
                    });

                    remotes.remove(remote);
                    Preferences.remoteConnections.setValue(remotes);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Removed ${remote.label}"),
                        action: SnackBarAction(
                          label: "Undo",
                          onPressed: () async {
                            final remotes =
                                await Preferences.remoteConnections.first;

                            Preferences.remoteConnections.setValue(
                              remotes
                                ..insert(_deletedRemoteIndex!, _deletedRemote!),
                            );

                            setState(() {
                              _deletedRemote = null;
                              _deletedRemoteIndex = null;
                            });
                          },
                        ),
                      ),
                    );

                    return true;
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

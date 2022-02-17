import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mpv_socket.dart';
import 'pages/home/home.dart';
import 'pages/loading.dart';
import 'pages/remotes/remotes.dart';
import 'remote_connection.dart';
import 'preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<RemoteConnectionSelection>(
        create: (_) => ValueNotifier(null),
      ),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MPV Remote",
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.black,
        hoverColor: Colors.white10,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A0950),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF4A0950),
          height: 64,
        ),
      ),
      home: Consumer<RemoteConnectionSelection>(
        builder: (context, connection, _) {
          if (connection.value != null) {
            return FutureBuilder<MpvSocket>(
              future: connection.value!.connect(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return MultiProvider(
                    providers: [
                      Provider<MpvSocket>.value(value: snapshot.data!),
                      Provider<RemoteConnection>.value(
                        value: connection.value!,
                      ),
                    ],
                    child: Navigator(
                      key: ValueKey(connection.value!.id),
                      onGenerateRoute: (settings) {
                        if (settings.name == "/") {
                          return HomePage.route();
                        }

                        return null;
                      },
                    ),
                  );
                } else {
                  return const LoadingPage();
                }
              },
            );
          } else {
            return const RemotesPage();
          }
        },
      ),
    );
  }
}

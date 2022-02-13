import 'package:flutter/material.dart';

import 'zoom.dart';

class More extends StatelessWidget {
  const More({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => ListView(
          children: [
            ListTile(
              title: const Text("Zoom"),
              trailing: const Icon(Icons.zoom_in),
              onTap: () {
                Navigator.push(
                  context,
                  Zoom.route(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

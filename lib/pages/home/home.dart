import 'package:flutter/material.dart';
import 'package:mpv_remote/pages/home/tracks/tracks.dart';
import 'package:mpv_remote/widgets/remote_app_bar_title.dart';

import 'controls/controls.dart';
import 'playlist/playlist.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => const HomePage(),
    );
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;

  static final _pages = [
    _Page("Controls", Icons.play_arrow, () => const Controls()),
    _Page("Playlist", Icons.playlist_play, () => const Playlist()),
    _Page("Tracks", Icons.art_track, () => const Tracks()),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController()
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const RemoteAppBarTitle(),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemBuilder: (_, idx) {
          return _pages[idx].builder();
        },
        itemCount: _pages.length,
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          for (final page in _pages)
            NavigationDestination(
              icon: Icon(page.icon),
              label: page.title,
            ),
        ],
        selectedIndex:
            (_pageController.hasClients ? _pageController.page ?? 0 : 0)
                .round(),
        onDestinationSelected: (idx) {
          _pageController.animateToPage(
            idx,
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
          );
        },
      ),
    );
  }
}

class _Page {
  final String title;
  final IconData icon;
  final Widget Function() builder;

  const _Page(
    this.title,
    this.icon,
    this.builder,
  );
}

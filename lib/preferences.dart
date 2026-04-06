import 'package:mpv_remote/prefs.dart';
import 'package:mpv_remote/remote_connection.dart';

class Preferences {
  static StreamingSharedPreferences? _prefs;

  static late final Preference<List<RemoteConnection>> remoteConnections;
  static late final Preference<bool> showPercentPos;
  static late final Preference<bool> showRemainingTime;

  static Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await StreamingSharedPreferences.instance;
    remoteConnections = _prefs!.getCustomValue(
      "remoteConnections",
      defaultValue: [],
      adapter: _remoteConnectionAdapter,
    );
    showPercentPos = _prefs!.getBool("showPercentPos", defaultValue: true);
    showRemainingTime =
        _prefs!.getBool("showRemainingTime", defaultValue: true);
  }
}

final _remoteConnectionAdapter = JsonAdapter<List<RemoteConnection>>(
  serializer: (value) => value.map((e) => e.toJson()).toList(),
  deserializer: (value) => (value as List<dynamic>)
      .map((e) => RemoteConnection.fromJson(e))
      .toList(),
);

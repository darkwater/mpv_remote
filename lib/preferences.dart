import 'package:mpv_remote/remote_connection.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class Preferences {
  static late StreamingSharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await StreamingSharedPreferences.instance;
  }

  static Preference<List<RemoteConnection>> get remoteConnections {
    return _prefs.getCustomValue(
      "remoteConnections",
      defaultValue: [],
      adapter: _remoteConnectionAdapter,
    );
  }

  static Preference<bool> get showPercentPos {
    return _prefs.getBool("showPercentPos", defaultValue: true);
  }

  static Preference<bool> get showRemainingTime {
    return _prefs.getBool("showRemainingTime", defaultValue: true);
  }
}

final _remoteConnectionAdapter = JsonAdapter(
  serializer: (value) => value.map((e) => e.toJson()).toList(),
  deserializer: (value) => (value as List<dynamic>)
      .map((e) => RemoteConnection.fromJson(e))
      .toList(),
);

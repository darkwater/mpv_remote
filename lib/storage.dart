import 'package:mpv_remote/remote_connection.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

class Storage {
  static late StreamingSharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await StreamingSharedPreferences.instance;
  }

  static final _remoteConnectionAdapter = JsonAdapter(
    serializer: (value) => value.map((e) => e.toJson()).toList(),
    deserializer: (value) => (value as List<dynamic>)
        .map((e) => RemoteConnection.fromJson(e))
        .toList(),
  );

  static Preference<List<RemoteConnection>> get remoteConnections {
    return _prefs.getCustomValue(
      "remoteConnections",
      defaultValue: [],
      adapter: _remoteConnectionAdapter,
    );
  }

  static Future<void> addRemoteConnection(RemoteConnection value) async {
    final current = await remoteConnections.first;
    current.add(value);
    await remoteConnections.setValue(current);
  }

  static Future<void> removeRemoteConnectionById(String id) async {
    final current = await remoteConnections.first;
    current.removeWhere((e) => e.id == id);
    await remoteConnections.setValue(current);
  }

  static Preference<bool> get showPercentPos {
    return _prefs.getBool("showPercentPos", defaultValue: true);
  }

  static Preference<bool> get showRemainingTime {
    return _prefs.getBool("showRemainingTime", defaultValue: true);
  }
}

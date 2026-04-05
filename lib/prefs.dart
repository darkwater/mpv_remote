import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef JsonSerializer<T> = dynamic Function(T value);
typedef JsonDeserializer<T> = T Function(dynamic value);

class JsonAdapter<T> {
  final JsonSerializer<T> serializer;
  final JsonDeserializer<T> deserializer;

  const JsonAdapter({required this.serializer, required this.deserializer});
}

class Preference<T> {
  final BehaviorSubject<T> _subject;
  final SharedPreferences _prefs;
  final String _key;
  final JsonAdapter<T>? _adapter;

  Preference._internal({
    required BehaviorSubject<T> subject,
    required SharedPreferences prefs,
    required String key,
    JsonAdapter<T>? adapter,
  })  : _subject = subject,
        _prefs = prefs,
        _key = key,
        _adapter = adapter;

  static T _read<T>(
    SharedPreferences prefs,
    String key,
    T defaultValue,
    JsonAdapter<T>? adapter,
  ) {
    if (adapter != null) {
      final raw = prefs.getString(key);
      if (raw == null) return defaultValue;
      try {
        return adapter.deserializer(jsonDecode(raw));
      } catch (_) {
        return defaultValue;
      }
    }
    if (T == bool) return ((prefs.getBool(key) ?? (defaultValue as bool)) as T);
    if (T == int) return ((prefs.getInt(key) ?? (defaultValue as int)) as T);
    if (T == double) {
      return ((prefs.getDouble(key) ?? (defaultValue as double)) as T);
    }
    if (T == String) {
      return ((prefs.getString(key) ?? (defaultValue as String)) as T);
    }
    return defaultValue;
  }

  factory Preference._create({
    required SharedPreferences prefs,
    required String key,
    required T defaultValue,
    JsonAdapter<T>? adapter,
  }) {
    final initial = _read<T>(prefs, key, defaultValue, adapter);
    return Preference._internal(
      subject: BehaviorSubject<T>.seeded(initial),
      prefs: prefs,
      key: key,
      adapter: adapter,
    );
  }

  T getValue() => _subject.value;

  Future<T> get first => _subject.first;

  Stream<T> get stream => _subject.stream;

  Future<void> setValue(T value) async {
    final adapter = _adapter;
    if (adapter != null) {
      await _prefs.setString(_key, jsonEncode(adapter.serializer(value)));
    } else if (value is bool) {
      await _prefs.setBool(_key, value);
    } else if (value is int) {
      await _prefs.setInt(_key, value);
    } else if (value is double) {
      await _prefs.setDouble(_key, value);
    } else if (value is String) {
      await _prefs.setString(_key, value);
    }
    _subject.add(value);
  }
}

class StreamingSharedPreferences {
  final SharedPreferences _prefs;

  StreamingSharedPreferences._(this._prefs);

  static Future<StreamingSharedPreferences> get instance async {
    return StreamingSharedPreferences._(await SharedPreferences.getInstance());
  }

  Preference<T> getCustomValue<T>(
    String key, {
    required T defaultValue,
    required JsonAdapter<T> adapter,
  }) {
    return Preference._create(
      prefs: _prefs,
      key: key,
      defaultValue: defaultValue,
      adapter: adapter,
    );
  }

  Preference<bool> getBool(String key, {required bool defaultValue}) {
    return Preference._create(
      prefs: _prefs,
      key: key,
      defaultValue: defaultValue,
    );
  }
}

class PreferenceBuilder<T> extends StatelessWidget {
  final Preference<T> preference;
  final Widget Function(BuildContext context, T value) builder;

  const PreferenceBuilder({
    super.key,
    required this.preference,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: preference.stream,
      initialData: preference.getValue(),
      builder: (context, snapshot) => builder(context, snapshot.requireData),
    );
  }
}
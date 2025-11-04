import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:mpv_remote/secure_storage.dart';

import 'mpv_socket.dart';

typedef RemoteConnectionSelection = ValueNotifier<RemoteConnection?>;

class RemoteConnection {
  final String id;
  final String label;
  final String host;
  final int port;
  final String username;
  final String socketPath;

  static String createId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }

  RemoteConnection({
    required this.id,
    required this.label,
    required this.host,
    required this.port,
    required this.username,
    required this.socketPath,
  });

  factory RemoteConnection.fromJson(Map<String, dynamic> json) {
    return RemoteConnection(
      id: json['id'],
      label: json['label'],
      host: json['host'],
      port: json['port'],
      username: json['username'],
      socketPath: json['socketPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'host': host,
      'port': port,
      'username': username,
      'socketPath': socketPath,
    };
  }

  Future<String?> _getPassword() async {
    return await SecureStorage.getPasswordById(id);
  }

  Future<bool> testConnection(Sink<String> printOut) async {
    final socket = await SSHSocket.connect(host, port);
    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: _getPassword,
      printDebug: (s) => printOut.add(s ?? ""),
    );

    await client.authenticated;

    printOut.add("connection successful.");

    late final SSHSession session;
    late final String util;

    if (client.remoteVersion?.contains("Windows") ?? false) {
      printOut.add("Windows detected.");
      util = "npiperelay";
      session = await client.execute("where.exe $util.exe");
    } else {
      util = "socat";
      session = await client.execute("which $util");
    }
    session.stdin.close();

    await session.stdout.listen((bytes) {
      for (final line in utf8.decode(bytes).trim().split("\n")) {
        printOut.add("$util found: $line");
      }
    }).asFuture();

    await session.done;

    if (session.exitCode == 0) {
      printOut.add("`$util` found.");
      printOut.add("test successful.");
      return true;
    } else {
      printOut.add("`$util` not found.");
      printOut.add("test failed.");
      return false;
    }
  }

  Future<MpvSocket> connect() async {
    final socket = await SSHSocket.connect(host, port);
    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: _getPassword,
    );

    await client.authenticated;

    final session = await client.execute(
        "${client.remoteVersion?.contains("Windows") ?? false ? "npiperelay.exe" : "socat -"} $socketPath");

    // stdin and stdout are newline-separated JSON objects
    return MpvSocket(
      session.stdin,
      session.stdout
          .map((event) => event.toList(growable: false))
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .map<Map<String, dynamic>>((line) => json.decode(line))
          .asBroadcastStream(),
    );
  }

  Future<bool> detectMpv() async {
    final conn = await connect();

    await conn.execute("get_property", ["mpv-version"]);

    return true;
  }
}

class SSHConnectionFailed implements Exception {}

class MPVConnectionFailed implements Exception {}

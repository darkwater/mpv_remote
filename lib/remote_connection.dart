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
    final privateKey = await SecureStorage.getPrivateKeyById(id);
    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: _getPassword,
      identities: privateKey == null ? null : SSHKeyPair.fromPem(privateKey),
      printDebug: (s) => printOut.add(s ?? ""),
    );

    await client.authenticated;

    printOut.add("connection successful.");

    final session = await client.execute("which socat");
    session.stdin.close();

    await session.stdout.listen((bytes) {
      for (final line in utf8.decode(bytes).trim().split("\n")) {
        printOut.add("which: $line");
      }
    }).asFuture();

    await session.done;

    if (session.exitCode == 0) {
      printOut.add("`socat` found.");
      printOut.add("test successful.");
      return true;
    } else {
      printOut.add("`socat` not found.");
      printOut.add("test failed.");
      return false;
    }
  }

  Future<MpvSocket> connect() async {
    final socket = await SSHSocket.connect(host, port);
    final privateKey = await SecureStorage.getPrivateKeyById(id);
    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: _getPassword,
      identities: privateKey == null ? null : SSHKeyPair.fromPem(privateKey),
    );

    await client.authenticated;

    final session = await client.execute("socat - $socketPath");

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

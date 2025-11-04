import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mpv_remote/remote_connection.dart';
import 'package:mpv_remote/secure_storage.dart';
import 'package:mpv_remote/preferences.dart';
import 'package:mpv_remote/widgets/async_button.dart';

class AddRemotePage extends StatefulWidget {
  const AddRemotePage({Key? key}) : super(key: key);

  static Route route() => MaterialPageRoute<void>(
        builder: (_) => const AddRemotePage(),
        fullscreenDialog: true,
      );

  @override
  _AddRemotePageState createState() => _AddRemotePageState();
}

const _horizPadding = 16.0;

class _AddRemotePageState extends State<AddRemotePage> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _socketPathController = TextEditingController();

  late final String _id;
  bool _keepPassword = false;
  bool _keepPrivateKey = false;

  static const _defaultPort = "22";
  static const _defaultSocketPath = "/tmp/mpvsocket";

  List<Widget> testOutput = [];

  @override
  void initState() {
    super.initState();

    _id = RemoteConnection.createId();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _socketPathController.dispose();

    if (!_keepPassword) {
      _deletePassword();
    }

    if (!_keepPrivateKey) {
      _deletePrivateKey();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Add remote"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: _horizPadding),
                _Field(_labelController, "Label"),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const SizedBox(width: _horizPadding),
                    Expanded(
                      child: _Field(
                        _hostController,
                        "Host",
                        padding: false,
                        urlKeyboard: true,
                      ),
                    ),
                    const SizedBox(width: _horizPadding / 2),
                    const Text(":"),
                    const SizedBox(width: _horizPadding / 2),
                    SizedBox(
                      width: 96,
                      child: _Field(
                        _portController,
                        "Port",
                        padding: false,
                        portNumber: true,
                        defaultValue: _defaultPort,
                      ),
                    ),
                    const SizedBox(width: _horizPadding),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: _horizPadding),
                  child: TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: "Username",
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return "Username is required";
                      }
                      return null;
                    },
                  ),
                ),
                _Field(_passwordController, "Password", password: true),
                _Field(
                  _privateKeyController,
                  "Private Key",
                  privateKey: true,
                ),
                _Field(
                  _socketPathController,
                  "Socket path",
                  defaultValue: _defaultSocketPath,
                  urlKeyboard: true,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const SizedBox(width: _horizPadding),
                    Expanded(
                      child: ElevatedButton(
                        child: const Text("Add"),
                        onPressed: _submitForm,
                      ),
                    ),
                    const SizedBox(width: _horizPadding),
                    Expanded(
                      child: AsyncButton(
                        label: "Test",
                        onPressed: _testConnection,
                      ),
                    ),
                    const SizedBox(width: _horizPadding),
                  ],
                ),
                const SizedBox(height: 16),
                ...testOutput,
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  RemoteConnection? _readForm() {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    String label = _labelController.text;
    String host = _hostController.text;
    String port = _portController.text;
    String username = _usernameController.text;
    String socketPath = _socketPathController.text;

    if (label.isEmpty) label = host;
    if (port.isEmpty) port = _defaultPort;
    if (socketPath.isEmpty) socketPath = _defaultSocketPath;

    return RemoteConnection(
      id: _id,
      label: label,
      host: host,
      port: int.parse(port),
      username: username,
      socketPath: socketPath,
    );
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;
    SecureStorage.savePassword(_id, password);
  }

  Future<void> _savePrivateKey() async {
    final privateKey = _privateKeyController.text;
    SecureStorage.savePrivateKey(_id, privateKey);
  }

  Future<void> _deletePassword() async {
    SecureStorage.deletePassword(_id);
  }

  Future<void> _deletePrivateKey() async {
    SecureStorage.deletePrivateKey(_id);
  }

  Future<bool> _testConnection() async {
    final conn = _readForm();
    if (conn == null) {
      return false;
    }

    setState(() {
      testOutput = [
        const Text("Testing connection..."),
      ];
    });

    await _savePassword();
    await _savePrivateKey();

    final sc = StreamController<String>();
    sc.stream.listen((line) {
      final readable = line
          .replaceFirst(
            RegExp(r"^SSH(Client|Transport)\._?"),
            "",
          )
          .replaceAllMapped(
            RegExp(r"([A-Z])([a-z])"),
            (match) => " " + match.group(1)!.toLowerCase() + match.group(2)!,
          );

      final Widget widget;

      if (readable.contains("remote version =") ||
          readable.contains("start authentication") ||
          readable.contains("auth with") ||
          readable.startsWith("which: ") ||
          readable.contains("handle userauth")) {
        widget = Text(readable);
      } else if (readable.contains(" successful.") ||
          readable.contains("` found.")) {
        widget = Text(
          readable,
          style: const TextStyle(color: Colors.green),
        );
      } else if (readable.contains("close with error") ||
          readable.contains("` not found.") ||
          readable.contains("test failed")) {
        widget = Text(
          readable,
          style: const TextStyle(color: Colors.red),
        );
      } else {
        widget = Opacity(
          opacity: 0.6,
          child: Text(readable),
        );
      }

      setState(() {
        testOutput.insert(
          0,
          widget,
        );
      });
    });

    return await conn.testConnection(sc.sink);
  }

  void _submitForm() async {
    final remote = _readForm();
    if (remote != null) {
      final remotes = await Preferences.remoteConnections.first;
      remotes.add(remote);
      Preferences.remoteConnections.setValue(remotes);

      await _savePassword();
      await _savePrivateKey();

      _keepPassword = true;
      _keepPrivateKey = true;
      Navigator.pop(context);
    }
  }
}

class _Field extends StatefulWidget {
  const _Field(
    this.controller,
    this.label, {
    this.defaultValue,
    this.padding = true,
    this.urlKeyboard = false,
    this.portNumber = false,
    this.password = false,
    this.privateKey = false,
    Key? key,
  }) : super(key: key);

  final TextEditingController controller;
  final String label;
  final String? defaultValue;
  final bool padding;
  final bool urlKeyboard;
  final bool portNumber;
  final bool password;
  final bool privateKey;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      maxLines: widget.privateKey ? null : 1,
      controller: widget.controller,
      textInputAction: TextInputAction.next,
      obscureText: widget.password && !showPassword,
      keyboardType: widget.portNumber
          ? TextInputType.number
          : widget.urlKeyboard
              ? TextInputType.url
              : (widget.password && showPassword)
                  ? TextInputType.visiblePassword
                  : widget.privateKey
                      ? TextInputType.multiline
                      : TextInputType.text,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        floatingLabelBehavior: (widget.defaultValue != null)
            ? FloatingLabelBehavior.always
            : FloatingLabelBehavior.auto,
        labelText: widget.label,
        hintText: widget.defaultValue,
        suffixIcon: (widget.password)
            ? IconButton(
                focusNode: FocusNode(skipTraversal: true),
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              )
            : null,
      ),
      validator: (value) {
        if (widget.defaultValue == null &&
            !widget.password &&
            (value?.isEmpty ?? true)) {
          return "${widget.label} is required";
        }

        if (widget.portNumber) {
          final port = int.tryParse(
            ((value?.isNotEmpty ?? false) ? value : widget.defaultValue) ?? "",
          );

          if (port == null || port < 1 || port > 65535) {
            return "Invalid value";
          }
        }

        return null;
      },
    );

    if (widget.padding) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _horizPadding),
        child: field,
      );
    } else {
      return field;
    }
  }
}

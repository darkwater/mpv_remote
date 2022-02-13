import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mpv_remote/remote_connection.dart';

class MpvSocket {
  MpvSocket(this.stdin, this.stdout) {
    execute("disable_event", ["all"]);
  }

  final StreamSink<Uint8List> stdin;
  final Stream<Map<String, dynamic>> stdout;

  int requestId = 1;
  int observeId = 1;

  Future<T> execute<T>(
    String command, [
    List<dynamic> arguments = const [],
  ]) async {
    final id = requestId++;
    final data = jsonEncode({
          "command": [command, ...arguments],
          "request_id": id,
        }) +
        "\n";
    final bytes = Uint8List.fromList(utf8.encode(data));
    stdin.add(bytes);

    try {
      final res = await stdout.firstWhere((event) => event["request_id"] == id);

      if (res["error"] != "success") {
        throw Exception(res["error"]);
      }

      return res["data"] as T;
    } on StateError {
      throw MPVConnectionFailed();
    } catch (_) {
      rethrow;
    }
  }

  Future<T> getProperty<T>(String name) async {
    final res = await execute<T>("get_property", [name]);
    return res;
  }

  Future setProperty<T>(String name, T value) async {
    final res = await execute("set_property", [name, value]);
    return res;
  }

  Stream<Map<String, dynamic>> observeProperties(
    List<String> properties,
  ) async* {
    final id = observeId++;

    final sc = StreamController(
      onCancel: () async {
        print("unobserving $properties");
        execute("unobserve_property", [id]);
      },
    );

    sc.addStream(stdout.where((event) {
      return event["event"] == "property-change" && event["id"] == id;
    }));

    Future.wait([
      for (final property in properties)
        execute("observe_property", [id, property]),
    ]);

    final snapshot = <String, dynamic>{
      for (final property in properties) property: null,
    };

    await for (final event in sc.stream) {
      snapshot[event["name"]] = event["data"];
      yield snapshot;
    }
  }

  Future<void> playlistPlayIndex(int index) async {
    await execute("playlist-play-index", [index]);
  }

  /// Position in current file (0-100). The advantage over using this instead of
  /// calculating it out of other properties is that it properly falls back to
  /// estimating the playback position from the byte position, if the file
  /// duration is not known.
  set percentPos(double v) => setProperty("percent-pos", v);

  /// Position in current file in seconds.
  set timePos(double v) => setProperty("time-pos", v);

  /// Position in current file in seconds. Unlike time-pos, the time is clamped
  /// to the range of the file. (Inaccurate file durations etc. could make it go
  /// out of range. Useful on attempts to seek outside of the file, as the seek
  /// target time is considered the current position during seeking.)
  set playbackTime(double v) => setProperty("playback-time", v);

  /// Current chapter number. The number of the first chapter is 0.
  set chapter(int v) => setProperty("chapter", v);

  /// Current MKV edition number. Setting this property to a different value
  /// will restart playback. The number of the first edition is 0.
  ///
  /// Before mpv 0.31.0, this showed the actual edition selected at runtime, if
  /// you didn't set the option or property manually. With mpv 0.31.0 and later,
  /// this strictly returns the user-set option or property value, and the
  /// current-edition property was added to return the runtime selected edition
  /// (this matters with --edition=auto, the default).
  set edition(int v) => setProperty("edition", v);

  /// System volume. This property is available only if mpv audio output is
  /// currently active, and only if the underlying implementation supports
  /// volume control. What this option does depends on the API. For example, on
  /// ALSA this usually changes system-wide audio, while with PulseAudio this
  /// controls per-application volume.
  set aoVolume(double v) => setProperty("ao-volume", v);

  /// Similar to ao-volume, but controls the mute state. May be unimplemented
  /// even if ao-volume works.
  set aoMute(bool v) => setProperty("ao-mute", v);

  /// Reflects the --hwdec option.
  ///
  /// Writing to it may change the currently used hardware decoder, if possible.
  /// (Internally, the player may reinitialize the decoder, and will perform a
  /// seek to refresh the video properly.) You can watch the other hwdec
  /// properties to see whether this was successful.
  ///
  /// Unlike in mpv 0.9.x and before, this does not return the currently active
  /// hardware decoder. Since mpv 0.18.0, hwdec-current is available for this
  /// purpose.
  set hwdec(String v) => setProperty("hwdec", v);

  /// Window size multiplier. Setting this will resize the video window to the
  /// values contained in dwidth and dheight multiplied with the value set with
  /// this property. Setting 1 will resize to original video size (or to be
  /// exact, the size the video filters output). 2 will set the double size, 0.5
  /// halves the size.
  ///
  /// Note that setting a value identical to its previous value will not resize
  /// the window. That's because this property mirrors the window-scale option,
  /// and setting an option to its previous value is ignored. If this value is
  /// set while the window is in a fullscreen, the multiplier is not applied
  /// until the window is taken out of that state. Writing this property to a
  /// maximized window can unmaximize the window depending on the OS and window
  /// manager. If the window does not unmaximize, the multiplier will be applied
  /// if the user unmaximizes the window later.
  ///
  /// See current-window-scale for the value derived from the actual window
  /// size.
  ///
  /// Since mpv 0.31.0, this always returns the previously set value (or the
  /// default value), instead of the value implied by the actual window size.
  /// Before mpv 0.31.0, this returned what current-window-scale returns now,
  /// after the window was created.
  set windowScale(double v) => setProperty("window-scale", v);

  /// The window-scale value calculated from the current window size. This has
  /// the same value as window-scale if the window size was not changed since
  /// setting the option, and the window size was not restricted in other ways.
  /// If the window is fullscreened, this will return the scale value calculated
  /// from the last non-fullscreen size of the window. The property is
  /// unavailable if no video is active.
  ///
  /// When setting this property in the fullscreen or maximized state, the
  /// behavior is the same as window-scale. In all ther cases, setting the value
  /// of this property will always resize the window. This does not affect the
  /// value of window-scale.
  set currentWindowScale(double v) => setProperty("current-window-scale", v);

  /// See --cursor-autohide. Setting this to a new value will always update the cursor, and reset the internal timer.
  set cursorAutohide(bool v) => setProperty("cursor-autohide", v);

  /// Set the audio device. This directly reads/writes the --audio-device
  /// option, but on write accesses, the audio output will be scheduled for
  /// reloading.
  ///
  /// Writing this property while no audio output is active will not
  /// automatically enable audio. (This is also true in the case when audio was
  /// disabled due to reinitialization failure after a previous write access to
  /// audio-device.)
  ///
  /// This property also doesn't tell you which audio device is actually in use.
  ///
  /// How these details are handled may change in the future.
  set audioDevice(String v) => setProperty("audio-device", v);

  set pause(bool v) => setProperty("pause", v);

  set videoZoom(double v) => setProperty("video-zoom", v);
  set videoAlignX(double v) => setProperty("video-align-x", v);
  set videoAlignY(double v) => setProperty("video-align-y", v);
}

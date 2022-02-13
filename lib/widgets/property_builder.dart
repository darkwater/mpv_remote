import "package:flutter/material.dart";
import "package:mpv_remote/mpv_socket.dart";
import "package:provider/provider.dart";
import "package:rxdart/rxdart.dart";

class PropertyBuilder extends StatefulWidget {
  const PropertyBuilder({
    required this.properties,
    required this.builder,
    this.errorBuilder = _defaultErrorBuilder,
    this.loadingBuilder = _defaultLoadingBuilder,
    Key? key,
  }) : super(key: key);

  final List<String> properties;
  final Widget Function(BuildContext, PropertySnapshot) builder;
  final Widget Function(BuildContext, Object) errorBuilder;
  final Widget Function(BuildContext) loadingBuilder;

  @override
  _PropertyBuilderState createState() => _PropertyBuilderState();

  static Widget _defaultErrorBuilder(
    BuildContext context,
    Object exception,
  ) {
    return Center(child: Text(exception.toString()));
  }

  static Widget _defaultLoadingBuilder(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}

class _PropertyBuilderState extends State<PropertyBuilder> {
  late final Stream<Map<String, dynamic>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context
        .read<MpvSocket>()
        .observeProperties(widget.properties)
        .debounceTime(const Duration(milliseconds: 20));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return widget.builder(context, PropertySnapshot(snapshot.data!));
        } else if (snapshot.hasError) {
          return widget.errorBuilder(context, snapshot.error!);
        } else {
          return widget.loadingBuilder(context);
        }
      },
    );
  }
}

class PropertySnapshot {
  const PropertySnapshot(this.data, [this.error]);

  final Map<String, dynamic> data;
  final Object? error;

  dynamic operator [](String key) => data[key];

  Playlist? get playlist =>
      data["playlist"] == null ? null : Playlist(data["playlist"]!);

  ChapterList? get chapterList =>
      data["chapter-list"] == null ? null : ChapterList(data["chapter-list"]!);

  List<Track>? get trackList => data["track-list"] == null
      ? null
      : data["track-list"]!.map<Track>((v) => Track(v)).toList();

  /// Returns whether the player is paused.
  bool? get pause => data[MpvProperty.pause];

  double? get videoZoom => data[MpvProperty.videoZoom];
  double? get videoAlignX => data[MpvProperty.videoAlignX];
  double? get videoAlignY => data[MpvProperty.videoAlignY];

  /// Currently played file, with path stripped. If this is an URL, try to undo
  /// percent encoding as well. (The result is not necessarily correct, but
  /// looks better for display purposes. Use the path property to get an
  /// unmodified filename.)
  String? get filename => data[MpvProperty.filename];

  /// Length in bytes of the source file/stream. (This is the same as
  /// ${stream-end}. For segmented/multi-part files, this will return the size
  /// of the main or manifest file, whatever it is.)
  int? get fileSize => data[MpvProperty.fileSize];

  /// Full path of the currently played file. Usually this is exactly the same
  /// string you pass on the mpv command line or the loadfile command, even if
  /// it"s a relative path. If you expect an absolute path, you will have to
  /// determine it yourself, for example by using the working-directory
  /// property.
  String? get path => data[MpvProperty.path];

  /// If the currently played file has a title tag, use that.
  ///
  /// Otherwise, return the filename property.
  String? get mediaTitle => data[MpvProperty.mediaTitle];

  /// Symbolic name of the file format. In some cases, this is a comma-separated
  /// list of format names, e.g. mp4 is mov,mp4,m4a,3gp,3g2,mj2 (the list may
  /// grow in the future for any format).
  String? get fileFormat => data[MpvProperty.fileFormat];

  /// Duration of the current file in seconds. If the duration is unknown, the
  /// property is unavailable. Note that the file duration is not always exactly
  /// known, so this is an estimate.
  ///
  /// This replaces the length property, which was deprecated after the mpv 0.9
  /// release. (The semantics are the same.)
  double? get duration => data[MpvProperty.duration];

  /// Position in current file (0-100). The advantage over using this instead of
  /// calculating it out of other properties is that it properly falls back to
  /// estimating the playback position from the byte position, if the file
  /// duration is not known.
  double? get percentPos => data[MpvProperty.percentPos];

  /// Position in current file in seconds.
  double? get timePos => data[MpvProperty.timePos];

  /// Remaining length of the file in seconds. Note that the file duration is
  /// not always exactly known, so this is an estimate.
  double? get timeRemaining => data[MpvProperty.timeRemaining];

  int? get playlistPos => data[MpvProperty.playlistPos];
  int? get playlistCount => data[MpvProperty.playlistCount];
  int? get chapter => data[MpvProperty.chapter];
  int? get chapters => data[MpvProperty.chapters];
  bool? get seekable => data[MpvProperty.seekable];
  bool? get seeking => data[MpvProperty.seeking];
}

class Playlist {
  Playlist(List<dynamic> data)
      : entries = data.map((entry) => PlaylistEntry(entry)).toList(
              growable: false,
            );

  final List<PlaylistEntry> entries;

  PlaylistEntry operator [](int key) => entries[key];

  int get length => entries.length;
}

class PlaylistEntry {
  const PlaylistEntry(this.data);

  final Map<String, dynamic> data;

  int get id => data["id"]!;
  String get filename => data["filename"]!;
  String? get title => data["title"];
  bool get playing => data["playing"] ?? false;
  bool get current => data["current"] ?? false;
}

class ChapterList {
  ChapterList(List<dynamic> data)
      : chapters = data.map((entry) => Chapter(entry)).toList(
              growable: false,
            );

  final List<Chapter> chapters;

  Chapter operator [](int key) => chapters[key];

  int get length => chapters.length;
}

class Chapter {
  const Chapter(this.data);

  final Map<String, dynamic> data;

  String? get title => data["title"];
  double get time => data["time"]!;
}

class Track {
  const Track(this.data);

  final Map<String, dynamic> data;

  /// The ID as it's used for --sid/--aid/--vid. This is unique within tracks of
  /// the same type (sub/audio/video), but otherwise not.
  int get id => data["id"]!;

  /// The type of the track. One of "audio", "video", "sub".
  String get type => data["type"]!;

  /// Track ID as used in the source file. (It is missing if the format has no
  /// native ID, if the track is a pseudo-track that does not exist in this way
  /// in the actual file, or if the format is handled by libavformat, and the
  /// format was not whitelisted as having track IDs.)
  int? get srcId => data["src-id"];

  /// Track title as it is stored in the file.
  String? get title => data["title"];

  /// Track language as identified by the file.
  String? get lang => data["lang"];

  /// true if this is a video track that consists of a single picture, no/false
  /// or unavailable otherwise. The heuristic used to determine if a stream is
  /// an image doesn't attempt to detect images in codecs normally used for
  /// videos. Otherwise, it is reliable.
  bool get image => data["image"] ?? false;

  /// true if this is an image embedded in an audio file or external cover art.
  bool get albumart => data["albumart"] ?? false;

  /// true if the track has the default flag set in the file.
  bool get defaultTrack => data["default"] ?? false;

  /// true if the track has the forced flag set in the file.
  bool get forcedTrack => data["forced"] ?? false;

  /// The codec name used by this track, for example "h264". Unavailable in some
  /// rare cases.
  String? get codec => data["codec"];

  /// true if the track is an external file. This is set for separate subtitle
  /// files.
  bool get external => data["external"] ?? false;

  /// The filename if the track is from an external file.
  String? get externalFilename => data["external-filename"];

  /// true if the track is currently decoded.
  bool get selected => data["selected"] ?? false;

  // TODO: more
}

abstract class MpvProperty {
  /// Slow down or speed up playback by the factor given as parameter.
  ///
  /// If --audio-pitch-correction (on by default) is used, playing with a speed
  /// higher than normal automatically inserts the scaletempo2 audio filter.
  static const String speed = "speed";

  /// Pause.
  static const String pause = "pause";

  /// Play files in random order.
  static const String shuffle = "shuffle";

  /// Adjust the video display scale factor by the given value. The parameter is
  /// given log 2. For example, --video-zoom=0 is unscaled, --video-zoom=1 is
  /// twice the size, --video-zoom=-2 is one fourth of the size, and so on.
  ///
  /// This option is disabled if the --no-keepaspect option is used.
  static const String videoZoom = "video-zoom";

  /// Moves the video rectangle within the black borders, which are usually
  /// added to pad the video to screen if video and screen aspect ratios are
  /// different. --video-align-y=-1 would move the video to the top of the
  /// screen (leaving a border only on the bottom), a value of 0 centers it
  /// (default), and a value of 1 would put the video at the bottom of the
  /// screen.
  ///
  /// If video and screen aspect match perfectly, these options do nothing.
  ///
  /// This option is disabled if the --no-keepaspect option is used.
  static const String videoAlignY = "video-align-y";

  /// Moves the video rectangle within the black borders, which are usually
  /// added to pad the video to screen if video and screen aspect ratios are
  /// different. --video-align-x=-1 would move the video to the left of the
  /// screen (leaving a border only on the right), a value of 0 centers it
  /// (default), and a value of 1 would put the video at the right of the
  /// screen.
  ///
  /// If video and screen aspect match perfectly, these options do nothing.
  ///
  /// This option is disabled if the --no-keepaspect option is used.
  static const String videoAlignX = "video-align-x";

  // ↑ options | properties ↓

  /// Factor multiplied with speed at which the player attempts to play the
  /// file. Usually it's exactly 1. (Display sync mode will make this useful.)
  ///
  /// OSD formatting will display it in the form of +1.23456%, with the number
  /// being (raw - 1) * 100 for the given raw property value.
  static const String audioSpeedCorrection = "audio-speed-correction";

  /// Factor multiplied with speed at which the player attempts to play the
  /// file. Usually it's exactly 1. (Display sync mode will make this useful.)
  ///
  /// OSD formatting will display it in the form of +1.23456%, with the number
  /// being (raw - 1) * 100 for the given raw property value.
  static const String videoSpeedCorrection = "video-speed-correction";

  /// Whether --video-sync=display is actually active.
  static const String displaySyncActive = "display-sync-active";

  /// Currently played file, with path stripped. If this is an URL, try to undo
  /// percent encoding as well. (The result is not necessarily correct, but
  /// looks better for display purposes. Use the path property to get an
  /// unmodified filename.)
  static const String filename = "filename";

  /// Length in bytes of the source file/stream. (This is the same as
  /// ${stream-end}. For segmented/multi-part files, this will return the size
  /// of the main or manifest file, whatever it is.)
  static const String fileSize = "file-size";

  /// Total number of frames in current file.
  ///
  /// ## Note
  /// This is only an estimate. (It's computed from two unreliable quantities:
  /// fps and stream length.)
  static const String estimatedFrameCount = "estimated-frame-count";

  /// Number of current frame in current stream.
  ///
  /// ## Note
  /// This is only an estimate. (It's computed from two unreliable quantities:
  /// fps and possibly rounded timestamps.)
  static const String estimatedFrameNumber = "estimated-frame-number";

  /// Process-id of mpv.
  static const String pid = "pid";

  /// Full path of the currently played file. Usually this is exactly the same
  /// string you pass on the mpv command line or the loadfile command, even if
  /// it's a relative path. If you expect an absolute path, you will have to
  /// determine it yourself, for example by using the working-directory
  /// property.
  static const String path = "path";

  /// The full path to the currently played media. This is different from path
  /// only in special cases. In particular, if --ytdl=yes is used, and the URL
  /// is detected by youtube-dl, then the script will set this property to the
  /// actual media URL. This property should be set only during the on_load or
  /// on_load_fail hooks, otherwise it will have no effect (or may do
  /// something implementation defined in the future). The property is reset if
  /// playback of the current media ends.
  static const String streamOpenFilename = "stream-open-filename";

  /// If the currently played file has a title tag, use that.
  ///
  /// Otherwise, return the filename property.
  static const String mediaTitle = "media-title";

  /// Symbolic name of the file format. In some cases, this is a comma-separated
  /// list of format names, e.g. mp4 is mov,mp4,m4a,3gp,3g2,mj2 (the list may
  /// grow in the future for any format).
  static const String fileFormat = "file-format";

  /// Name of the current demuxer. (This is useless.)
  ///
  /// (Renamed from demuxer.)
  static const String currentDemuxer = "current-demuxer";

  /// Filename (full path) of the stream layer filename. (This is probably
  /// useless and is almost never different from path.)
  static const String streamPath = "stream-path";

  /// Raw byte position in source stream. Technically, this returns the
  /// position of the most recent packet passed to a decoder.
  static const String streamPos = "stream-pos";

  /// Raw end position in bytes in source stream.
  static const String streamEnd = "stream-end";

  /// Duration of the current file in seconds. If the duration is unknown, the
  /// property is unavailable. Note that the file duration is not always
  /// exactly known, so this is an estimate.
  ///
  /// This replaces the length property, which was deprecated after the mpv
  /// 0.9 release. (The semantics are the same.)
  static const String duration = "duration";

  /// Last A/V synchronization difference. Unavailable if audio or video is
  /// disabled.
  static const String avsync = "avsync";

  /// Total A-V sync correction done. Unavailable if audio or video is disabled.
  static const String totalAvsyncChange = "total-avsync-change";

  static const String decoderFrameDropCount = "decoder-frame-drop-count";
  static const String frameDropCount = "frame-drop-count";
  static const String mistimedFrameCount = "mistimed-frame-count";
  static const String vsyncRatio = "vsync-ratio";
  static const String voDelayedFrameCount = "vo-delayed-frame-count";
  static const String percentPos = "percent-pos";

  /// Position in current file in seconds.
  static const String timePos = "time-pos";

  /// Remaining length of the file in seconds. Note that the file duration is
  /// not always exactly known, so this is an estimate.
  static const String timeRemaining = "time-remaining";

  static const String audioPts = "audio-pts";
  static const String playtimeRemaining = "playtime-remaining";
  static const String playbackTime = "playback-time";

  /// Current chapter number. The number of the first chapter is 0.
  static const String chapter = "chapter";

  /// Current MKV edition number. Setting this property to a different value
  /// will restart playback. The number of the first edition is 0.
  ///
  /// Before mpv 0.31.0, this showed the actual edition selected at runtime, if
  /// you didn't set the option or property manually. With mpv 0.31.0 and later,
  /// this strictly returns the user-set option or property value, and the
  /// current-edition property was added to return the runtime selected edition
  /// (this matters with --edition=auto, the default).
  static const String edition = "edition";

  /// Currently selected edition. This property is unavailable if no file is
  /// loaded, or the file has no editions. (Matroska files make a difference
  /// between having no editions and a single edition, which will be reflected
  /// by the property, although in practice it does not matter.)
  static const String currentEdition = "current-edition";

  /// Number of chapters.
  static const String chapters = "chapters";

  /// Number of MKV editions.
  static const String editions = "editions";

  /// List of editions.
  static const String editionList = "edition-list";

  static const String metadata = "metadata";
  static const String filteredMetadata = "filtered-metadata";
  static const String chapterMetadata = "chapter-metadata";

  /// Returns yes/true if no file is loaded, but the player is staying around
  /// because of the --idle option.
  ///
  /// (Renamed from idle.)
  static const String idleActive = "idle-active";
  static const String coreIdle = "core-idle";
  static const String cacheSpeed = "cache-speed";
  static const String demuxerCacheDuration = "demuxer-cache-duration";
  static const String demuxerCacheTime = "demuxer-cache-time";
  static const String demuxerCacheIdle = "demuxer-cache-idle";
  static const String demuxerCacheState = "demuxer-cache-state";
  static const String demuxerViaNetwork = "demuxer-via-network";
  static const String demuxerStartTime = "demuxer-start-time";
  static const String pausedForCache = "paused-for-cache";
  static const String cacheBufferingState = "cache-buffering-state";
  static const String eofReached = "eof-reached";

  /// Whether the player is currently seeking, or otherwise trying to restart
  /// playback. (It's possible that it returns yes/true while a file is loaded.
  /// This is because the same underlying code is used for seeking and
  /// resyncing.)
  static const String seeking = "seeking";

  static const String mixerActive = "mixer-active";
  static const String aoVolume = "ao-volume";
  static const String aoMute = "ao-mute";
  static const String audioCodec = "audio-codec";
  static const String audioCodecName = "audio-codec-name";
  static const String audioParams = "audio-params";
  static const String audioOutParams = "audio-out-params";
  static const String colormatrix = "colormatrix";
  static const String colormatrixInputRange = "colormatrix-input-range";
  static const String colormatrixPrimaries = "colormatrix-primaries";
  static const String hwdec = "hwdec";
  static const String hwdecCurrent = "hwdec-current";
  static const String hwdecInterop = "hwdec-interop";
  static const String videoFormat = "video-format";
  static const String videoCodec = "video-codec";
  static const String width = "width";
  static const String height = "height";
  static const String videoParams = "video-params";
  static const String dwidth = "dwidth";
  static const String dheight = "dheight";
  static const String videoDecParams = "video-dec-params";
  static const String videoOutParams = "video-out-params";
  static const String videoFrameInfo = "video-frame-info";
  static const String containerFps = "container-fps";
  static const String estimatedVfFps = "estimated-vf-fps";
  static const String windowScale = "window-scale";
  static const String currentWindowScale = "current-window-scale";
  static const String focused = "focused";
  static const String displayNames = "display-names";
  static const String displayFps = "display-fps";
  static const String estimatedDisplayFps = "estimated-display-fps";
  static const String vsyncJitter = "vsync-jitter";
  static const String displayWidth = "display-width";
  static const String displayHeight = "display-height";
  static const String displayHidpiScale = "display-hidpi-scale";
  static const String osdWidth = "osd-width";
  static const String osdHeight = "osd-height";
  static const String osdPar = "osd-par";
  static const String osdDimensions = "osd-dimensions";
  static const String mousePos = "mouse-pos";
  static const String subText = "sub-text";
  static const String subTextAss = "sub-text-ass";
  static const String secondarySubText = "secondary-sub-text";
  static const String subStart = "sub-start";
  static const String secondarySubStart = "secondary-sub-start";
  static const String subEnd = "sub-end";
  static const String secondarySubEnd = "secondary-sub-end";

  /// Current position on playlist. The first entry is on position 0. Writing to
  /// this property may start playback at the new position.
  ///
  /// In some cases, this is not necessarily the currently playing file. See
  /// explanation of current and playing flags in playlist.
  ///
  /// If there the playlist is empty, or if it's non-empty, but no entry is
  /// "current", this property returns -1. Likewise, writing -1 will put the
  /// player into idle mode (or exit playback if idle mode is not enabled). If
  /// an out of range index is written to the property, this behaves as if
  /// writing -1. (Before mpv 0.33.0, instead of returning -1, this property was
  /// unavailable if no playlist entry was current.)
  ///
  /// Writing the current value back to the property is subject to change.
  /// Currently, it will restart playback of the playlist entry. But in the
  /// future, writing the current value will be ignored. Use the
  /// playlist-play-index command to get guaranteed behavior.
  static const String playlistPos = "playlist-pos";

  /// Same as playlist-pos, but 1-based.
  static const String playlistPos1 = "playlist-pos-1";

  /// Index of the "current" item on playlist. This usually, but not
  /// necessarily, the currently playing item (see playlist-playing-pos).
  /// Depending on the exact internal state of the player, it may refer to the
  /// playlist item to play next, or the playlist item used to determine what to
  /// play next.
  ///
  /// For reading, this is exactly the same as playlist-pos.
  ///
  /// For writing, this only sets the position of the "current" item, without
  /// stopping playback of the current file (or starting playback, if this is
  /// done in idle mode). Use -1 to remove the current flag.
  ///
  /// This property is only vaguely useful. If set during playback, it will
  /// typically cause the playlist entry after it to be played next. Another
  /// possibly odd observable state is that if playlist-next is run during
  /// playback, this property is set to the playlist entry to play next (unlike
  /// the previous case). There is an internal flag that decides whether the
  /// current playlist entry or the next one should be played, and this flag is
  /// currently inaccessible for API users. (Whether this behavior will kept is
  /// possibly subject to change.)
  static const String playlistCurrentPos = "playlist-current-pos";

  /// Index of the "playing" item on playlist. A playlist item is "playing" if
  /// it's being loaded, actually playing, or being unloaded. This property is
  /// set during the MPV_EVENT_START_FILE (start-file) and the
  /// MPV_EVENT_START_END (end-file) events. Outside of that, it returns -1. If
  /// the playlist entry was somehow removed during playback, but playback
  /// hasn't stopped yet, or is in progress of being stopped, it also returns
  /// -1. (This can happen at least during state transitions.)
  ///
  /// In the "playing" state, this is usually the same as playlist-pos, except
  /// during state changes, or if playlist-current-pos was written explicitly.
  static const String playlistPlayingPos = "playlist-playing-pos";

  static const String playlistCount = "playlist-count";
  static const String playlist = "playlist";

  /// List of audio/video/sub tracks.
  static const String trackList = "track-list";

  static const String chapterList = "chapter-list";
  static const String af = "af";
  static const String vf = "vf";
  static const String seekable = "seekable";
  static const String partiallySeekable = "partially-seekable";
  static const String playbackAbort = "playback-abort";
  static const String cursorAutohide = "cursor-autohide";
  static const String osdSymCc = "osd-sym-cc";
  static const String osdAssCc = "osd-ass-cc";
  static const String voConfigured = "vo-configured";
  static const String voPasses = "vo-passes";
  static const String perfInfo = "perf-info";
  static const String videoBitrate = "video-bitrate";
  static const String audioBitrate = "audio-bitrate";
  static const String subBitrate = "sub-bitrate";
  static const String packetVideoBitrate = "packet-video-bitrate";
  static const String packetAudioBitrate = "packet-audio-bitrate";
  static const String packetSubBitrate = "packet-sub-bitrate";
  static const String audioDeviceList = "audio-device-list";
  static const String audioDevice = "audio-device";
  static const String currentVo = "current-vo";
  static const String currentAo = "current-ao";
  static const String sharedScriptProperties = "shared-script-properties";
  static const String workingDirectory = "working-directory";
  static const String protocolList = "protocol-list";
  static const String decoderList = "decoder-list";
  static const String encoderList = "encoder-list";
  static const String demuxerLavfList = "demuxer-lavf-list";
  static const String inputKeyList = "input-key-list";
  static const String mpvVersion = "mpv-version";
  static const String mpvConfiguration = "mpv-configuration";
  static const String ffmpegVersion = "ffmpeg-version";
  static const String libassVersion = "libass-version";
  static const String propertyList = "property-list";
  static const String profileList = "profile-list";
  static const String commandList = "command-list";
}

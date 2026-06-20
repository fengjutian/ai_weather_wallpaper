import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;

import '../player/audio_player.dart';

/// Internal container pairing an `audioplayers.AudioPlayer` with its per-track
/// gain multiplier.
class AudioPlayerTrack {
  /// The underlying `audioplayers` player instance.
  final ap.AudioPlayer player;

  /// Per-track gain multiplier applied on top of the track volume.
  double gain;

  /// The track volume (0.0 – 1.0) before the master volume is multiplied.
  double volume;

  /// The source path this track was configured with.
  final String path;

  /// Creates an [AudioPlayerTrack].
  AudioPlayerTrack({
    required this.player,
    required this.path,
    this.gain = 1.0,
    this.volume = 1.0,
  });
}

/// A mixer that manages multiple audio tracks simultaneously.
///
/// Each track is identified by a unique [String] ID and backed by an
/// `audioplayers.AudioPlayer` instance.  The mixer applies per-track gain
/// and a master volume that multiplies every track.
///
/// ## Usage
///
/// ```dart
/// final mixer = AudioMixer();
/// final id = mixer.addTrack('rain', 'assets/sounds/rain.mp3', gain: 0.8);
/// await mixer.start();
/// mixer.setTrackVolume(id, 0.5);
/// mixer.setMasterVolume(0.7);
/// ```
class AudioMixer {
  final Map<String, AudioPlayerTrack> _tracks = {};
  double _masterVolume = 1.0;
  bool _isRunning = false;

  // ---------------------------------------------------------------------------
  // Volume
  // ---------------------------------------------------------------------------

  /// The master output volume (0.0 – 1.0) applied to every track.
  double get masterVolume => _masterVolume;

  /// Sets the master output volume, clamped to 0.0 – 1.0.
  ///
  /// This value multiplies every track's individual volume.
  set masterVolume(double vol) {
    _masterVolume = vol.clamp(0.0, 1.0);
    _applyMasterVolume();
  }

  // ---------------------------------------------------------------------------
  // Track management
  // ---------------------------------------------------------------------------

  /// Adds a new audio track identified by [id].
  ///
  /// [path] is the audio source (file path, asset path, or URL).  [gain] is
  /// an additional per-track gain multiplier (default 1.0).
  ///
  /// Returns [id] for chaining convenience.
  ///
  /// If a track with the same [id] already exists, it is removed first.
  String addTrack(String id, String path, {double gain = 1.0}) {
    // Remove any existing track with this ID.
    if (_tracks.containsKey(id)) {
      removeTrack(id);
    }

    final player = ap.AudioPlayer();
    final track = AudioPlayerTrack(
      player: player,
      path: path,
      gain: gain,
    );

    // Set the source asynchronously — errors are swallowed so the call
    // to addTrack remains synchronous.
    _setSource(player, path);

    _tracks[id] = track;

    // If the mixer is already running, start this track immediately.
    if (_isRunning) {
      _startTrack(track);
    }

    return id;
  }

  /// Removes the track identified by [id].
  ///
  /// Does nothing if [id] is unknown.
  void removeTrack(String id) {
    final track = _tracks.remove(id);
    if (track != null) {
      track.player.stop();
      track.player.dispose();
    }
  }

  /// Removes all tracks and stops the mixer.
  void clear() {
    _isRunning = false;
    for (final track in _tracks.values) {
      track.player.stop();
      track.player.dispose();
    }
    _tracks.clear();
  }

  // ---------------------------------------------------------------------------
  // Playback controls
  // ---------------------------------------------------------------------------

  /// Starts playback of all registered tracks.
  ///
  /// Returns `true` when all tracks have begun playing.
  Future<bool> start() async {
    _isRunning = true;
    final futures = <Future<bool>>[];
    for (final track in _tracks.values) {
      futures.add(_startTrack(track));
    }
    final results = await Future.wait(futures);
    return results.every((r) => r);
  }

  /// Stops playback of all tracks and resets their positions.
  Future<void> stop() async {
    _isRunning = false;
    final futures = <Future<void>>[];
    for (final track in _tracks.values) {
      futures.add(track.player.stop());
    }
    await Future.wait(futures);
  }

  /// Pauses all tracks without rewinding.
  Future<void> pauseAll() async {
    final futures = <Future<void>>[];
    for (final track in _tracks.values) {
      futures.add(track.player.pause());
    }
    await Future.wait(futures);
  }

  /// Resumes all paused tracks.
  Future<void> resumeAll() async {
    final futures = <Future<void>>[];
    for (final track in _tracks.values) {
      futures.add(track.player.resume());
    }
    await Future.wait(futures);
  }

  // ---------------------------------------------------------------------------
  // Per-track controls
  // ---------------------------------------------------------------------------

  /// Sets the volume (0.0 – 1.0) for the track identified by [id].
  ///
  /// The final output volume is `trackVolume * masterVolume * gain`.
  void setTrackVolume(String id, double vol) {
    final track = _tracks[id];
    if (track != null) {
      track.volume = vol.clamp(0.0, 1.0);
      track.player.setVolume(track.volume * _masterVolume * track.gain);
    }
  }

  /// Sets the gain multiplier for the track identified by [id].
  ///
  /// Unlike [setTrackVolume], gain is not clamped so it can be used to
  /// boost a quiet source above 1.0.
  void setTrackGain(String id, double gain) {
    final track = _tracks[id];
    if (track != null) {
      track.gain = gain;
      track.player.setVolume(track.volume * _masterVolume * track.gain);
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Releases all resources held by the mixer.
  ///
  /// The mixer must not be used after calling [dispose].
  Future<void> dispose() async {
    _isRunning = false;
    for (final track in _tracks.values) {
      await track.player.dispose();
    }
    _tracks.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Applies the current master volume to all registered tracks.
  void _applyMasterVolume() {
    for (final track in _tracks.values) {
      track.player.setVolume(track.volume * _masterVolume * track.gain);
    }
  }

  /// Asynchronously sets the source on [player] from [path].
  Future<void> _setSource(ap.AudioPlayer player, String path) async {
    try {
      final source = _resolveSource(path);
      await player.setSource(source);
      await player.setReleaseMode(ap.ReleaseMode.loop);
    } catch (_) {
      // Source loading errors are silent — the player simply won't play.
    }
  }

  /// Starts a single [track] if the mixer is running.
  Future<bool> _startTrack(AudioPlayerTrack track) async {
    try {
      await track.player.setVolume(track.volume * _masterVolume * track.gain);
      await track.player.resume();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resolves a string [path] to the appropriate [ap.Source] type.
  ap.Source _resolveSource(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return ap.UrlSource(path);
    }
    if (path.startsWith('assets/')) {
      return ap.AssetSource(path);
    }
    return ap.DeviceFileSource(path);
  }
}

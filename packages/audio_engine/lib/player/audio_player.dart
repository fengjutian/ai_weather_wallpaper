import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';

/// Possible states of the audio player lifecycle.
enum PlayerState { stopped, playing, paused, error }

/// Configuration for a single audio track.
class AudioTrackConfig {
  /// The asset path or URL of the audio source.
  final String source;

  /// Whether the track should loop indefinitely.
  final bool loop;

  /// Initial volume (0.0 – 1.0).
  final double volume;

  /// Fade-in duration when the track starts.
  final Duration fadeIn;

  const AudioTrackConfig({
    required this.source,
    this.loop = true,
    this.volume = 1.0,
    this.fadeIn = Duration.zero,
  });
}

/// A lightweight audio player that handles playback of a single ambient track.
///
/// Wraps `audioplayers.AudioPlayer` to provide play/pause/stop/seek controls,
/// volume management, and state change notifications via [ValueNotifier].
///
/// ## Usage
///
/// ```dart
/// final player = AudioPlayer(
///   config: AudioTrackConfig(source: 'assets/sounds/rain.mp3', loop: true),
/// );
/// await player.play();
/// ```
class AudioPlayer {
  final ap.AudioPlayer _player = ap.AudioPlayer();
  final ValueNotifier<PlayerState> _stateNotifier =
      ValueNotifier<PlayerState>(PlayerState.stopped);

  String? _currentSource;
  double _volume;
  Duration _cachedPosition = Duration.zero;
  Duration _cachedDuration = Duration.zero;
  StreamSubscription<ap.PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  /// Creates an [AudioPlayer] with an optional [config].
  ///
  /// If [config] is provided, its [AudioTrackConfig.source] is immediately
  /// set as the player's source and looping is configured.
  AudioPlayer({AudioTrackConfig? config})
      : _volume = config?.volume ?? 1.0 {
    _stateSub = _player.onPlayerStateChanged.listen(_onPlayerStateChanged);
    _positionSub = _player.onPositionChanged.listen((pos) {
      _cachedPosition = pos;
    });
    _durationSub = _player.onDurationChanged.listen((dur) {
      _cachedDuration = dur ?? Duration.zero;
    });
    if (config != null) {
      _currentSource = config.source;
      if (config.loop) {
        _player.setReleaseMode(ap.ReleaseMode.loop);
      }
    }
  }

  /// Creates an [AudioPlayer] from a predefined [config].
  factory AudioPlayer.fromConfig(AudioTrackConfig config) {
    return AudioPlayer(config: config);
  }

  // ---------------------------------------------------------------------------
  // Streams & notifiers
  // ---------------------------------------------------------------------------

  /// A broadcast stream that emits every time the player state changes.
  Stream<PlayerState> get onStateChanged => _stateNotifier.stream;

  /// A [ValueNotifier] that exposes the current [PlayerState].
  ///
  /// Listen to this to reactively update UI when the player state changes.
  ValueNotifier<PlayerState> get stateNotifier => _stateNotifier;

  // ---------------------------------------------------------------------------
  // State getters
  // ---------------------------------------------------------------------------

  /// The current player state.
  PlayerState get state => _stateNotifier.value;

  /// Current playback volume in the range 0.0 (silent) to 1.0 (full).
  double get volume => _volume;

  /// The current playback position.
  Duration get position => _cachedPosition;

  /// The total duration of the current audio source.
  ///
  /// Returns [Duration.zero] if the duration is not yet known.
  Duration get duration => _cachedDuration;

  // ---------------------------------------------------------------------------
  // Playback controls
  // ---------------------------------------------------------------------------

  /// Sets the audio source from a [path] (file path or URL).
  ///
  /// Local file paths, asset paths (starting with `assets/`), and HTTP(S)
  /// URLs are all supported.
  Future<void> setSource(String path) async {
    try {
      _currentSource = path;
      final source = _resolveSource(path);
      await _player.setSource(source);
    } catch (e) {
      _stateNotifier.value = PlayerState.error;
    }
  }

  /// Starts (or resumes) playback of the current audio source.
  ///
  /// If [path] is provided, the source is changed before playing.
  /// Returns `true` when playback has begun successfully.
  Future<bool> play({String? path}) async {
    try {
      if (path != null) {
        _currentSource = path;
        final source = _resolveSource(path);
        await _player.setSource(source);
      }
      await _player.resume();
      _stateNotifier.value = PlayerState.playing;
      return true;
    } catch (e) {
      _stateNotifier.value = PlayerState.error;
      return false;
    }
  }

  /// Pauses playback without rewinding.
  ///
  /// Call [play] again to resume from the same position.
  void pause() {
    try {
      _player.pause();
      _stateNotifier.value = PlayerState.paused;
    } catch (e) {
      _stateNotifier.value = PlayerState.error;
    }
  }

  /// Stops playback and resets the position to the beginning.
  void stop() {
    try {
      _player.stop();
      _stateNotifier.value = PlayerState.stopped;
    } catch (e) {
      _stateNotifier.value = PlayerState.error;
    }
  }

  /// Seeks to a specific [position] in the audio track.
  ///
  /// If [position] exceeds the track duration, behaviour depends on the
  /// underlying platform (usually playback stops).
  void seek(Duration position) {
    try {
      _player.seek(position);
    } catch (e) {
      _stateNotifier.value = PlayerState.error;
    }
  }

  /// Sets the playback volume.
  ///
  /// [vol] is clamped to the range 0.0 – 1.0.
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    try {
      _player.setVolume(_volume);
    } catch (e) {
      _stateNotifier.value = PlayerState.error;
    }
  }

  /// Releases all resources held by this player.
  ///
  /// The player must not be used after calling [dispose].
  Future<void> dispose() async {
    await _stateSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _player.dispose();
    _stateNotifier.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

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

  /// Maps the `audioplayers` [ap.PlayerState] to our [PlayerState].
  void _onPlayerStateChanged(ap.PlayerState state) {
    switch (state) {
      case ap.PlayerState.playing:
        _stateNotifier.value = PlayerState.playing;
      case ap.PlayerState.paused:
        _stateNotifier.value = PlayerState.paused;
      case ap.PlayerState.stopped:
      case ap.PlayerState.completed:
        _stateNotifier.value = PlayerState.stopped;
    }
  }
}

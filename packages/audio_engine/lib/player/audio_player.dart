import 'dart:async';

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
/// ## Responsibilities
///
/// * Load and decode an audio asset (WAV, MP3, OGG).
/// * Provide play / pause / stop / seek controls.
/// * Support looping and fade-in.
/// * Expose a [state] stream so the UI can react to loading, playing, or
///   error states.
///
/// ## Usage
///
/// ```dart
/// final player = AudioPlayer(
///   AudioTrackConfig(source: 'assets/rain.wav', loop: true),
/// );
/// await player.play();
/// ```
///
/// **TODO(jutianfeng):** Replace the stub implementation with a real audio
///   backend — either `package:audioplayers`, `package:just_audio`, or a
///   custom FFI bridge to the desktop platform's audio API (e.g. WASAPI on
///   Windows, CoreAudio on macOS).
class AudioPlayer {
  final AudioTrackConfig config;

  PlayerState _state = PlayerState.stopped;
  double _volume;

  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();

  /// Creates an [AudioPlayer] for the given [config].
  AudioPlayer(this.config) : _volume = config.volume;

  /// A broadcast stream that emits every time the player state changes.
  Stream<PlayerState> get stateStream => _stateController.stream;

  /// The current player state.
  PlayerState get state => _state;

  /// Current playback volume (0.0 – 1.0).
  double get volume => _volume;

  /// Starts (or resumes) playback of the configured audio source.
  ///
  /// Returns `true` when playback has begun successfully.
  Future<bool> play() async {
    // TODO(jutianfeng): Implement actual audio playback.
    //   1. Load the audio file from [config.source].
    //   2. Decode into a PCM buffer.
    //   3. Start streaming to the audio output device.
    //   4. Apply [config.fadeIn] as a volume ramp.
    //   5. Loop if [config.loop] is true.
    _state = PlayerState.playing;
    _stateController.add(_state);
    return true;
  }

  /// Pauses playback without rewinding.
  ///
  /// Call [play] again to resume from the same position.
  Future<void> pause() async {
    // TODO(jutianfeng): Pause the audio stream; keep the decode buffer alive.
    _state = PlayerState.paused;
    _stateController.add(_state);
  }

  /// Stops playback and resets the position to the beginning.
  Future<void> stop() async {
    // TODO(jutianfeng): Stop the audio stream and free the decode buffer.
    _state = PlayerState.stopped;
    _stateController.add(_state);
  }

  /// Seeks to a specific [position] in the audio track.
  ///
  /// If [position] exceeds the track duration, playback stops.
  Future<void> seek(Duration position) async {
    // TODO(jutianfeng): Implement seeking into the PCM buffer.
  }

  /// Sets the playback volume.
  ///
  /// [vol] is clamped to the range 0.0 – 1.0.
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    // TODO(jutianfeng): Push the new volume to the audio mixer / device.
  }

  /// Releases all resources held by this player.
  ///
  /// The player must not be used after calling [dispose].
  void dispose() {
    // TODO(jutianfeng): Free native audio buffers and close device handles.
    _stateController.close();
    _state = PlayerState.stopped;
  }
}

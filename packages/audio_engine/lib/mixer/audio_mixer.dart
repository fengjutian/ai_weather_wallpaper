import '../player/audio_player.dart';

/// A mixer that combines multiple [AudioPlayer] instances into a single
/// output stream.
///
/// ## Use Case
///
/// Ambient wallpapers often layer several sounds simultaneously — e.g. rain
/// (looping), gentle wind (looping), and a distant thunderclap (one-shot).
/// [AudioMixer] accepts any number of [AudioTrack] inputs, sums their samples,
/// applies per-track gain, and feeds the result to the audio output device.
///
/// ## Usage
///
/// ```dart
/// final mixer = AudioMixer();
/// mixer.addTrack(rainPlayer);
/// mixer.addTrack(windPlayer);
/// mixer.setMasterVolume(0.8);
/// await mixer.start();
/// ```
///
/// **TODO(jutianfeng):** Replace the stub with a real mixing engine:
///   - Accumulate PCM frames from each active player.
///   - Apply per-track gain before summing.
///   - Clip to prevent overflow after summation.
///   - Support adding / removing tracks at runtime.
///   - Optionally expose per-track VU meters.
class AudioMixer {
  final List<_TrackEntry> _tracks = [];

  double _masterVolume = 1.0;

  /// Whether the mixer is currently running.
  bool _isRunning = false;

  /// The master output volume applied after all tracks are summed.
  double get masterVolume => _masterVolume;

  /// Sets the master output volume (0.0 – 1.0).
  set masterVolume(double vol) {
    _masterVolume = vol.clamp(0.0, 1.0);
  }

  /// Adds an [AudioPlayer] as a track in the mix.
  ///
  /// [gain] is an additional per-track volume multiplier (default 1.0).
  /// Returns the (zero-based) track index.
  int addTrack(AudioPlayer player, {double gain = 1.0}) {
    // TODO(jutianfeng): Register [player] in the mixing loop and allocate
    //   a ring-buffer slot for its decoded PCM data.
    _tracks.add(_TrackEntry(player, gain));
    return _tracks.length - 1;
  }

  /// Removes a track by [index].
  ///
  /// Does nothing if [index] is out of range.
  void removeTrack(int index) {
    if (index >= 0 && index < _tracks.length) {
      // TODO(jutianfeng): Unregister from the mixing loop.
      _tracks[index].player.dispose();
      _tracks.removeAt(index);
    }
  }

  /// Starts the mixing loop.
  ///
  /// All registered tracks will begin playback simultaneously.  Returns
  /// `true` when the mixer is successfully running.
  Future<bool> start() async {
    // TODO(jutianfeng): Start the audio output device and begin the mixing
    //   render loop (e.g. a high-priority timer or an audio worker isolate).
    _isRunning = true;
    return true;
  }

  /// Stops the mixing loop and pauses all tracks.
  Future<void> stop() async {
    // TODO(jutianfeng): Stop the render loop and pause every track.
    _isRunning = false;
  }

  /// Pauses all tracks but keeps the mixer alive.
  Future<void> pauseAll() async {
    for (final entry in _tracks) {
      await entry.player.pause();
    }
  }

  /// Resumes all paused tracks.
  Future<void> resumeAll() async {
    for (final entry in _tracks) {
      await entry.player.play();
    }
  }

  /// Sets the per-track gain for the track at [index].
  void setTrackGain(int index, double gain) {
    if (index >= 0 && index < _tracks.length) {
      _tracks[index].gain = gain;
    }
  }

  /// Releases all resources and clears the track list.
  void dispose() {
    for (final entry in _tracks) {
      entry.player.dispose();
    }
    _tracks.clear();
    _isRunning = false;
  }
}

/// Internal container pairing an [AudioPlayer] with its per-track gain.
class _TrackEntry {
  final AudioPlayer player;
  double gain;

  _TrackEntry(this.player, this.gain);
}

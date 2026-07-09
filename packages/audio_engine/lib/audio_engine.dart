/// Audio Engine — Background ambient audio playback, mixing, and effects.
///
/// Provides a high-level API for playing layered ambient sounds (rain, ocean,
/// forest, white/pink/brown noise) with DSP effects such as reverb, filter,
/// and equalisation.
///
/// ## Built-in Presets
///
/// | Preset       | Description                        |
/// |--------------|------------------------------------|
/// | [Rain]       | Steady rainfall with gentle patter |
/// | [Ocean]      | Crashing waves & surf              |
/// | [Forest]     | Birdsong, wind through leaves      |
/// | [WhiteNoise] | Flat power spectral density        |
/// | [PinkNoise]  | -3 dB/octave roll-off              |
/// | [BrownNoise] | -6 dB/octave roll-off (rumbling)   |
///
/// ## Usage
///
/// ```dart
/// import 'package:audio_engine/audio_engine.dart';
///
/// final player = AudioPlayer(Rain.config);
/// await player.play();
/// ```
library audio_engine;

import 'player/audio_player.dart' show AudioPlayer, AudioTrackConfig, PlayerState;

export 'player/audio_player.dart'
    show AudioPlayer, AudioTrackConfig, PlayerState;
export 'mixer/audio_mixer.dart' show AudioMixer;
export 'effects/audio_effects.dart'
    show
        AudioEffects,
        ReverbParams,
        FilterParams,
        EqualizerParams;

// ---------------------------------------------------------------------------
// Built-in preset configurations
// ---------------------------------------------------------------------------

/// Steady rainfall ambience.
///
/// **TODO(jutianfeng):** Replace `source` with the actual asset path once
///   audio files have been added to the project.
abstract final class Rain {
  static const AudioTrackConfig config = AudioTrackConfig(
    source: 'assets/audio/rain.wav',
    loop: true,
    volume: 0.7,
  );
}

/// Ocean surf and wave ambience.
abstract final class Ocean {
  static const AudioTrackConfig config = AudioTrackConfig(
    source: 'assets/audio/ocean.wav',
    loop: true,
    volume: 0.6,
  );
}

/// Forest ambience with birds and wind.
abstract final class Forest {
  static const AudioTrackConfig config = AudioTrackConfig(
    source: 'assets/audio/forest.wav',
    loop: true,
    volume: 0.5,
  );
}

/// White noise — equal energy per Hz.
abstract final class WhiteNoise {
  static const AudioTrackConfig config = AudioTrackConfig(
    source: 'assets/audio/white_noise.wav',
    loop: true,
    volume: 0.3,
  );
}

/// Pink noise — equal energy per octave (-3 dB/octave).
abstract final class PinkNoise {
  static const AudioTrackConfig config = AudioTrackConfig(
    source: 'assets/audio/pink_noise.wav',
    loop: true,
    volume: 0.3,
  );
}

/// Brown / red noise — -6 dB/octave (deep rumbling).
abstract final class BrownNoise {
  static const AudioTrackConfig config = AudioTrackConfig(
    source: 'assets/audio/brown_noise.wav',
    loop: true,
    volume: 0.3,
  );
}

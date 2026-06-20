/// Type of audio effect that can be applied to a track or the master mix.
enum EffectType {
  /// Convolution / digital reverb (e.g. room, hall, cathedral).
  reverb,

  /// Low-pass, high-pass, band-pass filters.
  filter,

  /// Multi-band parametric equaliser.
  equalizer,

  /// Dynamic range compression.
  compressor,

  /// Chorus / phaser / flanger modulation effects.
  modulation,
}

/// Parameters shared by all effect types.
///
/// Each subclass adds its own typed parameters.
abstract class EffectParams {
  /// Whether this effect is currently active.
  bool enabled;

  /// The mix (wet/dry) ratio — 0.0 = dry only, 1.0 = wet only.
  double wetDryMix;

  EffectParams({this.enabled = true, this.wetDryMix = 0.5});
}

/// Reverb parameters.
class ReverbParams extends EffectParams {
  /// Decay time in seconds.
  double decaySeconds;

  /// Pre-delay in milliseconds.
  double preDelayMs;

  /// Early reflections level (dB).
  double earlyReflectionsLevel;

  ReverbParams({
    super.enabled = true,
    super.wetDryMix = 0.5,
    this.decaySeconds = 2.0,
    this.preDelayMs = 20.0,
    this.earlyReflectionsLevel = -10.0,
  });
}

/// Filter parameters.
class FilterParams extends EffectParams {
  /// Cut-off frequency in Hz.
  double cutoffHz;

  /// Filter resonance / Q-factor.
  double q;

  FilterParams({
    super.enabled = true,
    super.wetDryMix = 1.0,
    this.cutoffHz = 200.0,
    this.q = 0.707,
  });
}

/// Equaliser band definition.
class EqBand {
  /// Centre frequency in Hz.
  final double frequencyHz;

  /// Gain in dB (-24 … +24).
  double gainDb;

  /// Bandwidth in octaves.
  double bandwidthOct;

  EqBand({
    required this.frequencyHz,
    this.gainDb = 0.0,
    this.bandwidthOct = 1.0,
  });
}

/// Equaliser parameters.
class EqualizerParams extends EffectParams {
  /// Ordered list of EQ bands (low → high frequency).
  final List<EqBand> bands;

  EqualizerParams({
    super.enabled = true,
    super.wetDryMix = 1.0,
    List<EqBand>? bands,
  }) : bands = bands ??
            [
              EqBand(frequencyHz: 60, gainDb: 0.0),
              EqBand(frequencyHz: 230, gainDb: 0.0),
              EqBand(frequencyHz: 910, gainDb: 0.0),
              EqBand(frequencyHz: 4000, gainDb: 0.0),
              EqBand(frequencyHz: 14000, gainDb: 0.0),
            ];
}

/// Applies digital signal-processing (DSP) effects to an audio stream.
///
/// ## Supported Effects
///
/// | Effect        | Description                                       |
/// |---------------|---------------------------------------------------|
/// | Reverb        | Room / hall / cathedral convolution reverb        |
/// | Filter        | Low-pass, high-pass, band-pass (state-variable)   |
/// | Equalizer     | Multi-band peaking / shelving EQ                  |
/// | Compressor    | Dynamic range compression (future)                |
///
/// ## Usage
///
/// ```dart
/// final fx = AudioEffects();
/// fx.setReverb(ReverbParams(decaySeconds: 3.0, wetDryMix: 0.3));
/// fx.applyTo(buffer);
/// ```
///
/// **TODO(jutianfeng):** Replace the stub with a real DSP engine.
///   - Implement convolution reverb via FFT / partitioned convolution.
///   - Implement state-variable filter (SVF) for LP/HP/BP.
///   - Implement biquad filters for the equaliser.
///   - All processing should operate on `Float64List` PCM buffers.
class AudioEffects {
  ReverbParams _reverb = ReverbParams();
  FilterParams _filter = FilterParams();
  EqualizerParams _equalizer = EqualizerParams();

  /// The current reverb configuration.
  ReverbParams get reverb => _reverb;

  /// The current filter configuration.
  FilterParams get filter => _filter;

  /// The current equaliser configuration.
  EqualizerParams get equalizer => _equalizer;

  /// Updates the reverb parameters.
  void setReverb(ReverbParams params) {
    // TODO(jutianfeng): Recalculate reverb impulse response / IR.
    _reverb = params;
  }

  /// Updates the filter parameters.
  void setFilter(FilterParams params) {
    // TODO(jutianfeng): Recalculate filter coefficients (biquad / SVF).
    _filter = params;
  }

  /// Updates the equaliser parameters.
  void setEqualizer(EqualizerParams params) {
    // TODO(jutianfeng): Recalculate per-band biquad coefficients.
    _equalizer = params;
  }

  /// Applies all enabled effects to an in-place PCM frame [buffer].
  ///
  /// [buffer] is a flat `Float64List` interleaved as `[L, R, L, R, ...]`.
  /// [numChannels] defaults to 2 (stereo).
  ///
  /// Effects are applied in order: filter → equalizer → reverb.
  ///
  /// **TODO(jutianfeng):** Implement the actual DSP chain.
  void applyTo(List<double> buffer, {int numChannels = 2}) {
    // TODO(jutianfeng): Chain DSP processors:
    //   if (_filter.enabled) => applyStateVariableFilter(buffer);
    //   if (_equalizer.enabled) => applyEqualizer(buffer);
    //   if (_reverb.enabled) => applyConvolutionReverb(buffer);
  }

  /// Bypasses (disables) all effects at once.
  void bypassAll() {
    _reverb.enabled = false;
    _filter.enabled = false;
    _equalizer.enabled = false;
  }

  /// Enables all effects with their current parameters.
  void enableAll() {
    _reverb.enabled = true;
    _filter.enabled = true;
    _equalizer.enabled = true;
  }
}

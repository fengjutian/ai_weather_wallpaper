/// Parameters for a reverberation effect.
///
/// On desktop platforms without native DSP support, this configuration is
/// stored and can be forwarded to a server-side or pre-processing pipeline
/// that applies the effect to audio files before playback.
class ReverbParams {
  /// Decay time in seconds — how long the reverb tail lasts.
  double decay;

  /// Pre-delay in milliseconds — the gap between the dry signal and the
  /// onset of the reverberation.
  double preDelay;

  /// Creates [ReverbParams] with sensible default values.
  ///
  /// [decay] defaults to 2.0 seconds. [preDelay] defaults to 20 ms.
  ReverbParams({this.decay = 2.0, this.preDelay = 20.0});
}

/// Parameters for a filter effect.
///
/// Supported filter types: `lowpass`, `highpass`, `bandpass`.
///
/// This is a configuration model; the actual filtering must be performed
/// by a downstream DSP processor or external tool.
class FilterParams {
  /// The filter type: `lowpass`, `highpass`, or `bandpass`.
  String type;

  /// Cut-off frequency in Hertz.
  double cutoff;

  /// Resonance / Q-factor of the filter.
  ///
  /// Higher values produce a sharper peak at the cut-off frequency.
  double q;

  /// Creates [FilterParams] with a low-pass default (200 Hz, Q=0.707).
  FilterParams({
    this.type = 'lowpass',
    this.cutoff = 200.0,
    this.q = 0.707,
  });
}

/// Parameters for a 5-band graphic equaliser.
///
/// The [gains] list contains five values (one per band) in dB, one for each
/// of the following centre frequencies:
///
/// | Index | Frequency |
/// |-------|-----------|
/// | 0     | 60 Hz     |
/// | 1     | 230 Hz    |
/// | 2     | 910 Hz    |
/// | 3     | 4 kHz     |
/// | 4     | 14 kHz    |
///
/// This is a configuration model; the actual EQ filtering must be performed
/// by a downstream DSP processor or external tool.
class EqualizerParams {
  /// Five gain values in dB, one per EQ band.
  ///
  /// Defaults to all zeros (flat response).
  List<double> gains;

  /// Creates [EqualizerParams] with an optional list of five gain values.
  ///
  /// If [gains] is omitted, all bands default to 0 dB (flat).
  EqualizerParams({List<double>? gains})
      : gains = gains ??
            [0.0, 0.0, 0.0, 0.0, 0.0] {
    if (this.gains.length != 5) {
      throw ArgumentError('EqualizerParams requires exactly 5 gain values');
    }
  }
}

/// A configuration model for audio effects (reverb, filter, equaliser).
///
/// ## Purpose
///
/// On desktop platforms, real-time DSP effect processing is not feasible
/// without native audio processing plugins.  This class stores effect
/// parameters that can be:
///
/// * Forwarded to a server-side audio processing pipeline;
/// * Applied to audio files as a pre-processing step;
/// * Used by a native platform channel implementation;
/// * Inspected for debug / UI display purposes.
///
/// ## Usage
///
/// ```dart
/// final fx = AudioEffects();
/// fx.setReverb(ReverbParams(decay: 3.0, preDelay: 30.0));
/// fx.setFilter(FilterParams(type: 'lowpass', cutoff: 500.0));
/// fx.setEqualizer(EqualizerParams(gains: [-2.0, 0.0, 1.5, 3.0, 0.0]));
/// print(fx.describe());
/// ```
class AudioEffects {
  ReverbParams? _reverb;
  FilterParams? _filter;
  EqualizerParams? _equalizer;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The current reverb parameters, or `null` if reverb is not configured.
  ReverbParams? get reverb => _reverb;

  /// The current filter parameters, or `null` if filter is not configured.
  FilterParams? get filter => _filter;

  /// The current equaliser parameters, or `null` if EQ is not configured.
  EqualizerParams? get equalizer => _equalizer;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Configures the reverb effect with [params].
  ///
  /// Pass `null` to clear the reverb configuration.
  void setReverb(ReverbParams? params) {
    _reverb = params;
  }

  /// Configures the filter effect with [params].
  ///
  /// Pass `null` to clear the filter configuration.
  void setFilter(FilterParams? params) {
    _filter = params;
  }

  /// Configures the equaliser effect with [params].
  ///
  /// Pass `null` to clear the equaliser configuration.
  void setEqualizer(EqualizerParams? params) {
    _equalizer = params;
  }

  /// Removes all configured effects.
  void clearEffects() {
    _reverb = null;
    _filter = null;
    _equalizer = null;
  }

  // ---------------------------------------------------------------------------
  // Inspection
  // ---------------------------------------------------------------------------

  /// Returns a human-readable description of all currently configured effects.
  ///
  /// Example output:
  /// ```
  /// AudioEffects:
  ///   Reverb: decay=2.0s, preDelay=20.0ms
  ///   Filter: type=lowpass, cutoff=200.0Hz, Q=0.707
  ///   Equalizer: [0.0, 0.0, 0.0, 0.0, 0.0] dB
  /// ```
  String describe() {
    final parts = <String>['AudioEffects:'];

    if (_reverb != null) {
      parts.add(
        '  Reverb: decay=${_reverb!.decay}s, preDelay=${_reverb!.preDelay}ms',
      );
    }
    if (_filter != null) {
      parts.add(
        '  Filter: type=${_filter!.type}, '
            'cutoff=${_filter!.cutoff}Hz, Q=${_filter!.q}',
      );
    }
    if (_equalizer != null) {
      parts.add('  Equalizer: ${_equalizer!.gains} dB');
    }
    if (_reverb == null && _filter == null && _equalizer == null) {
      parts.add('  (no effects configured)');
    }

    return parts.join('\n');
  }

  /// Whether any effects are currently configured.
  bool get hasEffects =>
      _reverb != null || _filter != null || _equalizer != null;
}

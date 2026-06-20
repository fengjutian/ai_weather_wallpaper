import 'package:flutter/material.dart';

/// A card widget showing current weather information.
///
/// Displays a city name, temperature, weather condition icon/text,
/// and optional additional details (humidity, wind speed).
///
/// ```dart
/// WeatherCard(
///   city: 'Paris',
///   temperature: '22°C',
///   condition: Icons.wb_sunny,
///   conditionLabel: 'Sunny',
///   humidity: '55%',
///   windSpeed: '12 km/h',
/// )
/// ```
class WeatherCard extends StatelessWidget {
  /// City or location name.
  final String city;

  /// Temperature string (e.g. `"22°C"`).
  final String temperature;

  /// Icon representing the weather condition.
  final IconData condition;

  /// Human-readable condition label (e.g. `"Sunny"`).
  final String conditionLabel;

  /// Optional humidity string (e.g. `"55%"`).
  final String? humidity;

  /// Optional wind speed string (e.g. `"12 km/h"`).
  final String? windSpeed;

  /// Optional high / low temperature annotation.
  final String? highLow;

  const WeatherCard({
    super.key,
    required this.city,
    required this.temperature,
    required this.condition,
    required this.conditionLabel,
    this.humidity,
    this.windSpeed,
    this.highLow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // City name
            Text(city, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            // Temperature
            Text(
              temperature,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            // Condition icon + label
            Icon(condition, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(conditionLabel, style: theme.textTheme.bodyMedium),
            // Optional detail row
            if (humidity != null || windSpeed != null || highLow != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (highLow != null)
                      _DetailChip(
                        icon: Icons.thermostat,
                        label: highLow!,
                      ),
                    if (humidity != null)
                      _DetailChip(
                        icon: Icons.water_drop,
                        label: humidity!,
                      ),
                    if (windSpeed != null)
                      _DetailChip(
                        icon: Icons.air,
                        label: windSpeed!,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small helper widget used inside [WeatherCard] for detail chips.
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

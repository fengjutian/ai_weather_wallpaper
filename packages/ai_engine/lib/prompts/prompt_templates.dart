/// A collection of prompt templates for various weather conditions.
///
/// Each template describes a scene that can be used to generate wallpapers
/// or illustrations matching the current weather.
class PromptTemplates {
  /// Map of weather condition keys to their corresponding prompt template strings.
  ///
  /// Templates may contain placeholders like `{location}` or `{timeOfDay}`
  /// that can be substituted at runtime.
  static const Map<String, String> templates = {
    'clear': 'A bright and sunny day with a clear blue sky, warm golden sunlight '
        'streaming through scattered white clouds, lush green trees gently swaying '
        'in a light breeze, vibrant colors, highly detailed, 4K wallpaper.',

    'partly-cloudy': 'A partly cloudy sky with soft white and grey clouds drifting '
        'across a blue backdrop, patches of sunlight breaking through, calm and '
        'serene atmosphere, gentle shadows on the landscape, beautiful nature scene, '
        'high resolution.',

    'cloudy': 'An overcast sky filled with layers of soft grey and silver clouds, '
        'diffused light filtering through, muted earthy tones, a tranquil and '
        'contemplative mood, misty horizons, cinematic composition, 4K quality.',

    'rain': 'A gentle rain shower falling over a tranquil landscape, raindrops '
        'creating ripples on puddles, wet leaves glistening, soft grey clouds '
        'overhead, moody yet peaceful atmosphere, reflections on wet surfaces, '
        'detailed water effects, wallpaper.',

    'heavy-rain': 'A dramatic heavy rainstorm with sheets of rain pouring down, '
        'dark storm clouds rolling across the sky, wind-blown trees, lightning '
        'flashes illuminating the scene, powerful and intense atmosphere, '
        'cinematic lighting, ultra detailed.',

    'thunderstorm': 'A powerful thunderstorm with dramatic lightning bolts '
        'splitting the dark sky, heavy rain lashing the ground, ominous dark '
        'clouds churning above, electric blue flashes, intense and awe-inspiring '
        'natural spectacle, high contrast, 4K wallpaper.',

    'snow': 'A serene winter wonderland with fresh white snow covering the ground, '
        'snowflakes gently falling from a soft grey sky, frosted tree branches, '
        'peaceful and quiet atmosphere, soft blue and white color palette, '
        'magical winter scenery, highly detailed.',

    'heavy-snow': 'A heavy snowstorm with thick snowflakes swirling in the wind, '
        'deep snowdrifts covering everything, limited visibility, frost-covered '
        'trees and buildings, cold crisp air, dramatic winter weather scene, '
        'atmospheric and immersive, 4K.',

    'sleet': 'A bleak winter mix of sleet and freezing rain falling over a cold '
        'landscape, icy surfaces glistening under a dull grey sky, bare trees '
        'coated in ice, raw and chilly atmosphere, realistic precipitation effects, '
        'high detail.',

    'drizzle': 'A light misty drizzle settling over a quiet landscape, fine '
        'water droplets floating in the air, soft diffused light, dewy grass '
        'and flowers, calm and refreshing mood, gentle pastel tones, serene '
        'wallpaper scene.',

    'fog': 'A thick fog enveloping the landscape, soft white and grey mist '
        'obscuring distant shapes, dew-covered grass and spiderwebs, mysterious '
        'and ethereal atmosphere, low visibility, muted colors, dreamlike '
        'composition, cinematic quality.',

    'haze': 'A hazy day with a warm golden-brown tint in the air, distant '
        'mountains and buildings softened by atmospheric particles, sun glows '
        'through the haze, tranquil and slightly nostalgic mood, painterly '
        'quality, 4K wallpaper.',

    'wind': 'A windy day with long grass bending in strong gusts, leaves '
        'swirling through the air, trees swaying dynamically, dramatic cloud '
        'movement overhead, sense of motion and energy, vibrant landscape, '
        'high detail.',

    'tornado': 'A massive tornado touching down under a dark greenish sky, '
        'debris swirling in the air, powerful rotating funnel cloud, '
        'dramatic and frightening natural phenomenon, intense storm atmosphere, '
        'cinematic composition, ultra detailed.',

    'hurricane': 'A satellite or ground view of a powerful hurricane with '
        'spiral cloud bands, intense eye wall, churning ocean waves, dark '
        'foreboding sky, nature\'s immense power on display, dramatic lighting, '
        'epic scale, 4K wallpaper.',

    'sandstorm': 'A massive sandstorm sweeping across a desert landscape, '
        'thick orange-brown particles filling the air, obscured sun, rolling '
        'dunes partially visible, harsh and dramatic atmosphere, dynamic motion, '
        'cinematic quality.',

    'dust': 'A dusty landscape with fine particles suspended in the air, '
        'warm earthy tones, softened sunlight, distant shapes barely visible '
        'through the haze, arid and atmospheric, painterly desert scene, '
        'high resolution.',

    'smoke': 'A landscape affected by wildfire smoke, thick grey and amber '
        'haze blanketing the sky, eerie orange-red sun barely visible, '
        'oppressive and somber atmosphere, muted colors, dramatic environmental '
        'scene, cinematic.',

    'volcanic-ash': 'A dark apocalyptic scene with volcanic ash clouding the sky, '
        'fine grey particles settling over the landscape, dim eerie light, '
        'otherworldly atmosphere, stark and dramatic, high contrast, detailed '
        'particle effects, 4K.',

    'aurora': 'A breathtaking night sky filled with vibrant aurora borealis '
        'in green, purple, and blue hues, stars twinkling above a dark '
        'silhouetted landscape, magical and mesmerizing, glowing celestial '
        'phenomenon, ultra detailed wallpaper.',

    'rainbow': 'A beautiful rainbow arching across the sky after a rain shower, '
        'soft sunlight breaking through clouds, lush green landscape below, '
        'vivid colors, hopeful and uplifting mood, stunning natural spectacle, '
        'high resolution.',

    'hail': 'A hailstorm with large chunks of ice bouncing off the ground, '
        'dark storm clouds overhead, accumulations of hail collecting like snow, '
        'dramatic sky, intense weather event, detailed ice textures, '
        'cinematic composition, 4K.',

    'frost': 'A crisp frosty morning with delicate ice crystals covering every '
        'surface, frosted leaves and grass sparkling in the low morning sun, '
        'cold blue and white tones, peaceful winter detail, macro and landscape '
        'blend, high detail.',

    'mist': 'A gentle mist rising from a calm lake or river in the early morning, '
        'soft sunlight beginning to pierce through, reflections on the water, '
        'peaceful and meditative atmosphere, tranquil nature scene, '
        'painterly quality, 4K wallpaper.',

    'overcast': 'A uniformly overcast sky with a flat layer of grey clouds '
        'stretching to the horizon, soft even lighting, muted colors, calm and '
        'subdued mood, minimalist landscape, serene atmosphere, high resolution.',
  };

  /// Returns the prompt template for the given [weatherCondition], or a fallback
  /// if the condition is not recognized.
  static String getTemplate(String weatherCondition) {
    final condition = weatherCondition.toLowerCase().trim();
    return templates[condition] ?? templates['clear']!;
  }

  /// Returns a formatted prompt by substituting [placeholders] into the template
  /// for the given [weatherCondition].
  static String formatPrompt(String weatherCondition,
      {Map<String, String>? placeholders}) {
    String template = getTemplate(weatherCondition);
    if (placeholders != null) {
      for (final entry in placeholders.entries) {
        template = template.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return template;
  }
}

# Kuma Anime

A beautiful, feature-rich, and open-source application built using Flutter to stream and download anime directly on your Android device.

## Features

- **Streaming & Downloading:** Fast streaming and offline download manager.
- **External Subtitles (Beta):** Highly customizable subtitle settings (adjust font size, family, colors, opacity, outline, background, and timing offset).
- **Weekly Schedule:** Tracking currently releasing weekly airing anime grouped by day.
- **Terbaru Page:** Discover recent episodes, newly added anime, and manga updates.
- **Material 3 UI:** Sleek modern interface with support for dark mode, glassmorphism, dynamic color themes, and smooth micro-animations.

## Getting Started

### Prerequisites

Ensure you have the Flutter SDK installed on your system:
- Flutter (compatible with SDK `>=3.2.0 <4.0.0`)
- Android SDK (compile SDK version 36, target SDK version 34)

### Building from Source

To build a release APK, follow these commands:

```bash
flutter pub get
flutter build apk --release
```

The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

### Running on Device / Emulator

To run the application in developer mode:

```bash
flutter run
```

## Contributing

Contributions are welcome! Please feel free to open issues, submit feedback, or create pull requests. Refer to [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

This project is licensed under the GNU General Public License v3 - see the [LICENSE](LICENSE) file for details.

<p align="center">
  <img src="lib/assets/icons/logo_foreground.png" width="144" alt="Kuma Anime">
</p>

<h1 align="center">Kuma Anime</h1>

<p align="center">
  <strong>Discover your next series. Watch on your terms.</strong><br>
  A Flutter anime client for streaming, offline downloads, and weekly discovery.
</p>

<p align="center">
  <a href="https://github.com/SayuZX/KumaAnime-App/releases"><img src="https://img.shields.io/github/v/release/SayuZX/KumaAnime-App?style=flat&labelColor=222222&color=8BC34A" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPLv3-58A6FF?style=flat&labelColor=222222" alt="GNU GPL v3"></a>
  <img src="https://img.shields.io/badge/Flutter-3.41.6-02569B?style=flat&labelColor=222222&logo=flutter" alt="Flutter 3.41.6">
  <img src="https://img.shields.io/badge/language-Dart-0175C2?style=flat&labelColor=222222&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/interface-Material_3-8BC34A?style=flat&labelColor=222222" alt="Material 3 interface">
</p>

<p align="center">
  <a href="https://github.com/SayuZX/KumaAnime-App/releases">Downloads</a> ·
  <a href="#features">Features</a> ·
  <a href="#build-from-source">Build from source</a> ·
  <a href="https://github.com/SayuZX/KumaAnime-App/issues">Issues</a> ·
  <a href="CHANGELOG.md">Changelog</a>
</p>

Kuma Anime brings episode discovery, streaming, downloads, and customizable subtitles into one application. Built with Flutter, it combines a Material 3 interface with dark mode, dynamic colors, and desktop build targets.

**Streaming and downloads** · **Weekly schedules** · **Customizable subtitles** · **Material 3**

> [!NOTE]
> Source availability and playback depend on the configured providers. Use media sources you are authorized to access. Feature availability can vary by platform; platform directories alone do not guarantee a supported release.

## Download

Check the [Releases page](https://github.com/SayuZX/KumaAnime-App/releases) for available builds and release notes. Install the package matching your device and review its requirements before upgrading.

For development or a customized build, follow the source instructions below.

## Features

### 01 · Stream now, download for later

Browse anime and play available episodes through configured sources. The download manager supports keeping episodes for offline viewing when the source and platform permit it.

### 02 · Keep up with the weekly schedule

Find currently airing series grouped by day. Use the schedule to follow ongoing shows without searching for each title individually.

### 03 · Discover recent updates

The recent-updates page brings together new episodes, newly added anime, and manga updates so you can see what has changed since your last visit.

### 04 · Make subtitles easier to read

External subtitle support is in beta. Customize font size, font family, colors, opacity, outlines, backgrounds, and timing offset to suit your viewing setup.

### 05 · An interface that follows your preferences

Material 3 components, dark mode, dynamic color themes, translucent surfaces, and small interface animations provide a consistent viewing experience without replacing familiar navigation.

### 06 · Mobile first, with desktop build workflows

The repository includes Android, Linux, and Windows release workflows. It also contains iOS, macOS, and web platform projects; check their configuration and dependency compatibility before treating those targets as release-ready.

## Build from source

### Requirements

| Component | Project configuration |
|---|---|
| Flutter | **3.41.6**, pinned in `.fvmrc` and the release workflow |
| Dart | SDK constraint `>=3.2.0 <4.0.0`; use the SDK bundled with the pinned Flutter version |
| Java | **17** in the Android release workflow |
| Android compile SDK | **36** |
| Android target SDK | **34** |
| Android minimum SDK | **24** |
| Git | Required to clone this repository and fetch Git-based dependencies |

Install the platform toolchain for your chosen target, then check it with `flutter doctor`.

### Get the project

```bash
git clone https://github.com/SayuZX/KumaAnime-App.git
cd KumaAnime-App
flutter --version
flutter doctor
flutter pub get
```

If you use FVM, install the version specified in `.fvmrc` and run Flutter commands through `fvm flutter`.

Several dependencies are fetched from Git repositories rather than only from pub.dev. A working connection to those repositories is required during dependency resolution.

### Configure integrations

Review `.env_example` and the platform configuration before running account or source integrations. The template includes SIMKL configuration and a source base URL. The release workflow creates an `.env` file from configured secrets; this is not a guarantee that every integration loads that file automatically.

The application also includes Firebase and Auth0 integration code. Supply the configuration required by the enabled services for your environment. Never commit production secrets, signing keys, or personal session data.

### Run on a device

```bash
flutter devices
flutter run
```

### Build an Android APK

```bash
flutter build apk --release
```

Default output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

> [!IMPORTANT]
> Release distribution requires your own signing configuration. Review `android/app/build.gradle` and `android/key.properties` handling before distributing an APK; a locally generated release build is not automatically signed with an official release key.

### Build for desktop

Run these commands on a host with the corresponding platform toolchain installed:

```bash
# Windows host
flutter build windows --release

# Linux host
flutter build linux --release
```

See `.github/workflows/build-and-release.yml` for release packaging and `build_installer.ps1` for the Windows installer entrypoint.

## Project structure

```text
KumaAnime-App/
├── lib/
│   ├── core/          Application services, authentication, data, and sources
│   ├── controllers/   Application controllers
│   ├── models/        Shared data models
│   ├── services/      Subtitle services and repositories
│   ├── ui/            Screens, components, navigation, and themes
│   ├── l10n/          Localization resources and generated translations
│   ├── assets/        Icons, images, and fonts
│   └── main.dart      Application entrypoint
├── android/           Android project and signing configuration
├── linux/             Linux desktop project
├── windows/           Windows desktop project
├── ios/               iOS platform project
├── macos/             macOS platform project
├── web/               Web platform project
├── test/              Automated checks
├── .github/workflows/ Build and release automation
├── pubspec.yaml       Application metadata and dependencies
└── LICENSE            GNU GPL v3 terms
```

## Development checks

```bash
flutter analyze
flutter test
```

Run the application on the target platform as well. Static analysis and automated tests do not prove that provider playback, downloads, authentication, or native media integration work on a device.

## Troubleshooting

| Problem | What to check |
|---|---|
| Dependencies fail to resolve | Confirm the pinned Flutter version, Git availability, and access to Git-hosted packages. |
| Android build fails | Check Java 17, Android SDK 36, local SDK paths, and signing configuration. |
| A source cannot play an episode | Check provider availability, configuration, and network access. |
| External subtitles are out of sync | Adjust the timing offset; external subtitle support is still in beta. |
| Account features do not initialize | Review the Firebase, Auth0, and other enabled integration configuration. |
| Desktop build fails | Verify the native desktop toolchain and platform support of media and webview dependencies. |

## Contributing

Bug reports, reproducible examples, and focused pull requests are welcome. Include the affected platform, app version, steps to reproduce, and relevant logs with credentials removed.

Read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing. Follow [SECURITY.md](SECURITY.md) for security reports rather than publishing sensitive details in a public issue.

## Privacy

Review [PRIVACY_POLICY.txt](PRIVACY_POLICY.txt) before enabling account or network integrations. Keep personal tokens and session data out of screenshots, logs, and issue reports.

## License

Kuma Anime is distributed under the **GNU General Public License v3**. See [LICENSE](LICENSE) for the complete terms. Existing copyright notices, contributor attribution, and third-party license obligations remain in effect.

import 'dart:io';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/settingPages/logs.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoSetting extends StatefulWidget {
  const AppInfoSetting({super.key});

  @override
  State<AppInfoSetting> createState() => _AppInfoSettingState();
}

class _AppInfoSettingState extends State<AppInfoSetting> {
  String _version = '';
  String _buildNumber = '';
  String _buildTime = '-';
  String _sdk = '-';
  String _arch = '-';
  int _devTapCounter = 0;

  static const _repoUrl = "https://github.com/SayuZX/KumaAnime-App";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    _version = info.version;
    _buildNumber = info.buildNumber;
    _buildTime = _timestampFromVersion(info.version);
    if (Platform.isAndroid) {
      final android = await DeviceInfoPlugin().androidInfo;
      _sdk = "API ${android.version.sdkInt}";
      _arch = android.supportedAbis.firstOrNull ?? '-';
    }
    if (mounted) setState(() {});
  }

  String _timestampFromVersion(String version) {
    final match = RegExp(r'(\d{12})$').firstMatch(version);
    if (match == null) return '-';
    final s = match.group(1)!;
    return "${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)} ${s.substring(8, 10)}:${s.substring(10, 12)}";
  }

  void _open(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  bool get _isDark => currentUserSettings?.darkMode ?? true;

  Color get _cardColor => _isDark ? const Color(0xFF1E1F22) : Colors.white;

  Color get _chipColor => _isDark ? const Color(0xFF2A2B2F) : const Color(0xFFF1F1F4);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context, bottom: true).copyWith(left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, loc.aiAppInfo),
              const SizedBox(height: 12),
              _heroCard(loc),
              const SizedBox(height: 20),
              _sectionHeader(Icons.person_rounded, loc.aiSectionDeveloper),
              _developerCard(),
              const SizedBox(height: 20),
              _sectionHeader(Icons.info_rounded, loc.aiSectionApp),
              _appInfoCard(loc),
              const SizedBox(height: 20),
              _sectionHeader(Icons.policy_rounded, loc.aiSectionPolicies),
              _policiesCard(loc),
              const SizedBox(height: 20),
              _sectionHeader(Icons.widgets_rounded, loc.aiSectionMore),
              _moreCard(loc),
              const SizedBox(height: 20),
              _sectionHeader(Icons.public_rounded, loc.aiSectionSocial),
              _socialCard(loc),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  loc.aiMadeWith,
                  style: TextStyle(color: appTheme.textSubColor, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appTheme.accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: appTheme.accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(20), double radius = 28}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.06), width: 1),
      ),
      child: child,
    );
  }

  Widget _heroCard(AppLocalizations loc) {
    return _card(
      radius: 32,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              _devTapCounter++;
              if (_devTapCounter % 5 == 0) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LogScreen()));
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('lib/assets/icons/logo_foreground.png', height: 96, width: 96),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Kuma Anime",
            style: TextStyle(color: appTheme.textMainColor, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            loc.aiDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: appTheme.textSubColor, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _chip("v$_version", filled: true),
              if (_buildNumber.isNotEmpty) _chip("build $_buildNumber"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? appTheme.accentColor : _chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? appTheme.onAccent : appTheme.textMainColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _developerCard() {
    return _card(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: appTheme.accentColor, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/img/owner.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: appTheme.accentColor,
                  alignment: Alignment.center,
                  child: Text(
                    "RN",
                    style: TextStyle(color: appTheme.onAccent, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Raihan Nugroho",
                  style: TextStyle(color: appTheme.textMainColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const ["Founder", "Lead Developer", "UI/UX Designer"]
                      .map((role) => _roleChip(role))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role,
        style: TextStyle(color: appTheme.textMainColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _appInfoCard(AppLocalizations loc) {
    final rows = <MapEntry<String, String>>[
      MapEntry(loc.aiRowVersion, _version.isEmpty ? '-' : _version),
      MapEntry(loc.aiRowBuild, _buildNumber.isEmpty ? '-' : _buildNumber),
      MapEntry(loc.aiRowBuildTime, _buildTime),
      MapEntry(loc.aiRowEngine, "Flutter / Dart ${Platform.version.split(' ').first}"),
      if (Platform.isAndroid) MapEntry(loc.aiRowSdk, _sdk),
      if (Platform.isAndroid) MapEntry(loc.aiRowArch, _arch),
    ];

    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.key, style: TextStyle(color: appTheme.textSubColor, fontSize: 13.5)),
                    Text(
                      row.value,
                      style: TextStyle(color: appTheme.textMainColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _policiesCard(AppLocalizations loc) {
    final items = <(IconData, String, String)>[
      (Icons.privacy_tip_rounded, loc.aiPrivacy, loc.aiPrivacyBody),
      (Icons.description_rounded, loc.aiTerms, loc.aiTermsBody),
      (Icons.gavel_rounded, loc.aiDmca, loc.aiDmcaBody),
      (Icons.copyright_rounded, loc.aiCopyrightInfo, loc.aiCopyrightBody),
      (Icons.report_gmailerrorred_rounded, loc.aiDisclaimer, loc.aiDisclaimerBody),
    ];

    return _card(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: items.map((item) => _navRow(item.$1, item.$2, () => _openPolicy(item.$2, item.$3))).toList(),
      ),
    );
  }

  Widget _moreCard(AppLocalizations loc) {
    return _card(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _navRow(Icons.source_rounded, loc.aiLicenses, () => _showLicenses(loc)),
          _navRow(Icons.extension_rounded, loc.aiThirdParty, () => _showLicenses(loc)),
          _navRow(Icons.numbers_rounded, loc.aiVersionInfo, () => _versionDialog(loc)),
          _navRow(Icons.history_rounded, loc.aiChangelog, () => _open("$_repoUrl/releases")),
          _navRow(Icons.mail_rounded, loc.aiContactDev, () => _open("mailto:pixelraihan77@gmail.com")),
        ],
      ),
    );
  }

  Widget _navRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: appTheme.accentColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(color: appTheme.textMainColor, fontSize: 14.5)),
            ),
            Icon(Icons.chevron_right_rounded, color: appTheme.textSubColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _socialCard(AppLocalizations loc) {
    final links = <(IconData, String, String)>[
      (Icons.code_rounded, "GitHub", _repoUrl),
      (Icons.send_rounded, "Telegram", "https://t.me/kumaanime"),
      (Icons.forum_rounded, "Discord", "https://discord.gg/kumaanime"),
      (Icons.language_rounded, "Website", _repoUrl),
      (Icons.alternate_email_rounded, "Email", "mailto:pixelraihan77@gmail.com"),
    ];

    return _card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: links.map((link) {
              return InkWell(
                onTap: () => _open(link.$3),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: tileWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _chipColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(link.$1, color: appTheme.accentColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          link.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: appTheme.textMainColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _openPolicy(String title, String body) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: appTheme.textMainColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Text(body, style: TextStyle(color: appTheme.textSubColor, fontSize: 14, height: 1.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLicenses(AppLocalizations loc) {
    showLicensePage(
      context: context,
      applicationName: "Kuma Anime",
      applicationVersion: _version,
    );
  }

  void _versionDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.modalSheetBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.aiVersionInfo, style: TextStyle(color: appTheme.textMainColor)),
        content: Text(
          "${loc.aiRowVersion}: $_version\n${loc.aiRowBuild}: $_buildNumber\n${loc.aiRowBuildTime}: $_buildTime",
          style: TextStyle(color: appTheme.textSubColor, height: 1.7),
        ),
      ),
    );
  }
}

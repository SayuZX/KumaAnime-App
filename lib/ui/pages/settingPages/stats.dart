import 'dart:math';
import 'dart:ui';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/database/anilist/queries.dart';
import 'package:kumaanime/core/database/anilist/types.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class UserStats extends StatefulWidget {
  final UserModal userModal;
  const UserStats({super.key, required this.userModal});

  @override
  State<UserStats> createState() => _UserStatsState();
}

class _UserStatsState extends State<UserStats> {
  @override
  void initState() {
    user = widget.userModal;
    fetchUserStats();
    super.initState();
  }

  Future<void> fetchUserStats() async {
    try {
      final res = await AnilistQueries().getUserStats(user.name);
      final genreRes = res.genres.isNotEmpty ? await AnilistQueries().getGenreThumbnail(res.genres[0].genre) : [];
      setState(() {
        stats = res;
        genreThumbnail = genreRes.isNotEmpty ? genreRes[Random().nextInt(genreRes.length)] : null;
        timeSpent = convertMinutes(res.minutesWatched);
      });
    } catch (err) {
      if (currentUserSettings?.showErrors ?? false) {
        floatingSnackBar(err.toString());
      }
    }
  }

  late UserModal user;
  String? genreThumbnail;
  AnilistUserStats? stats;

  ({int minutes, int hours, int days, int months, int years})? timeSpent;

  TextStyle textStyle(double fontSize, {bool bold = false, String fontFamily = "NotoSans"}) => TextStyle(
        color: appTheme.textMainColor,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : null,
      );

  ({int minutes, int hours, int days, int months, int years}) convertMinutes(int minutes) {
    int minutesInYear = 60 * 24 * 365;
    int minutesInMonth = 60 * 24 * 30;
    int minutesInDay = 60 * 24;
    int minutesInHour = 60;

    int years = minutes ~/ minutesInYear;
    int months = (minutes % minutesInYear) ~/ minutesInMonth;
    int days = ((minutes % minutesInYear) % minutesInMonth) ~/ minutesInDay;
    int hours = (((minutes % minutesInYear) % minutesInMonth) % minutesInDay) ~/ minutesInHour;
    int remainingMinutes = (((minutes % minutesInYear) % minutesInMonth) % minutesInDay) % minutesInHour;

    return (minutes: remainingMinutes, hours: hours, days: days, months: months, years: years);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: appTheme.textMainColor,
          ),
        ),
        backgroundColor: appTheme.backgroundColor,
        title: Text(
          loc.stStats,
          style: TextStyle(color: appTheme.textMainColor, fontSize: 25),
        ),
      ),
      body: stats != null
          ? Container(
              padding: pagePadding(context).copyWith(top: 0),
              child: Container(
                margin:
                    EdgeInsets.only(top: 30, left: 15, right: 15, bottom: MediaQuery.of(context).padding.bottom + 10),
                child: MediaQuery.sizeOf(context).width < 1200
                    ? SingleChildScrollView(
                        child: Column(
                          children: [_profileSection(false, loc), _tableSection(loc)],
                        ),
                      )
                    : Row(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _profileSection(true, loc)),
                          Expanded(flex: 3, child: SingleChildScrollView(child: _tableSection(loc))),
                        ],
                      ),
              ),
            )
          : Center(
              child: KumaAnimeLoading(
                color: appTheme.accentColor,
              ),
            ),
    );
  }

  Column _tableSection(AppLocalizations loc) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 35),
          decoration: BoxDecoration(
              // color: appTheme.backgroundSubColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: appTheme.textMainColor.withAlpha(30))),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // color: appTheme.accentColor.withAlpha(30),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        loc.stGenre,
                        style: textStyle(18, bold: true, ).copyWith(color: appTheme.accentColor),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        loc.stWatched,
                        textAlign: TextAlign.center,
                        style: textStyle(18, bold: true, ).copyWith(color: appTheme.accentColor),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        loc.stMinutes,
                        textAlign: TextAlign.right,
                        style: textStyle(18, bold: true, ).copyWith(color: appTheme.accentColor),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: stats?.genres.length ?? 0,
                itemBuilder: (context, index) {
                  final genre = stats!.genres[index];
                  final isLast = index == stats!.genres.length - 1;

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isLast ? Colors.transparent : appTheme.textMainColor.withAlpha(30),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  genre.genre,
                                  style: textStyle(17, bold: true),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${genre.count}",
                              textAlign: TextAlign.center,
                              style: textStyle(17, bold: true),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            genre.minutesWatched.toString(),
                            textAlign: TextAlign.right,
                            style: textStyle(17, bold: true).copyWith(color: appTheme.textMainColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column _profileSection(bool center, AppLocalizations loc) {
    return Column(
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.center,
          child: CircleAvatar(
            backgroundImage: user.avatar != null
                ? NetworkImage(user.avatar!)
                : AssetImage('lib/assets/images/chisato_AI.jpg') as ImageProvider,
            backgroundColor: Colors.grey,
            radius: 50,
          ),
        ),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 15),
          child: Text(
            "${user.name}",
            style: textStyle(22, bold: true),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 30),
          child: Text(
            loc.stStats,
            style: textStyle(23, bold: true, ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.stAnimesWatched,
                    style: textStyle(18, bold: true),
                  ),
                  Text(
                    "${stats!.notInPlanned}",
                    style: textStyle(18),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.stEpisodesWatched,
                    style: textStyle(18, bold: true),
                  ),
                  Text(
                    "${stats!.episodesWatched}",
                    style: textStyle(18),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.stTotalTime,
                    style: textStyle(18, bold: true),
                  ),
                  Text(
                    loc.stMinutesValue(stats!.minutesWatched),
                    style: textStyle(17),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(loc.stAight))
                          ],
                          content: Text(
                            loc.stTimeSpentDetail(timeSpent!.years, timeSpent!.months, timeSpent!.days,
                                timeSpent!.hours, timeSpent!.minutes),
                            style: textStyle(18),
                          ),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: appTheme.textMainColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 30),
          child: Text(
            loc.stMostWatchedGenre,
            style: textStyle(23, bold: true, ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(top: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 1.3, sigmaY: 1.3),
                child: Container(
                  width: 400,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: genreThumbnail != null
                          ? NetworkImage(genreThumbnail!)
                          : AssetImage('lib/assets/images/chisato.jpeg') as ImageProvider,
                      fit: BoxFit.cover,
                      opacity: 0.55,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stats?.genres.isNotEmpty == true ? stats!.genres.first.genre : loc.stNoGenreData,
                        style: textStyle(35, bold: true),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 8),
                      if (stats?.genres.isNotEmpty == true) ...[
                        _buildStatRow(
                          loc.stWatchedLabel,
                          "${stats!.genres.first.count}",
                        ),
                        SizedBox(height: 4),
                        _buildStatRow(
                          loc.stTimeSpent,
                          loc.stMinValue(stats!.genres.first.minutesWatched),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textStyle(18, bold: true),
        ),
        Text(
          value,
          style: textStyle(17),
        ),
      ],
    );
  }
}

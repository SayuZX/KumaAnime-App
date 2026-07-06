import 'package:kumaanime/controllers/subtitle_controller.dart';
import 'package:kumaanime/ui/models/bottomSheets/subtitleSelectorSheet.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/bottomSheets/customControlsSheet.dart';
import 'package:kumaanime/ui/models/providers/playerDataProvider.dart';
import 'package:kumaanime/ui/models/providers/playerProvider.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({super.key});

  void showSheet(BuildContext context, Widget child) => showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      context: context,
      builder: (BuildContext context) {
        return child;
      });

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.read<PlayerDataProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final loc = AppLocalizations.of(context);
    // final a = dataProvider.state.currentAudioTrack;
    // playerProvider.controller.setAudioTrack(a.url, a.language, a.name);

    return dataProvider.state.controlsLocked
        ? Container()
        : Container(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          backgroundColor: appTheme.modalSheetBackgroundColor,
                          showDragHandle: false,
                          barrierColor: Color.fromARGB(17, 255, 255, 255),
                          builder: (BuildContext context) {
                            return Container(
                              width: 400,
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      loc.bcChooseQuality,
                                      style:
                                          TextStyle(color: appTheme.textMainColor, fontSize: 20),
                                    ),
                                  ),
                                  ListView.builder(
                                    itemCount: dataProvider.state.qualities.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (BuildContext context, index) {
                                      return Container(
                                        padding: EdgeInsets.only(left: 25, right: 25),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // final src = dataProvider.state.qualities[index].url;
                                            dataProvider.updateCurrentQuality(dataProvider.state.qualities[index]);
                                            playerProvider.setQuality(dataProvider.state.qualities[index]);
                                            // selectedQuality = dataProvider.state.qualities[index]['quality'] ?? '720';
                                            // dataProvider.updateCurrentQuality(dataProvider.state.qualities[index]);
                                            // playerProvider.playVideo(src,
                                            //     currentStream: dataProvider.state.currentStream,
                                            //     preserveProgress: true);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              // side: BorderSide(color: Colors.white)
                                            ),
                                            backgroundColor: dataProvider.state.qualities[index].url ==
                                                    dataProvider.state.currentQuality.url
                                                ? appTheme.accentColor
                                                : appTheme.backgroundSubColor,
                                          ),
                                          child: Text(
                                            "${dataProvider.state.qualities[index].quality}",
                                            style: TextStyle(
                                              color: dataProvider.state.qualities[index].url ==
                                                      dataProvider.state.currentQuality.url
                                                  ? Colors.black
                                                  : appTheme.accentColor,
                                              ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      tooltip: loc.bcQualities,
                      icon: Icon(
                        Icons.high_quality_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showSheet(
                          context,
                          CustomControlsBottomSheet(
                            index: dataProvider.state.currentEpIndex,
                            dataProvider: dataProvider,
                            playerProvider: playerProvider,
                          ),
                        );
                      },
                      tooltip: loc.bcServers,
                      icon: Icon(
                        Icons.source_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: appTheme.modalSheetBackgroundColor,
                          context: context,
                          builder: (context) => Container(
                            padding: EdgeInsets.only(left: 20, right: 20, top: 15),
                            height: MediaQuery.of(context).size.height - 80,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    loc.bcSelectEpisode,
                                    style: textStyle().copyWith(fontSize: 23),
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.only(left: 6, right: 6, bottom: 20),
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: List.generate(dataProvider.epLinks.length, (index) {
                                        final isCurrent = index == dataProvider.state.currentEpIndex;
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context);
                                            if (isCurrent) return;
                                            sheet2(index, context, playerProvider, dataProvider);
                                          },
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                color: isCurrent ? appTheme.accentColor : appTheme.backgroundSubColor,
                                                borderRadius: BorderRadius.circular(12)),
                                            child: Text(
                                              "${index + 1}",
                                              style: TextStyle(
                                                color: isCurrent ? appTheme.onAccent : appTheme.textMainColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      tooltip: loc.bcEpisodeList,
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                //right side
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return playBackSpeedDialog(context, playerProvider, dataProvider);
                          },
                        );
                      },
                      tooltip: loc.bcPlaybackSpeed,
                      icon: Icon(
                        Icons.speed_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final subController = context.read<SubtitleController>();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SubtitleSelectorSheet(
                            controller: subController,
                            playerProvider: playerProvider,
                            onSettingsChanged: () {
                              dataProvider.initSubsettings();
                            },
                          ),
                        );
                      },
                      tooltip: loc.bcSubtitles,
                      icon: Icon(
                        !playerProvider.state.showSubs ? Icons.subtitles_outlined : Icons.subtitles_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await playerProvider.setPip(!playerProvider.state.pip);
                      },
                      icon: Icon(Icons.picture_in_picture_alt_rounded),
                      tooltip: loc.bcPictureInPicture,
                      color: Colors.white,
                    ),
                    // IconButton(
                    //   onPressed: () async {
                    //     showModalBottomSheet(
                    //         context: context,
                    //         builder: (context) {
                    //           return ListView.builder(
                    //             itemCount: dataProvider.state.audioTracks.length,
                    //             shrinkWrap: true,
                    //             physics: NeverScrollableScrollPhysics(),
                    //             itemBuilder: (BuildContext context, index) {
                    //               return Container(
                    //                 padding: EdgeInsets.only(left: 25, right: 25),
                    //                 child: ElevatedButton(
                    //                   onPressed: () async {
                    //                     // final src = dataProvider.state.qualities[index].url;
                    //                     dataProvider.updateCurrentAudioTrack(dataProvider.state.audioTracks[index]);
                    //                     playerProvider.controller.setAudioTrack(dataProvider.state.currentAudioTrack);
                    //                     // selectedQuality = dataProvider.state.qualities[index]['quality'] ?? '720';
                    //                     // dataProvider.updateCurrentQuality(dataProvider.state.qualities[index]);
                    //                     // playerProvider.playVideo(src,
                    //                     //     currentStream: dataProvider.state.currentStream,
                    //                     //     preserveProgress: true);
                    //                     Navigator.pop(context);
                    //                   },
                    //                   style: ElevatedButton.styleFrom(
                    //                     shape: RoundedRectangleBorder(
                    //                       borderRadius: BorderRadius.circular(10),
                    //                       // side: BorderSide(color: Colors.white)
                    //                     ),
                    //                     backgroundColor: dataProvider.state.audioTracks[index].url ==
                    //                             dataProvider.state.currentAudioTrack.url
                    //                         ? appTheme.accentColor
                    //                         : appTheme.backgroundSubColor,
                    //                   ),
                    //                   child: Text(
                    //                     "${dataProvider.state.audioTracks[index].name} (${dataProvider.state.audioTracks[index].language})",
                    //                     style: TextStyle(
                    //                       color: dataProvider.state.audioTracks[index].url ==
                    //                               dataProvider.state.currentAudioTrack.url
                    //                           ? Colors.black
                    //                           : appTheme.accentColor,
                    //                       //                     ),
                    //                   ),
                    //                 ),
                    //               );
                    //             },
                    //           );
                    //         });
                    //   },
                    //   icon: Icon(Icons.audiotrack_rounded),
                    //   tooltip: "Audio Tracks",
                    //   color: Colors.white,
                    // ),
                    IconButton(
                      onPressed: () {
                        playerProvider.cycleViewMode();
                      },
                      icon: Icon(playerProvider.state.currentViewMode.icon),
                      tooltip: playerProvider.state.currentViewMode.desc,
                      color: Colors.white,
                    ),
                  ],
                )
              ],
            ),
          );
  }

  void sheet2(
    int index,
    BuildContext context,
    PlayerProvider pp,
    PlayerDataProvider dp,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (context) => CustomControlsBottomSheet(
        index: index,
        dataProvider: dp,
        playerProvider: pp,
      ),
    );
  }

  Widget playBackSpeedDialog(BuildContext context, PlayerProvider pp, PlayerDataProvider dp) {
    final loc = AppLocalizations.of(context);
    final playbackSpeeds = pp.playbackSpeeds;
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      child: AlertDialog(
        backgroundColor: appTheme.modalSheetBackgroundColor,
          content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              loc.bcSpeed,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, ),
            ),
          ),
          Expanded(
            child: StatefulBuilder(
              builder: (context, setState) => Container(
                // height: 230,
                width: 250,
                child: ListView.builder(
                  itemCount: playbackSpeeds.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 5),
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: appTheme.backgroundSubColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            pp.setSpeed(playbackSpeeds[index]);
                            setState(() {});
                          },
                          child: Row(
                            children: [
                              Radio<double>(
                                value: playbackSpeeds[index],
                                groupValue: pp.state.speed,
                                onChanged: (val) {
                                  pp.setSpeed(val ?? 1);
                                  setState(() {});
                                },
                              ),
                              Text(playbackSpeeds[index].toString() + "x"),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 5),
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc.bcClose,
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      )),
    );
  }
}

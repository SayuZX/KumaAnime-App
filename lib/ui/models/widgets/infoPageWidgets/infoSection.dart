import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/models/providers/infoProvider.dart';
import 'package:kumaanime/ui/models/widgets/infoPageWidgets/commonInfo.dart';
import 'package:kumaanime/ui/models/widgets/infoPageWidgets/scrollingList.dart';
import 'package:kumaanime/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class InfoSection extends StatelessWidget {
  final Size size;
  final InfoProvider provider;
  final int splitWidth;
  const InfoSection({
    super.key,
    required this.provider,
    required this.size,
    required this.splitWidth,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final recommendationScrollController = ScrollController();
    final charactersScrollController = ScrollController();
    // final relatedScrollController = ScrollController();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 30, left: 15),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start, // Puts the stuff to more left
            children: [
              CommonInfo(
                provider: provider,
                splitWidth: splitWidth,
              ),
              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(top: 50),
                width: size.width / 2,
                constraints: BoxConstraints(maxWidth: 650),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Text(
                            provider.data.type,
                            style: _textStyle(),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: appTheme.textMainColor, borderRadius: BorderRadius.circular(5)),
                          padding: EdgeInsets.fromLTRB(10, 5, 15, 5),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 33,
                                color: appTheme.backgroundColor,
                              ),
                              Text(
                                " ${provider.data.rating}",
                                style: _textStyle().copyWith(color: appTheme.backgroundColor),
                              ),
                            ],
                          ),
                        ),
                        Text(loc.isecEpisodesCount("${provider.data.episodes ?? "??"}"), style: _textStyle())
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 50, bottom: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (size.width <= splitWidth)
                      Container(
                        margin: EdgeInsets.only(bottom: 50),
                        width: size.width / 1.5,
                        child: Column(
                          spacing: 20,
                          children: [
                            Text(
                              loc.isecSynopsis,
                              style: _textStyle(),
                            ),
                            Text(
                              provider.data.synopsis ?? loc.isecNoSynopsis,
                              style: _textStyle().copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(20)),
                          constraints: BoxConstraints(minWidth: 450, maxWidth: 650),
                          width: size.width / 2.5,
                          padding: EdgeInsets.all(25),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  spacing: 2,
                                  children: [
                                    _infoBoxItem(loc.isecStatus, provider.data.status ?? "??"),
                                    _infoBoxItem(loc.isecDuration, provider.data.duration),
                                    _infoBoxItem(loc.isecStudios, provider.data.studios.join(", ")),
                                    _infoBoxItem(
                                        loc.isecAirStart,
                                        provider.data.aired['start']!.trim().isEmpty
                                            ? "??"
                                            : provider.data.aired['start']!),
                                    _infoBoxItem(
                                        loc.isecAirEnd,
                                        provider.data.aired['end']!.trim().isEmpty
                                            ? "??"
                                            : provider.data.aired['end']!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (size.width >= 1200 && size.width <= splitWidth)
                          _tagsNgenresBuilder(loc.isecGenres, provider.data.genres, context: context),
                      ],
                    ),
                    if (size.width < 1200)
                      Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: _tagsNgenresBuilder(loc.isecGenres, provider.data.genres,
                            context: context, unconstrainedWidth: true, padLeft: false),
                      ),
                  ],
                ),
              ),
              if (size.width < splitWidth)
                _tagsNgenresBuilder(loc.isecTags, provider.data.tags!,
                    unconstrainedWidth: true, padLeft: false, context: context),
              ScrollingList.character(
                  context, splitWidth, charactersScrollController, provider.data.characters),
              // ScrollingList.animeCards(context, splitWidth, relatedScrollController, "Related", provider.data.related), // Notto ereganto!
              ScrollingList.animeCards(context, splitWidth, recommendationScrollController, loc.isecRecommended,
                  provider.data.recommended),
              SizedBox(
                height: 16,
              )
            ],
          ),
        ),
        if (size.width >= splitWidth)
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 30, right: size.width / 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _tagsNgenresBuilder(loc.isecGenres, provider.data.genres, context: context),
                  _tagsNgenresBuilder(loc.isecSynopsis, [provider.data.synopsis ?? ""], synopsis: true, context: context),
                  if (provider.data.tags != null) _tagsNgenresBuilder(loc.isecTags, provider.data.tags!, context: context),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Row _infoBoxItem(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            key,
            style: _textStyle().copyWith(fontSize: 20),
          ),
        ),
        Text(
          value,
          style: _textStyle().copyWith(fontWeight: FontWeight.normal, fontSize: 20),
        ),
      ],
    );
  }

  Container _tagsNgenresBuilder(String title, List<dynamic> list,
      {bool unconstrainedWidth = false, bool synopsis = false, bool padLeft = true, required BuildContext context}) {
    return Container(
      margin: EdgeInsets.only(left: padLeft ? 60 : 0, bottom: 30),
      padding: EdgeInsets.all(15),
      constraints: BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: appTheme.backgroundSubColor,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, ),
          ),
          Container(
            width: unconstrainedWidth ? MediaQuery.sizeOf(context).width / 2 : 400,
            padding: EdgeInsets.only(top: 20),
            child: synopsis
                ? Text(list[0])
                : Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: list
                        .map(
                          (item) => Container(
                            margin: EdgeInsets.zero,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: appTheme.textSubColor,
                            ),
                            child: Text(
                              item ?? "",
                              style: TextStyle(fontSize: 18, color: appTheme.backgroundColor),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  TextStyle _textStyle() => TextStyle(fontSize: 25, fontWeight: FontWeight.bold);
}

import 'dart:ui';

import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/commons/enums.dart';
import 'package:kumaanime/core/data/secureStorage.dart';
import 'package:kumaanime/core/database/anilist/anilist.dart';
import 'package:kumaanime/core/database/anilist/login.dart';
import 'package:kumaanime/core/database/anilist/types.dart';
import 'package:kumaanime/core/database/database.dart';
import 'package:kumaanime/core/database/mal/login.dart';
import 'package:kumaanime/core/database/simkl/login.dart';
import 'package:kumaanime/core/database/simkl/types.dart';
import 'package:kumaanime/core/social/rankSystem.dart';
import 'package:kumaanime/core/social/socialService.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:kumaanime/ui/pages/settingPages/common.dart';
import 'package:kumaanime/ui/pages/settingPages/stats.dart';
import 'package:kumaanime/ui/models/providers/appProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  State<AccountSetting> createState() => _AccountSettingState();
}

class _AccountSettingState extends State<AccountSetting> {
  @override
  void initState() {
    getLoggedIn().then((value) {
      //display login button if not logged in any of accounts
      if (!anilistLoggedIn && !simklLoggedIn && !malLoggedIn) {
        if (mounted)
          setState(() {
            loading = false;
          });
      }

      List<Future> futures = [];
      UserModal? alu, simu, malu;

      //load user profile if logged in
      if (anilistLoggedIn) {
        futures.add(AniListLogin().getUserProfile().then((res) {
          alu = res;
        }).catchError((Object? err) async {
          if (!(err is AnilistApiException)) {
            floatingSnackBar("Anilist error: ${err.toString()}");
            return;

            // yes, i know its not a good idea to check by message but yeah...
          } else if (err.statusCode == 401 || err.message.toLowerCase().contains("invalid token")) {
            // token is expired, invalid or has its access revoked!
            floatingSnackBar("Anilist token is invalid. Login again!");

            await AniListLogin().removeToken();
          }
          if (mounted) {
            setState(() {
              anilistLoggedIn = false;
            });
          }
        }));
      }
      if (simklLoggedIn) {
        futures.add(SimklLogin().getUserProfile().then((res) {
          simu = res;
        }).catchError((Object? err) {
          if (err is SimklException) {
            if (err.isUnauthorized) {
              floatingSnackBar("Simkl token is invalid. Login again!");

              SimklLogin().removeToken();
            }
          }
          if (mounted) {
            setState(() {
              simklLoggedIn = false;
            });
          }
        }));
      }

      if (malLoggedIn) {
        futures.add(MALLogin().getUserProfile().then((res) {
          malu = res;
        }).catchError((Object? err) {
          // since token cant be revoked from MAL site :), the 401 error is only for expired tokens
          // and it is handled in MAL.fetch() itself, so no need to check for that here
          // if (err is MalException) {
          //   if (err.isUnauthorized) {
          //     // token is expired, invalid or has its access revoked!
          //     floatingSnackBar("MAL token is invalid. Login again!");

          //     MALLogin().removeToken();
          //   }
          // }
          floatingSnackBar("MAL error: ${err.toString()}");
          setState(() {
            malLoggedIn = false;
          });
        }));
      }

      Future.wait(futures).then((val) {
        if (mounted)
          setState(() {
            simklUser = simu;
            user = alu;
            malUser = malu;
            loading = false;
          });
      });
    });
    super.initState();
  }

  bool anilistLoggedIn = false;
  bool simklLoggedIn = false;
  bool malLoggedIn = false;

  UserModal? user;
  UserModal? simklUser;
  UserModal? malUser;

  bool loading = true;

  Future<void> getLoggedIn() async {
    final aniToken = await getSecureVal(SecureStorageKey.anilistToken);
    final simklToken = await getSecureVal(SecureStorageKey.simklToken);
    final malToken = await getSecureVal(SecureStorageKey.malToken);
    if (aniToken != null && mounted) {
      setState(() {
        anilistLoggedIn = true;
      });
    }
    if (malToken != null && mounted) {
      setState(() {
        malLoggedIn = true;
      });
    }
    if (simklToken != null && mounted) {
      setState(() {
        simklLoggedIn = true;
      });
    }
  }

  String capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  bool getLoginState(Databases db) {
    switch (db) {
      case Databases.anilist:
        return anilistLoggedIn;
      case Databases.simkl:
        return simklLoggedIn;
      case Databases.mal:
        return malLoggedIn;
      // default:
      //   return false; // Default for other databases
    }
  }

  UserModal? getUserModal(String databaseName) {
    switch (databaseName) {
      case "anilist":
        return user;
      case "simkl":
        return simklUser;
      case "mal":
        return malUser;
      default:
        throw Exception("No User for $databaseName");
    }
  }

  Future<bool> Function() getLoginFunction(Databases db) {
    switch (db) {
      case Databases.anilist:
        return AniListLogin().initiateLogin;
      case Databases.simkl:
        return SimklLogin().initiateLogin;
      case Databases.mal:
        return MALLogin().initiateLogin;
      // default:
      //   throw Exception("Login function not defined for $db");
    }
  }

  Future<void> Function() getLogoutFunction(Databases db) {
    switch (db) {
      case Databases.anilist:
        return AniListLogin().removeToken;
      case Databases.simkl:
        return SimklLogin().removeToken;
      case Databases.mal:
        return MALLogin().removeToken;
      // default:
      // throw Exception("Logout function not defined for $db");
    }
  }

  final dbs = Databases.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingPagesTitleHeader(context, "Account"),
              _communityProfileCard(),
              _rankSection(),
              loading
                  ? Container(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                        child: KumaAnimeLoading(
                          color: appTheme.accentColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: dbs.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final db = Databases.values[index];
                        final dbName = capitalizeFirstLetter(db.name);
                        final loggedIn = getLoginState(db);
                        final loginFunction = getLoginFunction(db);
                        final logoutFunction = getLogoutFunction(db);

                        return _databaseAccountCard(
                          context,
                          dbName,
                          loggedIn,
                          loginFunction,
                          logoutFunction,
                        );
                      }),
            ],
          ),
        ),
      ),
    );
  }

  Container _databaseAccountCard(
    BuildContext context,
    String databaseName,
    bool loggedIn,
    Future<bool> Function() onLogin,
    Future<void> Function() onLogout,
  ) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      margin: EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 25),
            child: Text(
              capitalizeFirstLetter(databaseName),
              style: textStyle().copyWith(
                fontSize: 24,
              ),
            ),
          ),
          loggedIn
              ? _accountCard(context, onLogout: () {
                  if (mounted)
                    setState(() {
                      onLogout().then(
                        (value) => setState(() {
                          if (databaseName.toLowerCase() == 'anilist') {
                            anilistLoggedIn = false;
                          } else if (databaseName.toLowerCase() == 'simkl') {
                            simklLoggedIn = false;
                          } else if (databaseName.toLowerCase() == 'mal') {
                            malLoggedIn = false;
                          }
                        }),
                      );
                    });
                  floatingSnackBar("Logged out successfully!");
                }, usermodal: getUserModal(databaseName.toLowerCase()))
              : _loginCard(context, onLogin: () {
                  setState(() {
                    onLogin().then((logged) {
                      if (logged) {
                        floatingSnackBar("Login successful!");
                        Provider.of<AppProvider>(context, listen: false).justRefresh();
                      }
                      //replace the page with itself to avoid recalling the functions in initState to update the user data
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountSetting(),
                        ),
                      );
                    }).onError((err, st) {
                      floatingSnackBar("Login failed! Try again");
                      print(err.toString());
                      print(st.toString());
                    });
                  });
                }),
        ],
      ),
    );
  }

  Container _loginCard(
    BuildContext context, {
    required void Function() onLogin,
  }) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: appTheme.backgroundSubColor,
          boxShadow: [BoxShadow(color: appTheme.backgroundSubColor, blurRadius: 5)]),
      padding: EdgeInsets.only(top: 20, bottom: 20),
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.backgroundColor,
                fixedSize: Size(150, 50),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: appTheme.accentColor),
                  borderRadius: BorderRadius.circular(35),
                )),
            child: Text(
              "Log In",
              style: TextStyle(
                color: appTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              "The Animes watched is being saved in local storage.",
              style: TextStyle(
                color: appTheme.textSubColor,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }

  GestureDetector _accountCard(BuildContext context,
      {required void Function() onLogout, required UserModal? usermodal}) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserStats(userModal: usermodal!)));
      },
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  image: DecorationImage(
                    image: usermodal?.banner != null
                        ? NetworkImage(usermodal!.banner!)
                        : AssetImage('lib/assets/images/profile_banner.jpg') //such a nice image!
                            as ImageProvider,
                    fit: BoxFit.cover,
                    opacity: 0.75,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: usermodal?.avatar != null
                      ? NetworkImage(usermodal!.avatar!)
                      : AssetImage(
                          "lib/assets/images/ghost.png",
                        ) as ImageProvider,
                  radius: 35,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          usermodal?.name ?? "UNKNOWN_GUY_69",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent.withAlpha(50),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: appTheme.accentColor),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                        ),
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _avatars = ['😺', '🦊', '🐼', '🐯', '🐧', '🐨', '🦁', '🐸', '🐙', '👾', '🍥', '⭐'];

  Widget _communityProfileCard() {
    final social = SocialService.instance;
    final avatar = social.avatar;
    final nickname = social.nickname;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: Text("Community Profile", style: textStyle().copyWith(fontSize: 24)),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: appTheme.accentColor.withValues(alpha: 0.2),
                  child: Text(
                    avatar.isNotEmpty ? avatar : (nickname.isNotEmpty ? nickname[0].toUpperCase() : "?"),
                    style: TextStyle(
                      color: appTheme.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: avatar.isNotEmpty ? 26 : 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nickname,
                          style: TextStyle(color: appTheme.textMainColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        social.isReady ? "Nama tampil di komentar & like" : "Fitur sosial tidak tersedia",
                        style: TextStyle(color: appTheme.textSubColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: social.isReady ? _editProfile : null,
                  icon: Icon(Icons.edit_rounded, color: appTheme.accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    final social = SocialService.instance;
    final controller = TextEditingController(text: social.nickname);
    String selected = social.avatar;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: appTheme.modalSheetBackgroundColor,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 6, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Profil", style: textStyle().copyWith(fontSize: 22)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLength: 24,
                style: TextStyle(color: appTheme.textMainColor),
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: appTheme.textSubColor),
                  filled: true,
                  fillColor: appTheme.backgroundSubColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              Text("Ikon Profil", style: TextStyle(color: appTheme.textMainColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _avatars.map((emoji) {
                  final isSelected = selected == emoji;
                  return GestureDetector(
                    onTap: () => setSheet(() => selected = emoji),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? appTheme.accentColor.withValues(alpha: 0.18) : appTheme.backgroundSubColor,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: appTheme.accentColor, width: 2) : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    await social.saveProfile(nickname: name.isEmpty ? social.nickname : name, avatar: selected);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    setState(() {});
                    floatingSnackBar("Profil disimpan");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.accentColor,
                    foregroundColor: appTheme.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rankSection() {
    final social = SocialService.instance;
    if (!social.isReady || social.accountCreatedAt == null) return const SizedBox.shrink();

    final ageDays = social.accountAgeDays;
    final episodes = social.episodesWatched;

    final timeRank = RankSystem.current(RankSystem.timeRanks, ageDays);
    final timeNext = RankSystem.next(RankSystem.timeRanks, ageDays);
    final activityRank = RankSystem.current(RankSystem.activityRanks, episodes);
    final activityNext = RankSystem.next(RankSystem.activityRanks, episodes);
    final achieved = RankSystem.timeRankAchievedOn(social.accountCreatedAt!, ageDays);
    final badges = RankSystem.earnedBadges(ageDays: ageDays, granted: social.grantedBadges);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            child: Text("Rank & Pencapaian", style: textStyle().copyWith(fontSize: 24)),
          ),
          _rankTile(
            emoji: timeRank.emoji,
            title: timeRank.name,
            subtitle: "Tercapai ${_formatDate(achieved)}",
            progress: RankSystem.progress(RankSystem.timeRanks, ageDays),
            footer: timeNext != null
                ? "Menuju ${timeNext.emoji} ${timeNext.name} • ${timeNext.threshold - ageDays} hari lagi"
                : "Rank waktu tertinggi tercapai 🎉",
          ),
          const SizedBox(height: 14),
          _rankTile(
            emoji: activityRank.emoji,
            title: activityRank.name,
            subtitle: "$episodes episode ditonton",
            progress: RankSystem.progress(RankSystem.activityRanks, episodes),
            footer: activityNext != null
                ? "Menuju ${activityNext.emoji} ${activityNext.name} • ${activityNext.threshold - episodes} episode lagi"
                : "Rank aktivitas tertinggi tercapai 🎉",
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text("Badge", style: TextStyle(color: appTheme.textMainColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: badges.map(_badgeChip).toList()),
          ],
        ],
      ),
    );
  }

  Widget _rankTile({
    required String emoji,
    required String title,
    required String subtitle,
    required double progress,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(color: appTheme.textMainColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: appTheme.backgroundColor,
              valueColor: AlwaysStoppedAnimation(appTheme.accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(footer, style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badgeChip(BadgeDef badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(badge.name, style: TextStyle(color: appTheme.textMainColor, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  void dispose() {
    super.dispose();
  }
}

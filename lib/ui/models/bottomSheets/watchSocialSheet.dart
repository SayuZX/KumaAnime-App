import 'package:kumaanime/core/app/logging.dart';
import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/core/database/database.dart';
import 'package:kumaanime/core/database/handler/handler.dart';
import 'package:kumaanime/core/social/socialService.dart';
import 'package:kumaanime/ui/models/snackBar.dart';
import 'package:kumaanime/ui/models/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

String socialKeyFor(int animeId, String title) {
  if (animeId > 0) return "anime:$animeId";
  final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'(^-+)|(-+$)'), '');
  return "title:${slug.isEmpty ? 'unknown' : slug}";
}

class WatchSocialSheet extends StatelessWidget {
  final int animeId;
  final String title;
  final VoidCallback onDownload;

  const WatchSocialSheet({
    super.key,
    required this.animeId,
    required this.title,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final socialKey = socialKeyFor(animeId, title);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: _TitleDescription(animeId: animeId, title: title),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: WatchActionsBar(socialKey: socialKey, animeId: animeId, title: title, onDownload: onDownload),
            ),
            Divider(height: 1, color: appTheme.textSubColor.withValues(alpha: 0.15)),
            Expanded(child: WatchCommentsView(socialKey: socialKey)),
          ],
        ),
      ),
    );
  }
}

class WatchSocialPanel extends StatelessWidget {
  final int animeId;
  final String title;
  final VoidCallback onDownload;

  const WatchSocialPanel({
    super.key,
    required this.animeId,
    required this.title,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final socialKey = socialKeyFor(animeId, title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _TitleDescription(animeId: animeId, title: title),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: WatchActionsBar(socialKey: socialKey, animeId: animeId, title: title, onDownload: onDownload),
        ),
        Divider(height: 1, color: appTheme.textSubColor.withValues(alpha: 0.15)),
        Expanded(child: WatchCommentsView(socialKey: socialKey)),
      ],
    );
  }
}

class _TitleDescription extends StatefulWidget {
  final int animeId;
  final String title;

  const _TitleDescription({required this.animeId, required this.title});

  @override
  State<_TitleDescription> createState() => _TitleDescriptionState();
}

class _TitleDescriptionState extends State<_TitleDescription> {
  String? _synopsis;
  String? _apiTitle;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.animeId <= 0) {
      setState(() => _loading = false);
      return;
    }
    try {
      final info = await DatabaseHandler(database: Databases.anilist).getAnimeInfo(widget.animeId);
      if (!mounted) return;
      setState(() {
        _synopsis = info.synopsis;
        _apiTitle = info.title['english'] ?? info.title['romaji'];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desc = (_synopsis ?? '').trim();
    final displayTitle = (_apiTitle != null && _apiTitle!.trim().isNotEmpty) ? _apiTitle! : widget.title;
    return GestureDetector(
      onTap: desc.isEmpty ? null : () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            maxLines: _expanded ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: appTheme.textMainColor, fontSize: 17, fontWeight: FontWeight.bold, height: 1.3),
          ),
          if (_loading && widget.animeId > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text("Memuat deskripsi...", style: TextStyle(color: appTheme.textSubColor, fontSize: 12)),
            )
          else if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: Text(
                desc,
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(color: appTheme.textSubColor, fontSize: 13, height: 1.45),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _expanded ? "Tutup" : "...selengkapnya",
              style: TextStyle(color: appTheme.textMainColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

class WatchActionsBar extends StatefulWidget {
  final String socialKey;
  final int animeId;
  final String title;
  final VoidCallback onDownload;

  const WatchActionsBar({
    super.key,
    required this.socialKey,
    required this.animeId,
    required this.title,
    required this.onDownload,
  });

  @override
  State<WatchActionsBar> createState() => _WatchActionsBarState();
}

class _WatchActionsBarState extends State<WatchActionsBar> {
  final _social = SocialService.instance;
  int _myVote = 0;

  late final Stream<Map<String, int>> _countsStream =
      _social.isReady ? _social.watchCounts(widget.socialKey) : const Stream<Map<String, int>>.empty();

  @override
  void initState() {
    super.initState();
    _loadVote();
  }

  Future<void> _loadVote() async {
    final vote = await _social.getMyVote(widget.socialKey);
    if (mounted) setState(() => _myVote = vote);
  }

  Future<void> _vote(int value) async {
    if (!_social.isReady) return;
    final applied = await _social.setVote(widget.socialKey, value);
    if (mounted) setState(() => _myVote = applied);
  }

  void _share() {
    final link = widget.animeId > 0 ? "\nhttps://anilist.co/anime/${widget.animeId}" : "";
    SharePlus.instance.share(ShareParams(text: "Nonton ${widget.title} di Kuma Anime$link"));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: StreamBuilder<Map<String, int>>(
        stream: _countsStream,
        builder: (context, snapshot) {
          final likes = snapshot.data?['likes'] ?? 0;
          final dislikes = snapshot.data?['dislikes'] ?? 0;
          return Row(
            children: [
              _voteSegment(likes, dislikes),
              const SizedBox(width: 10),
              _pill(Icons.share_rounded, "Bagikan", _share),
              const SizedBox(width: 10),
              _pill(Icons.download_rounded, "Unduh", widget.onDownload),
            ],
          );
        },
      ),
    );
  }

  Widget _voteSegment(int likes, int dislikes) {
    return Container(
      decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
            onTap: () => _vote(1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_myVote == 1 ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                      size: 20, color: _myVote == 1 ? appTheme.accentColor : appTheme.textMainColor),
                  const SizedBox(width: 8),
                  Text("$likes", style: TextStyle(color: appTheme.textMainColor, fontSize: 14)),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 22, color: appTheme.textSubColor.withValues(alpha: 0.25)),
          InkWell(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(30)),
            onTap: () => _vote(-1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_myVote == -1 ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined,
                      size: 20, color: _myVote == -1 ? appTheme.accentColor : appTheme.textMainColor),
                  const SizedBox(width: 8),
                  Text("$dislikes", style: TextStyle(color: appTheme.textMainColor, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(color: appTheme.backgroundSubColor, borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: appTheme.textMainColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: appTheme.textMainColor, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class WatchCommentsView extends StatefulWidget {
  final String socialKey;

  const WatchCommentsView({super.key, required this.socialKey});

  @override
  State<WatchCommentsView> createState() => _WatchCommentsViewState();
}

class _WatchCommentsViewState extends State<WatchCommentsView> {
  final _social = SocialService.instance;
  final _controller = TextEditingController();
  bool _sending = false;

  late final Stream<List<SocialComment>> _commentsStream =
      _social.isReady ? _social.watchComments(widget.socialKey) : const Stream<List<SocialComment>>.empty();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_social.isReady || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await _social.addComment(widget.socialKey, text);
    } catch (e) {
      Logs.app.log("[SOCIAL] comment write failed: ${e.toString()}");
      _controller.text = text;
      floatingSnackBar("Komentar gagal terkirim: ${e.toString()}");
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text("Komentar", style: TextStyle(color: appTheme.textMainColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(child: _list()),
          _input(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _list() {
    if (!_social.isReady) {
      return Center(child: Text("Fitur sosial tidak tersedia", style: TextStyle(color: appTheme.textSubColor)));
    }
    return StreamBuilder<List<SocialComment>>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: KumaAnimeLoading(color: appTheme.accentColor, size: 30));
        }
        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return Center(
            child: Text("Belum ada komentar. Jadilah yang pertama!",
                style: TextStyle(color: appTheme.textSubColor, fontSize: 14)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 4),
          itemCount: comments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _tile(comments[index]),
        );
      },
    );
  }

  Widget _tile(SocialComment comment) {
    final mine = comment.uid == _social.uid;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: appTheme.accentColor.withValues(alpha: 0.2),
          backgroundImage: comment.avatar.startsWith('http') ? NetworkImage(comment.avatar) : null,
          child: comment.avatar.startsWith('http')
              ? null
              : Text(
                  comment.avatar.isNotEmpty
                      ? comment.avatar
                      : (comment.nickname.isNotEmpty ? comment.nickname[0].toUpperCase() : "?"),
                  style: TextStyle(
                    color: appTheme.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: comment.avatar.isNotEmpty ? 18 : 14,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    mine ? "${comment.nickname} (kamu)" : comment.nickname,
                    style: TextStyle(color: appTheme.textMainColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  if (comment.createdAt != null) ...[
                    const SizedBox(width: 8),
                    Text(_relativeTime(comment.createdAt!),
                        style: TextStyle(color: appTheme.textSubColor, fontSize: 11)),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(comment.text, style: TextStyle(color: appTheme.textSubColor, fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return "baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}j";
    if (diff.inDays < 7) return "${diff.inDays}h";
    return "${(diff.inDays / 7).floor()}mgg";
  }

  Widget _input() {
    if (!_social.isReady) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            style: TextStyle(color: appTheme.textMainColor),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              hintText: "Tulis komentar...",
              hintStyle: TextStyle(color: appTheme.textSubColor, fontSize: 14),
              filled: true,
              fillColor: appTheme.backgroundSubColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, child) {
            final enabled = value.text.trim().isNotEmpty && !_sending;
            return IconButton.filled(
              onPressed: enabled ? _send : null,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: appTheme.accentColor,
                foregroundColor: appTheme.onAccent,
                disabledBackgroundColor: appTheme.accentColor.withValues(alpha: 0.3),
              ),
            );
          },
        ),
      ],
    );
  }
}

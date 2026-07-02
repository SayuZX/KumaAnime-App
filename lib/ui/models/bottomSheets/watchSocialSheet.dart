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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: WatchSocialPanel(animeId: animeId, title: title, onDownload: onDownload, showTitleHeader: true),
      ),
    );
  }
}

class WatchSocialPanel extends StatefulWidget {
  final int animeId;
  final String title;
  final VoidCallback onDownload;
  final bool showTitleHeader;

  const WatchSocialPanel({
    super.key,
    required this.animeId,
    required this.title,
    required this.onDownload,
    this.showTitleHeader = false,
  });

  @override
  State<WatchSocialPanel> createState() => _WatchSocialPanelState();
}

class _WatchSocialPanelState extends State<WatchSocialPanel> {
  final _social = SocialService.instance;
  final _commentController = TextEditingController();

  late final String _key = socialKeyFor(widget.animeId, widget.title);

  String? _synopsis;
  bool _synopsisLoading = true;
  bool _synopsisExpanded = false;
  int _myVote = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadSynopsis();
    _loadVote();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSynopsis() async {
    if (widget.animeId <= 0) {
      setState(() => _synopsisLoading = false);
      return;
    }
    try {
      final info = await DatabaseHandler(database: Databases.anilist).getAnimeInfo(widget.animeId);
      if (!mounted) return;
      setState(() {
        _synopsis = info.synopsis;
        _synopsisLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _synopsisLoading = false);
    }
  }

  Future<void> _loadVote() async {
    final vote = await _social.getMyVote(_key);
    if (mounted) setState(() => _myVote = vote);
  }

  Future<void> _vote(int value) async {
    if (!_social.isReady) return;
    final applied = await _social.setVote(_key, value);
    if (mounted) setState(() => _myVote = applied);
  }

  void _share() {
    final link = widget.animeId > 0 ? "\nhttps://anilist.co/anime/${widget.animeId}" : "";
    SharePlus.instance.share(ShareParams(text: "Nonton ${widget.title} di Kuma Anime$link"));
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || !_social.isReady || _sending) return;
    setState(() => _sending = true);
    _commentController.clear();
    try {
      await _social.addComment(_key, text);
    } catch (_) {
      _commentController.text = text;
      floatingSnackBar("Gagal mengirim komentar");
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
          const SizedBox(height: 6),
          if (widget.showTitleHeader) ...[
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: appTheme.textMainColor, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
          ],
          _synopsisBlock(),
          const SizedBox(height: 14),
          _actionRow(),
          const SizedBox(height: 6),
          Divider(color: appTheme.textSubColor.withValues(alpha: 0.2)),
          _commentsHeader(),
          const SizedBox(height: 8),
          Expanded(child: _commentsList()),
          _commentInput(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _synopsisBlock() {
    if (widget.animeId <= 0) return const SizedBox.shrink();
    if (_synopsisLoading) {
      return Row(
        children: [
          KumaAnimeLoading(color: appTheme.accentColor, size: 18),
          const SizedBox(width: 10),
          Text("Memuat deskripsi...", style: TextStyle(color: appTheme.textSubColor, fontSize: 13)),
        ],
      );
    }
    final text = _synopsis ?? '';
    if (text.isEmpty) {
      return Text("Deskripsi tidak tersedia", style: TextStyle(color: appTheme.textSubColor, fontSize: 13));
    }
    return GestureDetector(
      onTap: () => setState(() => _synopsisExpanded = !_synopsisExpanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Text(
          text,
          maxLines: _synopsisExpanded ? null : 3,
          overflow: _synopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(color: appTheme.textSubColor, fontSize: 13, height: 1.5),
        ),
      ),
    );
  }

  Widget _actionRow() {
    return StreamBuilder<Map<String, int>>(
      stream: _social.isReady ? _social.watchCounts(_key) : const Stream.empty(),
      builder: (context, snapshot) {
        final likes = snapshot.data?['likes'] ?? 0;
        final dislikes = snapshot.data?['dislikes'] ?? 0;
        return Row(
          children: [
            _pillButton(
              icon: _myVote == 1 ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
              label: "$likes",
              active: _myVote == 1,
              onTap: () => _vote(1),
            ),
            const SizedBox(width: 10),
            _pillButton(
              icon: _myVote == -1 ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined,
              label: "$dislikes",
              active: _myVote == -1,
              onTap: () => _vote(-1),
            ),
            const Spacer(),
            _iconButton(Icons.share_rounded, _share),
            const SizedBox(width: 6),
            _iconButton(Icons.download_rounded, widget.onDownload),
          ],
        );
      },
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? appTheme.accentColor.withValues(alpha: 0.16) : appTheme.backgroundSubColor,
          borderRadius: BorderRadius.circular(30),
          border: active ? Border.all(color: appTheme.accentColor.withValues(alpha: 0.55)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? appTheme.accentColor : appTheme.textMainColor),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(color: active ? appTheme.accentColor : appTheme.textMainColor, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: appTheme.backgroundSubColor, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: appTheme.textMainColor),
      ),
    );
  }

  Widget _commentsHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text("Komentar", style: TextStyle(color: appTheme.textMainColor, fontSize: 17, fontWeight: FontWeight.bold)),
    );
  }

  Widget _commentsList() {
    if (!_social.isReady) {
      return Center(
        child: Text("Fitur sosial tidak tersedia", style: TextStyle(color: appTheme.textSubColor, fontSize: 14)),
      );
    }
    return StreamBuilder<List<SocialComment>>(
      stream: _social.watchComments(_key),
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
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) => _commentTile(comments[index]),
        );
      },
    );
  }

  Widget _commentTile(SocialComment comment) {
    final mine = comment.uid == _social.uid;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: appTheme.accentColor.withValues(alpha: 0.2),
          child: Text(
            comment.nickname.isNotEmpty ? comment.nickname[0].toUpperCase() : "?",
            style: TextStyle(color: appTheme.accentColor, fontWeight: FontWeight.bold),
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

  Widget _commentInput() {
    if (!_social.isReady) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
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
          valueListenable: _commentController,
          builder: (context, value, child) {
            final enabled = value.text.trim().isNotEmpty && !_sending;
            return IconButton.filled(
              onPressed: enabled ? _sendComment : null,
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

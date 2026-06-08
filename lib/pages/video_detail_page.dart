import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media.dart';
import '../models/comment.dart';
import '../models/playlist.dart';
import '../services/murrtube_api.dart';
import '../theme/app_theme.dart';
import '../widgets/video_card.dart';

class VideoDetailPage extends StatefulWidget {
  final String shortCode;

  const VideoDetailPage({super.key, required this.shortCode});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  Media? _medium;
  List<Comment> _comments = [];
  List<Media> _watchMore = [];
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _showComments = false;
  bool _showSkip = false;
  bool _skipForward = true;
  bool _isDraggingTimeline = false;
  double _dragProgress = 0;
  bool _viewerCanLike = false;
  bool _viewerLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await MurrtubeApi.getVideo(widget.shortCode);
      setState(() {
        _medium = result.medium;
        _comments = result.comments;
        _watchMore = result.watchMore;
        _viewerCanLike = result.viewerCanLike;
        _viewerLiked = result.medium.viewerLiked;
        _likesCount = result.medium.likesCount;
        _loading = false;
      });
      if (_medium?.hlsUrl != null) {
        _initPlayer(_medium!.hlsUrl!);
      }
    } catch (e) {
      debugPrint('VideoDetailPage load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _showSaveBottomSheet() async {
    if (_medium == null) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SaveSheet(
        medium: _medium!,
        onCreate: (name, visibility) async {
          await MurrtubeApi.createPlaylist(
            name: name,
            visibility: visibility,
          );
          final updated = await MurrtubeApi.getMyPlaylists();
          final created = updated.firstWhere(
            (p) => p.name == name,
            orElse: () => updated.first,
          );
          await MurrtubeApi.addToPlaylist(
            playlistId: created.id,
            shortCode: _medium!.shortCode,
            mediumId: _medium!.id,
          );
          if (mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved to $name')),
            );
          }
        },
        onSelect: (playlist) async {
          await MurrtubeApi.addToPlaylist(
            playlistId: playlist.id,
            shortCode: _medium!.shortCode,
            mediumId: _medium!.id,
          );
          if (mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved to ${playlist.name}')),
            );
          }
        },
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_medium == null || !_viewerCanLike) return;
    final medium = _medium!;
    final wasLiked = _viewerLiked;
    setState(() {
      _viewerLiked = !wasLiked;
      _likesCount += wasLiked ? -1 : 1;
    });
    try {
      if (wasLiked) {
        await MurrtubeApi.unlikeVideo(medium.id);
      } else {
        await MurrtubeApi.likeVideo(medium.id);
      }
    } catch (e) {
      debugPrint('Toggle like error: $e');
      // Revert on error
      setState(() {
        _viewerLiked = wasLiked;
        _likesCount += wasLiked ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${wasLiked ? 'unlike' : 'like'}: $e')),
        );
      }
    }
  }

  void _initPlayer(String url) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  void _onDoubleTap(bool forward) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;

    Duration newPos;
    if (forward) {
      newPos = pos + const Duration(seconds: 10);
      if (newPos > dur) newPos = dur;
    } else {
      newPos = pos - const Duration(seconds: 10);
      if (newPos < Duration.zero) newPos = Duration.zero;
    }

    _controller!.seekTo(newPos);
    setState(() {
      _showSkip = true;
      _skipForward = forward;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showSkip = false);
    });
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    final medium = _medium;
    if (medium == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Video not found',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player / Thumbnail
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_controller != null && _controller!.value.isInitialized)
                              FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: _controller!.value.size.width,
                                  height: _controller!.value.size.height,
                                  child: VideoPlayer(_controller!),
                                ),
                              )
                            else
                              CachedNetworkImage(
                                imageUrl: medium.thumbnailUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => Container(
                                  color: AppColors.surfaceHighlight,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surfaceHighlight,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                    // Double tap zones
                    if (_controller != null && _controller!.value.isInitialized)
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onDoubleTap: () => _onDoubleTap(false),
                                behavior: HitTestBehavior.translucent,
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onDoubleTap: () => _onDoubleTap(true),
                                behavior: HitTestBehavior.translucent,
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Play/Pause single tap overlay
                    if (_controller != null && _controller!.value.isInitialized)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _controller!.value.isPlaying
                                  ? _controller!.pause()
                                  : _controller!.play();
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _controller!.value.isPlaying ? 0 : 1,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Skip animation overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _showSkip ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _skipForward
                                        ? Icons.forward_10
                                        : Icons.replay_10,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _skipForward ? '+10s' : '-10s',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Bottom timeline
                    if (_controller != null && _controller!.value.isInitialized)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final barWidth = constraints.maxWidth;
                                  void seekToFraction(double fraction) {
                                    final dur = _controller!.value.duration;
                                    _controller!.seekTo(
                                      Duration(
                                        milliseconds: (fraction.clamp(0.0, 1.0) * dur.inMilliseconds).round(),
                                      ),
                                    );
                                  }

                                  final progress = _controller!.value.duration.inMilliseconds > 0
                                      ? _controller!.value.position.inMilliseconds /
                                          _controller!.value.duration.inMilliseconds
                                      : 0.0;

                                  final currentFraction = _isDraggingTimeline ? _dragProgress : progress;

                                  return GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: (details) {
                                      final fraction = details.localPosition.dx / barWidth;
                                      seekToFraction(fraction);
                                    },
                                    onHorizontalDragStart: (_) {
                                      setState(() => _isDraggingTimeline = true);
                                    },
                                    onHorizontalDragUpdate: (details) {
                                      final fraction = details.localPosition.dx / barWidth;
                                      setState(() => _dragProgress = fraction.clamp(0.0, 1.0));
                                    },
                                    onHorizontalDragEnd: (_) {
                                      seekToFraction(_dragProgress);
                                      setState(() => _isDraggingTimeline = false);
                                    },
                                    onHorizontalDragCancel: () {
                                      setState(() => _isDraggingTimeline = false);
                                    },
                                    child: Container(
                                      height: 32,
                                      alignment: Alignment.center,
                                      child: Stack(
                                        alignment: Alignment.centerLeft,
                                        children: [
                                          // Background track
                                          Container(
                                            height: 4,
                                            color: Colors.white.withValues(alpha: 0.25),
                                          ),
                                          // Filled progress
                                          FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: currentFraction,
                                            child: Container(
                                              height: 4,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          // Thumb / head
                                          Positioned(
                                            left: (currentFraction * barWidth - 8).clamp(0.0, barWidth - 16),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              curve: Curves.easeOut,
                                              width: _isDraggingTimeline ? 16 : 12,
                                              height: _isDraggingTimeline ? 16 : 12,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withValues(alpha: 0.4),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.3),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(
                                        _isDraggingTimeline
                                            ? Duration(
                                                milliseconds: (_dragProgress *
                                                        _controller!.value.duration.inMilliseconds)
                                                    .round(),
                                              )
                                            : _controller!.value.position,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_controller!.value.duration),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Back button (last so it sits on top)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medium.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ClipOval(
                            child: medium.user.avatarUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: medium.user.avatarUrl!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.surfaceHighlight,
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHighlight,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medium.user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  '@${medium.user.slug}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              icon: Icons.visibility_outlined,
                              value: '${medium.viewsCount}',
                              label: 'Views',
                            ),
                            Container(
                              width: 1,
                              height: 28,
                              color: AppColors.divider.withValues(alpha: 0.3),
                            ),
                            GestureDetector(
                              onTap: _viewerCanLike ? _toggleLike : null,
                              child: _StatItem(
                                icon: _viewerLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                value: '$_likesCount',
                                label: 'Likes',
                                iconColor: _viewerLiked ? AppColors.primary : null,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 28,
                              color: AppColors.divider.withValues(alpha: 0.3),
                            ),
                            GestureDetector(
                              onTap: MurrtubeApi.hasCookies ? _showSaveBottomSheet : null,
                              child: _StatItem(
                                icon: Icons.playlist_add_rounded,
                                value: '',
                                label: 'Save',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 28,
                              color: AppColors.divider.withValues(alpha: 0.3),
                            ),
                            _StatItem(
                              icon: Icons.chat_bubble_outline,
                              value: '${medium.commentsCount}',
                              label: 'Comments',
                            ),
                          ],
                        ),
                      ),
                      if (medium.description != null &&
                          medium.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          medium.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (medium.tags.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: medium.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.divider
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '#${tag.name}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                // Comments toggle
                GestureDetector(
                  onTap: () => setState(() => _showComments = !_showComments),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${medium.commentsCount} Comments',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _showComments ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.expand_more,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showComments) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: _comments
                          .map((c) => _CommentTile(comment: c))
                          .toList(),
                    ),
                  ),
                ],
                // Watch more
                if (_watchMore.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Watch More',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: _watchMore
                          .map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: VideoCard(
                                  media: m,
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VideoDetailPage(
                                          shortCode: m.shortCode,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor ?? AppColors.textMuted),
        const SizedBox(height: 4),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}

class _SaveSheet extends StatefulWidget {
  final Media medium;
  final Future<void> Function(String name, String visibility) onCreate;
  final void Function(Playlist playlist) onSelect;

  const _SaveSheet({
    required this.medium,
    required this.onCreate,
    required this.onSelect,
  });

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  bool _creating = false;
  bool _showCreateForm = false;
  bool _loading = true;
  List<Playlist> _playlists = [];
  final _nameController = TextEditingController();
  String _visibility = 'public';

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final lists = await MurrtubeApi.getMyPlaylists();
      if (mounted) {
        setState(() {
          _playlists = lists;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Load playlists error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Save to playlist',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_showCreateForm)
              _buildCreateForm()
            else
              _buildPlaylistList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_playlists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No playlists yet',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _playlists.length,
              itemBuilder: (ctx, i) {
                final p = _playlists[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.playlist_play,
                    color: AppColors.textMuted,
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(color: AppColors.text),
                  ),
                  subtitle: Text(
                    '${p.visibility} · ${p.itemsCount} items',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  onTap: () => widget.onSelect(p),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showCreateForm = true),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create new playlist'),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Playlist name',
            hintText: 'My favorites',
          ),
          autofocus: true,
        ),
        const SizedBox(height: 12),
        Text(
          'Visibility',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _VisibilityChip(
              label: 'Public',
              selected: _visibility == 'public',
              onTap: () => setState(() => _visibility = 'public'),
            ),
            const SizedBox(width: 8),
            _VisibilityChip(
              label: 'Unlisted',
              selected: _visibility == 'unlisted',
              onTap: () => setState(() => _visibility = 'unlisted'),
            ),
            const SizedBox(width: 8),
            _VisibilityChip(
              label: 'Private',
              selected: _visibility == 'private',
              onTap: () => setState(() => _visibility = 'private'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _creating || _nameController.text.trim().isEmpty
                ? null
                : () async {
                    setState(() => _creating = true);
                    try {
                      await widget.onCreate(_nameController.text.trim(), _visibility);
                    } finally {
                      if (mounted) setState(() => _creating = false);
                    }
                  },
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create & save'),
          ),
        ),
      ],
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppColors.primary : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: comment.user.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: comment.user.avatarUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceHighlight,
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  )
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                    if (comment.isCreator)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CREATOR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                if (comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8),
                    child: Column(
                      children: comment.replies
                          .map((r) => _CommentTile(comment: r))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

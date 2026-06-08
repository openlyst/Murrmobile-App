import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media.dart';
import '../models/comment.dart';
import '../services/murrtube_api.dart';
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
        _loading = false;
      });
      if (_medium?.hlsUrl != null) {
        _initPlayer(_medium!.hlsUrl!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  void _initPlayer(String url) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final medium = _medium;
    if (medium == null) {
      return const Scaffold(
        body: Center(child: Text('Video not found')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(medium.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player
            if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    IconButton(
                      icon: Icon(
                        _controller!.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 48,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: medium.thumbnailUrl,
                  fit: BoxFit.cover,
                ),
              ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medium.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: medium.user.avatarUrl != null
                            ? NetworkImage(medium.user.avatarUrl!)
                            : null,
                        radius: 16,
                        child: medium.user.avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        medium.user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.visibility, size: 16),
                      const SizedBox(width: 4),
                      Text('${medium.viewsCount} views'),
                      const SizedBox(width: 16),
                      const Icon(Icons.thumb_up, size: 16),
                      const SizedBox(width: 4),
                      Text('${medium.likesCount} likes'),
                      const SizedBox(width: 16),
                      Text(
                        medium.publishedAt.toLocal().toString().split(' ')[0],
                      ),
                    ],
                  ),
                  if (medium.description != null && medium.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(medium.description!),
                  ],
                  if (medium.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: medium.tags
                          .map((tag) => Chip(
                                label: Text(tag.name),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Comments toggle
            ListTile(
              title: Text('${medium.commentsCount} Comments'),
              trailing: Icon(
                _showComments ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () => setState(() => _showComments = !_showComments),
            ),
            if (_showComments)
              ..._comments.map((c) => _CommentTile(comment: c)),
            // Watch more
            if (_watchMore.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Watch More',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ..._watchMore.map((m) => VideoCard(
                    media: m,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoDetailPage(shortCode: m.shortCode),
                        ),
                      );
                    },
                  )),
            ],
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: comment.user.avatarUrl != null
                ? NetworkImage(comment.user.avatarUrl!)
                : null,
            radius: 16,
            child: comment.user.avatarUrl == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(comment.body),
                if (comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
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

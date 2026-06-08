import 'package:flutter/material.dart';
import '../models/media.dart';
import '../models/user.dart';
import '../models/tag.dart';
import '../services/murrtube_api.dart';
import '../widgets/video_card.dart';
import 'video_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  List<Media> _media = [];
  List<User> _users = [];
  List<Tag> _tagMatches = [];
  bool _loading = false;
  String? _lastQuery;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _lastQuery = query;
    });
    try {
      final result = await MurrtubeApi.search(query: query);
      setState(() {
        _media = result.media;
        _users = result.users;
        _tagMatches = result.tagMatches;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search videos, users, tags...',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_tagMatches.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Tags',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 8,
                        children: _tagMatches
                          .map((tag) => ActionChip(
                                label: Text('${tag.name} (${tag.count})'),
                                onPressed: () {
                                  _controller.text = tag.name;
                                  _search();
                                },
                              ))
                          .toList(),
                        ),
                      ),
                  ],
                  if (_users.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Users',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._users.map((user) => ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(user.name),
                          onTap: () {},
                        )),
                  ],
                  if (_media.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Videos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._media.map((m) => VideoCard(
                          media: m,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    VideoDetailPage(shortCode: m.shortCode),
                              ),
                            );
                          },
                        )),
                  ],
                  if (_media.isEmpty &&
                      _users.isEmpty &&
                      _tagMatches.isEmpty &&
                      _lastQuery != null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No results found')),
                    ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/media.dart';
import '../models/announcement.dart';
import '../services/murrtube_api.dart';
import '../widgets/video_card.dart';
import '../widgets/announcement_banner.dart';
import 'video_detail_page.dart';

class HomePage extends StatefulWidget {
  final String tab;
  const HomePage({super.key, this.tab = 'trending'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Media> _media = [];
  List<Announcement> _announcements = [];
  bool _loading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  late String _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.tab;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await MurrtubeApi.getHome(tab: _currentTab, page: _currentPage);
      setState(() {
        if (_currentPage == 1) {
          _media = result.media;
          _announcements = result.announcements;
        } else {
          _media.addAll(result.media);
        }
        _hasMore = result.pagination.next != null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _switchTab(String tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
      _currentPage = 1;
      _media = [];
      _hasMore = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _currentPage++;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Murrtube'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _TabButton(
                label: 'Trending',
                active: _currentTab == 'trending',
                onTap: () => _switchTab('trending'),
              ),
              _TabButton(
                label: 'Subscriptions',
                active: _currentTab == 'subscriptions',
                onTap: () => _switchTab('subscriptions'),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _currentPage = 1;
          await _load();
        },
        child: CustomScrollView(
          slivers: [
            if (_announcements.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  children: _announcements
                      .map((a) => AnnouncementBanner(announcement: a))
                      .toList(),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 16 / 14,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _media.length) {
                      if (_hasMore) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                        return const Center(child: CircularProgressIndicator());
                      }
                      return const SizedBox.shrink();
                    }
                    return VideoCard(
                      media: _media[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoDetailPage(
                              shortCode: _media[index].shortCode,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _media.length + (_hasMore ? 1 : 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

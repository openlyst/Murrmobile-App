import 'package:flutter/material.dart';
import '../models/media.dart';
import '../models/announcement.dart';
import '../services/murrtube_api.dart';
import '../theme/app_theme.dart';
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
      debugPrint('HomePage load error: $e');
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

  int _crossAxisCount(double width) {
    if (width >= 1600) return 6;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cols = _crossAxisCount(size.width);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _currentPage = 1;
          await _load();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    _PillTab(
                      label: 'Trending',
                      active: _currentTab == 'trending',
                      onTap: () => _switchTab('trending'),
                    ),
                    const SizedBox(width: 10),
                    _PillTab(
                      label: 'Subscriptions',
                      active: _currentTab == 'subscriptions',
                      onTap: () => _switchTab('subscriptions'),
                    ),
                  ],
                ),
              ),
            ),
            if (_announcements.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AnnouncementBanner(announcement: _announcements[index]),
                    ),
                    childCount: _announcements.length,
                  ),
                ),
              ),
            if (_loading && _media.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else if (!_loading && _media.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No videos found',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 16 / 15,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _media.length) {
                        if (_hasMore) {
                          WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          );
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

class _PillTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? null
              : Border.all(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textMuted,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/murrtube_api.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await MurrtubeApi.getNotifications();
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } catch (e) {
      debugPrint('NotificationsPage error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () {},
              child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          leading: Icon(
                            item.read ? Icons.notifications_none : Icons.notifications,
                            color: item.read ? Colors.grey : null,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight:
                                  item.read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(item.body),
                          trailing: Text(
                            _timeAgo(item.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () {
                            if (item.url != null) {
                              // Navigate to URL
                            }
                          },
                        );
                      },
                    ),
            ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }
}

import 'package:flutter/material.dart';
import '../models/announcement.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementBanner extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementBanner({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(announcement.body),
          if (announcement.ctaUrl != null && announcement.ctaLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(announcement.ctaUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(announcement.ctaLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

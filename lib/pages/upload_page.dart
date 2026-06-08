import 'package:flutter/material.dart';
import '../services/murrtube_api.dart';
import '../theme/app_theme.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Map<String, dynamic>? _props;
  bool _loading = true;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _visibility = 'public';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final props = await MurrtubeApi.getUpload();
      setState(() {
        _props = props;
        _loading = false;
      });
    } catch (e) {
      debugPrint('UploadPage error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibilities = _props?['visibilities'] as List<dynamic>? ?? [];
    final popularTags = _props?['popular_tags'] as List<dynamic>? ?? [];

    return Scaffold(
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Upload',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Title'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: AppColors.text),
                        decoration: InputDecoration(
                          hintText: 'Enter video title...',
                          hintStyle:
                              const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          counterStyle:
                              const TextStyle(color: AppColors.textMuted),
                        ),
                        maxLength: _props?['max_title_length'] ?? 100,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        style: const TextStyle(color: AppColors.text),
                        decoration: InputDecoration(
                          hintText: 'Describe your video...',
                          hintStyle:
                              const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (visibilities.isNotEmpty) ...[
                  _buildLabel('Visibility'),
                  const SizedBox(height: 10),
                  _buildCard(
                    child: Column(
                      children: visibilities.map((v) {
                        final value = v['value'] as String;
                        final isSelected = _visibility == value;
                        return InkWell(
                          onTap: () => setState(() => _visibility = value),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: visibilities.last != v
                                ? BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.divider
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  )
                                : null,
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.divider,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  v['label'] ?? value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (popularTags.isNotEmpty) ...[
                  _buildLabel('Popular Tags'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: popularTags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      AppColors.divider.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                t['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('Upload flow not implemented');
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file, size: 20),
                        SizedBox(width: 8),
                        Text('Select Video File'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

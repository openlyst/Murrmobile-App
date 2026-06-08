import 'package:flutter/material.dart';
import '../services/murrtube_api.dart';

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
    final visibilities =
        _props?['visibilities'] as List<dynamic>? ?? [];
    final popularTags =
        _props?['popular_tags'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Video',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: _props?['max_title_length'] ?? 100,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  const Text('Visibility'),
                  ...visibilities.map((v) => RadioListTile<String>(
                        title: Text(v['label'] ?? v['value'] ?? ''),
                        value: v['value'] as String,
                        groupValue: _visibility,
                        onChanged: (val) => setState(() => _visibility = val!),
                      )),
                  const SizedBox(height: 12),
                  if (popularTags.isNotEmpty) ...[
                    const Text('Popular Tags'),
                    Wrap(
                      spacing: 8,
                      children: popularTags
                          .map((t) => Chip(label: Text(t['name'] ?? '')))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('Upload flow not implemented');
                      },
                      child: const Text('Select Video File'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

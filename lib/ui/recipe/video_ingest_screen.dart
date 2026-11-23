import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import 'recipe_detail_screen.dart';

class VideoIngestScreen extends StatefulWidget {
  const VideoIngestScreen({super.key});

  @override
  State<VideoIngestScreen> createState() => _VideoIngestScreenState();
}

class _VideoIngestScreenState extends State<VideoIngestScreen> {
  final _urlController = TextEditingController();

  final List<Map<String, String>> _sampleVideos = [
    {
      'title': 'Garlic Butter Chicken (TikTok)',
      'url': 'https://www.tiktok.com/@cooking/video/7391823746',
      'platform': 'TikTok',
      'icon': '🎵',
    },
    {
      'title': '15-Min Aglio e Olio (Shorts)',
      'url': 'https://www.youtube.com/shorts/pasta12345',
      'platform': 'YouTube Shorts',
      'icon': '▶️',
    },
    {
      'title': 'Creamy Honey Glaze (Reels)',
      'url': 'https://www.instagram.com/reel/C89abcdef/',
      'platform': 'Instagram Reels',
      'icon': '📸',
    },
  ];

  Future<void> _handleIngest() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a TikTok, Reels, or Shorts URL')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final provider = context.read<AppProvider>();
    final recipe = await provider.ingestVideoUrl(url);

    if (recipe != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: recipe),
        ),
      );
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(provider.errorMessage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_rounded, color: AppTheme.accentOrange),
            SizedBox(width: 8),
            Text('Video Recipe Ingestion'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryDarkGreen.withValues(alpha: 0.4),
                    AppTheme.primaryGreen.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.accentAmber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'AI Video to Structured Recipe',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Paste a short-form video link. Cook-Ed extracts the audio track, transcribes dialogue with Whisper, and structures ingredients & instructions with Gemini Flash.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // URL Input Field
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Paste Video URL',
                hintText: 'https://tiktok.com/@... or Shorts, Reels',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_paste_rounded),
                      tooltip: 'Paste from clipboard',
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _urlController.text = data!.text!;
                        }
                      },
                    ),
                    if (_urlController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _urlController.clear()),
                      ),
                  ],
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Ingest Button or Pipeline Progress Tracker
            if (provider.isIngesting)
              _buildPipelineProgress(provider)
            else
              ElevatedButton.icon(
                onPressed: _handleIngest,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Extract & Structure Recipe'),
              ),

            const SizedBox(height: 32),

            // Sample Demo Link Chips
            const Text(
              'Or test with sample video links:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ..._sampleVideos.map((sample) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Text(
                    sample['icon']!,
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(
                    sample['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    sample['platform']!,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    _urlController.text = sample['url']!;
                    _handleIngest();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineProgress(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: provider.ingestProgress,
            backgroundColor: Colors.grey[800],
            color: AppTheme.primaryGreen,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.ingestStatusText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

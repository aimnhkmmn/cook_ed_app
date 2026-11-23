import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isTestingConnection = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = context.read<AppProvider>().backendUrl;
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testBackend() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTestingConnection = true;
      _testResult = null;
    });

    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    try {
      final response = await http
          .get(Uri.parse('$cleanUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geminiConfigured = data['gemini_configured'] == true;
        setState(() {
          _isTestingConnection = false;
          _testSuccess = true;
          _testResult =
              'Connected! Status: Healthy\nGemini API: ${geminiConfigured ? "Configured ✓" : "Missing Key ⚠️"}\nWhisper: ${data["whisper_model"] ?? "base"}';
        });
        if (mounted) {
          context.read<AppProvider>().backendUrl = cleanUrl;
        }
      } else {
        setState(() {
          _isTestingConnection = false;
          _testSuccess = false;
          _testResult = 'Server returned HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isTestingConnection = false;
        _testSuccess = false;
        _testResult = 'Could not reach server: $e\n(Make sure "python run.py" is running in backend/)';
      });
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
            Icon(Icons.tune_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Settings & Connectivity'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Backend Configuration Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dns_rounded, color: AppTheme.primaryGreen),
                      SizedBox(width: 10),
                      Text(
                        'FastAPI AI Backend',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Handles Whisper speech transcription, Gemini multimodal OCR & NLP, and portion calculations.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Backend Base URL',
                      hintText: 'http://10.0.2.2:8000',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    onSubmitted: (val) {
                      provider.backendUrl = val.trim();
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('10.0.2.2:8000 (Android)'),
                        onPressed: () {
                          _urlController.text = 'http://10.0.2.2:8000';
                          provider.backendUrl = 'http://10.0.2.2:8000';
                        },
                      ),
                      ActionChip(
                        label: const Text('localhost:8000 (Desktop/Web)'),
                        onPressed: () {
                          _urlController.text = 'http://localhost:8000';
                          provider.backendUrl = 'http://localhost:8000';
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isTestingConnection ? null : _testBackend,
                    icon: _isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.network_check_rounded),
                    label: Text(_isTestingConnection ? 'Pinging Server...' : 'Test Connection & Save'),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_testSuccess ? AppTheme.primaryGreen : Colors.red)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _testSuccess ? AppTheme.primaryGreen : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess ? AppTheme.primaryGreen : Colors.red[300],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Supabase Database Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storage_rounded, color: AppTheme.accentAmber),
                      SizedBox(width: 10),
                      Text(
                        'Database & Inventory Sync',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: provider.isLiveSupabase ? AppTheme.primaryGreen : AppTheme.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.isLiveSupabase
                            ? 'Connected to Live Supabase'
                            : 'Offline Mock Demo Mode (Active)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: provider.isLiveSupabase ? AppTheme.primaryGreen : AppTheme.accentAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    provider.isLiveSupabase
                        ? 'Using remote PostgreSQL database with real-time atomic inventory deduction.'
                        : 'Using in-memory virtual pantry & recipe storage. Ideal for offline demonstrations without credentials.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  if (provider.currentUserEmail != null) ...[
                    Text(
                      'Chef Account: ${provider.currentUserEmail}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange),
                      SizedBox(width: 10),
                      Text(
                        'About Cook-Ed',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppConstants.appTagline,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Built for CAT301. Transforms viral cooking videos (TikTok, Instagram Reels, YouTube Shorts) into actionable recipes with intelligent portion scaling and zero-waste pantry stock checking.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

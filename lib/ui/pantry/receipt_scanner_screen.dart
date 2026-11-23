import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/receipt_item.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  List<ReceiptScannedItem> _scannedItems = [];
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    final provider = context.read<AppProvider>();
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _imageBytes = bytes;
          _isProcessing = true;
          _scannedItems = [];
        });

        final items = await provider.scanReceiptImage(bytes);
        if (!mounted) return;

        setState(() {
          _scannedItems = items;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick/scan image: $e')),
      );
    }
  }

  void _demoTestScan() async {
    final provider = context.read<AppProvider>();
    setState(() {
      _isProcessing = true;
      _scannedItems = [];
    });
    // Create dummy 1x1 image bytes for demo test
    final dummyBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final items = await provider.scanReceiptImage(dummyBytes);

    if (!mounted) return;
    setState(() {
      _scannedItems = items;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt OCR Scanner'),
      ),
      body: _imageBytes == null && _scannedItems.isEmpty && !_isProcessing
          ? _buildPickerPrompt()
          : _buildResultsView(),
      bottomNavigationBar: _scannedItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: const Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final provider = context.read<AppProvider>();
                  provider.addReceiptItems(_scannedItems);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.primaryGreen,
                      content: Text(
                        'Added ${_scannedItems.where((i) => i.isSelected).length} items to your pantry!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  'Add Selected (${_scannedItems.where((i) => i.isSelected).length}) to Pantry',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPickerPrompt() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Snap or Upload Store Receipt',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Cook-Ed uses Gemini Flash multimodal OCR to itemize your groceries, extract quantities, and automatically populate your virtual pantry.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Take Receipt Photo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppTheme.primaryGreen),
            ),
            icon: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryGreen),
            label: const Text('Choose from Gallery', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _demoTestScan,
            child: const Text('Or Test with Sample Supermarket Receipt', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        // Image preview banner if picked
        if (_imageBytes != null)
          Container(
            height: 130,
            width: double.infinity,
            color: Colors.black26,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(_imageBytes!, fit: BoxFit.cover),
                Container(color: Colors.black38),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black54),
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retake'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Scanning indicator
        if (_isProcessing)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 20),
                  Text(
                    'Gemini Flash Parsing Receipt...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Extracting grocery items, quantities, and units',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        // Extracted list
        if (!_isProcessing && _scannedItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extracted Groceries (${_scannedItems.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    final allSelected = _scannedItems.every((i) => i.isSelected);
                    setState(() {
                      for (var item in _scannedItems) {
                        item.isSelected = !allSelected;
                      }
                    });
                  },
                  child: Text(
                    _scannedItems.every((i) => i.isSelected) ? 'Deselect All' : 'Select All',
                    style: const TextStyle(color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _scannedItems.length,
              itemBuilder: (context, index) {
                final item = _scannedItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    activeColor: AppTheme.primaryGreen,
                    value: item.isSelected,
                    onChanged: (val) {
                      setState(() => item.isSelected = val ?? true);
                    },
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      '${item.quantity} ${item.unit} • ${item.category}${item.estimatedPrice != null ? " • \$${item.estimatedPrice!.toStringAsFixed(2)}" : ""}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_rounded, color: AppTheme.primaryGreen, size: 20),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

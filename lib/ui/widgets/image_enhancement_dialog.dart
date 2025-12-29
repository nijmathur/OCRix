import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../core/interfaces/image_enhancement_service_interface.dart';

class ImageEnhancementDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List enhancedImage, Map<String, dynamic> metadata)
      onEnhance;

  const ImageEnhancementDialog({
    super.key,
    required this.imageBytes,
    required this.onEnhance,
  });

  @override
  State<ImageEnhancementDialog> createState() => _ImageEnhancementDialogState();
}

class _ImageEnhancementDialogState extends State<ImageEnhancementDialog> {
  bool _perspectiveCorrection = false;
  bool _deskew = true;
  bool _adjustContrast = true;
  bool _adjustBrightness = true;
  bool _reduceNoise = true;
  bool _binarize = false;

  double _contrastFactor = 1.3;
  double _brightnessFactor = 1.1;
  int _noiseStrength = 2;
  int _binarizationThreshold = 128;

  bool _isProcessing = false;
  Uint8List? _previewImage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Image Enhancement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview Section
                    _buildPreviewSection(),
                    const SizedBox(height: 24),

                    // Enhancement Options
                    _buildEnhancementOptions(),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _previewImage != null
                  ? Image.memory(_previewImage!, fit: BoxFit.contain)
                  : Image.memory(widget.imageBytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancementOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enhancement Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Quick Preset
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Auto Enhance'),
            subtitle: const Text('Apply smart defaults'),
            trailing: ElevatedButton(
              onPressed: _isProcessing ? null : _applyAutoEnhance,
              child: const Text('Apply'),
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Divider(),
        const SizedBox(height: 16),

        // Individual Options
        _buildCheckboxOption(
          'Deskew',
          'Automatically correct rotation',
          _deskew,
          (value) => setState(() => _deskew = value ?? false),
        ),
        _buildCheckboxOption(
          'Adjust Contrast',
          'Enhance text clarity',
          _adjustContrast,
          (value) => setState(() => _adjustContrast = value ?? false),
        ),
        if (_adjustContrast) _buildContrastSlider(),

        _buildCheckboxOption(
          'Adjust Brightness',
          'Optimize lighting',
          _adjustBrightness,
          (value) => setState(() => _adjustBrightness = value ?? false),
        ),
        if (_adjustBrightness) _buildBrightnessSlider(),

        _buildCheckboxOption(
          'Reduce Noise',
          'Remove image artifacts',
          _reduceNoise,
          (value) => setState(() => _reduceNoise = value ?? false),
        ),
        if (_reduceNoise) _buildNoiseSlider(),

        _buildCheckboxOption(
          'Binarize',
          'Convert to black and white',
          _binarize,
          (value) => setState(() => _binarize = value ?? false),
        ),
        if (_binarize) _buildThresholdSlider(),

        _buildCheckboxOption(
          'Perspective Correction',
          'Straighten document edges (experimental)',
          _perspectiveCorrection,
          (value) => setState(() => _perspectiveCorrection = value ?? false),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(
    String title,
    String subtitle,
    bool value,
    Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }

  Widget _buildContrastSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contrast: ${_contrastFactor.toStringAsFixed(1)}x'),
          Slider(
            value: _contrastFactor,
            min: 0.5,
            max: 3.0,
            divisions: 25,
            label: _contrastFactor.toStringAsFixed(1),
            onChanged: (value) => setState(() => _contrastFactor = value),
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brightness: ${_brightnessFactor.toStringAsFixed(1)}x'),
          Slider(
            value: _brightnessFactor,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: _brightnessFactor.toStringAsFixed(1),
            onChanged: (value) => setState(() => _brightnessFactor = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNoiseSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Noise Reduction: $_noiseStrength'),
          Slider(
            value: _noiseStrength.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _noiseStrength.toString(),
            onChanged: (value) =>
                setState(() => _noiseStrength = value.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Threshold: $_binarizationThreshold'),
          Slider(
            value: _binarizationThreshold.toDouble(),
            min: 50,
            max: 200,
            divisions: 150,
            label: _binarizationThreshold.toString(),
            onChanged: (value) =>
                setState(() => _binarizationThreshold = value.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          if (_previewImage != null)
            TextButton(
              onPressed: _isProcessing ? null : _resetPreview,
              child: const Text('Reset'),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _applyEnhancements,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isProcessing ? 'Processing...' : 'Apply & Save'),
          ),
        ],
      ),
    );
  }

  void _resetPreview() {
    setState(() {
      _previewImage = null;
    });
  }

  Future<void> _applyAutoEnhance() async {
    setState(() => _isProcessing = true);

    // Auto-enhance with smart defaults
    setState(() {
      _deskew = true;
      _adjustContrast = true;
      _adjustBrightness = true;
      _reduceNoise = true;
      _binarize = false;
      _perspectiveCorrection = false;
      _contrastFactor = 1.3;
      _brightnessFactor = 1.1;
      _noiseStrength = 2;
    });

    await _applyEnhancements();
  }

  Future<void> _applyEnhancements() async {
    setState(() => _isProcessing = true);

    try {
      final options = ImageEnhancementOptions(
        perspectiveCorrection: _perspectiveCorrection,
        deskew: _deskew,
        adjustContrast: _adjustContrast,
        adjustBrightness: _adjustBrightness,
        reduceNoise: _reduceNoise,
        binarize: _binarize,
        contrastFactor: _contrastFactor,
        brightnessFactor: _brightnessFactor,
        noiseReductionStrength: _noiseStrength,
        binarizationThreshold: _binarizationThreshold,
      );

      // Close dialog and return the enhancement options
      if (mounted) {
        Navigator.pop(context, options);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

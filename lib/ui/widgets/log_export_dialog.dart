import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/troubleshooting_logger_provider.dart';

/// Dialog widget for exporting logs (SOLID - Single Responsibility)
class LogExportDialog extends ConsumerStatefulWidget {
  const LogExportDialog({super.key});

  @override
  ConsumerState<LogExportDialog> createState() => _LogExportDialogState();
}

class _LogExportDialogState extends ConsumerState<LogExportDialog> {
  bool _isExporting = false;
  String? _exportedLogs;

  Future<void> _exportLogs() async {
    setState(() {
      _isExporting = true;
      _exportedLogs = null;
    });

    try {
      final logger = ref.read(troubleshootingLoggerProvider);
      final logs = await logger.exportLogs();
      
      setState(() {
        _exportedLogs = logs;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _exportedLogs = 'Error exporting logs: $e';
        _isExporting = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_exportedLogs != null) {
      await Clipboard.setData(ClipboardData(text: _exportedLogs!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs copied to clipboard')),
        );
      }
    }
  }

  Future<void> _shareLogs() async {
    if (_exportedLogs == null) return;

    // In a real app, you would use a share package like share_plus
    // For now, we'll just copy to clipboard
    await _copyToClipboard();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Export Troubleshooting Logs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export your app logs to help troubleshoot issues. The logs contain:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• All app activities and errors'),
                          Text('• Service initialization logs'),
                          Text('• Database operations'),
                          Text('• Navigation events'),
                          Text('• System information'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_exportedLogs == null && !_isExporting)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _exportLogs,
                          icon: const Icon(Icons.file_download),
                          label: const Text('Export Logs'),
                        ),
                      ),
                    if (_isExporting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Exporting logs...'),
                            ],
                          ),
                        ),
                      ),
                    if (_exportedLogs != null) ...[
                      const Text(
                        'Exported Logs:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _exportedLogs!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            if (_exportedLogs != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _shareLogs,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


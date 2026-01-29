import 'package:flutter/material.dart';

class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;
  final Function(bool downloadModel, bool downloadApp) onUpdate;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onUpdate,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isUpdating = false;
  double _progress = 0.0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    final hasModelUpdate = widget.updateInfo['hasModelUpdate'] ?? false;
    final hasAppUpdate = widget.updateInfo['hasAppUpdate'] ?? false;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1de9b6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.system_update,
              color: Color(0xFF1de9b6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Update Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasModelUpdate) ...[
              _buildUpdateSection(
                'AI Model Update',
                widget.updateInfo['currentModelVersion'],
                widget.updateInfo['latestModelVersion'],
                widget.updateInfo['modelData']['change_log'] ?? 'No changelog available',
                Icons.psychology,
                Colors.blue,
              ),
              if (hasAppUpdate) const SizedBox(height: 20),
            ],
            if (hasAppUpdate) ...[
              _buildUpdateSection(
                'App Update',
                widget.updateInfo['currentAppVersion'],
                widget.updateInfo['latestAppVersion'],
                widget.updateInfo['appData']['change_log'] ?? 'No changelog available',
                Icons.phone_android,
                Colors.green,
              ),
            ],
            if (_isUpdating) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1de9b6)),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isUpdating) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isUpdating = true;
                _statusMessage = 'Starting update...';
              });
              widget.onUpdate(hasModelUpdate, hasAppUpdate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1de9b6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Update Now'),
          ),
        ],
      ],
    );
  }

  Widget _buildUpdateSection(
      String title,
      int currentVersion,
      int latestVersion,
      String changelog,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildVersionBadge('v$currentVersion', Colors.grey),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              _buildVersionBadge('v$latestVersion', color),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'What\'s New:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            changelog,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionBadge(String version, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        version,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void updateProgress(double progress, String message) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _statusMessage = message;
      });
    }
  }
}
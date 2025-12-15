import 'package:flutter/material.dart';

/// Dialog for prompting user to enter password for database export/import
class PasswordDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool requireConfirmation;
  final bool showStrengthIndicator;

  const PasswordDialog({
    super.key,
    required this.title,
    required this.message,
    this.requireConfirmation = false,
    this.showStrengthIndicator = false,
  });

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate password
    if (password.isEmpty) {
      setState(() {
        _errorText = 'Password cannot be empty';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorText = 'Password must be at least 8 characters';
      });
      return;
    }

    if (widget.requireConfirmation && password != confirmPassword) {
      setState(() {
        _errorText = 'Passwords do not match';
      });
      return;
    }

    Navigator.of(context).pop(password);
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.length >= 16) strength++;

    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength.clamp(0, 5);
  }

  Color _getStrengthColor(int strength) {
    if (strength <= 2) return Colors.red;
    if (strength <= 4) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthText(int strength) {
    if (strength == 0) return 'Too weak';
    if (strength <= 2) return 'Weak';
    if (strength <= 4) return 'Medium';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(_passwordController.text);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                errorText: _errorText,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _errorText = null;
                });
              },
              onSubmitted: (_) {
                if (!widget.requireConfirmation) {
                  _submit();
                }
              },
            ),
            if (widget.showStrengthIndicator && _passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: strength / 5,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStrengthColor(strength),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStrengthText(strength),
                    style: TextStyle(
                      color: _getStrengthColor(strength),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            if (widget.requireConfirmation) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'IMPORTANT: If you forget this password, you will NOT be able to restore your database. Please store it safely!',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// Show password dialog for database export
Future<String?> showExportPasswordDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PasswordDialog(
      title: 'Set Export Password',
      message: 'Choose a strong password to encrypt your database backup.',
      requireConfirmation: true,
      showStrengthIndicator: true,
    ),
  );
}

/// Show password dialog for database import
Future<String?> showImportPasswordDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PasswordDialog(
      title: 'Enter Password',
      message: 'Enter the password used to encrypt this database backup.',
      requireConfirmation: false,
      showStrengthIndicator: false,
    ),
  );
}

import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
            )
          : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: enabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
            ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: enabled
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38),
                  ),
            )
          : null,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }
}

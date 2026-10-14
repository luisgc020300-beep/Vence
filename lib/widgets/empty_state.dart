// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.title, required this.description, this.action, super.key});

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: context.colors.brandTint, shape: BoxShape.circle),
            child: Icon(icon, size: 26, color: context.colors.brand),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(description, textAlign: TextAlign.center, style: TextStyle(color: context.colors.inkMuted, fontSize: 13)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

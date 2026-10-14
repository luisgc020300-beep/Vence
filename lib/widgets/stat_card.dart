// lib/widgets/stat_card.dart
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Tarjeta blanca de resumen (p. ej. "Vencen este mes: 3") -- va dentro o
/// justo debajo de [CurvedHeader], en una Row de dos.
class StatCard extends StatelessWidget {
  const StatCard({required this.icon, required this.etiqueta, required this.valor, this.color, super.key});

  final IconData icon;
  final String etiqueta;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tono = color ?? context.colors.brand;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(VenceRadius.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: tono.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(VenceRadius.xs)),
              child: Icon(icon, size: 16, color: tono),
            ),
            const SizedBox(height: 10),
            Text(etiqueta, style: TextStyle(fontSize: 11.5, color: context.colors.inkMuted)),
            const SizedBox(height: 2),
            Text(valor, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: context.colors.ink)),
          ],
        ),
      ),
    );
  }
}

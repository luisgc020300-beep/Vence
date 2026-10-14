// lib/widgets/app_list_tile.dart
//
// Fila de lista con icono cuadrado de color (en vez del icono circular +
// chevron de IosRow) -- el patrón de las referencias tipo gestor de
// suscripciones: icono de categoría a la izquierda, título/subtítulo en
// medio, precio/estado arriba a la derecha y una etiqueta pequeña debajo.
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    this.subtitulo,
    this.valorArriba,
    this.valorAbajo,
    this.valorAbajoColor,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String? subtitulo;
  final String? valorArriba;
  final String? valorAbajo;
  final Color? valorAbajoColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(VenceRadius.lg),
        boxShadow: [BoxShadow(color: context.colors.ink.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(VenceRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(VenceRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(VenceRadius.sm)),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.ink)),
                    if (subtitulo != null)
                      Text(subtitulo!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.colors.inkMuted)),
                  ],
                ),
              ),
              if (valorArriba != null || valorAbajo != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (valorArriba != null) Text(valorArriba!, style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.ink)),
                    if (valorAbajo != null)
                      Text(valorAbajo!, style: TextStyle(fontSize: 11, color: valorAbajoColor ?? context.colors.inkMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

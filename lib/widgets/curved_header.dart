// lib/widgets/curved_header.dart
//
// Cabecera azul con esquinas inferiores muy curvas -- lenguaje visual de
// referencia (apps de seguimiento de suscripciones tipo Summary), usada en
// las 5 pestañas principales. Las pantallas de detalle (con botón "atrás")
// NO la usan -- se quedan con un AppBar plano, igual que la referencia
// distingue "Summary" (cabecera azul) de "Add Subscription" (cabecera
// blanca con flecha).
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class CurvedHeader extends StatelessWidget {
  const CurvedHeader({
    required this.titulo,
    this.leading,
    this.trailing,
    this.child,
    super.key,
  });

  final String titulo;
  final Widget? leading;
  final Widget? trailing;

  /// Contenido extra debajo del título (p. ej. las tarjetas de resumen).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.brand,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(VenceSpace.s4, VenceSpace.s2, VenceSpace.s4, VenceSpace.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  leading ?? const SizedBox(width: 36),
                  Expanded(
                    child: Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.brandOn, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  trailing ?? const SizedBox(width: 36),
                ],
              ),
              if (child != null) ...[const SizedBox(height: VenceSpace.s4), child!],
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderAvatar extends StatelessWidget {
  const HeaderAvatar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: context.colors.brandOn, shape: BoxShape.circle),
      child: Icon(Icons.person_outline, size: 18, color: context.colors.brand),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({required this.icon, this.onTap, super.key});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: context.colors.brandOn.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Icon(icon, color: context.colors.brandOn, size: 18)),
      ),
    );
  }
}

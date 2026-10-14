// lib/widgets/curved_header.dart
//
// Cabecera azul con esquinas inferiores muy curvas -- lenguaje visual de
// referencia (apps de seguimiento de suscripciones tipo Summary), usada en
// las 5 pestañas principales. Las pantallas de detalle (con botón "atrás")
// NO la usan -- se quedan con un AppBar plano, igual que la referencia
// distingue "Summary" (cabecera azul) de "Add Subscription" (cabecera
// blanca con flecha).
//
// [floatingCard] (p. ej. las tarjetas de resumen) NO va dentro del área
// azul -- se pinta superpuesto al límite entre el azul y el fondo claro,
// con sombra propia, igual que las tarjetas "Due this month"/"Monthly avg"
// de la referencia, que flotan a caballo entre ambas superficies en vez de
// quedar encajadas dentro de la cabecera.
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class CurvedHeader extends StatelessWidget {
  const CurvedHeader({
    required this.titulo,
    this.leading,
    this.trailing,
    this.floatingCard,
    super.key,
  });

  final String titulo;
  final Widget? leading;
  final Widget? trailing;
  final Widget? floatingCard;

  /// Cuánto sobresale [floatingCard] por debajo de la curva azul -- quien
  /// use esta cabecera con una tarjeta flotante debe reservar este mismo
  /// espacio justo debajo (ver `floatingCardSpacing`) para que el
  /// contenido siguiente no quede tapado.
  static const double overlap = 40;

  /// Aire de azul visible entre el título y el borde superior de la
  /// tarjeta flotante -- sin esto, la tarjeta arranca pegada al título.
  static const double _gapAntesDeTarjeta = 28;

  /// Alto total a reservar debajo de la cabecera cuando se usa
  /// [floatingCard]: el solape más un margen de aire hasta la siguiente
  /// sección.
  static const double floatingCardSpacing = overlap + VenceSpace.s4;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.colors.brand,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                VenceSpace.s4,
                VenceSpace.s2,
                VenceSpace.s4,
                floatingCard != null ? _gapAntesDeTarjeta + 64 : VenceSpace.s5,
              ),
              child: Row(
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
            ),
          ),
        ),
        if (floatingCard != null)
          Positioned(
            left: VenceSpace.s4,
            right: VenceSpace.s4,
            bottom: -overlap,
            child: floatingCard!,
          ),
      ],
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

// lib/screens/settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_error.dart';
import '../widgets/ios_list.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _cerrandoSesion = false;

  Future<void> _cerrarSesion() async {
    setState(() => _cerrandoSesion = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) AppError.show(context, 'No se ha podido cerrar sesión.', error: e);
    } finally {
      if (mounted) setState(() => _cerrandoSesion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(VenceSpace.s4),
            children: [
              IosSection(
                header: 'Cuenta',
                rows: [IosRow(icon: Icons.mail_outline, iconColor: context.colors.brand, title: email, subtitle: 'Correo de acceso', showChevron: false)],
              ),
              IosSection(
                header: 'Apariencia',
                footer: 'Elige cómo se ve Vence en este dispositivo.',
                rows: [
                  IosRow(
                    icon: Icons.light_mode_outlined,
                    iconColor: context.colors.warning,
                    title: 'Claro',
                    selected: controller.mode == ThemeMode.light,
                    trailing: controller.mode == ThemeMode.light ? Icon(Icons.check, color: context.colors.brand) : null,
                    showChevron: false,
                    onTap: () => controller.setMode(ThemeMode.light),
                  ),
                  IosRow(
                    icon: Icons.dark_mode_outlined,
                    iconColor: context.colors.lavanda,
                    title: 'Oscuro',
                    selected: controller.mode == ThemeMode.dark,
                    trailing: controller.mode == ThemeMode.dark ? Icon(Icons.check, color: context.colors.brand) : null,
                    showChevron: false,
                    onTap: () => controller.setMode(ThemeMode.dark),
                  ),
                  IosRow(
                    icon: Icons.phone_iphone,
                    iconColor: context.colors.inkMuted,
                    title: 'Sistema',
                    selected: controller.mode == ThemeMode.system,
                    trailing: controller.mode == ThemeMode.system ? Icon(Icons.check, color: context.colors.brand) : null,
                    showChevron: false,
                    onTap: () => controller.setMode(ThemeMode.system),
                  ),
                ],
              ),
              IosSection(
                header: 'Sesión',
                rows: [
                  IosRow(
                    icon: Icons.logout,
                    iconColor: context.colors.error,
                    titleColor: context.colors.errorText,
                    title: _cerrandoSesion ? 'Cerrando sesión...' : 'Cerrar sesión',
                    onTap: _cerrandoSesion ? null : _cerrarSesion,
                    showChevron: false,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

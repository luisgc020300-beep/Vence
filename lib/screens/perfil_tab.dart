// lib/screens/perfil_tab.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../theme/design_tokens.dart';
import '../widgets/app_error.dart';
import '../widgets/curved_header.dart';
import '../widgets/ios_list.dart';

class PerfilTab extends StatefulWidget {
  const PerfilTab({super.key});

  @override
  State<PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<PerfilTab> {
  bool _exportando = false;
  bool _eliminando = false;

  Future<void> _exportarDatos() async {
    setState(() => _exportando = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(uid);

      final documentos = await userRef.collection('documentos').get();
      final eventos = await userRef.collection('eventos').get();
      final asuntos = await userRef.collection('asuntos').get();

      final payload = {
        'exportado_en': DateTime.now().toIso8601String(),
        'documentos': documentos.docs.map((d) => d.data()).toList(),
        'eventos': eventos.docs.map((d) => d.data()).toList(),
        'asuntos': asuntos.docs.map((d) => d.data()).toList(),
      };

      // sharePositionOrigin es obligatorio en iPad/iPhone -- sin él,
      // Share.share revienta siempre ahí (mismo bug que en Repara).
      if (!mounted) return;
      await Share.share(
        const JsonEncoder.withIndent('  ').convert(payload),
        subject: 'Mis datos de Vence',
        sharePositionOrigin: Offset.zero & MediaQuery.of(context).size,
      );
    } catch (e) {
      if (mounted) AppError.show(context, 'No se han podido exportar los datos.', error: e);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _eliminarCuenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text('Esto eliminará tu cuenta de acceso de forma permanente. Tus documentos quedan en el servidor hasta que un administrador los borre (ver limitaciones del proyecto).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _eliminando = true);
    try {
      await FirebaseAuth.instance.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AppError.show(context, e.code == 'requires-recent-login' ? 'Por seguridad, vuelve a iniciar sesión y repite esta acción.' : 'No se ha podido eliminar la cuenta.', error: e);
      }
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const CurvedHeader(titulo: 'Perfil', leading: HeaderAvatar()),
          Padding(
            padding: const EdgeInsets.all(VenceSpace.s4),
            child: Column(
              children: [
                IosSection(
                  header: 'Cuenta',
                  rows: [IosRow(icon: Icons.mail_outline, iconColor: context.colors.brand, title: email, subtitle: 'Correo de acceso', showChevron: false)],
                ),
                IosSection(
                  header: 'Privacidad y datos',
                  rows: [
                    IosRow(
                      icon: Icons.download_outlined,
                      iconColor: context.colors.success,
                      title: _exportando ? 'Exportando...' : 'Exportar todos mis datos',
                      onTap: _exportando ? null : _exportarDatos,
                    ),
                    IosRow(icon: Icons.logout, iconColor: context.colors.inkMuted, title: 'Cerrar sesión', onTap: _cerrarSesion, showChevron: false),
                    IosRow(
                      icon: Icons.delete_outline,
                      iconColor: context.colors.error,
                      titleColor: context.colors.errorText,
                      title: _eliminando ? 'Eliminando...' : 'Eliminar cuenta',
                      onTap: _eliminando ? null : _eliminarCuenta,
                      showChevron: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

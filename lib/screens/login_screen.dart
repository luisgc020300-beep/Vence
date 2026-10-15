// lib/screens/login_screen.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../widgets/app_error.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _esRegistro = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      if (_esRegistro) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      }
      TextInput.finishAutofillContext();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Error de autenticación');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperarContrasena() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Escribe primero tu correo arriba para enviarte el enlace.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) AppError.showSuccess(context, 'Te hemos enviado un correo para restablecer tu contraseña.');
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'No se ha podido enviar el correo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VenceSpace.s6),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: context.colors.brand, borderRadius: BorderRadius.circular(VenceRadius.md)),
                      alignment: Alignment.center,
                      child: Text('V', style: TextStyle(color: context.colors.brandOn, fontSize: 32, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: VenceSpace.s5),
                  Text('Vence', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: VenceSpace.s2),
                  Text(
                    'Se ocupa de tus documentos para que no se te escape nada importante.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.inkMuted),
                  ),
                  const SizedBox(height: VenceSpace.s8),
                  AutofillGroup(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline)),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Correo no válido' : null,
                        ),
                        const SizedBox(height: VenceSpace.s3),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          autofillHints: [_esRegistro ? AutofillHints.newPassword : AutofillHints.password],
                          decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
                          validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: VenceSpace.s3),
                    Row(
                      children: [
                        Icon(Icons.error_outline, size: 18, color: context.colors.error),
                        const SizedBox(width: VenceSpace.s2),
                        Expanded(child: Text(_error!, style: TextStyle(color: context.colors.errorText))),
                      ],
                    ),
                  ],
                  const SizedBox(height: VenceSpace.s5),
                  FilledButton(
                    onPressed: _cargando ? null : _enviar,
                    child: _cargando
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.brandOn))
                        : Text(_esRegistro ? 'Crear cuenta' : 'Entrar'),
                  ),
                  const SizedBox(height: VenceSpace.s2),
                  TextButton(
                    onPressed: _cargando ? null : () => setState(() => _esRegistro = !_esRegistro),
                    child: Text(_esRegistro ? '¿Ya tienes cuenta? Entra' : '¿No tienes cuenta? Regístrate'),
                  ),
                  if (!_esRegistro)
                    TextButton(
                      onPressed: _cargando ? null : _recuperarContrasena,
                      child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: context.colors.inkMuted)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

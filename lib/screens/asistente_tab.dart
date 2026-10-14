// lib/screens/asistente_tab.dart
import 'package:flutter/material.dart';

import '../models/mensaje.dart';
import '../services/asistente_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_error.dart';
import 'documento_detail_screen.dart';

class AsistenteTab extends StatefulWidget {
  const AsistenteTab({super.key});

  @override
  State<AsistenteTab> createState() => _AsistenteTabState();
}

class _AsistenteTabState extends State<AsistenteTab> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _conversacionId;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    AsistenteService.ultimaConversacionId().then((id) {
      if (mounted) setState(() => _conversacionId = id);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? texto]) async {
    final pregunta = (texto ?? _inputCtrl.text).trim();
    if (pregunta.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    _inputCtrl.clear();
    try {
      final convId = await AsistenteService.preguntar(pregunta, _conversacionId);
      if (mounted) setState(() => _conversacionId = convId);
    } catch (e) {
      if (mounted) AppError.show(context, 'No se ha podido responder.', error: e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  static const _sugerencias = ['¿Qué vence este mes?', '¿Qué tengo pendiente esta semana?', 'Resume mis documentos recientes'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente')),
      body: Column(
        children: [
          Expanded(
            child: _conversacionId == null
                ? _estadoInicial(context)
                : StreamBuilder<List<Mensaje>>(
                    stream: AsistenteService.streamMensajes(_conversacionId!),
                    builder: (context, snapshot) {
                      final mensajes = snapshot.data ?? [];
                      if (mensajes.isEmpty) return _estadoInicial(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                      });
                      return ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(VenceSpace.s4),
                        itemCount: mensajes.length,
                        itemBuilder: (context, i) => _BurbujaMensaje(mensaje: mensajes[i]),
                      );
                    },
                  ),
          ),
          if (_enviando) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(VenceSpace.s3),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      decoration: const InputDecoration(hintText: 'Escribe tu pregunta...'),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _enviando ? null : () => _enviar()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoInicial(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 36, color: context.colors.brand),
            const SizedBox(height: 12),
            const Text('Pregúntame sobre tus documentos', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Respondo solo con datos reales de lo que tienes guardado, citando la fuente.', textAlign: TextAlign.center, style: TextStyle(color: context.colors.inkMuted)),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: _sugerencias.map((s) => ActionChip(label: Text(s), onPressed: () => _enviar(s))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BurbujaMensaje extends StatelessWidget {
  const _BurbujaMensaje({required this.mensaje});
  final Mensaje mensaje;

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.rol == 'user';
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: esUsuario ? context.colors.brand : context.colors.surfaceMuted,
          borderRadius: BorderRadius.circular(VenceRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje.contenido, style: TextStyle(color: esUsuario ? Colors.white : context.colors.ink)),
            if (!esUsuario && mensaje.confiado == false)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.info_outline, size: 14, color: context.colors.warningText),
                  const SizedBox(width: 4),
                  Text('Información insuficiente', style: TextStyle(fontSize: 11, color: context.colors.warningText)),
                ]),
              ),
            if (!esUsuario && mensaje.esDemo)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Modo demostración', style: TextStyle(fontSize: 11, color: context.colors.lavanda)),
              ),
            if (mensaje.fuentes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  children: mensaje.fuentes
                      .map((f) => ActionChip(
                            label: Text(f.nombreDocumento, style: const TextStyle(fontSize: 11)),
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentoDetailScreen(documentoId: f.documentoId))),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

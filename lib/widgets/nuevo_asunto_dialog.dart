// lib/widgets/nuevo_asunto_dialog.dart
import 'package:flutter/material.dart';

import '../models/asunto.dart';
import '../services/asunto_service.dart';
import 'app_error.dart';

/// Devuelve el id del asunto creado, o null si se cancela.
Future<String?> mostrarDialogoNuevoAsunto(BuildContext context, {String? documentoId, String? nombreArchivoDocumento}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NuevoAsuntoDialog(documentoId: documentoId, nombreArchivoDocumento: nombreArchivoDocumento),
  );
}

class _NuevoAsuntoDialog extends StatefulWidget {
  const _NuevoAsuntoDialog({this.documentoId, this.nombreArchivoDocumento});
  final String? documentoId;
  final String? nombreArchivoDocumento;

  @override
  State<_NuevoAsuntoDialog> createState() => _NuevoAsuntoDialogState();
}

class _NuevoAsuntoDialogState extends State<_NuevoAsuntoDialog> {
  final _tituloCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  TipoAsunto _tipo = TipoAsunto.otro;
  bool _creando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _objetivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (_tituloCtrl.text.trim().isEmpty) return;
    setState(() => _creando = true);
    try {
      final id = await AsuntoService.crear(
        titulo: _tituloCtrl.text.trim(),
        tipo: _tipo,
        objetivo: _objetivoCtrl.text.trim().isEmpty ? null : _objetivoCtrl.text.trim(),
        documentoId: widget.documentoId,
        nombreArchivoDocumento: widget.nombreArchivoDocumento,
      );
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) {
        AppError.show(context, 'No se ha podido crear el asunto.', error: e);
        setState(() => _creando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo asunto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Título', hintText: 'p. ej. Lavadora rota')),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoAsunto>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: TipoAsunto.values.map((t) => DropdownMenuItem(value: t, child: Text(t.etiqueta))).toList(),
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _objetivoCtrl, decoration: const InputDecoration(labelText: 'Objetivo (opcional)'), maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _creando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _creando ? null : _crear, child: Text(_creando ? 'Creando...' : 'Crear')),
      ],
    );
  }
}

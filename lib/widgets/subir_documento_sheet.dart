// lib/widgets/subir_documento_sheet.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/documento.dart';
import '../services/documento_service.dart';
import '../theme/design_tokens.dart';
import 'app_error.dart';

/// Abre el selector de "Añadir documento": cámara, galería, PDF, o alta
/// manual sin archivo. Si se pasa [asuntoId], el documento subido se
/// vincula automáticamente a ese asunto al terminar.
Future<String?> mostrarHojaSubirDocumento(BuildContext context, {String? asuntoId, String rolAsunto = 'documento'}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(VenceRadius.lg))),
    builder: (ctx) => _SubirDocumentoSheet(asuntoId: asuntoId, rolAsunto: rolAsunto),
  );
}

class _SubirDocumentoSheet extends StatefulWidget {
  const _SubirDocumentoSheet({this.asuntoId, required this.rolAsunto});
  final String? asuntoId;
  final String rolAsunto;

  @override
  State<_SubirDocumentoSheet> createState() => _SubirDocumentoSheetState();
}

class _SubirDocumentoSheetState extends State<_SubirDocumentoSheet> {
  bool _subiendo = false;

  Future<void> _subir(File file, String filename, String mimeType) async {
    setState(() => _subiendo = true);
    try {
      final sizeBytes = await file.length();
      final id = await DocumentoService.subirYAnalizar(file, filename, mimeType, sizeBytes);
      if (widget.asuntoId != null) {
        // La vinculación real al Asunto la hace quien llamó a este sheet,
        // (AsuntoDetailScreen) -- aquí solo devolvemos el id del documento.
      }
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) {
        AppError.show(context, e is DocumentoUploadException ? e.mensaje : 'No se ha podido subir el documento.', error: e);
        setState(() => _subiendo = false);
      }
    }
  }

  Future<void> _desdeCamara() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) await _subir(File(picked.path), picked.name, 'image/jpeg');
  }

  Future<void> _desdeGaleria() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) await _subir(File(picked.path), picked.name, 'image/jpeg');
  }

  Future<void> _desdeArchivo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    final path = result?.files.single.path;
    if (path != null) await _subir(File(path), result!.files.single.name, 'application/pdf');
  }

  @override
  Widget build(BuildContext context) {
    if (_subiendo) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Subiendo y analizando el documento...'),
          ]),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Añadir documento', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Hacer una foto'), onTap: _desdeCamara),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Elegir de la galería'), onTap: _desdeGaleria),
            ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('Subir un PDF'), onTap: _desdeArchivo),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_note_outlined),
              title: const Text('No tengo archivo, lo añado a mano'),
              onTap: () => _abrirAltaManual(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirAltaManual(BuildContext context) async {
    // El diálogo se abre ENCIMA de esta hoja (sin cerrarla antes) para
    // poder devolver su resultado como si fuera el de la propia hoja --
    // si la cerráramos primero, no habría forma de propagar el id hacia
    // quien llamó a mostrarHojaSubirDocumento.
    final id = await showDialog<String>(context: context, builder: (_) => const _AltaManualDialog());
    if (id != null && context.mounted) Navigator.of(context).pop(id);
  }
}

class _AltaManualDialog extends StatefulWidget {
  const _AltaManualDialog();
  @override
  State<_AltaManualDialog> createState() => _AltaManualDialogState();
}

class _AltaManualDialogState extends State<_AltaManualDialog> {
  final _tituloCtrl = TextEditingController();
  final _campoLabelCtrl = TextEditingController();
  final _campoValorCtrl = TextEditingController();
  CategoriaDocumento _categoria = CategoriaDocumento.otro;
  final Map<String, String> _campos = {};
  bool _guardando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _campoLabelCtrl.dispose();
    _campoValorCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_tituloCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    try {
      final id = await DocumentoService.crearManual(titulo: _tituloCtrl.text.trim(), categoria: _categoria, campos: _campos);
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) {
        AppError.show(context, 'No se ha podido guardar.', error: e);
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar a mano'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Título')),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoriaDocumento>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: CategoriaDocumento.values.map((c) => DropdownMenuItem(value: c, child: Text(c.etiqueta))).toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _campoLabelCtrl, decoration: const InputDecoration(labelText: 'Campo'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _campoValorCtrl, decoration: const InputDecoration(labelText: 'Valor'))),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_campoLabelCtrl.text.trim().isEmpty) return;
                  setState(() {
                    _campos[_campoLabelCtrl.text.trim()] = _campoValorCtrl.text.trim();
                    _campoLabelCtrl.clear();
                    _campoValorCtrl.clear();
                  });
                },
              ),
            ]),
            for (final entry in _campos.entries) Align(alignment: Alignment.centerLeft, child: Text('${entry.key}: ${entry.value}')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'Guardando...' : 'Guardar')),
      ],
    );
  }
}

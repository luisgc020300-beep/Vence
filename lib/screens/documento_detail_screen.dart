// lib/screens/documento_detail_screen.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/documento.dart';
import '../services/asunto_service.dart';
import '../services/documento_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_error.dart';
import '../widgets/nuevo_asunto_dialog.dart';
import 'asunto_detail_screen.dart';

class DocumentoDetailScreen extends StatefulWidget {
  const DocumentoDetailScreen({required this.documentoId, super.key});
  final String documentoId;

  @override
  State<DocumentoDetailScreen> createState() => _DocumentoDetailScreenState();
}

class _DocumentoDetailScreenState extends State<DocumentoDetailScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<int> _eventosAprobados = {};
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _eliminar(Documento d) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar documento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;
    await DocumentoService.eliminar(d.id, d.storagePath);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmarCambios(Documento d, List<CampoExtraido> campos) async {
    setState(() => _guardando = true);
    try {
      for (final c in campos) {
        final valor = _controllers[c.id]?.text ?? c.valor;
        final estado = valor != c.valor ? 'corregido' : 'confirmado';
        await DocumentoService.confirmarCampo(d.id, c.id, valor, estado);
      }
      if (d.eventosPropuestos.isNotEmpty || d.estado == EstadoDocumento.enRevision) {
        await DocumentoService.aprobarEventosYOrganizar(d.id, _eventosAprobados.toList(), d.eventosPropuestos);
      }
      if (mounted) AppError.showSuccess(context, 'Guardado');
    } catch (e) {
      if (mounted) AppError.show(context, 'No se ha podido guardar.', error: e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<String?> _urlFirmada(String storagePath) async {
    try {
      return await FirebaseStorage.instance.ref(storagePath).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Documento?>(
      stream: DocumentoService.streamDocumento(widget.documentoId),
      builder: (context, docSnap) {
        final d = docSnap.data;
        if (d == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return Scaffold(
          appBar: AppBar(
            title: Text(d.nombreOriginal, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _eliminar(d)),
            ],
          ),
          body: StreamBuilder<List<CampoExtraido>>(
            stream: DocumentoService.streamCampos(d.id),
            builder: (context, camposSnap) {
              final campos = camposSnap.data ?? [];
              for (final c in campos) {
                _controllers.putIfAbsent(c.id, () => TextEditingController(text: c.valor));
              }

              final esDemo = d.modoAnalisis == ModoAnalisis.demo;

              return ListView(
                padding: const EdgeInsets.all(VenceSpace.s4),
                children: [
                  Wrap(spacing: 8, children: [
                    Chip(label: Text(d.categoria.etiqueta)),
                    Chip(label: Text(d.estado.etiqueta)),
                    if (esDemo) Chip(label: const Text('Modo demostración'), backgroundColor: context.colors.brandTint),
                  ]),
                  if (d.resumen != null) ...[const SizedBox(height: 12), Text(d.resumen!, style: TextStyle(color: context.colors.inkMuted))],
                  const SizedBox(height: VenceSpace.s4),
                  _SeccionAsuntos(documentoId: d.id, nombreArchivo: d.nombreOriginal, asuntoIds: d.asuntoIds),
                  if (d.storagePath != null) ...[
                    const SizedBox(height: VenceSpace.s4),
                    FutureBuilder<String?>(
                      future: _urlFirmada(d.storagePath!),
                      builder: (context, s) => s.data == null
                          ? const SizedBox.shrink()
                          : OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Ver archivo original'),
                            ),
                    ),
                  ],
                  if (campos.isNotEmpty) ...[
                    const SizedBox(height: VenceSpace.s5),
                    Text('Datos detectados', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final c in campos)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(c.etiqueta, style: TextStyle(fontSize: 12, color: context.colors.inkMuted)),
                                _ConfianzaBadge(confianza: c.confianza, esDemo: esDemo),
                              ]),
                              TextField(controller: _controllers[c.id]),
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (d.eventosPropuestos.isNotEmpty) ...[
                    const SizedBox(height: VenceSpace.s5),
                    Text('Recordatorios propuestos', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (var i = 0; i < d.eventosPropuestos.length; i++)
                      CheckboxListTile(
                        value: _eventosAprobados.contains(i) || (d.estado != EstadoDocumento.enRevision),
                        onChanged: (v) => setState(() => v == true ? _eventosAprobados.add(i) : _eventosAprobados.remove(i)),
                        title: Text(d.eventosPropuestos[i].titulo),
                        subtitle: Text('${d.eventosPropuestos[i].fecha} · ${d.eventosPropuestos[i].motivo}'),
                      ),
                  ],
                  const SizedBox(height: VenceSpace.s5),
                  if (d.estado == EstadoDocumento.enRevision || campos.isNotEmpty)
                    FilledButton(
                      onPressed: _guardando ? null : () => _confirmarCambios(d, campos),
                      child: Text(_guardando ? 'Guardando...' : (d.estado == EstadoDocumento.enRevision ? 'Confirmar y organizar' : 'Guardar cambios')),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ConfianzaBadge extends StatelessWidget {
  const _ConfianzaBadge({required this.confianza, required this.esDemo});
  final double? confianza;
  final bool esDemo;

  @override
  Widget build(BuildContext context) {
    if (esDemo) return _chip(context, 'Dato de ejemplo', context.colors.lavanda);
    if (confianza == null) return _chip(context, 'Manual', context.colors.inkMuted);
    if (confianza! >= 0.75) return _chip(context, 'Alta confianza', context.colors.success);
    if (confianza! >= 0.5) return _chip(context, 'Confianza media', context.colors.warning);
    return _chip(context, 'Revisar', context.colors.error);
  }

  Widget _chip(BuildContext context, String texto, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(VenceRadius.pill)),
        child: Text(texto, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );
}

class _SeccionAsuntos extends StatelessWidget {
  const _SeccionAsuntos({required this.documentoId, required this.nombreArchivo, required this.asuntoIds});
  final String documentoId;
  final String nombreArchivo;
  final List<String> asuntoIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Icon(Icons.work_outline, size: 16, color: context.colors.brand), const SizedBox(width: 6), const Text('Asunto', style: TextStyle(fontWeight: FontWeight.w600))]),
            if (asuntoIds.isEmpty)
              TextButton(
                onPressed: () async {
                  final id = await mostrarDialogoNuevoAsunto(context, documentoId: documentoId, nombreArchivoDocumento: nombreArchivo);
                  if (id != null && context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AsuntoDetailScreen(asuntoId: id)));
                  }
                },
                child: const Text('Crear asunto'),
              ),
          ],
        ),
        if (asuntoIds.isEmpty)
          Text('Este documento no pertenece a ningún asunto todavía.', style: TextStyle(color: context.colors.inkMuted))
        else
          FutureBuilder(
            future: AsuntoService.obtenerPorIds(asuntoIds),
            builder: (context, snapshot) {
              final asuntos = snapshot.data ?? [];
              return Column(
                children: asuntos
                    .map((a) => Card(
                          child: ListTile(
                            title: Text(a.titulo),
                            trailing: Chip(label: Text(a.estado.etiqueta, style: const TextStyle(fontSize: 11))),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AsuntoDetailScreen(asuntoId: a.id))),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

// lib/screens/asunto_detail_screen.dart
import 'package:flutter/material.dart';

import '../models/asunto.dart';
import '../models/evento.dart';
import '../services/asunto_service.dart';
import '../services/evento_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_error.dart';
import '../widgets/empty_state.dart';
import '../widgets/subir_documento_sheet.dart';
import 'documento_detail_screen.dart';

class AsuntoDetailScreen extends StatefulWidget {
  const AsuntoDetailScreen({required this.asuntoId, super.key});
  final String asuntoId;

  @override
  State<AsuntoDetailScreen> createState() => _AsuntoDetailScreenState();
}

class _AsuntoDetailScreenState extends State<AsuntoDetailScreen> {
  final _objetivoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  final _criterioCtrl = TextEditingController();
  final _bloqueoCtrl = TextEditingController();
  EstadoAsunto? _estadoPendiente;
  bool _ocupado = false;
  String? _draftAsunto;
  String? _draftCuerpo;
  String? _draftModo;

  @override
  void dispose() {
    _objetivoCtrl.dispose();
    _notaCtrl.dispose();
    _criterioCtrl.dispose();
    _bloqueoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarEstado(Asunto asunto) async {
    if (_estadoPendiente == null) return;
    setState(() => _ocupado = true);
    try {
      await AsuntoService.cambiarEstado(
        asunto.id,
        asunto.estado,
        _estadoPendiente!,
        criterioCierre: _criterioCtrl.text.trim().isEmpty ? null : _criterioCtrl.text.trim(),
        bloqueoMotivo: _bloqueoCtrl.text.trim().isEmpty ? null : _bloqueoCtrl.text.trim(),
      );
      setState(() => _estadoPendiente = null);
    } on AsuntoException catch (e) {
      if (mounted) AppError.show(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _generarBorrador(Asunto asunto, List<Map<String, dynamic>> documentos) async {
    setState(() => _ocupado = true);
    try {
      final draft = await AsuntoService.generarBorrador(asunto, documentos);
      setState(() {
        _draftAsunto = draft.asunto;
        _draftCuerpo = draft.cuerpo;
        _draftModo = draft.modo;
      });
    } catch (e) {
      if (mounted) AppError.show(context, 'No se ha podido generar el borrador.', error: e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _eliminar(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar asunto?'),
        content: const Text('Los documentos no se eliminan, solo se desvinculan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;
    await AsuntoService.eliminar(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Asunto?>(
      stream: AsuntoService.streamAsunto(widget.asuntoId),
      builder: (context, snapshot) {
        final asunto = snapshot.data;
        if (asunto == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (_objetivoCtrl.text.isEmpty && asunto.objetivo != null) _objetivoCtrl.text = asunto.objetivo!;

        final necesitaCriterio = _estadoPendiente == EstadoAsunto.completado || _estadoPendiente == EstadoAsunto.cerrado;

        return Scaffold(
          appBar: AppBar(
            title: Text(asunto.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _eliminar(asunto.id))],
          ),
          body: ListView(
            padding: const EdgeInsets.all(VenceSpace.s4),
            children: [
              Wrap(spacing: 8, children: [
                Chip(label: Text(asunto.tipo.etiqueta)),
                Chip(label: Text(asunto.estado.etiqueta), backgroundColor: asunto.estado == EstadoAsunto.bloqueado ? context.colors.error.withValues(alpha: 0.15) : null),
              ]),
              if (asunto.estado == EstadoAsunto.bloqueado && asunto.bloqueoMotivo != null) ...[
                const SizedBox(height: 8),
                Text('Bloqueado: ${asunto.bloqueoMotivo}', style: TextStyle(color: context.colors.errorText)),
              ],

              // --- Avanzar estado ---
              if (asunto.estado.transicionesPermitidas.isNotEmpty) ...[
                const SizedBox(height: VenceSpace.s5),
                Text('Avanzar este asunto', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: asunto.estado.transicionesPermitidas
                      .map((t) => ChoiceChip(label: Text(t.etiqueta), selected: _estadoPendiente == t, onSelected: (_) => setState(() => _estadoPendiente = t)))
                      .toList(),
                ),
                if (_estadoPendiente != null) ...[
                  const SizedBox(height: 8),
                  if (_estadoPendiente == EstadoAsunto.bloqueado)
                    TextField(controller: _bloqueoCtrl, decoration: const InputDecoration(labelText: '¿Qué lo está bloqueando?')),
                  if (necesitaCriterio) ...[
                    const SizedBox(height: 4),
                    Text('No se puede ${_estadoPendiente == EstadoAsunto.cerrado ? "cerrar" : "completar"} sin indicar qué lo confirma:', style: TextStyle(fontSize: 12, color: context.colors.inkMuted)),
                    TextField(controller: _criterioCtrl, decoration: const InputDecoration(labelText: 'Criterio de cierre')),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    FilledButton(
                      onPressed: (_ocupado || (necesitaCriterio && _criterioCtrl.text.trim().isEmpty)) ? null : () => _confirmarEstado(asunto),
                      child: const Text('Confirmar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => setState(() => _estadoPendiente = null), child: const Text('Cancelar')),
                  ]),
                ],
              ],

              // --- Objetivo ---
              const SizedBox(height: VenceSpace.s5),
              Text('Objetivo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _objetivoCtrl,
                maxLines: 2,
                decoration: const InputDecoration(hintText: '¿Qué resultado buscas con este asunto?'),
                onEditingComplete: () => AsuntoService.actualizarObjetivo(asunto.id, _objetivoCtrl.text),
              ),

              // --- Documentos ---
              const SizedBox(height: VenceSpace.s5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Documentos y evidencias', style: Theme.of(context).textTheme.titleMedium),
                Row(children: [
                  TextButton(onPressed: () => _subirVinculado(context, asunto.id, 'documento'), child: const Text('Documento')),
                  TextButton(onPressed: () => _subirVinculado(context, asunto.id, 'evidencia'), child: const Text('Evidencia')),
                ]),
              ]),
              StreamBuilder<List<DocumentoVinculado>>(
                stream: AsuntoService.streamDocumentosVinculados(asunto.id),
                builder: (context, snap) {
                  final docs = snap.data ?? [];
                  if (docs.isEmpty) return Text('Todavía no hay documentos vinculados.', style: TextStyle(color: context.colors.inkMuted));
                  return Column(
                    children: docs
                        .map((d) => Card(
                              child: ListTile(
                                title: Text(d.nombreArchivo ?? d.documentoId),
                                trailing: Chip(label: Text(d.rol == 'evidencia' ? 'Evidencia' : 'Documento', style: const TextStyle(fontSize: 11))),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentoDetailScreen(documentoId: d.documentoId))),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),

              // --- Tareas ---
              const SizedBox(height: VenceSpace.s5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Próximos pasos', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: () => _nuevaTarea(context, asunto.id), child: const Text('Nueva tarea')),
              ]),
              StreamBuilder<List<Evento>>(
                stream: EventoService.streamEventos(asuntoId: asunto.id),
                builder: (context, snap) {
                  final eventos = snap.data ?? [];
                  if (eventos.isEmpty) return Text('No hay tareas vinculadas todavía.', style: TextStyle(color: context.colors.inkMuted));
                  return Column(
                    children: eventos
                        .map((e) => Card(
                              child: ListTile(title: Text(e.titulo), subtitle: Text(e.tipoEvento.etiqueta), trailing: Text(e.estado.name)),
                            ))
                        .toList(),
                  );
                },
              ),

              // --- Borrador de comunicación ---
              const SizedBox(height: VenceSpace.s5),
              Text('Preparar una comunicación', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _ocupado ? null : () => _generarBorrador(asunto, const []),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generar borrador con IA'),
              ),
              if (_draftAsunto != null) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_draftModo == 'demo') Chip(label: const Text('Borrador de ejemplo (demo)'), backgroundColor: context.colors.brandTint),
                        Text(_draftAsunto!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(_draftCuerpo ?? ''),
                        const SizedBox(height: 6),
                        Text('Este borrador no se envía solo: revísalo y envíalo tú.', style: TextStyle(fontSize: 11, color: context.colors.inkFaint)),
                      ],
                    ),
                  ),
                ),
              ],

              // --- Cronología ---
              const SizedBox(height: VenceSpace.s5),
              Text('Cronología', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _notaCtrl, decoration: const InputDecoration(hintText: 'Añadir una nota'))),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_notaCtrl.text.trim().isEmpty) return;
                    AsuntoService.anadirNota(asunto.id, _notaCtrl.text.trim());
                    _notaCtrl.clear();
                  },
                ),
              ]),
              StreamBuilder<List<ActividadAsunto>>(
                stream: AsuntoService.streamActividad(asunto.id),
                builder: (context, snap) {
                  final actividad = snap.data ?? [];
                  if (actividad.isEmpty) return const EmptyState(icon: Icons.history, title: 'Sin actividad todavía', description: '');
                  return Column(
                    children: actividad
                        .map((a) => ListTile(dense: true, leading: const Icon(Icons.circle, size: 8), title: Text(a.descripcion)))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _subirVinculado(BuildContext context, String asuntoId, String rol) {
    mostrarHojaSubirDocumento(context, asuntoId: asuntoId, rolAsunto: rol).then((docId) {
      if (docId is String) {
        AsuntoService.vincularDocumento(asuntoId, docId, rol);
      }
    });
  }

  void _nuevaTarea(BuildContext context, String asuntoId) {
    showDialog(context: context, builder: (_) => _NuevaTareaAsuntoDialog(asuntoId: asuntoId));
  }
}

class _NuevaTareaAsuntoDialog extends StatefulWidget {
  const _NuevaTareaAsuntoDialog({required this.asuntoId});
  final String asuntoId;
  @override
  State<_NuevaTareaAsuntoDialog> createState() => _NuevaTareaAsuntoDialogState();
}

class _NuevaTareaAsuntoDialogState extends State<_NuevaTareaAsuntoDialog> {
  final _tituloCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  bool _creando = false;

  Future<void> _crear() async {
    if (_tituloCtrl.text.trim().isEmpty) return;
    setState(() => _creando = true);
    await EventoService.crear(Evento(id: '', titulo: _tituloCtrl.text.trim(), fecha: _fecha, asuntoId: widget.asuntoId));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva tarea'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Título')),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}'),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setState(() => _fecha = picked);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _creando ? null : _crear, child: const Text('Crear')),
      ],
    );
  }
}

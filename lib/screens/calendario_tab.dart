// lib/screens/calendario_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/evento.dart';
import '../services/evento_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';

class CalendarioTab extends StatelessWidget {
  const CalendarioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _mostrarNuevaTarea(context))],
      ),
      body: StreamBuilder<List<Evento>>(
        stream: EventoService.streamEventos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final eventos = snapshot.data!;
          final pendientes = eventos.where((e) => e.estado == EstadoEvento.pendiente).toList();
          final resueltos = eventos.where((e) => e.estado != EstadoEvento.pendiente).take(10).toList();

          if (pendientes.isEmpty && resueltos.isEmpty) {
            return const EmptyState(icon: Icons.calendar_month_outlined, title: 'No tienes vencimientos pendientes', description: 'Los que detectemos en tus documentos, o que crees a mano, aparecerán aquí.');
          }

          final grupos = <String, List<Evento>>{};
          for (final e in pendientes) {
            final clave = DateFormat('MMMM yyyy', 'es_ES').format(e.fecha);
            grupos.putIfAbsent(clave, () => []).add(e);
          }

          return ListView(
            padding: const EdgeInsets.all(VenceSpace.s4),
            children: [
              for (final entry in grupos.entries) ...[
                Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                for (final e in entry.value) _EventoTile(evento: e),
                const SizedBox(height: 16),
              ],
              if (resueltos.isNotEmpty) ...[
                Text('Resueltas recientemente', style: TextStyle(color: context.colors.inkMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                for (final e in resueltos) _EventoTile(evento: e),
              ],
            ],
          );
        },
      ),
    );
  }

  void _mostrarNuevaTarea(BuildContext context) {
    showDialog(context: context, builder: (_) => const _NuevaTareaDialog());
  }
}

class _EventoTile extends StatelessWidget {
  const _EventoTile({required this.evento});
  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final dias = evento.diasRestantes;
    final esPendiente = evento.estado == EstadoEvento.pendiente;
    return Opacity(
      opacity: esPendiente ? 1 : 0.6,
      child: Card(
        child: ListTile(
          title: Text(evento.titulo),
          subtitle: Text('${evento.tipoEvento.etiqueta} · ${DateFormat('d MMM yyyy', 'es_ES').format(evento.fecha)}${esPendiente ? (dias < 0 ? ' · Atrasado' : dias == 0 ? ' · Hoy' : ' · en $dias días') : ''}'),
          trailing: esPendiente
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: Icon(Icons.check, color: context.colors.success), onPressed: () => EventoService.actualizarEstado(evento.id, EstadoEvento.completada)),
                  IconButton(icon: Icon(Icons.schedule, color: context.colors.warningText), onPressed: () => EventoService.posponerUnaSemana(evento)),
                  IconButton(icon: Icon(Icons.close, color: context.colors.errorText), onPressed: () => EventoService.actualizarEstado(evento.id, EstadoEvento.cancelada)),
                ])
              : null,
        ),
      ),
    );
  }
}

class _NuevaTareaDialog extends StatefulWidget {
  const _NuevaTareaDialog();
  @override
  State<_NuevaTareaDialog> createState() => _NuevaTareaDialogState();
}

class _NuevaTareaDialogState extends State<_NuevaTareaDialog> {
  final _tituloCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  TipoEvento _tipo = TipoEvento.manual;
  PrioridadEvento _prioridad = PrioridadEvento.media;
  bool _creando = false;

  Future<void> _crear() async {
    if (_tituloCtrl.text.trim().isEmpty) return;
    setState(() => _creando = true);
    await EventoService.crear(Evento(id: '', titulo: _tituloCtrl.text.trim(), fecha: _fecha, tipoEvento: _tipo, prioridad: _prioridad));
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
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}'),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setState(() => _fecha = picked);
            },
          ),
          DropdownButtonFormField<TipoEvento>(
            initialValue: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: TipoEvento.values.map((t) => DropdownMenuItem(value: t, child: Text(t.etiqueta))).toList(),
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          DropdownButtonFormField<PrioridadEvento>(
            initialValue: _prioridad,
            decoration: const InputDecoration(labelText: 'Prioridad'),
            items: PrioridadEvento.values.map((p) => DropdownMenuItem(value: p, child: Text(p.etiqueta))).toList(),
            onChanged: (v) => setState(() => _prioridad = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _creando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _creando ? null : _crear, child: Text(_creando ? 'Creando...' : 'Crear')),
      ],
    );
  }
}

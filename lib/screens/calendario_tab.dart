// lib/screens/calendario_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/evento.dart';
import '../services/evento_service.dart';
import '../theme/categoria_estilos.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/curved_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';

class CalendarioTab extends StatefulWidget {
  const CalendarioTab({super.key});

  @override
  State<CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<CalendarioTab> {
  DateTime _mesVisible = DateTime(DateTime.now().year, DateTime.now().month);

  void _cambiarMes(int delta) {
    setState(() => _mesVisible = DateTime(_mesVisible.year, _mesVisible.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Evento>>(
        stream: EventoService.streamEventos(),
        builder: (context, snapshot) {
          final eventos = snapshot.data ?? [];
          final pendientes = eventos.where((e) => e.estado == EstadoEvento.pendiente).toList();
          final delMes = pendientes.where((e) => e.fecha.year == _mesVisible.year && e.fecha.month == _mesVisible.month).toList();
          final atrasados = pendientes.where((e) => e.diasRestantes < 0).length;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              CurvedHeader(
                titulo: 'Calendario',
                trailing: HeaderIconButton(icon: Icons.add, onTap: () => showDialog(context: context, builder: (_) => const _NuevaTareaDialog())),
                floatingCard: Row(
                  children: [
                    StatCard(icon: Icons.event_outlined, etiqueta: 'Este mes', valor: '${delMes.length}'),
                    const SizedBox(width: VenceSpace.s3),
                    StatCard(icon: Icons.warning_amber_outlined, etiqueta: 'Atrasados', valor: '$atrasados', color: atrasados > 0 ? context.colors.error : null),
                  ],
                ),
              ),
              const SizedBox(height: CurvedHeader.floatingCardSpacing),
              Padding(
                padding: const EdgeInsets.fromLTRB(VenceSpace.s4, 0, VenceSpace.s4, VenceSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SelectorMes(mes: _mesVisible, onPrev: () => _cambiarMes(-1), onNext: () => _cambiarMes(1)),
                    const SizedBox(height: 12),
                    _GridMes(mes: _mesVisible, eventos: delMes),
                    const SizedBox(height: VenceSpace.s5),
                    Text('Pendientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: context.colors.ink)),
                    const SizedBox(height: 12),
                    if (pendientes.isEmpty)
                      const EmptyState(icon: Icons.calendar_month_outlined, title: 'No tienes vencimientos pendientes', description: 'Los que detectemos en tus documentos, o que crees a mano, aparecerán aquí.')
                    else
                      ...pendientes.map((e) {
                        final dias = e.diasRestantes;
                        final (icon, color) = estiloEvento(context, e.tipoEvento);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey(e.id),
                            background: Container(color: context.colors.success, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.check, color: Colors.white)),
                            secondaryBackground: Container(color: context.colors.error, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.close, color: Colors.white)),
                            onDismissed: (dir) => EventoService.actualizarEstado(e.id, dir == DismissDirection.startToEnd ? EstadoEvento.completada : EstadoEvento.cancelada),
                            child: AppListTile(
                              icon: icon,
                              iconColor: color,
                              titulo: e.titulo,
                              subtitulo: DateFormat('d MMM yyyy', 'es_ES').format(e.fecha),
                              valorArriba: dias < 0 ? 'Atrasado' : (dias == 0 ? 'Hoy' : '$dias días'),
                              valorAbajoColor: dias < 0 ? context.colors.errorText : null,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectorMes extends StatelessWidget {
  const _SelectorMes({required this.mes, required this.onPrev, required this.onNext});
  final DateTime mes;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Text(DateFormat('MMMM yyyy', 'es_ES').format(mes), style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.ink)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
      ],
    );
  }
}

class _GridMes extends StatelessWidget {
  const _GridMes({required this.mes, required this.eventos});
  final DateTime mes;
  final List<Evento> eventos;

  @override
  Widget build(BuildContext context) {
    final primerDia = DateTime(mes.year, mes.month, 1);
    final diasEnMes = DateTime(mes.year, mes.month + 1, 0).day;
    final offset = (primerDia.weekday - 1) % 7; // lunes = 0
    final hoy = DateTime.now();
    final diasConEvento = eventos.map((e) => e.fecha.day).toSet();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(VenceRadius.lg),
        boxShadow: [BoxShadow(color: context.colors.ink.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                .map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, color: context.colors.inkMuted)))))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: offset + diasEnMes,
            itemBuilder: (context, i) {
              if (i < offset) return const SizedBox.shrink();
              final dia = i - offset + 1;
              final esHoy = hoy.year == mes.year && hoy.month == mes.month && hoy.day == dia;
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: esHoy ? BoxDecoration(color: context.colors.brand, shape: BoxShape.circle) : null,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$dia', style: TextStyle(fontSize: 12, color: esHoy ? context.colors.brandOn : context.colors.ink)),
                    if (diasConEvento.contains(dia))
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: esHoy ? context.colors.brandOn : context.colors.brand, shape: BoxShape.circle),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
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

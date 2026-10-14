// lib/screens/inicio_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/asunto.dart';
import '../models/documento.dart';
import '../models/evento.dart';
import '../services/asunto_service.dart';
import '../services/documento_service.dart';
import '../services/evento_service.dart';
import '../theme/categoria_estilos.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/curved_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import 'asuntos_tab.dart';
import 'asunto_detail_screen.dart';
import 'documento_detail_screen.dart';
import 'settings_screen.dart';

class InicioTab extends StatelessWidget {
  const InicioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          StreamBuilder<List<Evento>>(
            stream: EventoService.streamEventos(estado: EstadoEvento.pendiente),
            builder: (context, eventosSnap) {
              return StreamBuilder<List<Asunto>>(
                stream: AsuntoService.streamAsuntos(soloAbiertos: true),
                builder: (context, asuntosSnap) {
                  final hoy = DateTime.now();
                  final esteMes = (eventosSnap.data ?? []).where((e) => e.fecha.year == hoy.year && e.fecha.month == hoy.month).length;
                  final abiertos = asuntosSnap.data?.length ?? 0;

                  return CurvedHeader(
                    titulo: 'Vence',
                    leading: const HeaderAvatar(),
                    trailing: HeaderIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                    child: Row(
                      children: [
                        StatCard(icon: Icons.event_busy_outlined, etiqueta: 'Vencen este mes', valor: '$esteMes'),
                        const SizedBox(width: VenceSpace.s3),
                        StatCard(icon: Icons.work_outline, etiqueta: 'Asuntos abiertos', valor: '$abiertos'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(VenceSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SeccionAsuntos(),
                const SizedBox(height: VenceSpace.s6),
                const _SeccionBandeja(),
                const SizedBox(height: VenceSpace.s6),
                const _SeccionVencimientos(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo({required this.titulo, this.accion, this.onAccion});
  final String titulo;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.ink)),
          if (accion != null) TextButton(onPressed: onAccion, child: Text(accion!)),
        ],
      ),
    );
  }
}

class _SeccionAsuntos extends StatelessWidget {
  const _SeccionAsuntos();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeccionTitulo(titulo: 'Asuntos abiertos', accion: 'Ver todos', onAccion: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AsuntosTab()))),
        StreamBuilder<List<Asunto>>(
          stream: AsuntoService.streamAsuntos(soloAbiertos: true),
          builder: (context, snapshot) {
            final asuntos = (snapshot.data ?? []).take(4).toList();
            if (asuntos.isEmpty) {
              return const EmptyState(icon: Icons.work_outline, title: 'No tienes asuntos abiertos', description: 'Un asunto agrupa documentos, tareas y evidencias de una gestión real.');
            }
            return Column(
              children: asuntos.map((a) {
                final (icon, color) = estiloAsunto(context, a.tipo);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppListTile(
                    icon: icon,
                    iconColor: a.estado == EstadoAsunto.bloqueado ? context.colors.error : color,
                    titulo: a.titulo,
                    subtitulo: a.tipo.etiqueta,
                    valorAbajo: a.estado.etiqueta,
                    valorAbajoColor: a.estado == EstadoAsunto.bloqueado ? context.colors.errorText : null,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AsuntoDetailScreen(asuntoId: a.id))),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SeccionBandeja extends StatelessWidget {
  const _SeccionBandeja();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SeccionTitulo(titulo: 'Bandeja de entrada'),
        StreamBuilder<List<Documento>>(
          stream: DocumentoService.streamDocumentos(estado: EstadoDocumento.enRevision),
          builder: (context, snapshot) {
            final docs = snapshot.data ?? [];
            if (docs.isEmpty) {
              return const EmptyState(icon: Icons.inbox_outlined, title: 'Nada pendiente de revisar', description: 'Cuando añadas un documento, aparecerá aquí.');
            }
            return Column(
              children: docs.map((d) {
                final (icon, color) = estiloCategoria(context, d.categoria);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppListTile(
                    icon: icon,
                    iconColor: color,
                    titulo: d.nombreOriginal,
                    subtitulo: d.resumen ?? 'Sin resumen',
                    valorArriba: d.categoria.etiqueta,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentoDetailScreen(documentoId: d.id))),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SeccionVencimientos extends StatelessWidget {
  const _SeccionVencimientos();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SeccionTitulo(titulo: 'Próximos vencimientos'),
        StreamBuilder<List<Evento>>(
          stream: EventoService.streamEventos(estado: EstadoEvento.pendiente),
          builder: (context, snapshot) {
            final eventos = (snapshot.data ?? []).take(5).toList();
            if (eventos.isEmpty) {
              return const EmptyState(icon: Icons.event_outlined, title: 'Sin vencimientos próximos', description: 'Los que detectemos en tus documentos, o que crees a mano, aparecerán aquí.');
            }
            return Column(
              children: eventos.map((e) {
                final dias = e.diasRestantes;
                final (icon, color) = estiloEvento(context, e.tipoEvento);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppListTile(
                    icon: icon,
                    iconColor: color,
                    titulo: e.titulo,
                    subtitulo: DateFormat('d MMM yyyy', 'es_ES').format(e.fecha),
                    valorArriba: dias < 0 ? 'Atrasado' : (dias == 0 ? 'Hoy' : '$dias días'),
                    valorAbajoColor: dias < 0 ? context.colors.errorText : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

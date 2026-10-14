// lib/screens/inicio_tab.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/asunto.dart';
import '../models/documento.dart';
import '../models/evento.dart';
import '../services/asunto_service.dart';
import '../services/documento_service.dart';
import '../services/evento_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
import 'asuntos_tab.dart';
import 'asunto_detail_screen.dart';
import 'documento_detail_screen.dart';

class InicioTab extends StatelessWidget {
  const InicioTab({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final nombre = email.contains('@') ? email.split('@').first : email;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('VENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: context.colors.inkMuted)),
            Text(nombre.isEmpty ? 'Hola' : 'Hola, $nombre', style: Theme.of(context).textTheme.displaySmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(VenceSpace.s4),
        children: [
          _SeccionAsuntos(),
          const SizedBox(height: VenceSpace.s6),
          _SeccionBandeja(),
          const SizedBox(height: VenceSpace.s6),
          _SeccionVencimientos(),
        ],
      ),
    );
  }
}

class _SeccionAsuntos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Icon(Icons.work_outline, size: 16, color: context.colors.brand), const SizedBox(width: 6), const Text('Asuntos abiertos', style: TextStyle(fontWeight: FontWeight.w600))]),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AsuntosTab())),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        StreamBuilder<List<Asunto>>(
          stream: AsuntoService.streamAsuntos(soloAbiertos: true),
          builder: (context, snapshot) {
            final asuntos = (snapshot.data ?? []).take(5).toList();
            if (asuntos.isEmpty) {
              return const EmptyState(icon: Icons.work_outline, title: 'No tienes asuntos abiertos', description: 'Un asunto agrupa documentos, tareas y evidencias de una gestión real.');
            }
            return Column(
              children: asuntos
                  .map((a) => Card(
                        child: ListTile(
                          title: Text(a.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(a.tipo.etiqueta),
                          trailing: _Badge(texto: a.estado.etiqueta, tono: a.estado == EstadoAsunto.bloqueado ? context.colors.error : context.colors.brand),
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

class _SeccionBandeja extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.inbox_outlined, size: 16, color: context.colors.brand), const SizedBox(width: 6), const Text('Bandeja de entrada', style: TextStyle(fontWeight: FontWeight.w600))]),
        StreamBuilder<List<Documento>>(
          stream: DocumentoService.streamDocumentos(estado: EstadoDocumento.enRevision),
          builder: (context, snapshot) {
            final docs = snapshot.data ?? [];
            if (docs.isEmpty) {
              return const EmptyState(icon: Icons.inbox_outlined, title: 'Nada pendiente de revisar', description: 'Cuando añadas un documento, aparecerá aquí para confirmar los datos detectados.');
            }
            return Column(
              children: docs
                  .map((d) => Card(
                        child: ListTile(
                          title: Text(d.nombreOriginal, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(d.resumen ?? 'Sin resumen', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: _Badge(texto: d.categoria.etiqueta, tono: context.colors.warning),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentoDetailScreen(documentoId: d.id))),
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

class _SeccionVencimientos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.event_outlined, size: 16, color: context.colors.brand), const SizedBox(width: 6), const Text('Próximos vencimientos', style: TextStyle(fontWeight: FontWeight.w600))]),
        StreamBuilder<List<Evento>>(
          stream: EventoService.streamEventos(estado: EstadoEvento.pendiente),
          builder: (context, snapshot) {
            final eventos = (snapshot.data ?? []).take(6).toList();
            if (eventos.isEmpty) {
              return const EmptyState(icon: Icons.event_outlined, title: 'Sin vencimientos próximos', description: 'Los que detectemos en tus documentos, o que crees a mano, aparecerán aquí.');
            }
            return Column(
              children: eventos.map((e) {
                final dias = e.diasRestantes;
                final tono = dias < 0 ? context.colors.error : (dias <= 7 ? context.colors.warning : context.colors.inkMuted);
                return Card(
                  child: ListTile(
                    title: Text(e.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(e.tipoEvento.etiqueta),
                    trailing: _Badge(texto: dias < 0 ? 'Atrasado' : (dias == 0 ? 'Hoy' : '$dias días'), tono: tono),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.texto, required this.tono});
  final String texto;
  final Color tono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: tono.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(VenceRadius.pill)),
      child: Text(texto, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tono)),
    );
  }
}

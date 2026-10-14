// lib/screens/asuntos_tab.dart
import 'package:flutter/material.dart';

import '../models/asunto.dart';
import '../services/asunto_service.dart';
import '../theme/categoria_estilos.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/nuevo_asunto_dialog.dart';
import 'asunto_detail_screen.dart';

class AsuntosTab extends StatelessWidget {
  const AsuntosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asuntos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final id = await mostrarDialogoNuevoAsunto(context);
              if (id != null && context.mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => AsuntoDetailScreen(asuntoId: id)));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Asunto>>(
        stream: AsuntoService.streamAsuntos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final asuntos = snapshot.data!;
          final abiertos = asuntos.where((a) => a.estado != EstadoAsunto.cerrado).toList();
          final cerrados = asuntos.where((a) => a.estado == EstadoAsunto.cerrado).toList();

          if (asuntos.isEmpty) {
            return const EmptyState(
              icon: Icons.work_outline,
              title: 'No tienes asuntos abiertos',
              description: 'Un asunto agrupa documentos, tareas y evidencias de una misma gestión: una compra, una incidencia, una renovación...',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(VenceSpace.s4),
            children: [
              for (final a in abiertos) Padding(padding: const EdgeInsets.only(bottom: 8), child: _AsuntoTile(asunto: a)),
              if (cerrados.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Cerrados', style: TextStyle(color: context.colors.inkMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                for (final a in cerrados) Padding(padding: const EdgeInsets.only(bottom: 8), child: Opacity(opacity: 0.7, child: _AsuntoTile(asunto: a))),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AsuntoTile extends StatelessWidget {
  const _AsuntoTile({required this.asunto});
  final Asunto asunto;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = estiloAsunto(context, asunto.tipo);
    return AppListTile(
      icon: icon,
      iconColor: asunto.estado == EstadoAsunto.bloqueado ? context.colors.error : color,
      titulo: asunto.titulo,
      subtitulo: asunto.tipo.etiqueta,
      valorAbajo: asunto.estado.etiqueta,
      valorAbajoColor: asunto.estado == EstadoAsunto.bloqueado ? context.colors.errorText : null,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AsuntoDetailScreen(asuntoId: asunto.id))),
    );
  }
}

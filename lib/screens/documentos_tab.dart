// lib/screens/documentos_tab.dart
import 'package:flutter/material.dart';

import '../models/documento.dart';
import '../services/documento_service.dart';
import '../theme/categoria_estilos.dart';
import '../theme/design_tokens.dart';
import '../widgets/curved_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_list_tile.dart';
import 'documento_detail_screen.dart';

class DocumentosTab extends StatefulWidget {
  const DocumentosTab({super.key});

  @override
  State<DocumentosTab> createState() => _DocumentosTabState();
}

class _DocumentosTabState extends State<DocumentosTab> {
  String _busqueda = '';
  CategoriaDocumento? _categoria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          CurvedHeader(
            titulo: 'Documentos',
            leading: const SizedBox(width: 36),
            trailing: PopupMenuButton<CategoriaDocumento?>(
              icon: Icon(Icons.filter_list, color: context.colors.brandOn),
              onSelected: (v) => setState(() => _categoria = v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('Todas las categorías')),
                ...CategoriaDocumento.values.map((c) => PopupMenuItem(value: c, child: Text(c.etiqueta))),
              ],
            ),
            floatingCard: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(VenceRadius.md),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search), border: InputBorder.none),
                onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
              ),
            ),
          ),
          const SizedBox(height: CurvedHeader.floatingCardSpacing),
          Padding(
            padding: const EdgeInsets.fromLTRB(VenceSpace.s4, 0, VenceSpace.s4, VenceSpace.s4),
            child: StreamBuilder<List<Documento>>(
              stream: DocumentoService.streamDocumentos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!;
                if (_categoria != null) docs = docs.where((d) => d.categoria == _categoria).toList();
                if (_busqueda.isNotEmpty) docs = docs.where((d) => d.nombreOriginal.toLowerCase().contains(_busqueda)).toList();

                if (docs.isEmpty) {
                  return const EmptyState(icon: Icons.description_outlined, title: 'No hay documentos', description: 'Prueba a cambiar los filtros, o añade tu primer documento con el botón +.');
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
                        subtitulo: d.resumen ?? d.estado.etiqueta,
                        valorArriba: d.categoria.etiqueta,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentoDetailScreen(documentoId: d.id))),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

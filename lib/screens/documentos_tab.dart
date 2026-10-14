// lib/screens/documentos_tab.dart
import 'package:flutter/material.dart';

import '../models/documento.dart';
import '../services/documento_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/empty_state.dart';
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
      appBar: AppBar(title: const Text('Documentos')),
      body: Padding(
        padding: const EdgeInsets.all(VenceSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search)),
                    onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<CategoriaDocumento?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (v) => setState(() => _categoria = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Todas las categorías')),
                    ...CategoriaDocumento.values.map((c) => PopupMenuItem(value: c, child: Text(c.etiqueta))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: VenceSpace.s4),
            Expanded(
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

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      return Card(
                        child: ListTile(
                          title: Text(d.nombreOriginal, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(d.resumen ?? d.estado.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Chip(label: Text(d.categoria.etiqueta, style: const TextStyle(fontSize: 11))),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentoDetailScreen(documentoId: d.id))),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

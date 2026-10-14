// lib/theme/categoria_estilos.dart
//
// Icono + color por categoría/tipo -- para las filas con insignia de color
// (AppListTile) de Documentos, Asuntos y Calendario.
import 'package:flutter/material.dart';

import '../models/asunto.dart';
import '../models/documento.dart';
import '../models/evento.dart';
import 'design_tokens.dart';
import 'marca_estilos.dart';

/// Icono + color para una fila de documento: logo real si el
/// nombre/resumen menciona una marca reconocida (Netflix, Spotify...),
/// icono genérico de categoría en cualquier otro caso.
(IconData, Color) estiloDocumento(BuildContext context, Documento d) {
  final marca = estiloMarca('${d.nombreOriginal} ${d.resumen ?? ''}');
  return marca ?? estiloCategoria(context, d.categoria);
}

(IconData, Color) estiloCategoria(BuildContext context, CategoriaDocumento c) {
  final colors = context.colors;
  return switch (c) {
    CategoriaDocumento.factura => (Icons.receipt_long, colors.brand),
    CategoriaDocumento.garantia => (Icons.verified_outlined, colors.success),
    CategoriaDocumento.contrato => (Icons.description_outlined, colors.lavanda),
    CategoriaDocumento.seguro => (Icons.shield_outlined, colors.warning),
    CategoriaDocumento.suscripcion => (Icons.autorenew, colors.error),
    CategoriaDocumento.justificante => (Icons.payments_outlined, colors.success),
    CategoriaDocumento.manualProducto => (Icons.menu_book_outlined, colors.inkMuted),
    CategoriaDocumento.otro => (Icons.insert_drive_file_outlined, colors.inkMuted),
  };
}

(IconData, Color) estiloAsunto(BuildContext context, TipoAsunto t) {
  final colors = context.colors;
  return switch (t) {
    TipoAsunto.compra => (Icons.shopping_bag_outlined, colors.brand),
    TipoAsunto.devolucion => (Icons.keyboard_return, colors.warning),
    TipoAsunto.incidencia => (Icons.report_problem_outlined, colors.error),
    TipoAsunto.poliza => (Icons.shield_outlined, colors.success),
    TipoAsunto.contrato => (Icons.description_outlined, colors.lavanda),
    TipoAsunto.documentoPersonal => (Icons.badge_outlined, colors.inkMuted),
    TipoAsunto.gestion => (Icons.task_alt_outlined, colors.brand),
    TipoAsunto.otro => (Icons.work_outline, colors.inkMuted),
  };
}

(IconData, Color) estiloEvento(BuildContext context, TipoEvento t) {
  final colors = context.colors;
  return switch (t) {
    TipoEvento.vencimiento => (Icons.event_busy_outlined, colors.error),
    TipoEvento.renovacion => (Icons.autorenew, colors.brand),
    TipoEvento.devolucion => (Icons.keyboard_return, colors.warning),
    TipoEvento.garantia => (Icons.verified_outlined, colors.success),
    TipoEvento.revision => (Icons.search, colors.lavanda),
    TipoEvento.pago => (Icons.payments_outlined, colors.success),
    TipoEvento.manual => (Icons.task_alt_outlined, colors.inkMuted),
  };
}

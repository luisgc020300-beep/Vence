// lib/theme/marca_estilos.dart
//
// Logo real (Simple Icons, SVG libres de marca, igual criterio que usan
// gestores de suscripciones) para documentos de marcas reconocibles --
// nunca inventado, solo cuando el nombre/resumen del documento menciona
// una marca conocida. Si no hay coincidencia, la fila usa el icono
// genérico de categoría (ver categoria_estilos.dart).
//
// Lista acotada a propósito: solo marcas confirmadas contra el paquete
// instalado (varias esperables -- Microsoft, LinkedIn, Slack, Amazon,
// Adobe, OpenAI/ChatGPT -- no están disponibles en Simple Icons, al
// parecer retiradas del proyecto por petición de marca).
import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

/// Busca una marca conocida en [texto] (normalmente nombreOriginal +
/// resumen del documento) y devuelve su icono + color de marca real, o
/// null si no reconoce ninguna.
(IconData, Color)? estiloMarca(String texto) {
  final t = _normalizar(texto);
  for (final entry in _marcas.values) {
    if (entry.$3.any((palabra) => t.contains(palabra))) {
      return (entry.$1, entry.$2);
    }
  }
  return null;
}

String _normalizar(String s) => s
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');

/// clave interna -> (icono, color, palabras que lo detectan)
final _marcas = <String, (IconData, Color, List<String>)>{
  'netflix': (SimpleIcons.netflix, SimpleIconColors.netflix, ['netflix']),
  'spotify': (SimpleIcons.spotify, SimpleIconColors.spotify, ['spotify']),
  'youtube': (SimpleIcons.youtube, SimpleIconColors.youtube, ['youtube']),
  'applemusic': (SimpleIcons.applemusic, SimpleIconColors.applemusic, ['apple music']),
  'appletv': (SimpleIcons.appletv, SimpleIconColors.appletv, ['apple tv']),
  'apple': (SimpleIcons.apple, SimpleIconColors.apple, ['apple', 'icloud', 'itunes']),
  'google': (SimpleIcons.google, SimpleIconColors.google, ['google']),
  'paypal': (SimpleIcons.paypal, SimpleIconColors.paypal, ['paypal']),
  'dropbox': (SimpleIcons.dropbox, SimpleIconColors.dropbox, ['dropbox']),
  'github': (SimpleIcons.github, SimpleIconColors.github, ['github']),
  'whatsapp': (SimpleIcons.whatsapp, SimpleIconColors.whatsapp, ['whatsapp']),
  'instagram': (SimpleIcons.instagram, SimpleIconColors.instagram, ['instagram']),
  'notion': (SimpleIcons.notion, SimpleIconColors.notion, ['notion']),
  'airbnb': (SimpleIcons.airbnb, SimpleIconColors.airbnb, ['airbnb']),
  'uber': (SimpleIcons.uber, SimpleIconColors.uber, ['uber']),
  'steam': (SimpleIcons.steam, SimpleIconColors.steam, ['steam']),
  'playstation': (SimpleIcons.playstation, SimpleIconColors.playstation, ['playstation', 'ps plus', 'ps5', 'ps4']),
  'vodafone': (SimpleIcons.vodafone, SimpleIconColors.vodafone, ['vodafone']),
  'figma': (SimpleIcons.figma, SimpleIconColors.figma, ['figma']),
  'zoom': (SimpleIcons.zoom, SimpleIconColors.zoom, ['zoom']),
};

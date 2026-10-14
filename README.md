# Vence

> «Vence se ocupa de tus documentos y te ayuda a que no se te escape nada importante.»

App móvil (Flutter + Firebase) de gestión administrativa personal con IA: sube facturas,
garantías, contratos, seguros o suscripciones; Vence extrae los datos importantes, propone
recordatorios, y organiza todo alrededor de **Asuntos** (una compra, una incidencia, una
renovación...) en vez de solo archivar documentos sueltos.

Hermana de Repara/Convive/VecindApp — mismo stack, mismo flujo de trabajo (GitHub Actions
compila el `.ipa`, se instala en el iPhone con Sideloadly).

## Stack

- **Flutter** (Dart) — iOS y Android desde un único código.
- **Firebase**: Firestore (`europe-west1`), Auth (email/contraseña), Storage, Cloud Functions, Crashlytics, App Check (modo Monitor).
- **Anthropic Claude** (vía Cloud Functions, nunca desde el cliente) — análisis de documentos, asistente, borradores de comunicación. **Opcional**: sin clave real configurada, las funciones devuelven un modo demostración determinista, siempre etiquetado como tal.

## Puesta en marcha

```bash
cd c:\dev\vence
flutter pub get
flutter run
```

El proyecto Firebase (`vence-sixapp`) y `lib/firebase_options.dart`/`android/app/google-services.json` ya están configurados — no hace falta `flutterfire configure` de nuevo salvo que cambies de proyecto.

### Clave de Anthropic (opcional)

Por defecto las Cloud Functions están en modo demostración. Para activar el análisis real:

```bash
cd functions
firebase functions:secrets:set ANTHROPIC_API_KEY --project=vence-sixapp
firebase deploy --only functions --project=vence-sixapp
```

## Modelo de datos (Firestore)

Todo cuelga de `users/{uid}` — app personal, sin "casa" compartida:

```
users/{uid}
  documentos/{docId}            -- categoría, estado, resumen, eventosPropuestos[], asuntoIds[]
    campos/{campoId}            -- dato extraído: clave, valor, confianza, estado (detectado/confirmado/corregido)
  eventos/{eventId}             -- recordatorio/tarea, opcionalmente ligado a un documento y/o asunto
  asuntos/{asuntoId}            -- la unidad de trabajo real: estado, objetivo, criterioCierre
    documentos/{docId}          -- vínculo a un documento (rol: documento | evidencia)
    actividad/{actId}           -- cronología (creado, documento añadido, cambio de estado, nota, borrador)
  conversaciones/{convId}
    mensajes/{msgId}            -- rol, contenido, fuentes citadas, modo (demo/real)
```

`firestore.rules` exige `request.auth.uid == uid` en todo, y bloquea marcar un asunto como
`completado`/`cerrado` sin `criterioCierre` explícito.

## Cloud Functions

- `analizarDocumento` — descarga el archivo de Storage, lo manda a Claude (tool-use forzado para extracción JSON fiable) o devuelve un análisis de demostración si no hay clave real.
- `pedirAsistente` — responde solo con el contexto de documentos/eventos que el cliente adjunta (ya leído con las reglas normales de Firestore), nunca con conocimiento externo.
- `generarBorrador` — prepara un borrador de comunicación (reclamación, solicitud...). **Nunca se envía nada automáticamente.**

## Qué funciona de verdad ahora mismo

- Autenticación real (email/contraseña) con aislamiento de datos por usuario.
- Subida de documentos (cámara/galería/PDF) o alta manual sin archivo.
- Bandeja de revisión: campos editables con estado detectado→confirmado/corregido.
- Motor de Asuntos: crear desde un documento o desde cero, vincular documentos/evidencias, tareas, cambio de estado con transiciones validadas y cierre que exige criterio, cronología, generador de borradores.
- Calendario agrupado por mes con completar/posponer/cancelar.
- Asistente con fuentes citadas.
- Perfil: exportar datos (comparte un JSON), cerrar sesión, eliminar cuenta.

## Limitaciones conocidas

- Sin notificaciones push todavía (no hay FCM conectado en esta primera versión).
- El asistente usa los últimos ~40 documentos/60 eventos como contexto, sin búsqueda semántica.
- Sin pruebas automatizadas de los servicios Firestore/Functions todavía (solo un smoke test de tema).
- "Eliminar cuenta" borra el usuario de Auth pero no limpia en cascada sus documentos/Storage — pendiente de una Cloud Function de borrado.

## Próximos pasos de mayor valor

1. Notificaciones push (FCM) para los vencimientos próximos.
2. Cloud Function `eliminarCuenta` que limpie Firestore + Storage en cascada.
3. Pruebas del emulador de Firestore para las reglas de seguridad y la validación de cierre de asuntos.

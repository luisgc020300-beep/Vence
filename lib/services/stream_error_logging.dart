// lib/services/stream_error_logging.dart
//
// Registra en Crashlytics el error en el punto donde se genera cada stream
// y lo vuelve a lanzar tal cual -- igual que en Repara/Convive -- para que
// un fallo de reglas o un documento corrupto no se confunda con "no hay
// nada guardado todavía".
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

extension RegistraErroresDeStream<T> on Stream<T> {
  Stream<T> conRegistroDeErrores() {
    return handleError((Object error, StackTrace stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
      Error.throwWithStackTrace(error, stackTrace);
    });
  }
}

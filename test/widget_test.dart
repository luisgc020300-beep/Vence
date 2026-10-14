// Smoke test: construir los temas de Vence no debe lanzar excepciones.
// No se monta VenceApp completa porque StreamBuilder sobre
// FirebaseAuth.instance.authStateChanges() necesita Firebase inicializado,
// algo fuera de alcance de un test de widgets puro (mismo criterio que
// Convive/VecindApp).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vence/theme/design_tokens.dart';

void main() {
  testWidgets('los temas claro y oscuro de Vence se construyen sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildVenceLightTheme(),
      darkTheme: buildVenceDarkTheme(),
      home: Builder(builder: (context) {
        final colors = Theme.of(context).extension<VenceColors>();
        expect(colors, isNotNull);
        return Scaffold(body: Text('Vence', style: Theme.of(context).textTheme.displayMedium));
      }),
    ));

    expect(find.text('Vence'), findsOneWidget);
  });
}

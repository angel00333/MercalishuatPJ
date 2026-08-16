// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mercalishuat/main.dart';
import 'package:mercalishuat/services/theme_service.dart';

void main() {
  testWidgets(
    'Mercalishuat inicia correctamente',
    (WidgetTester tester) async {
      final themeService = ThemeService();

      await themeService.cargarTema();

      await tester.pumpWidget(
        MercalishuatApp(
          themeService: themeService,
        ),
      );

      expect(
        find.text('Mercalishuat'),
        findsOneWidget,
      );
    },
  );
}
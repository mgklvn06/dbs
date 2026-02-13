// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dbs/config/app_theme.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';

void main() {
  testWidgets('App shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppBackground(
          child: AppCard(
            child: Text('AstraCare'),
          ),
        ),
      ),
    );

    expect(find.text('AstraCare'), findsOneWidget);
    expect(find.byType(AppBackground), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);
  });
}

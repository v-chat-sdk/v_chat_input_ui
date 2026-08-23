import 'package:example/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the package composer and feature overview', (
    tester,
  ) async {
    await tester.pumpWidget(const VChatInputExampleApp());

    expect(find.text('V Chat Input UI'), findsOneWidget);
    expect(find.text('A complete chat composer'), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsOneWidget);
    expect(find.byTooltip('Open emoji picker'), findsOneWidget);
    expect(find.byTooltip('Add attachment'), findsOneWidget);
  });

  testWidgets('submits typed text into the conversation', (tester) async {
    await tester.pumpWidget(const VChatInputExampleApp());

    await tester.enterText(
      find.byType(CupertinoTextField),
      'Hello from the example',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('Hello from the example'), findsOneWidget);
    expect(find.byTooltip('Send message'), findsNothing);
  });

  testWidgets('switches attachment presenters and dispatches custom Poll', (
    tester,
  ) async {
    await tester.pumpWidget(const VChatInputExampleApp());

    await tester.tap(find.byTooltip('Add attachment'));
    await tester.pumpAndSettle();
    expect(find.text('Poll'), findsOneWidget);
    await tester.tap(find.text('Poll'));
    await tester.pumpAndSettle();
    expect(find.text('Poll is a consumer-owned custom action'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final bottomSheetChoice = find.widgetWithText(ChoiceChip, 'Bottom sheet');
    await tester.ensureVisible(bottomSheetChoice);
    await tester.tap(bottomSheetChoice);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add attachment'));
    await tester.pumpAndSettle();

    expect(find.text('Poll'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('switches between light and dark themes', (tester) async {
    await tester.pumpWidget(const VChatInputExampleApp());

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    await tester.tap(find.byTooltip('Use dark theme'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });
}

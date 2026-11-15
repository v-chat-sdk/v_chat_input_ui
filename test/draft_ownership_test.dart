import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_chat_input_ui/v_chat_input_ui.dart';
import 'package:v_chat_mention_controller/v_chat_mention_controller.dart';

const _alice = MentionModel(
  peerId: 'alice',
  name: 'Alice',
  image: 'https://example.invalid/alice.png',
);
Future<List<MentionModel>> _searchAlice(String _) async => [_alice];

Widget _app({
  TextEditingController? draft,
  bool Function(String)? accept,
  ValueChanged<String>? submit,
  Future<List<MentionModel>> Function(String)? search,
  double height = 200,
  Widget? stopped,
  ThemeData? theme,
  VMessageInputController? panels,
  ValueChanged<RoomTypingEnum>? activity,
}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: VMessageInputWidget(
        textController: draft,
        onSubmitTextAccepted: accept,
        mentionListMaxHeight: height,
        onMentionSearch: search,
        mentionItemBuilder: (mention) => Text(mention.name),
        stopChatWidget: stopped,
        controller: panels,
        attachmentPresentation: VAttachmentPresentation.inlineTray,
        enableEmojiPicker: false,
        enableCamera: false,
        enableVoiceRecording: false,
        onSubmitText: submit ?? (_) {},
        onSubmitFiles: (_) {},
        onSubmitMedia: (_) {},
        onSubmitLocation: (_) {},
        onSubmitVoice: (_) {},
        onTypingChange: activity ?? (_) {},
      ),
    ),
  );
}

TextEditingController _editor(WidgetTester tester) => tester
    .widget<CupertinoTextField>(find.byType(CupertinoTextField))
    .controller!;

TextEditingController _query(String text) => TextEditingController.fromValue(
  TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  ),
);

void main() {
  testWidgets('borrows the complete draft value in both directions', (
    tester,
  ) async {
    const initial = TextEditingValue(
      text: 'First draft',
      selection: TextSelection(
        baseOffset: 1,
        extentOffset: 4,
        affinity: TextAffinity.upstream,
        isDirectional: true,
      ),
      composing: TextRange(start: 0, end: 5),
    );
    final draft = TextEditingController.fromValue(initial);
    await tester.pumpWidget(_app(draft: draft));
    expect(_editor(tester).value, initial);
    const restored = TextEditingValue(
      text: 'Restored',
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 1, end: 4),
    );
    draft.value = restored;
    expect(_editor(tester).value, restored);
    const edited = TextEditingValue(
      text: 'Editing',
      selection: TextSelection(baseOffset: 2, extentOffset: 5),
      composing: TextRange(start: 0, end: 5),
    );
    _editor(tester).value = edited;
    expect(draft.value, edited);
    await tester.pumpWidget(const SizedBox());
    draft.text = 'Still owned by the app';
    expect(draft.text, 'Still owned by the app');
    draft.dispose();
  });

  testWidgets('does not normalize an externally supplied unset selection', (
    tester,
  ) async {
    final draft = TextEditingController(text: 'Unfocused draft');
    final initial = draft.value;
    await tester.pumpWidget(_app(draft: draft));
    expect(_editor(tester).value, initial);
    expect(draft.selection.baseOffset, -1);
    await tester.pumpWidget(const SizedBox());
    draft.dispose();
  });

  testWidgets('replacing a borrowed controller detaches the previous owner', (
    tester,
  ) async {
    final first = _query('First');
    final second = _query('Second');
    await tester.pumpWidget(_app(draft: first));
    await tester.pumpWidget(_app(draft: second));
    expect(_editor(tester).value, second.value);
    first.text = 'Detached';
    expect(_editor(tester).text, 'Second');
    _editor(tester).text = 'Updated second';
    expect(second.text, 'Updated second');
    expect(first.text, 'Detached');
    await tester.pumpWidget(const SizedBox());
    first.text = 'Alive';
    second.text = 'Alive too';
    first.dispose();
    second.dispose();
  });

  testWidgets(
    'accepted-send callback gets plain text and preserves rejected values',
    (tester) async {
      final draft = _query('@al');
      var accepted = false;
      final values = <String>[];
      final legacy = <String>[];
      await tester.pumpWidget(
        _app(
          draft: draft,
          search: _searchAlice,
          submit: legacy.add,
          accept: (value) {
            values.add(value);
            return accepted;
          },
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Alice'));
      await tester.pump();
      final beforeSend = draft.value;
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(values, ['@Alice ']);
      expect(legacy, isEmpty);
      expect(draft.value, beforeSend);
      accepted = true;
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(values, ['@Alice ', '@Alice ']);
      expect(draft.text, isEmpty);
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets('legacy submission retains mention markup and clears the draft', (
    tester,
  ) async {
    final draft = _query('@al');
    final values = <String>[];
    await tester.pumpWidget(
      _app(draft: draft, search: _searchAlice, submit: values.add),
    );
    await tester.pump();
    await tester.tap(find.text('Alice'));
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    expect(values, ['[@Alice:alice] ']);
    expect(draft.text, isEmpty);
    await tester.pumpWidget(const SizedBox());
    draft.dispose();
  });

  testWidgets(
    'mention height supports default, constrained, and zero-size panes',
    (tester) async {
      final draft = _query('@al');
      for (final height in [200.0, 40.0, 0.0]) {
        await tester.pumpWidget(
          _app(draft: draft, search: _searchAlice, height: height),
        );
        await tester.pump();
        expect(tester.getSize(find.byType(ListView)).height, height);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  test('mention height rejects negative and infinite bounds', () {
    VMessageInputWidget widget(double height) => VMessageInputWidget(
      mentionListMaxHeight: height,
      onSubmitText: (_) {},
      onSubmitMedia: (_) {},
      onSubmitFiles: (_) {},
      onSubmitLocation: (_) {},
      onSubmitVoice: (_) {},
      onTypingChange: (_) {},
    );
    expect(() => widget(-1), throwsAssertionError);
    expect(() => widget(double.infinity), throwsAssertionError);
    expect(() => widget(double.nan), throwsAssertionError);
  });

  testWidgets(
    'restored multiline mention query searches and inserts at the caret',
    (tester) async {
      final draft = _query('Hello\n@al');
      final searches = <String>[];
      await tester.pumpWidget(
        _app(
          draft: draft,
          search: (query) async {
            searches.add(query);
            return [_alice];
          },
        ),
      );
      await tester.pump();
      expect(searches, ['al']);
      await tester.tap(find.text('Alice'));
      await tester.pump();
      expect(draft.text, 'Hello\n@Alice ');
      expect(draft.selection.baseOffset, draft.text.length);
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets('attaching a search callback primes an existing query', (
    tester,
  ) async {
    final draft = _query('@al');
    await tester.pumpWidget(_app(draft: draft));
    expect(find.text('Alice'), findsNothing);
    await tester.pumpWidget(_app(draft: draft, search: _searchAlice));
    await tester.pump();
    expect(find.text('Alice'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    draft.dispose();
  });

  testWidgets(
    'controller replacement ignores an old asynchronous search result',
    (tester) async {
      final old = _query('@old');
      final next = _query('@new');
      final pending = Completer<List<MentionModel>>();
      Future<List<MentionModel>> search(String query) => query == 'old'
          ? pending.future
          : Future.value([
              const MentionModel(peerId: 'new', name: 'New result', image: ''),
            ]);
      await tester.pumpWidget(_app(draft: old, search: search));
      await tester.pumpWidget(_app(draft: next, search: search));
      await tester.pump();
      expect(find.text('New result'), findsOneWidget);
      pending.complete([_alice]);
      await tester.pump();
      expect(find.text('Alice'), findsNothing);
      expect(find.text('New result'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      old.dispose();
      next.dispose();
    },
  );

  testWidgets(
    'callback replacement ignores results from its previous callback',
    (tester) async {
      final draft = _query('@al');
      final pending = Completer<List<MentionModel>>();
      await tester.pumpWidget(
        _app(draft: draft, search: (_) => pending.future),
      );
      await tester.pumpWidget(
        _app(
          draft: draft,
          search: (_) async => [
            const MentionModel(peerId: 'new', name: 'New callback', image: ''),
          ],
        ),
      );
      await tester.pump();
      pending.complete([_alice]);
      await tester.pump();
      expect(find.text('Alice'), findsNothing);
      expect(find.text('New callback'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets(
    'restricted messaging preserves drafts, closes panels, and stops activity',
    (tester) async {
      final draft = _query('Unsent draft');
      final panels = VMessageInputController();
      final activity = <RoomTypingEnum>[];
      final searches = <String>[];
      Future<List<MentionModel>> search(String query) async {
        searches.add(query);
        return [_alice];
      }

      await tester.pumpWidget(
        _app(
          draft: draft,
          panels: panels,
          search: search,
          activity: activity.add,
        ),
      );
      _editor(tester).selection = const TextSelection.collapsed(offset: 2);
      expect(activity.last, RoomTypingEnum.typing);
      panels.showAttachments();
      await tester.pumpAndSettle();
      expect(panels.activePanel, VComposerPanel.attachments);
      final beforeRestriction = draft.value;
      await tester.pumpWidget(
        _app(
          draft: draft,
          panels: panels,
          search: search,
          activity: activity.add,
          stopped: const Text('Unavailable'),
        ),
      );
      expect(draft.value, beforeRestriction);
      expect(activity.last, RoomTypingEnum.stop);
      final stoppedActivityCount = activity.length;
      expect(panels.activePanel, VComposerPanel.none);
      expect(find.text('Unavailable'), findsOneWidget);
      draft.value = const TextEditingValue(
        text: '@restored',
        selection: TextSelection.collapsed(offset: 9),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(searches, isEmpty);
      expect(activity.length, stoppedActivityCount);
      expect(activity.last, RoomTypingEnum.stop);
      await tester.pumpWidget(
        _app(
          draft: draft,
          panels: panels,
          search: search,
          activity: activity.add,
        ),
      );
      await tester.pump();
      expect(searches, ['restored']);
      expect(draft.text, '@restored');
      await tester.pumpWidget(const SizedBox());
      panels.dispose();
      draft.dispose();
    },
  );

  testWidgets('mention emphasis follows live consumer theme changes', (
    tester,
  ) async {
    final draft = _query('Draft');
    for (final color in [Colors.purple, Colors.orange]) {
      await tester.pumpWidget(
        _app(
          draft: draft,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: color)
                .copyWith(primary: color),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controller = _editor(tester) as VChatTextMentionController;
      expect(controller.mentionStyle.color, color);
      expect(controller.mentionStyle.fontWeight, FontWeight.w700);
    }
    await tester.pumpWidget(const SizedBox());
    draft.dispose();
  });

  test('picker API is available from the public package barrel', () {
    expect(VAppPick.isPicking, isFalse);
  });
}

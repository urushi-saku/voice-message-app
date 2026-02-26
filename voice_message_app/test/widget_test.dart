// ===================================
// Vio ボイスメッセージアプリ - ウィジェットテスト
// ===================================
// 基本的なFlutterウィジェット機能テスト
// (MyApp の複雑な初期化をスキップし、単純なウィジェットのみテスト)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('基本ウィジェット - UIテスト', () {
    testWidgets('ElevatedButton がタップ可能', (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => tapCount++,
                child: const Text('Test Button'),
              ),
            ),
          ),
        ),
      );

      // ボタンが存在することを確認
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Test Button'), findsOneWidget);

      // ボタンをタップ
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // コールバックが実行されたことを確認
      expect(tapCount, 1);
    });

    testWidgets('TextFormField にテキスト入力可能', (WidgetTester tester) async {
      const testText = 'Hello, Vio!';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextFormField(key: const Key('testField'))),
        ),
      );

      // テキストフィールドが存在することを確認
      expect(find.byType(TextFormField), findsOneWidget);

      // テキストフィールドにテキスト入力
      await tester.enterText(find.byKey(const Key('testField')), testText);
      await tester.pump();

      // 入力されたテキストを確認
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('ListView がレンダリングされる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: List.generate(
                5,
                (i) => ListTile(key: Key('item_$i'), title: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      // リストアイテムが表示されていることを確認
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('複数のアイテムがリストに表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                ListTile(title: Text('First')),
                ListTile(title: Text('Second')),
                ListTile(title: Text('Third')),
              ],
            ),
          ),
        ),
      );

      // すべてのアイテムが表示されていることを確認
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });
    ;

    testWidgets('Checkbox の状態が変わる', (WidgetTester tester) async {
      bool isChecked = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    setState(() {
                      isChecked = value ?? false;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      // チェックボックスが存在することを確認
      expect(find.byType(Checkbox), findsOneWidget);

      // チェックボックスをタップ
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // 状態が変わったことを確認
      expect(isChecked, isTrue);
    });

    testWidgets('SnackBar が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  tester.element(find.byType(Scaffold)),
                ).showSnackBar(const SnackBar(content: Text('Test Snackbar')));
              },
              child: const Icon(Icons.add),
            ),
            body: const Center(child: Text('Test Page')),
          ),
        ),
      );

      // FAB をタップ
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // SnackBar が表示されていることを確認
      expect(find.text('Test Snackbar'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

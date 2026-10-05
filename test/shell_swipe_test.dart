// Navegación del Shell: taps del Nav y swipe cambian de pestaña.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rickpedia_v2/data/api.dart';
import 'package:rickpedia_v2/data/app_state.dart';
import 'package:rickpedia_v2/ui/screens/shell.dart';
import 'package:rickpedia_v2/ui/widgets/common.dart';

void main() {
  testWidgets('swipe y taps cambian de tab', (t) async {
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => Api()),
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const MaterialApp(home: Shell()),
      ),
    );
    await t.pump();

    Nav nav() => t.widget<Nav>(find.byType(Nav));

    expect(nav().index, 0);
    // Tap en Charts (tab 2).
    await t.tap(find.text('Charts'));
    await t.pumpAndSettle();
    expect(nav().index, 2);

    // Swipe a la izquierda -> Favorites (tab 3).
    await t.fling(find.byType(PageView), const Offset(-400, 0), 800);
    await t.pumpAndSettle();
    expect(nav().index, 3);

    // Swipe a la derecha -> Charts (tab 2).
    await t.fling(find.byType(PageView), const Offset(400, 0), 800);
    await t.pumpAndSettle();
    expect(nav().index, 2);
  });
}

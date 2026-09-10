import 'package:flutter_test/flutter_test.dart';
import 'package:kairo_music_player/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KairoMPApp());
    expect(find.byType(KairoMPApp), findsOneWidget);
  });
}

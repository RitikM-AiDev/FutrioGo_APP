import 'package:flutter_test/flutter_test.dart';
import 'package:futrio_go/main.dart';

void main() {
  testWidgets('FutrioGoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FutrioGoApp());
    expect(find.byType(FutrioGoApp), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:motomate/app.dart';

void main() {
  testWidgets('MotoMate app launches successfully',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MotoMateApp());

        expect(find.byType(MotoMateApp), findsOneWidget);
      });
}
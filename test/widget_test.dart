import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yaan_owner/main.dart';
import 'package:yaan_owner/providers/hotel_provider.dart';
import 'package:yaan_owner/screens/splash_screen.dart';

void main() {
  testWidgets('Yaan Owner App launches and displays SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HotelProvider()),
        ],
        child: const MyApp(),
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    // Drain pending timers from SplashScreen transition
    await tester.pump(const Duration(seconds: 4));
  });
}

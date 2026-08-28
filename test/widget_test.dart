import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:handora/main.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://mock.supabase.co
SUPABASE_ANON_KEY=mock-key
GEMINI_API_KEY=mock-gemini-key
''');
  });

  testWidgets('App renders without errors', (tester) async {
    await tester.pumpWidget(const HandoraApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Hand'), findsWidgets);
  });
}

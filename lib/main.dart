import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/progress_provider.dart';
import 'core/services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WikiGameApp());
}

class WikiGameApp extends StatelessWidget {
  const WikiGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = ProgressProvider(StorageService());
            provider.load();
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'WikiGame',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF58CC02),
            secondary: const Color(0xFF1CB0F6),
            surface: const Color(0xFF1E2F38),
            error: const Color(0xFFFF4B4B),
          ),
          scaffoldBackgroundColor: const Color(0xFF131F24),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

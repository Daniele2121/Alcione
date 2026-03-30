import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

// Import dei tuoi file
import 'package:alcione_scouting/auth.dart';
import 'package:alcione_scouting/pages/AuthPage.dart';
import 'package:alcione_scouting/pages/main_page.dart';
import 'app_theme.dart';
import 'firebase_options.dart';

// --- CONTROLLER GLOBALE TEMI ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// --- GESTORE NOTIFICHE RIMOSSO ---
// Le funzioni di messaging sono state rimosse per risolvere il conflitto Xcode 16

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inizializzazione Firebase (Firestore e Auth continuano a funzionare)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurazione estetica barra di sistema
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Alcione Scouting Elite',

          // --- LOGICA TEMI ---
          themeMode: currentMode,
          theme: AlcioneTheme.lightTheme,
          darkTheme: AlcioneTheme.darkTheme,

          // --- FLUSSO DI AUTENTICAZIONE ---
          home: StreamBuilder(
            stream: Auth().authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6600),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              if (snapshot.hasData) {
                return const MainPage();
              } else {
                return const Authpage();
              }
            },
          ),
        );
      },
    );
  }
}
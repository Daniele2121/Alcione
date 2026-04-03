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

void main() async {
  // 1. Assicura che i binding di Flutter siano pronti prima di Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inizializzazione Firebase con protezione dai crash all'avvio
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase inizializzato correttamente");
  } catch (e) {
    // Se Firebase fallisce, l'app non crasha ma logga l'errore
    debugPrint("❌ ERRORE CRITICO FIREBASE: $e");
  }

  // 3. Configurazione estetica barra di sistema
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // 4. Avvio dell'applicazione
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
              // Schermata di caricamento durante il controllo del login
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

              // Se l'utente è loggato vai alla MainPage, altrimenti alla AuthPage
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- AGGIUNTO

// Import dei tuoi file
import 'package:alcione_scouting/auth.dart';
import 'package:alcione_scouting/pages/AuthPage.dart';
import 'package:alcione_scouting/pages/main_page.dart';
import 'app_theme.dart';
import 'firebase_options.dart';

// --- CONTROLLER GLOBALE TEMI ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// --- GESTORE NOTIFICHE IN BACKGROUND ---
// Questa funzione deve stare fuori dalla classe perché viene eseguita in un isolamento separato
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Notifica ricevuta in Background: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inizializzazione Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Configurazione Notifiche
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Impostiamo il gestore per quando l'app è chiusa
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Richiesta Permessi (Il famoso Pop-up di sistema)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false, // impostato a false per avere il consenso esplicito subito
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Permesso concesso: Iscrizione al topic in corso...');
    // Iscriviamo l'utente al topic di default per le nuove segnalazioni
    await messaging.subscribeToTopic('segnalazioni');
  } else {
    print('L\'utente ha negato o non ha ancora concesso i permessi');
  }

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
                // Se loggato, prima di mostrare la MainPage,
                // ascoltiamo le notifiche mentre l'app è aperta (Foreground)
                _setupForegroundMessaging(context);
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

  // Logica per mostrare un avviso se arriva una notifica mentre stiamo usando l'app
  void _setupForegroundMessaging(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF001D3D), // Blue Alcione
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Color(0xFFFF6600)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${message.notification!.title}: ${message.notification!.body}",
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }
}
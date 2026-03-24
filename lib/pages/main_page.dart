import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import delle tue pagine
import 'package:alcione_scouting/pages/home_page.dart';
import 'package:alcione_scouting/pages/profil_page.dart';
import 'package:alcione_scouting/pages/stats_page.dart';
import 'package:alcione_scouting/pages/programs_page.dart';
import 'package:alcione_scouting/pages/aggiungi_giocatore.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();

  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MODIFICA 1: Fondamentale per l'effetto Instagram.
      // Mettendo false, il corpo dell'app NON va dietro la barra.
      extendBody: false,

      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(key: _homeKey),
          const StatsPage(),
          const ProgramsPage(),
          const ProfilePage(),
        ],
      ),

      // MODIFICA 2: Avvolgiamo il container nel SafeArea per gestire la striscia Samsung/iPhone
      bottomNavigationBar: Container(
        // Colore di sfondo uguale al tema per non avere stacchi visivi
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false, // Protegge solo la parte bassa (gesture bar)
          child: Container(
            height: 85,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10), // Margine pulito
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: blueAlcione.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, -2), // L'ombra va leggermente verso l'alto
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: _buildNavItem(Icons.home_outlined, Icons.home, "SCOUT", 0)),
                      Expanded(child: _buildNavItem(Icons.calendar_today_outlined, Icons.calendar_month, "PROGRAMS", 2)),
                      // Il bottone centrale lo lasciamo fisso perché è un cerchio
                      _buildCenterAddButton(),
                      Expanded(child: _buildNavItem(Icons.bar_chart_outlined, Icons.bar_chart, "STATS", 1)),
                      Expanded(child: _buildNavItem(Icons.person_outline, Icons.person, "PROFILE", 3)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildCenterAddButton() {
    return GestureDetector(
      onTap: () async {
        final nuovoGiocatore = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AggiungiGiocatore()),
        );
        if (nuovoGiocatore != null && _homeKey.currentState != null) {
          await _homeKey.currentState!.service.aggiungi(nuovoGiocatore);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: orangeAlcione,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: orangeAlcione.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildNavItem(IconData iconOff, IconData iconOn, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? iconOn : iconOff,
            color: isSelected ? orangeAlcione : Colors.white.withOpacity(0.5),
            size: 24,
          ),
          const SizedBox(height: 4),
          // --- MODIFICA QUI ---
          SizedBox(
            width: 65, // Diamo un limite massimo di larghezza "sicuro"
            child: FittedBox(
              fit: BoxFit.scaleDown, // <--- SE NON CI STA, SCALA IL FONT (NON VA A CAPO)
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 8, // Dimensione originale per iPhone 14
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
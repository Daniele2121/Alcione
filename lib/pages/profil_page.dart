import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alcione_scouting/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'target_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifications = true;
  int _countSegnalazioni = 0;
  int _countReportPro = 0;
  String _annataTop = "---";

  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);

  @override
  void initState() {
    super.initState();
    _loadRealStats();
    _loadNotificationPreference();
  }

  void _mostraDialogLogout() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            Text("VUOI USCIRE?", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 10),
            Text("Dovrai inserire nuovamente le tue credenziali per accedere al portale.",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 35),
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: Container(
                width: double.infinity, height: 60,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: Text("DISCONNETTI ORA", style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: Colors.white))),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ANNULLA", style: GoogleFonts.montserrat(color: Colors.grey[400], fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _notifications = prefs.getBool('notifications_enabled') ?? true);
  }

  // --- LOGICA NOTIFICHE SEMPLIFICATA (Solo UI locale) ---
  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    HapticFeedback.mediumImpact();
    setState(() => _notifications = value);
    await prefs.setBool('notifications_enabled', value);
    // Nota: Iscrizione/Disiscrizione al topic rimossa per compatibilità build
  }

  Future<void> _loadRealStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('giocatori')
          .where('scoutEmail', isEqualTo: user.email)
          .get();

      if (mounted) {
        int reportTecniciSvolti = 0;
        Map<int, int> conteggioAnni = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['report'] != null) reportTecniciSvolti++;
          int? anno = data['annoNascita'];
          if (anno != null) conteggioAnni[anno] = (conteggioAnni[anno] ?? 0) + 1;
        }
        String topYearStr = "---";
        if (conteggioAnni.isNotEmpty) {
          topYearStr = conteggioAnni.entries.reduce((a, b) => a.value > b.value ? a : b).key.toString();
        }
        setState(() {
          _countSegnalazioni = snapshot.docs.length;
          _countReportPro = reportTecniciSvolti;
          _annataTop = topYearStr;
        });
      }
    } catch (e) { debugPrint("Errore stats: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20),
            _buildProfileHeader(),
            const SizedBox(height: 35),
            _buildMiniStats(),
            const SizedBox(height: 40),

            _buildSectionTitle("IMPOSTAZIONI APP"),
            _buildSettingsCard([
              _buildSettingItem(
                  Icons.dark_mode_outlined, "Dark Mode",
                  trailing: Switch.adaptive(
                    value: isDarkMode,
                    activeColor: orangeAlcione,
                    onChanged: (v) {
                      themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                      HapticFeedback.mediumImpact();
                      setState(() {});
                    },
                  )
              ),
              _buildSettingItem(
                  Icons.notifications_none_rounded, "Notifiche Segnalazioni",
                  trailing: Switch.adaptive(
                    value: _notifications,
                    activeColor: orangeAlcione,
                    onChanged: (v) => _toggleNotifications(v),
                  )
              ),
            ]),

            const SizedBox(height: 25),

            _buildSectionTitle("STRATEGIA DI MERCATO"),
            _buildSettingsCard([
              _buildSettingItem(
                Icons.track_changes_rounded,
                "Visualizza Target Annate",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TargetPage()));
                },
              ),
            ]),

            const SizedBox(height: 50),
            _buildLogoutButton(),
            const SizedBox(height: 30),
            Text("Version 2.0.4 (Elite Edition)",
                style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600)),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: orangeAlcione, width: 2)),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: blueAlcione,
            child: Text(user?.email?.substring(0, 2).toUpperCase() ?? "SC",
                style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 15),
        Text(user?.email?.split('@')[0] ?? "Osservatore",
            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900)),
        Text("Official Scout • Alcione Milano",
            style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: orangeAlcione)),
      ],
    );
  }

  Widget _buildMiniStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statColumn(_countSegnalazioni.toString(), "SEGNALAZIONI"),
        Container(width: 1, height: 30, color: Colors.grey[200]),
        _statColumn(_countReportPro.toString(), "REPORT"),
        Container(width: 1, height: 30, color: Colors.grey[200]),
        _statColumn(_annataTop, "ANNATA TOP"),
      ],
    );
  }

  Widget _statColumn(String val, String lab) => Column(
    children: [
      Text(val, style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: orangeAlcione)),
      Text(lab, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[400], letterSpacing: 1)),
    ],
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1.5)),
    ),
  );

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: orangeAlcione, size: 22),
      title: Text(title, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _mostraDialogLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
        ),
        child: Center(
          child: Text("DISCONNETTI",
              style: GoogleFonts.montserrat(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
        ),
      ),
    );
  }
}
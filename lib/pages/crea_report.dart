import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alcione_scouting/models/giocatore.dart';
import 'package:alcione_scouting/models/report.dart';

class CreaReportPage extends StatefulWidget {
  final Giocatore giocatore;
  const CreaReportPage({super.key, required this.giocatore});

  @override
  State<CreaReportPage> createState() => _CreaReportPageState();
}

class _CreaReportPageState extends State<CreaReportPage> {
  final nomeCtrl = TextEditingController();
  final cognomeCtrl = TextEditingController();
  final annoCtrl = TextEditingController();
  final squadraCtrl = TextEditingController();
  final piedeCtrl = TextEditingController();
  final ruoloSpecCtrl = TextEditingController();
  final fisicoCtrl = TextEditingController();
  final costituzioneCtrl = TextEditingController();
  final segnalatoreCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  final Map<String, int> valutazioni = {
    'Tecnica': 1, 'Tattica': 1, 'Velocità': 1,
    'Struttura': 1, 'Comportamento': 1, 'Personalità': 1, 'Potenziale': 1,
  };

  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);
  final Color bgColor = const Color(0xFFF5F5F7);

  @override
  void initState() {
    super.initState();
    final g = widget.giocatore;
    nomeCtrl.text = g.nome;
    cognomeCtrl.text = g.cognome;
    annoCtrl.text = g.annoNascita.toString();
    squadraCtrl.text = g.squadra;
    piedeCtrl.text = '';

    // MODIFICA QUI: Carica il ruolo specifico, se è vuoto usa il ruolo base
    ruoloSpecCtrl.text = (g.ruoloSpecifico != null && g.ruoloSpecifico!.isNotEmpty)
        ? g.ruoloSpecifico!
        : g.ruolo;

    segnalatoreCtrl.text = g.segnalatore;

    if (g.report != null) {
      valutazioni.addAll(g.report!.valutazioni);
      noteCtrl.text = g.report!.note ?? '';
      fisicoCtrl.text = g.report!.fisico ?? '';
      costituzioneCtrl.text = g.report!.costituzione ?? '';
      piedeCtrl.text = g.report!.piede ?? '';
      // Se il report ha già un ruolo specifico salvato, usa quello
      if(g.report!.ruoloSpecifico != null && g.report!.ruoloSpecifico!.isNotEmpty) {
        ruoloSpecCtrl.text = g.report!.ruoloSpecifico!;
      }
    }
  }

  int get totale {
    int somma = 0;
    valutazioni.forEach((k, v) {
      somma += (k == 'Potenziale') ? (v * 2) : v;
    });
    return somma;
  }

  int _sliderIndex(String key) {
    final val = valutazioni[key]!;
    if (val == -1) return 0;
    if (val == 1) return 1;
    if (val == 2) return 2;
    if (val == 3) return 3;
    return 1;
  }

  int _valoreDaIndex(int index) {
    if (index == 0) return -1;
    if (index == 1) return 1;
    if (index == 2) return 2;
    if (index == 3) return 3;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: CloseButton(color: isDark ? Colors.white : blueAlcione),
        title: Text('DETTAGLI REPORT',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : blueAlcione,
                fontSize: 16,
                letterSpacing: 1
            )),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _sectionTitle("DATI ATLETA"),
            _buildInputGroup([
              _buildModernField(nomeCtrl, 'Nome', Icons.person_outline),
              _divider(),
              _buildModernField(cognomeCtrl, 'Cognome', Icons.badge_outlined),
              _divider(),
              _buildModernField(annoCtrl, 'Anno', Icons.cake_outlined, type: TextInputType.number),
              _divider(),
              _buildModernField(squadraCtrl, 'Squadra', Icons.shield_outlined),
              _divider(),
              _buildModernField(piedeCtrl, 'Piede (DX/SX)', Icons.directions_run_rounded),
              _divider(),
              _buildModernField(ruoloSpecCtrl, 'Ruolo Specifico', Icons.sports_soccer_rounded),
            ]),

            _sectionTitle("CARATTERISTICHE FISICHE"),
            _buildInputGroup([
              _buildModernField(fisicoCtrl, 'Fisico', Icons.fitness_center_rounded),
              _divider(),
              _buildModernField(costituzioneCtrl, 'Costituzione', Icons.accessibility_new_rounded),
              _divider(),
              _buildModernField(segnalatoreCtrl, 'Segnalatore', Icons.flag_rounded),
            ]),

            _sectionTitle("VALUTAZIONI TECNICHE"),
            _buildValutazioniGroup(),

            _sectionTitle("OSSERVAZIONI FINALI"),
            _buildNotesCard(),
            const SizedBox(height: 30),
            _buildLiveScoreCard(),

            const SizedBox(height: 20),
            _buildSaveButton(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveScoreCard() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    // In Dark Mode usiamo un bordo arancione per far risaltare la card score
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF001226) : blueAlcione,
        borderRadius: BorderRadius.circular(30),
        border: isDark ? Border.all(color: orangeAlcione.withOpacity(0.5), width: 1) : null,
        boxShadow: [BoxShadow(color: blueAlcione.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SCORE REPORT", style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 5),
              Text(totale.toString(), style: GoogleFonts.montserrat(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: orangeAlcione, shape: BoxShape.circle),
            child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 30),
          )
        ],
      ),
    );
  }

  Widget _buildValutazioniGroup() {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22)
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        children: valutazioni.keys.map((k) => _buildModernSlider(k)).toList(),
      ),
    );
  }

  Widget _buildModernSlider(String key) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    int val = valutazioni[key]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(key, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: isDark ? Colors.white : blueAlcione, fontSize: 13)),
              Text(val == -1 ? "N.C." : val.toString(),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: orangeAlcione)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: orangeAlcione,
              inactiveTrackColor: isDark ? Colors.white10 : bgColor,
              thumbColor: Colors.white,
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 5),
            ),
            child: Slider(
              value: _sliderIndex(key).toDouble(),
              min: 0, max: 3,
              divisions: 3,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => valutazioni[key] = _valoreDaIndex(v.round()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: isDark ? Colors.white : blueAlcione, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: orangeAlcione, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildNotesCard() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22)
      ),
      child: TextField(
        controller: noteCtrl,
        maxLines: 4,
        style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Inserisci osservazioni, punti di forza, debolezze...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? orangeAlcione : blueAlcione,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        onPressed: _salvaReport,
        child: Text("SALVA REPORT PRO", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8, top: 25),
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1.5)),
    );
  }

  Widget _buildInputGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22)
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, indent: 50, color: isDark ? Colors.white10 : Colors.grey[50]);
  }

  Future<void> _salvaReport() async {
    HapticFeedback.mediumImpact();
    final report = Report(
      nomereport: nomeCtrl.text,
      cognomereport: cognomeCtrl.text,
      annoreport: int.tryParse(annoCtrl.text) ?? 0,
      squadrareport: squadraCtrl.text,
      piede: piedeCtrl.text,

      // SALVA IL RUOLO SPECIFICO DAL CONTROLLER
      ruoloSpecifico: ruoloSpecCtrl.text.trim().toUpperCase(),

      fisico: fisicoCtrl.text,
      costituzione: costituzioneCtrl.text,
      segnalatore: segnalatoreCtrl.text,
      note: noteCtrl.text,
      valutazioni: Map.from(valutazioni),
      totale: totale,
    );

    await FirebaseFirestore.instance
        .collection('giocatori')
        .doc(widget.giocatore.id)
        .update({
      'report': report.toMap(),
      // Opzionale: aggiorna anche il campo nel profilo principale del giocatore
      'ruoloSpecifico': ruoloSpecCtrl.text.trim().toUpperCase(),
    });

    widget.giocatore.report = report;
    if (mounted) Navigator.pop(context, report);
  }
}
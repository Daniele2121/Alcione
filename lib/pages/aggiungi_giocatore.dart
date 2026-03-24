import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/giocatore.dart';
import 'package:alcione_scouting/data/squadre.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AggiungiGiocatore extends StatefulWidget {
  final Giocatore? giocatoreEsistente;
  const AggiungiGiocatore({super.key, this.giocatoreEsistente});

  @override
  State<AggiungiGiocatore> createState() => _AggiungiGiocatoreState();
}

class _AggiungiGiocatoreState extends State<AggiungiGiocatore> {
  bool _isSaving = false;
  final nomeController = TextEditingController();
  final cognomeController = TextEditingController();
  final segnalatoreController = TextEditingController();
  final partitaCtrl = TextEditingController();
  final ruoloSpecificoController = TextEditingController();

  DateTime? dataPartita;
  int? annoSelezionato;
  String? ruoloSelezionato;
  String? squadraSelezionata;

  final List<int> anni = List.generate(2018 - 2005 + 1, (i) => 2005 + i);
  final List<String> ruoli = ['Portiere', 'Difensore', 'Centrocampista', 'Attaccante'];

  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);

  @override
  void initState() {
    super.initState();
    if (widget.giocatoreEsistente != null) {
      final g = widget.giocatoreEsistente!;
      nomeController.text = g.nome;
      cognomeController.text = g.cognome;
      annoSelezionato = g.annoNascita;
      ruoloSelezionato = g.ruolo;
      squadraSelezionata = g.squadra;
      segnalatoreController.text = g.segnalatore;
      partitaCtrl.text = g.partitaVisionata;
      dataPartita = g.dataPartita;
      ruoloSpecificoController.text = g.ruoloSpecifico ?? "";
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    cognomeController.dispose();
    segnalatoreController.dispose();
    partitaCtrl.dispose();
    ruoloSpecificoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: CloseButton(color: isDark ? Colors.white : blueAlcione),
        title: Text(
          widget.giocatoreEsistente == null ? 'NUOVA SCHEDA' : 'MODIFICA SCHEDA',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : blueAlcione,
              fontSize: 16,
              letterSpacing: 1
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("DATI ANAGRAFICI"),
            _buildInputGroup([
              _buildTextField(nomeController, "Nome", Icons.person_outline),
              _divider(),
              _buildTextField(cognomeController, "Cognome", Icons.badge_outlined),
              _divider(),
              _buildAnnoPicker(),
            ]),

            _sectionTitle("POSIZIONE IN CAMPO"),
            _buildRuoloSelector(),

            const SizedBox(height: 15),
            _buildInputGroup([
              _buildTextField(
                  ruoloSpecificoController,
                  "Ruolo Specifico (es: Punta centrale...)",
                  Icons.settings_input_component_rounded
              ),
            ]),

            _sectionTitle("DETTAGLI MATCH"),
            _buildInputGroup([
              _buildSquadraDropdown(),
              _divider(),
              _buildTextField(partitaCtrl, "Partita visionata", Icons.stadium_outlined),
              _divider(),
              _buildDatePicker(),
            ]),

            _sectionTitle("INFO OSSERVATORE"),
            _buildInputGroup([
              _buildTextField(segnalatoreController, "Segnalato da...", Icons.edit_note_rounded),
            ]),

            const SizedBox(height: 40),
            _buildSubmitButton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- LOGICA DI SALVATAGGIO CON FILTRO MITTENTE ---
  Future<void> _salva() async {
    // 1. Validazione campi (rimane uguale)
    if (nomeController.text.isEmpty || cognomeController.text.isEmpty ||
        partitaCtrl.text.isEmpty || segnalatoreController.text.isEmpty ||
        annoSelezionato == null || ruoloSelezionato == null ||
        squadraSelezionata == null || dataPartita == null) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compila tutti i campi obbligatori')));
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final currentUser = FirebaseAuth.instance.currentUser;
    final String nomeSettato = nomeController.text.trim();
    final String cognomeSettato = cognomeController.text.trim();
    final String ruoloSpec = ruoloSpecificoController.text.trim().toUpperCase();

    // 2. Mappa base del Giocatore
    final Map<String, dynamic> giocatoreMap = {
      'nome': nomeSettato,
      'cognome': cognomeSettato,
      'annoNascita': annoSelezionato!,
      'ruolo': ruoloSelezionato!,
      'ruoloSpecifico': ruoloSpec,
      'squadra': squadraSelezionata!,
      'segnalatore': segnalatoreController.text.trim(),
      'dataPartita': dataPartita!,
      'partitaVisionata': partitaCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(), // Usiamo updatedAt per le modifiche
      'senderId': currentUser?.uid,
      'categoria': _calcolaCategoria(annoSelezionato!),
    };

    try {
      if (widget.giocatoreEsistente == null) {
        // NUOVO GIOCATORE
        giocatoreMap['createdAt'] = FieldValue.serverTimestamp();
        giocatoreMap['scoutEmail'] = currentUser?.email;
        await FirebaseFirestore.instance.collection('giocatori').add(giocatoreMap);
      } else {
        // MODIFICA GIOCATORE ESISTENTE

        // Se esiste un report, aggiorniamo i dati duplicati anche dentro il report
        if (widget.giocatoreEsistente!.report != null) {
          giocatoreMap['report.nomereport'] = nomeSettato;
          giocatoreMap['report.cognomereport'] = cognomeSettato;
          giocatoreMap['report.squadrareport'] = squadraSelezionata!;
          giocatoreMap['report.annoreport'] = annoSelezionato!;
          giocatoreMap['report.ruoloSpecifico'] = ruoloSpec;
          // Nota: non tocchiamo i voti (Tecnica, Tattica, ecc.) che restano intatti
        }

        await FirebaseFirestore.instance.collection('giocatori')
            .doc(widget.giocatoreEsistente!.id)
            .update(giocatoreMap);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    }
  }

  // --- WIDGETS HELPERS ---
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 8, top: 25),
    child: Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 1.2)),
  );

  Widget _buildInputGroup(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
    ),
    child: Column(children: children),
  );

  Widget _divider() => Divider(height: 1, indent: 50, color: Theme.of(context).dividerColor.withOpacity(0.1));

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: isDark ? Colors.white : blueAlcione, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: orangeAlcione, size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      ),
    );
  }

  Widget _buildRuoloSelector() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: ruoli.map((r) {
        bool isSel = ruoloSelezionato == r;
        return GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); setState(() => ruoloSelezionato = r); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSel ? orangeAlcione : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [if(isSel) BoxShadow(color: orangeAlcione.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Text(r, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12, color: isSel ? Colors.white : (isDark ? Colors.white70 : blueAlcione))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnnoPicker() => _buildSelectableField(icon: Icons.cake_outlined, label: "Anno di nascita", value: annoSelezionato?.toString(), onTap: () => _mostraPickerSemplice(title: "Seleziona Anno", items: anni.map((a) => a.toString()).toList(), onSelected: (v) => setState(() => annoSelezionato = int.parse(v))));
  Widget _buildSquadraDropdown() => _buildSelectableField(icon: Icons.shield_outlined, label: "Squadra attuale", value: squadraSelezionata, onTap: () => _mostraPickerSemplice(title: "Seleziona Squadra", items: squadre, onSelected: (v) => setState(() => squadraSelezionata = v)));
  Widget _buildDatePicker() { bool isDark = Theme.of(context).brightness == Brightness.dark; return _buildSelectableField(icon: Icons.calendar_today_outlined, label: "Data partita", value: dataPartita == null ? null : "${dataPartita!.day}/${dataPartita!.month}/${dataPartita!.year}", onTap: () async { final picked = await showDatePicker(context: context, initialDate: dataPartita ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now(), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: isDark ? ColorScheme.dark(primary: orangeAlcione, onPrimary: Colors.white, surface: blueAlcione) : ColorScheme.light(primary: orangeAlcione, onPrimary: Colors.white, onSurface: blueAlcione)), child: child!)); if (picked != null) setState(() => dataPartita = picked); }); }
  Widget _buildSelectableField({required IconData icon, required String label, String? value, required VoidCallback onTap}) { bool isDark = Theme.of(context).brightness == Brightness.dark; return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12), child: Row(children: [Icon(icon, color: orangeAlcione, size: 22), const SizedBox(width: 15), Expanded(child: Text(value ?? label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 15, color: value == null ? Colors.grey[400] : (isDark ? Colors.white : blueAlcione)))), Icon(Icons.arrow_forward_ios, color: Colors.grey[300], size: 14)]))); }
  void _mostraPickerSemplice({required String title, required List<String> items, required Function(String) onSelected}) { bool isDark = Theme.of(context).brightness == Brightness.dark; showModalBottomSheet(context: context, backgroundColor: Theme.of(context).cardColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (_) => Container(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: isDark ? Colors.white : blueAlcione)), const Divider(), Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (context, i) => ListTile(title: Text(items[i], textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)), onTap: () { onSelected(items[i]); Navigator.pop(context); } )))]))); }

  Widget _buildSubmitButton() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: isDark ? [orangeAlcione, const Color(0xFFFF8E4D)] : [blueAlcione, const Color(0xFF003566)]),
        boxShadow: [BoxShadow(color: (isDark ? orangeAlcione : blueAlcione).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: _isSaving ? null : _salva,
        child: _isSaving
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(widget.giocatoreEsistente == null ? 'SALVA GIOCATORE' : 'AGGIORNA DATI', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }

  String _calcolaCategoria(int anno) {
    int eta = DateTime.now().year - anno;
    return "U$eta";
  }
}
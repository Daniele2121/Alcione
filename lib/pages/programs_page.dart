import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class ProgramsPage extends StatelessWidget {
  const ProgramsPage({super.key});

  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);
  final Color bgDark = const Color(0xFF000814);

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color currentBg = isDark ? bgDark : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: currentBg,
      body: Stack(
        children: [
          // GLOW BACKGROUND - Effetto profondità Nike
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orangeAlcione.withOpacity(isDark ? 0.07 : 0.03),
              ),
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent)
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // HEADER DINAMICO APPLE STYLE CON RICHTEXT
              SliverAppBar(
                expandedHeight: 160.0,
                collapsedHeight: 85,
                pinned: true,
                stretch: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: currentBg.withOpacity(0.85),
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "PIANO\n",
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                                color: isDark ? Colors.white70 : Colors.grey[600],
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: "GARE",
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                                height: 0.9,
                                color: orangeAlcione,
                                letterSpacing: -1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  _headerIcon(Icons.cleaning_services_rounded, () => _confermaSvuotaTutto(context, isDark)),
                  const SizedBox(width: 10),
                  _headerAddBtn(() => _mostraPannelloAggiungiGara(context, isDark)),
                  const SizedBox(width: 20),
                ],
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('programmi')
                    .orderBy('dataOra', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6600)))
                    );
                  }

                  final gare = snapshot.data?.docs ?? [];
                  if (gare.isEmpty) return _buildEmptyState(isDark);

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildNikeCard(gare[index], isDark, context),
                        childCount: gare.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGETS COMPONENTI ---

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: Colors.grey[500]),
    );
  }

  Widget _headerAddBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: orangeAlcione,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: orangeAlcione.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
            ]
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildNikeCard(DocumentSnapshot doc, bool isDark, BuildContext context) {
    DateTime dataOra = (doc['dataOra'] as Timestamp).toDate();
    bool completata = doc['completata'] ?? false;
    String match = doc['match'] ?? "";
    String scout = doc['scoutNome'] ?? "";

    return GestureDetector(
      onLongPress: () => _mostraDossierGara(context, doc, isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: completata ? Colors.green.withOpacity(0.4) : Colors.white.withOpacity(0.05),
              width: 1.5
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10)
            )
          ],
        ),
        child: Opacity(
          opacity: completata ? 0.6 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: orangeAlcione.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: Text(
                      "${DateFormat('HH:mm').format(dataOra)} • ${DateFormat('dd MMM').format(dataOra).toUpperCase()}",
                      style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: orangeAlcione, letterSpacing: 0.5),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      FirebaseFirestore.instance.collection('programmi').doc(doc.id).update({'completata': !completata});
                    },
                    child: Icon(
                      completata ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                      color: completata ? Colors.green : Colors.grey[300],
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                match.toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  height: 1.1,
                  color: completata ? Colors.grey : (isDark ? Colors.white : blueAlcione),
                  decoration: completata ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 5),
                  Text(scout.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[500])),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, size: 16, color: orangeAlcione.withOpacity(0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostraPannelloAggiungiGara(BuildContext context, bool isDark) {
    final mC = TextEditingController();
    final sC = TextEditingController();
    final nC = TextEditingController();
    DateTime? dS; TimeOfDay? oS;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Recuperiamo lo spazio di sistema (Pillola iPhone o Gesture Samsung)
          final double systemBottom = MediaQuery.of(context).padding.bottom;
          // Calcoliamo un padding che spinga il tasto SALVA ben sopra la barra
          final double safePadding = systemBottom > 0 ? systemBottom + 35 : 45;

          return Container(
            padding: EdgeInsets.only(
              // Insets.bottom serve per la tastiera, safePadding per la barra di sistema
                bottom: MediaQuery.of(context).viewInsets.bottom + safePadding,
                left: 24, right: 24, top: 20
            ),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000814) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40))
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 25),
                  Text("NUOVO INCARICO", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: orangeAlcione)),
                  const SizedBox(height: 25),
                  _fieldElite(mC, "MATCH (ES: MILAN - ALCIONE)", Icons.sports_soccer_rounded, isDark),
                  const SizedBox(height: 12),
                  _fieldElite(sC, "SCOUT", Icons.person_search_rounded, isDark),
                  const SizedBox(height: 12),
                  _fieldElite(nC, "NOTE / GIOCATORI", Icons.edit_note_rounded, isDark),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _pickerElite(dS == null ? "DATA" : DateFormat('dd/MM').format(dS!), () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                        if (d != null) setModalState(() => dS = d);
                      }, isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _pickerElite(oS == null ? "ORA" : oS!.format(context), () async {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (t != null) setModalState(() => oS = t);
                      }, isDark)),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // IL TASTO SALVA ORA È ALZATO E SICURO
                  GestureDetector(
                    onTap: () async {
                      if (mC.text.isNotEmpty && sC.text.isNotEmpty && dS != null && oS != null) {
                        final dF = DateTime(dS!.year, dS!.month, dS!.day, oS!.hour, oS!.minute);
                        await FirebaseFirestore.instance.collection('programmi').add({
                          'match': mC.text.trim().toUpperCase(),
                          'scoutNome': sC.text.trim(),
                          'noteGiocatori': nC.text.trim().isEmpty ? "Nessuna nota" : nC.text.trim(),
                          'dataOra': dF,
                          'completata': false,
                        });
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: double.infinity, height: 65,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [orangeAlcione, const Color(0xFFFF8E4D)]),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: orangeAlcione.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                      ),
                      child: Center(child: Text("SALVA PIANO GARA", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16))),
                    ),
                  ),
                  // Non serve più il SizedBox vuoto in fondo perché lo gestisce il padding del Container
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostraDossierGara(BuildContext context, DocumentSnapshot doc, bool isDark) {
    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        // Usiamo SafeArea per assicurarci che il sistema "prenoti" lo spazio per la barra
        return SafeArea(
          bottom: false, // Lo gestiamo noi col padding per avere più controllo
          child: Container(
            // Aumentiamo il padding inferiore a 45 pixel fissi + il padding di sistema
            // Questo spingerà i tasti ELIMINA/CHIUDI ben sopra ogni tipo di barra
            padding: EdgeInsets.fromLTRB(28, 15, 28, MediaQuery.of(sheetContext).padding.bottom + 45),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF000814) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 25),
                        decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)
                        )
                    )
                ),

                Text("DETTAGLI GARA",
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 10, color: orangeAlcione, letterSpacing: 2)),
                const SizedBox(height: 5),
                Text(doc['match'],
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? Colors.white : blueAlcione)),

                const SizedBox(height: 25),

                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        doc['noteGiocatori'],
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : blueAlcione, height: 1.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35), // Aumentato spazio sopra i tasti

                Row(
                  children: [
                    Expanded(
                        child: _modalBtn("ELIMINA", Icons.delete_outline, Colors.redAccent, () {
                          HapticFeedback.mediumImpact();
                          FirebaseFirestore.instance.collection('programmi').doc(doc.id).delete();
                          Navigator.pop(sheetContext);
                        })
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                        child: _modalBtn("CHIUDI", Icons.close, Colors.grey, () => Navigator.pop(sheetContext))
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- HELPERS ---

  Widget _modalBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _fieldElite(TextEditingController ctrl, String hint, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(18)
      ),
      child: TextField(
        controller: ctrl,
        textCapitalization: TextCapitalization.characters,
        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : blueAlcione),
        decoration: InputDecoration(
            icon: Icon(icon, color: orangeAlcione, size: 20),
            border: InputBorder.none,
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500])
        ),
      ),
    );
  }

  Widget _pickerElite(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(18)
        ),
        child: Center(
            child: Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white : blueAlcione))
        ),
      ),
    );
  }

  void _confermaSvuotaTutto(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text("PULIZIA TOTALE", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18)),
        content: const Text("Eliminare tutte le gare in programma?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("ANNULLA", style: GoogleFonts.montserrat(color: Colors.grey))),
          TextButton(onPressed: () async {
            var s = await FirebaseFirestore.instance.collection('programmi').get();
            for (var d in s.docs) { await d.reference.delete(); }
            Navigator.pop(context);
          }, child: Text("ELIMINA", style: GoogleFonts.montserrat(color: Colors.redAccent, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_rounded, size: 50, color: Colors.grey[isDark ? 800 : 300]),
          const SizedBox(height: 15),
          Text("PIANO GARE VUOTO", style: GoogleFonts.montserrat(color: Colors.grey[500], fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
        ]),
      ),
    );
  }
}
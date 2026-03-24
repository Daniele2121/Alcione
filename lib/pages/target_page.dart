import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class TargetPage extends StatelessWidget {
  const TargetPage({super.key});

  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);
  final Color bgDark = const Color(0xFF000814);

  final List<String> annateSettore = const [
    '2008', '2009', '2010', '2011', '2012', '2013', '2014', '2015'
  ];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color currentBg = isDark ? bgDark : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: currentBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 110.0,
                pinned: true,
                elevation: 0,
                backgroundColor: currentBg.withOpacity(0.8),
                // Manteniamo il leading (la freccia)
                leading: BackButton(color: isDark ? Colors.white : blueAlcione),
                flexibleSpace: FlexibleSpaceBar(
                  // FORZIAMO centerTitle a false per evitare che si accentri sulla freccia
                  centerTitle: false,
                  // MODIFICHIAMO IL PADDING:
                  // Aumentiamo il padding sinistro a 56 (che è la larghezza standard del tasto back)
                  // Così il testo "cammina" su un binario che parte dopo la freccia.
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text(
                    "TARGET MERCATO",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: isDark ? Colors.white : blueAlcione,
                    ),
                  ),
                  background: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('targets')
                    .orderBy('data', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6600))));
                  }

                  final allTargets = snapshot.data?.docs ?? [];

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 150),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          String anno = annateSettore[index];
                          var targetsPerAnno = allTargets.where((doc) => doc['annata'] == anno).toList();
                          return _buildAnnataSection(context, anno, targetsPerAnno, isDark);
                        },
                        childCount: annateSettore.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 50,
            right: 50,
            child: _buildEliteFab(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnataSection(BuildContext context, String anno, List<QueryDocumentSnapshot> targets, bool isDark) {
    if (targets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
          child: Text(anno, style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black12)),
        ),
        ...targets.map((t) => _buildTargetCard(context, t, isDark)).toList(),
      ],
    );
  }

  Widget _buildTargetCard(BuildContext context, QueryDocumentSnapshot doc, bool isDark) {
    // Sicurezza per il campo note
    final data = doc.data() as Map<String, dynamic>;
    final bool hasNote = data.containsKey('note') && data['note'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.03), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _mostraDettaglioTarget(context, doc, isDark),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(Icons.radar_rounded, color: orangeAlcione, size: 18),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['ruolo'].toString().toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : blueAlcione),
                      ),
                      if (hasNote)
                        Text("Vedi note tecniche", style: GoogleFonts.montserrat(fontSize: 9, color: orangeAlcione.withOpacity(0.7), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // TASTO ELIMINA DIRETTO A DESTRA
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.4), size: 22),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    FirebaseFirestore.instance.collection('targets').doc(doc.id).delete();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostraDettaglioTarget(BuildContext context, QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final String noteTesto = data.containsKey('note') ? data['note'] : "";

    // Recuperiamo il padding di sistema (fondamentale per iPhone/Samsung)
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permette al pannello di adattarsi al contenuto
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => Container(
        // Altezza massima 70% dello schermo per non coprire tutto se le note sono lunghissime
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: EdgeInsets.fromLTRB(30, 15, 30, bottomPadding + 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Si stringe se c'è poco testo
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle superiore
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey[isDark ? 800 : 300], borderRadius: BorderRadius.circular(10))
                )
            ),

            // Header fisso
            Text("DETTAGLIO TARGET ${doc['annata']}",
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: orangeAlcione, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 5),
            Text(doc['ruolo'].toString().toUpperCase(),
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? Colors.white : blueAlcione)),

            const SizedBox(height: 20),

            // AREA SCORREVOLE PER LE NOTE
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NOTE TECNICHE", style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(
                      noteTesto.isEmpty ? "Nessuna nota aggiuntiva per questo ruolo." : noteTesto,
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.6
                      ),
                    ),
                    const SizedBox(height: 20), // Spazio extra interno allo scroll
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TASTO CHIUDI (Sempre visibile e sopra la barra di sistema)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: blueAlcione,
                    shape: const StadiumBorder(),
                    elevation: 0
                ),
                onPressed: () => Navigator.pop(sheetContext),
                child: Text("CHIUDI", style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEliteFab(BuildContext context, bool isDark) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: orangeAlcione.withOpacity(0.3), blurRadius: 20)],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: orangeAlcione, shape: const StadiumBorder()),
        onPressed: () => _mostraPannelloAggiungi(context, isDark),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text("NEW TARGET", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _mostraPannelloAggiungi(BuildContext context, bool isDark) {
    String? annataSelezionata;
    final TextEditingController ruoloCtrl = TextEditingController();
    final TextEditingController noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // FONDAMENTALE: permette al pannello di andare a tutto schermo
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        // Questo padding sposta il pannello esattamente sopra la tastiera
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(25, 15, 25, 25),
          child: SingleChildScrollView( // Permette di scorrere se lo spazio è poco
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barretta grigia per trascinare (stile iOS)
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 25),
                Text("IMPOSTA TARGET", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: orangeAlcione)),
                const SizedBox(height: 25),

                _buildInput(isDark, child: DropdownButtonFormField<String>(
                  dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  decoration: const InputDecoration(border: InputBorder.none, labelText: "Annata"),
                  items: annateSettore.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (v) => annataSelezionata = v,
                )),

                const SizedBox(height: 12),

                _buildInput(isDark, child: TextField(
                  controller: ruoloCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(border: InputBorder.none, labelText: "Ruolo"),
                )),

                const SizedBox(height: 12),

                _buildInput(isDark, child: TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(border: InputBorder.none, labelText: "Note (Opzionale)"),
                )),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: orangeAlcione,
                        shape: const StadiumBorder()
                    ),
                    onPressed: () async {
                      if (annataSelezionata != null && ruoloCtrl.text.isNotEmpty) {
                        HapticFeedback.mediumImpact();
                        await FirebaseFirestore.instance.collection('targets').add({
                          'annata': annataSelezionata,
                          'ruolo': ruoloCtrl.text.trim().toUpperCase(),
                          'note': noteCtrl.text.trim(),
                          'data': FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: Text("ATTIVA RADAR", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10), // Un po' di respiro sul fondo
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: child,
    );
  }
}
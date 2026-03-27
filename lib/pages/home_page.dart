import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Per il feedback tattile

// Import relativi ai tuoi file
import 'package:alcione_scouting/models/giocatore.dart';
import 'package:alcione_scouting/pages/AuthPage.dart';
import 'package:alcione_scouting/pages/aggiungi_giocatore.dart';
import 'package:alcione_scouting/pages/report_giocatore.dart';
import 'package:alcione_scouting/services/giocatori_service.dart';
import 'package:alcione_scouting/utils/logo_utils.dart';
import 'package:alcione_scouting/data/squadre.dart';
import 'package:alcione_scouting/widgets/animated_tap.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final service = GiocatoriService();
  List<Giocatore> giocatoriFiltrati = [];

  // Mantengo i tuoi colori originali per coerenza interna
  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);

  // Stato Filtri
  String? filtroRuolo;
  int? filtroAnno;
  String? filtroSquadra;
  bool? ordinePunteggioDesc;
  bool? ordineAlfabeticoAsc;
  String? filtroValutazione;

  // --- LOGICA DI AUTENTICAZIONE ---
  Future<void> _logout() async {
    final bool? conferma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, // Dinamico
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text('Logout', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Vuoi davvero uscire dall\'app scouting?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: const StadiumBorder()),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esci', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (conferma == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Authpage()),
            (route) => false,
      );
    }
  }

  void applicaFiltri(List<Giocatore> tutti) {
    // 1. FILTRAGGIO
    List<Giocatore> lista = tutti.where((g) {
      // Filtri base (Ruolo, Anno, Squadra)
      if (filtroRuolo != null && g.ruolo != filtroRuolo) return false;
      if (filtroAnno != null && g.annoNascita != filtroAnno) return false;
      if (filtroSquadra != null && g.squadra != filtroSquadra) return false;

      // Filtro Valutazione (Deve essere identico a quello salvato)
      if (filtroValutazione != null && g.valutazioneFinale != filtroValutazione) {
        return false;
      }

      // Filtro Top Score: se attivo, mostra SOLO chi ha un voto > 0
      if (ordinePunteggioDesc != null) {
        if (g.report == null || (g.report?.totale ?? 0) == 0) return false;
      }

      return true;
    }).toList();

    // 2. ORDINAMENTO COMBINATO
    lista.sort((a, b) {
      // Se l'utente vuole l'ordinamento per PUNTEGGIO
      if (ordinePunteggioDesc != null) {
        final pa = (a.report?.totale ?? 0).toDouble();
        final pb = (b.report?.totale ?? 0).toDouble();

        int compPunteggio = ordinePunteggioDesc! ? pb.compareTo(pa) : pa.compareTo(pb);

        // Se i punteggi sono diversi, vince il punteggio
        if (compPunteggio != 0) return compPunteggio;

        // SE I PUNTEGGI SONO UGUALI (es. due 7.0) o se non c'è ordinamento alfabetico attivo,
        // usa comunque l'alfabetico come paracadute per tenere ordine
        return a.cognome.toLowerCase().compareTo(b.cognome.toLowerCase());
      }

      // Se il punteggio NON è attivo, usa l'ordinamento alfabetico (A-Z o Z-A)
      if (ordineAlfabeticoAsc != null) {
        int compAlfabetico = a.cognome.toLowerCase().compareTo(b.cognome.toLowerCase());
        if (compAlfabetico == 0) {
          compAlfabetico = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        }
        return ordineAlfabeticoAsc! ? compAlfabetico : -compAlfabetico;
      }

      return 0;
    });

    setState(() {
      giocatoriFiltrati = lista;
    });
  }

  void resetFiltri(List<Giocatore> tutti) {
    setState(() {
      filtroRuolo = null;
      filtroAnno = null;
      filtroSquadra = null;
      filtroValutazione = null; // Fondamentale per far ricomparire tutti
      ordinePunteggioDesc = null;
      ordineAlfabeticoAsc = null;
      giocatoriFiltrati = []; // Svuotando torna a usare 'tutti' nel build
    });
  }

  Future<void> confermaEliminazione(Giocatore g) async {
    final bool? conferma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina'),
        content: Text('Eliminare la segnalazione di ${g.cognome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (conferma == true) {
      await service.elimina(g.id);
      setState(() {
        giocatoriFiltrati.removeWhere((x) => x.id == g.id);
      });
    }
  }

  void _mostraGestioneGiocatore(Giocatore g) {
    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        final double bottomPadding = MediaQuery.of(context).padding.bottom;
        final double safePadding = bottomPadding > 0 ? bottomPadding + 20 : 35;

        // --- LOGICA COLORE VALUTAZIONE ---
        // Dentro _mostraGestioneGiocatore, aggiorna lo switch dei colori:
        Color evalColor;
        switch (g.valutazioneFinale?.toUpperCase()) {
          case 'DA PRENDERE':
            evalColor = Colors.greenAccent; break;
          case 'DA MONITORARE':
            evalColor = Colors.orangeAccent; break;
          case 'DA MONITORARE IN PROSPETTIVA':
            evalColor = Colors.cyanAccent; break; // Un azzurro per i giovani futuribili
          case 'DA VEDERE':
            evalColor = Colors.yellowAccent; break;
          case 'NON ADATTO':
            evalColor = Colors.redAccent; break;
          default:
            evalColor = Colors.grey;
        }
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, safePadding),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF001D3D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INTESTAZIONE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${g.cognome} ${g.nome}'.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : blueAlcione,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: orangeAlcione.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(g.ruolo.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: orangeAlcione)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // --- NUOVA RIGA VALUTAZIONE ---
                      _infoRowSafe(
                        Icons.stars_rounded,
                        'Esito Scouting',
                        g.valutazioneFinale ?? 'NON VALUTATO',
                        isDark,
                        customColor: evalColor, // Applica il colore dinamico (Verde/Arancio/Rosso)
                      ),
                      _infoRowSafe(
                          Icons.shield_rounded,
                          'Squadra Attuale',
                          g.squadra.toUpperCase(),
                          isDark
                      ),

                      if (g.ruoloSpecifico != null && g.ruoloSpecifico!.isNotEmpty)
                        _infoRowSafe(Icons.psychology_rounded, 'Ruolo Specifico', g.ruoloSpecifico!.toUpperCase(), isDark),

                      _infoRowSafe(Icons.person_pin_rounded, 'Segnalatore', g.segnalatore, isDark),
                      _infoRowSafe(Icons.calendar_month_rounded, 'Data Partita', _formatDate(g.dataPartita), isDark),
                      _infoRowSafe(Icons.sports_soccer_rounded, 'Partita Visionata', g.partitaVisionata, isDark),

                      const Divider(height: 40, color: Colors.white10),

                      // TASTI AZIONE
                      _buildActionTile(
                        icon: Icons.edit_note_rounded,
                        label: 'Modifica Segnalazione',
                        color: orangeAlcione,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AggiungiGiocatore(giocatoreEsistente: g)));
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildActionTile(
                        icon: Icons.delete_sweep_rounded,
                        label: 'Elimina Giocatore',
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.pop(context);
                          confermaEliminazione(g);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Aggiunto {Color? customColor} come parametro opzionale nominato
  Widget _infoRowSafe(IconData icon, String label, String value, bool isDark, {Color? customColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Se customColor è presente usa quello, altrimenti usa orangeAlcione
          Icon(
              icon,
              color: customColor ?? orangeAlcione,
              size: 20
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                      letterSpacing: 1.1
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    // Se c'è un colore personalizzato lo usiamo anche per il testo
                    // per dare più risalto alla valutazione
                    color: customColor ?? (isDark ? Colors.white : blueAlcione),
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Piccolo helper per i tasti azione così restano puliti e distanziati
  Widget _buildActionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14)),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime? d) => d == null ? '-' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    // MODIFICA 1: Colori barre di sistema (Stato e Navigazione)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // MODIFICA 2: SafeArea per evitare notch e gesture bar
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('giocatori')
              .orderBy('dataPartita', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 1. RECUPERO DATI ORIGINALI
            List<Giocatore> lista = snapshot.data?.docs.map((d) => Giocatore.fromDoc(d)).toList() ?? [];

            // 2. APPLICAZIONE FILTRI (LOGICA "LIVE" AGGIORNATA)
            lista = lista.where((g) {
              if (filtroRuolo != null && g.ruolo != filtroRuolo) return false;
              if (filtroAnno != null && g.annoNascita != filtroAnno) return false;

              // --- LOGICA FILTRO SQUADRA (FIXATA PER "ALTRO") ---
              if (filtroSquadra != null) {
                if (filtroSquadra == "Altro") {
                  // Se filtro "Altro", mostro solo chi NON è nella lista ufficiale
                  if (squadre.contains(g.squadra) && g.squadra != "Altro") return false;
                } else {
                  // Altrimenti cerco la corrispondenza esatta
                  if (g.squadra != filtroSquadra) return false;
                }
              }

              // Controllo Valutazione
              if (filtroValutazione != null && g.valutazioneFinale?.toUpperCase() != filtroValutazione?.toUpperCase()) {
                return false;
              }

              if (ordinePunteggioDesc != null) {
                if (g.report == null || (g.report?.totale ?? 0) == 0) return false;
              }
              return true;
            }).toList();

            // 3. ORDINAMENTO COMBINATO (CORRETTO)
            lista.sort((a, b) {
              // SE ENTRAMBI SONO ATTIVI -> Comanda l'ALFABETICO (A-Z)
              if (ordineAlfabeticoAsc != null && ordinePunteggioDesc != null) {
                int compAlfabetico = a.cognome.toLowerCase().compareTo(b.cognome.toLowerCase());
                if (compAlfabetico == 0) {
                  compAlfabetico = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
                }
                // Restituisce l'ordine A-Z o Z-A richiesto
                return ordineAlfabeticoAsc! ? compAlfabetico : -compAlfabetico;
              }

              // SE SOLO PUNTEGGIO È ATTIVO
              if (ordinePunteggioDesc != null) {
                final pa = (a.report?.totale ?? 0).toDouble();
                final pb = (b.report?.totale ?? 0).toDouble();
                int compPunteggio = ordinePunteggioDesc! ? pb.compareTo(pa) : pa.compareTo(pb);
                if (compPunteggio != 0) return compPunteggio;
                return a.cognome.toLowerCase().compareTo(b.cognome.toLowerCase());
              }

              // SE SOLO ALFABETICO È ATTIVO
              if (ordineAlfabeticoAsc != null) {
                int compAlfabetico = a.cognome.toLowerCase().compareTo(b.cognome.toLowerCase());
                if (compAlfabetico == 0) {
                  compAlfabetico = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
                }
                return ordineAlfabeticoAsc! ? compAlfabetico : -compAlfabetico;
              }

              return 0;
            });

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyStatsDelegate(
                    child: _buildSimpleStatsRow(lista), // Stats basate sulla lista filtrata!
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 5, bottom: 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildModernPlayerCard(lista[i]),
                      childCount: lista.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      // ALTEZZA COMPATTA STILE NIKE/STRAVA
      expandedHeight: 90.0,
      pinned: true,
      stretch: true, // Mantiene l'effetto rimbalzo piacevole
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF000814) : Colors.white,

      // 1. LEADIND: Avatar Profilo Circolare (Più grande e visibile)
      leadingWidth: 70, // Diamo spazio all'avatar
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
        child: GestureDetector(
          onTap: _logout,
          child: Container(
            decoration: BoxDecoration(
              color: orangeAlcione.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: orangeAlcione.withOpacity(0.2), width: 1),
            ),
            child: Icon(Icons.person_outline_rounded, size: 24, color: orangeAlcione),
          ),
        ),
      ),

      // 2. AZIONI: Filtri (Rimangono esattamente dove volevi)
      actions: [
        IconButton(
          icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white : blueAlcione, size: 26),
          onPressed: _mostraFiltri,
        ),
        const SizedBox(width: 8),
      ],

      // 3. IL CUORE DELL'HEADER (Titolo + Saluto)
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 70, bottom: 14), // Allineato perfettamente con l'avatar
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SALUTO DINAMICO STILE FITNESS APP
            Text(
              'CIAO SCOUT,',
              style: GoogleFonts.montserrat(
                color: orangeAlcione,
                fontWeight: FontWeight.w700,
                fontSize: 8,
                letterSpacing: 1.5,
              ),
            ),
            // TITOLO PRINCIPALE (Bold, pulito)
            Text(
              'SCOUTING',
              style: GoogleFonts.montserrat(
                color: isDark ? Colors.white : blueAlcione,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        background: Container(
          color: isDark ? const Color(0xFF000814) : Colors.white,
        ),
      ),
    );

  }

  // DEVE AVERE (List<Giocatore> tutti) tra le parentesi!
  Widget _buildSimpleStatsRow(List<Giocatore> tutti) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect( // Questo serve per l'effetto blur
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Sfocatura Apple
        child: Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            // Colore molto trasparente
            color: isDark ? const Color(0xFF000814).withOpacity(0.7) : Colors.white.withOpacity(0.7),
            border: Border(
              bottom: BorderSide(color: orangeAlcione.withOpacity(0.8), width: 1.5), // Arancione più acceso qui!
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statText("SCOUT: ${tutti.length}"),
              _statText("REPORTS: ${tutti.where((g) => (g.report?.totale ?? 0) > 0).length}"),
              _statText("TOP: ${_getTopYear(tutti)}"),
            ],
          ),
        ),
      ),
    );
  }


// Piccolo helper per il testo delle stats (per non ripetere codice)
  Widget _statText(String txt) {
    return Row(
      children: [
        if (txt.contains("SCOUT")) // Solo vicino al primo dato
          Container(
            margin: const EdgeInsets.only(right: 5),
            width: 6, height: 6,
            decoration: BoxDecoration(color: orangeAlcione, shape: BoxShape.circle),
          ),
        Text(
          txt.toUpperCase(),
          style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900, // Più Bold
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              letterSpacing: 0.8
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
          letterSpacing: 0.5
      ),
    );
  }

  String _getTopYear(List<Giocatore> tutti) {
    if (tutti.isEmpty) return "-";
    var counts = <int, int>{};
    for (var g in tutti) { counts[g.annoNascita] = (counts[g.annoNascita] ?? 0) + 1; }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key.toString();
  }

  // 2. IL SINGOLO DATO
  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: orangeAlcione),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.grey)),
      ],
    );
  }

  // 3. IL DIVISORE VERTICALE
  Widget _statDivider() => Container(height: 25, width: 1, color: Colors.grey.withOpacity(0.2));



  Widget _buildModernPlayerCard(Giocatore g) {
    double punteggio = (g.report?.totale ?? 0).toDouble();
    bool isTopPlayer = punteggio >= 7.5;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        Feedback.forLongPress(context);
        _mostraGestioneGiocatore(g);
      },
      child: AnimatedTap(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ReportGiocatore(giocatore: g))
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 90,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF001D3D) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isTopPlayer
                  ? orangeAlcione.withOpacity(0.5)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!),
              width: isTopPlayer ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // LOGO IN BACKGROUND
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Opacity(
                    opacity: isDark ? 0.08 : 0.04,
                    child: Image.asset(
                      getLogoSquadra(g.squadra),
                      width: 100,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // 1. LOGO SQUADRA
                      Container(
                        width: 45, height: 45,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(getLogoSquadra(g.squadra)),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // INFO GIOCATORE
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  color: isDark ? Colors.white : blueAlcione,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${g.cognome.toUpperCase()} ',
                                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  ),
                                  TextSpan(
                                    text: g.nome,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: isDark ? Colors.white.withOpacity(0.6) : blueAlcione.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            // RIGA RUOLO + ANNO (BLINDATA)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: orangeAlcione.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        g.ruolo.toUpperCase(),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: orangeAlcione,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // L'anno ora rimane sempre incollato sulla stessa riga
                                Text(
                                  '  •  ${g.annoNascita}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 4), // Spazio minimo di sicurezza

                      // 3. IL VOTO (Fisso a destra)
                      _buildMiniScore(punteggio),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildMiniScore(double score) {
    if (score == 0) {
      return Container(
        width: 48, height: 38,
        decoration: BoxDecoration(
          // Grigio più leggero e moderno
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : (Colors.grey[50] ?? Colors.grey).withOpacity(0.8),
          borderRadius: BorderRadius.circular(14), // Più stondato (Apple Style)
        ),
        child: Icon(Icons.analytics_outlined, color: Colors.grey[400], size: 16),
      );
    }

    bool isTop = score >= 7.5;
    bool isGood = score >= 6.5 && score < 7.5;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 48,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), // Angoli più dolci
        gradient: isTop
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [orangeAlcione, const Color(0xFFFF8E4D)],
        )
            : null,
        color: isTop
            ? null
            : (isGood
            ? (isDark ? blueAlcione.withOpacity(0.4) : blueAlcione.withOpacity(0.08))
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100])),

        // IL TOCCO DI CLASSE: Un bordo sottile che dà profondità
        border: Border.all(
          color: isTop
              ? Colors.white.withOpacity(0.2) // Riflesso luce sul badge arancione
              : (isGood ? blueAlcione.withOpacity(0.15) : Colors.transparent),
          width: 1,
        ),

        // Ombra più ampia e sfumata (meno "macchia", più "elevazione")
        boxShadow: isTop ? [
          BoxShadow(
            color: orangeAlcione.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isTop)
            Positioned(
              top: 2, right: 2, // Spostata un filo per non toccare il bordo
              child: Icon(Icons.star_rounded, size: 10, color: Colors.white.withOpacity(0.5)),
            ),
          Text(
            score.toStringAsFixed(1),
            style: GoogleFonts.montserrat(
              color: isTop
                  ? Colors.white
                  : (isGood ? (isDark ? Colors.white : blueAlcione) : (isDark ? Colors.white70 : Colors.black87)),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: -0.5, // Testo più compatto = più professionale
            ),
          ),
        ],
      ),
    );
  }

  void _mostraFiltri() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return StreamBuilder<List<Giocatore>>(
            stream: service.streamGiocatori(),
            builder: (context, snapshot) {
              final tutti = snapshot.data ?? [];
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF001D3D) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.75,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (_, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(28, 20, 28, bottomPadding + 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 30),

                        Text('FILTRA TALENTI',
                            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : blueAlcione, letterSpacing: -0.5)),
                        const SizedBox(height: 35),

                        // RUOLO
                        _buildEliteFilterGroup('RUOLO', ['Portiere', 'Difensore', 'Centrocampista', 'Attaccante'], filtroRuolo, (v) {
                          setModalState(() => filtroRuolo = (filtroRuolo == v) ? null : v);
                          applicaFiltri(tutti);
                        }, Icons.directions_run_rounded),

                        // ANNATA
                        _buildEliteFilterGroup('ANNATA', List.generate(11, (i) => (2006 + i).toString()), filtroAnno?.toString(), (v) {
                          setModalState(() {
                            int annoScelto = int.parse(v);
                            filtroAnno = (filtroAnno == annoScelto) ? null : annoScelto;
                          });
                          applicaFiltri(tutti);
                        }, Icons.calendar_today_rounded),

                        // SQUADRA
                        _buildEliteFilterGroup('SQUADRA', squadre, filtroSquadra, (v) {
                          setModalState(() => filtroSquadra = (filtroSquadra == v) ? null : v);
                          applicaFiltri(tutti);
                        }, Icons.shield_rounded),

                        // NUOVA VALUTAZIONE TECNICA (Aggiunta qui)
                        _buildEliteFilterGroup(
                            'VALUTAZIONE TECNICA',
                            [
                              'NON ADATTO',
                              'DA VEDERE',
                              'DA MONITORARE',
                              'DA MONITORARE IN PROSPETTIVA',
                              'DA PRENDERE'
                            ],
                            filtroValutazione,
                                (v) {
                              setModalState(() => filtroValutazione = (filtroValutazione == v) ? null : v);
                              applicaFiltri(tutti);
                            },
                            Icons.manage_search_rounded
                        ),

                        const Divider(height: 40, color: Colors.white10),

                        // ORDINAMENTO (Ripristinato come lo avevi)
                        Text("ORDINAMENTO", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: orangeAlcione, letterSpacing: 1.5)),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            _buildSortPill(
                                label: ordinePunteggioDesc == null ? "PUNTEGGIO" : (ordinePunteggioDesc! ? "TOP SCORE" : "LOW SCORE"),
                                icon: Icons.star_rounded,
                                active: ordinePunteggioDesc != null,
                                onTap: () {
                                  setModalState(() {
                                    if (ordinePunteggioDesc == null) ordinePunteggioDesc = true;
                                    else if (ordinePunteggioDesc == true) ordinePunteggioDesc = false;
                                    else ordinePunteggioDesc = null;
                                  });
                                  applicaFiltri(tutti);
                                }
                            ),
                            const SizedBox(width: 10),
                            _buildSortPill(
                                label: ordineAlfabeticoAsc == null ? "A-Z" : (ordineAlfabeticoAsc! ? "A → Z" : "Z → A"),
                                icon: Icons.sort_by_alpha_rounded,
                                active: ordineAlfabeticoAsc != null,
                                onTap: () {
                                  setModalState(() {
                                    if (ordineAlfabeticoAsc == null) ordineAlfabeticoAsc = true;
                                    else if (ordineAlfabeticoAsc == true) ordineAlfabeticoAsc = false;
                                    else ordineAlfabeticoAsc = null;
                                  });
                                  applicaFiltri(tutti);
                                }
                            ),
                          ],
                        ),

                        const SizedBox(height: 50),

                        // TASTI AZIONE (Ripristinati)
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setModalState(() => resetFiltri(tutti));
                                  Navigator.pop(context);
                                },
                                child: Text("RESETTA", style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Container(
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(colors: [orangeAlcione, const Color(0xFFFF8E4D)]),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("APPLICA", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

// --- HELPER: GRUPPO FILTRI ELITE ---
  Widget _buildEliteFilterGroup(String title, List<String> items, String? selected, Function(String) onSelected, IconData icon) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: orangeAlcione),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[500], letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, i) {
              bool isSelected = items[i] == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(items[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? orangeAlcione : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? orangeAlcione : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(items[i],
                          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.white : (isDark ? Colors.white60 : blueAlcione))),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

// --- HELPER: PILLOLA ORDINAMENTO ---
  Widget _buildSortPill({required String label, required IconData icon, required bool active, required VoidCallback onTap}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? blueAlcione : (isDark ? Colors.white10 : Colors.grey[100]),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: active ? orangeAlcione : Colors.transparent, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? orangeAlcione : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: active ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterGroup(String title, List<String> items, String? selected, Function(String) onSelected) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 1.5)),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, i) {
              bool isSelected = items[i] == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(items[i]),
                  selected: isSelected,
                  onSelected: (_) => onSelected(items[i]),
                  selectedColor: orangeAlcione,
                  backgroundColor: isDark ? Colors.white10 : Colors.white,
                  labelStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : (isDark ? Colors.white70 : blueAlcione)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isSelected ? orangeAlcione : (isDark ? Colors.white10 : Colors.grey[200]!))),
                  elevation: 0,
                  pressElevation: 0,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: orangeAlcione),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
              Text(value, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : blueAlcione)),
            ],
          ),
        ],
      ),
    );

  }

}


class _StickyStatsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyStatsDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 35.0; // Altezza massima (sottilissima)
  @override
  double get minExtent => 35.0; // Altezza minima

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
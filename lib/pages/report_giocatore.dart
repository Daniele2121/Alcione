import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:alcione_scouting/models/giocatore.dart';
import 'package:alcione_scouting/models/report.dart';
import 'package:alcione_scouting/pages/crea_report.dart';
import 'package:alcione_scouting/utils/logo_utils.dart';
import 'package:alcione_scouting/services/pdf_report_service.dart';

class ReportGiocatore extends StatefulWidget {
  final Giocatore giocatore;
  const ReportGiocatore({super.key, required this.giocatore});

  @override
  State<ReportGiocatore> createState() => _ReportGiocatoreState();
}

class _ReportGiocatoreState extends State<ReportGiocatore> {
  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);
  final Color bgColor = const Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    final Report? report = widget.giocatore.report;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000814) : bgColor,
      body: report == null ? _emptyState() : _buildContent(report, isDark),
    );
  }

  Widget _buildContent(Report report, bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(report),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallScoreCard(report.totale, isDark),
                const SizedBox(height: 30),

                _sectionTitle("INFO ATLETA"),
                _buildInfoGrid(report, isDark),
                const SizedBox(height: 30),

                if (report.note != null && report.note!.isNotEmpty) ...[
                  _sectionTitle("ANALISI TECNICA"),
                  _buildNotesCard(report.note!, isDark),
                  const SizedBox(height: 30),
                ],

                _sectionTitle("VALUTAZIONI DETTAGLIATE"),
                _buildValutazioniList(report.valutazioni, isDark),

                // TASTO PDF AGGIUNTO IN FONDO
                const SizedBox(height: 60),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => PdfReportService.generaPdf(report),
                    icon: Icon(Icons.picture_as_pdf_rounded, color: orangeAlcione, size: 18),
                    label: Text(
                      "ESPORTA REPORT PDF",
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                          color: orangeAlcione,
                          fontSize: 11,
                          letterSpacing: 1.1
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: orangeAlcione.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(Report report) {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: blueAlcione,
      leading: const BackButton(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
          onPressed: () => _modificaReport(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12, right: 16),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final double appBarHeight = constraints.biggest.height;
            final bool isCollapsed = appBarHeight <= kToolbarHeight + MediaQuery.of(context).padding.top + 15;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.only(left: isCollapsed ? 35 : 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            report.ruoloSpecifico.toUpperCase(),
                            style: GoogleFonts.montserrat(
                                color: orangeAlcione,
                                fontWeight: FontWeight.w900,
                                fontSize: 7,
                                letterSpacing: 1.2
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "• ${report.annoreport}",
                        style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w700,
                            fontSize: 7
                        ),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${report.cognomereport} ${report.nomereport}".toUpperCase(),
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: -0.5
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: blueAlcione),
            Positioned(
              right: -40,
              top: -20,
              child: Opacity(
                opacity: 0.15,
                child: Transform.rotate(
                  angle: -0.15,
                  child: Image.asset(
                    getLogoSquadra(report.squadrareport),
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScoreCard(int totale, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF001D3D) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("RANKING SCORE", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400])),
              const SizedBox(height: 4),
              Text("$totale", style: GoogleFonts.montserrat(fontSize: 42, fontWeight: FontWeight.w900, color: isDark ? Colors.white : blueAlcione)),
              Text("MAX 24", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: orangeAlcione)),
            ],
          ),
          _buildMiniCircularProgress(totale, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Report report, bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _infoTile(Icons.shield_outlined, "Squadra", report.squadrareport, isDark),
        _infoTile(Icons.cake_outlined, "Anno", report.annoreport.toString(), isDark),
        _infoTile(Icons.directions_run_rounded, "Piede", report.piede, isDark),
        _infoTile(Icons.fitness_center_rounded, "Struttura", report.costituzione, isDark),
        _infoTile(Icons.flash_on_rounded, "Fisico", report.fisico, isDark),
        _infoTile(Icons.person_pin_outlined, "Scout", report.segnalatore, isDark),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value, bool isDark) {
    final width = (MediaQuery.of(context).size.width - 50) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF001D3D) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent)
      ),
      child: Row(
        children: [
          Icon(icon, color: orangeAlcione, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: GoogleFonts.montserrat(fontSize: 7, color: Colors.grey[500], fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : blueAlcione
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildValutazioniList(Map<String, int> vals, bool isDark) {
    final orderedKeys = ['Struttura', 'Tecnica', 'Tattica', 'Velocità', 'Personalità', 'Comportamento', 'Potenziale'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF001D3D) : Colors.white,
          borderRadius: BorderRadius.circular(25)
      ),
      child: Column(
        children: orderedKeys.map((key) {
          final value = vals[key] ?? -1;
          double progress = value == -1 ? 0 : (value / 3.0).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _iconForCategory(key),
                        const SizedBox(width: 10),
                        Text(key.toUpperCase(),
                            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : blueAlcione)),
                      ],
                    ),
                    Text(
                      key == 'Potenziale'
                          ? (value == -1 ? "N.C." : "${value * 2}/6")
                          : (value == -1 ? "N.C." : "$value/3"),
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: orangeAlcione, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : bgColor, borderRadius: BorderRadius.circular(10)),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      height: 4,
                      width: (MediaQuery.of(context).size.width - 80) * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [orangeAlcione, const Color(0xFFFF8E4D)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesCard(String note, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF001D3D) : Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(note,
          style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : blueAlcione.withOpacity(0.9),
              fontWeight: FontWeight.w500
          )
      ),
    );
  }

  Widget _buildMiniCircularProgress(int totale, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70, height: 70,
          child: CircularProgressIndicator(
            value: (totale / 24).clamp(0.0, 1.0),
            strokeWidth: 8,
            backgroundColor: isDark ? Colors.white10 : bgColor,
            color: orangeAlcione,
            strokeCap: StrokeCap.round,
          ),
        ),
        Icon(Icons.bolt_rounded, color: orangeAlcione, size: 28),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12),
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1.5)),
    );
  }

  Icon _iconForCategory(String category) {
    IconData icon;
    switch (category) {
      case 'Struttura': icon = Icons.fitness_center_rounded; break;
      case 'Tecnica': icon = Icons.star_border_rounded; break;
      case 'Tattica': icon = Icons.grid_view_rounded; break;
      case 'Velocità': icon = Icons.bolt_rounded; break;
      case 'Personalità': icon = Icons.military_tech_rounded; break;
      case 'Comportamento': icon = Icons.gavel_rounded; break;
      case 'Potenziale': icon = Icons.trending_up_rounded; break;
      default: icon = Icons.check_circle_outline_rounded;
    }
    return Icon(icon, color: orangeAlcione, size: 22);
  }

  // --- STATO VUOTO "ANALISI RICHIESTA" ORIGINALE ---
  Widget _emptyState() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000814) : bgColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: BackButton(color: isDark ? Colors.white : blueAlcione)),
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: orangeAlcione.withOpacity(isDark ? 0.08 : 0.05)),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 140, height: 140, decoration: BoxDecoration(color: orangeAlcione.withOpacity(0.05), shape: BoxShape.circle)),
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(color: orangeAlcione.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: orangeAlcione.withOpacity(0.1), width: 1)),
                      child: Icon(Icons.add_chart_rounded, size: 60, color: orangeAlcione),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Text(
                  "Analisi Richiesta",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : blueAlcione,
                      letterSpacing: -1.5
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Non è presente alcun report per questo profilo. Crea ora la prima scheda tecnica.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      color: Colors.grey[500],
                      height: 1.5,
                      fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: () => _modificaReport(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    decoration: BoxDecoration(
                        color: orangeAlcione,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: orangeAlcione.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          "CREA REPORT",
                          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _modificaReport() async {
    final nuovo = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreaReportPage(giocatore: widget.giocatore)));
    if (nuovo != null) setState(() { widget.giocatore.report = nuovo; });
  }
}
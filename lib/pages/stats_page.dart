import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Color orangeAlcione = const Color(0xFFFF6600);
  final Color blueAlcione = const Color(0xFF001D3D);
  final Color bgColor = const Color(0xFFF5F5F7);

  final List<String> annate = ["2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016"];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000814) : bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text("ALCIONE ANALYTICS",
            style: GoogleFonts.montserrat(
                color: isDark ? Colors.white : blueAlcione,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 4
            )),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // APPLE GLOW BACKGROUND
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orangeAlcione.withOpacity(isDark ? 0.08 : 0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('giocatori').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Errore"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return Column(
                  children: [
                    _buildModernIndicator(),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: annate.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, index) {
                          final data = _processData(docs, annate[index]);
                          return _DashboardView(data: data, orange: orangeAlcione, blue: blueAlcione);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _processData(List<QueryDocumentSnapshot> docs, String anno) {
    var tuttiAnnata = docs.where((d) => (d.data() as Map)['annoNascita'].toString() == anno).toList();
    if (tuttiAnnata.isEmpty) return {"year": anno, "isEmpty": true};

    int att = tuttiAnnata.where((g) => (g.data() as Map)['ruolo'] == 'Attaccante').length;
    int cen = tuttiAnnata.where((g) => (g.data() as Map)['ruolo'] == 'Centrocampista').length;
    int difPor = tuttiAnnata.where((g) => ['Difensore', 'Portiere'].contains((g.data() as Map)['ruolo'])).length;

    Map<String, int> squadreMap = {};
    for (var doc in tuttiAnnata) {
      String s = (doc.data() as Map)['squadra'] ?? "Sconosciuta";
      squadreMap[s] = (squadreMap[s] ?? 0) + 1;
    }
    var sortedTeams = squadreMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var topTeam = sortedTeams.isNotEmpty ? sortedTeams.first : MapEntry("Nessuna", 0);

    Map<String, int> obsMap = {};
    for (var doc in tuttiAnnata) {
      String obs = (doc.data() as Map)['segnalatore'] ?? "N.C.";
      obsMap[obs] = (obsMap[obs] ?? 0) + 1;
    }
    var sortedObs = obsMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    var conVoto = tuttiAnnata.where((d) {
      var map = d.data() as Map;
      return map.containsKey('report') && map['report'] != null;
    }).toList();

    conVoto.sort((a, b) => ((b.data() as Map)['report']['totale'] as num).compareTo((a.data() as Map)['report']['totale'] as num));

    List<Map<String, String>> top3 = conVoto.take(3).map((g) {
      final d = g.data() as Map;
      return {"n": (d['cognome'] ?? "-").toString(), "v": (d['report']['totale'] as num).toStringAsFixed(0)};
    }).toList();

    return {
      "year": anno, "roles": [att.toDouble(), cen.toDouble(), difPor.toDouble()],
      "count": tuttiAnnata.length, "topTeam": topTeam.key, "topTeamCount": topTeam.value,
      "observers": sortedObs, "top3": top3, "isEmpty": false,
    };
  }

  Widget _buildModernIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(annate.length, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 3, width: _currentPage == i ? 20 : 3,
          decoration: BoxDecoration(
              color: _currentPage == i ? orangeAlcione : blueAlcione.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)
          ),
        )),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color orange, blue;

  const _DashboardView({required this.data, required this.orange, required this.blue});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // EMPTY STATE PERSONALIZZATO PER ANNATA
    if (data['isEmpty'] == true) return _buildEmptyState(context, data['year']);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ANNATA", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: orange, letterSpacing: 2)),
              Text("${data['year']}",
                  style: GoogleFonts.montserrat(
                      fontSize: 58, fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : blue,
                      letterSpacing: -4, height: 0.9
                  )),
            ],
          ),
          const SizedBox(height: 35),
          _buildVolumeHero(context),
          const SizedBox(height: 35),
          _sectionTitle("BILANCIAMENTO RUOLI"),
          _buildHeroPie(context),
          const SizedBox(height: 35),
          _sectionTitle("TARGET ANALYSIS"),
          _buildDetailCard(context, Icons.shield_rounded, "CLUB PIÙ OSSERVATO", data['topTeam'].toString().toUpperCase(), orange, sub: "${data['topTeamCount']} ATLETI SEGNALATI"),
          const SizedBox(height: 35),
          _sectionTitle("TOP OSSERVATORI"),
          _buildObserversSection(context),
          const SizedBox(height: 35),
          _sectionTitle("LEADERBOARD REPORT"),
          _buildTopPerformanceList(context),
        ],
      ),
    );
  }

  Widget _buildVolumeHero(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF001D3D), const Color(0xFF001226)]
                : [Colors.white, const Color(0xFFF8F9FA)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SCOUTING VOLUME", style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: orange, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text("Segnalazioni totali", style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            ],
          ),
          Text("${data['count']}", style: GoogleFonts.montserrat(fontSize: 52, fontWeight: FontWeight.w900, color: isDark ? Colors.white : blue, letterSpacing: -3)),
        ],
      ),
    );
  }

  Widget _buildHeroPie(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    double total = data['roles'][0] + data['roles'][1] + data['roles'][2];
    String getPerc(int i) => total > 0 ? "${((data['roles'][i] / total) * 100).toStringAsFixed(0)}%" : "0%";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF001D3D) : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 1,
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 45,
                sections: [
                  PieChartSectionData(value: data['roles'][0], color: orange, radius: 7, showTitle: false),
                  PieChartSectionData(value: data['roles'][1], color: isDark ? Colors.white : blue, radius: 7, showTitle: false),
                  PieChartSectionData(value: data['roles'][2], color: Colors.grey[400]!, radius: 7, showTitle: false),
                ],
              )),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _legendItem("ATT", getPerc(0), orange),
                const SizedBox(height: 12),
                _legendItem("CEN", getPerc(1), isDark ? Colors.white : blue),
                const SizedBox(height: 12),
                _legendItem("DIF/PT", getPerc(2), Colors.grey[400]!),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _legendItem(String label, String perc, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[500])),
        ]),
        Text(perc, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildObserversSection(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<MapEntry<String, int>> obs = data['observers'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF001D3D) : Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: obs.take(3).map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key.toUpperCase(), style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800)),
                Text("${e.value}", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: orange)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                    value: data['count'] > 0 ? e.value / data['count'] : 0,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F5F7),
                    color: orange, minHeight: 4
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTopPerformanceList(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    List top3 = data['top3'] ?? [];
    return Column(
      children: top3.asMap().entries.map((entry) {
        bool isFirst = entry.key == 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
              color: isFirst ? orange : (isDark ? const Color(0xFF001D3D) : Colors.white),
              borderRadius: BorderRadius.circular(22),
              boxShadow: isFirst ? [BoxShadow(color: orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))] : []
          ),
          child: Row(
            children: [
              Text("${entry.key + 1}", style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: isFirst ? Colors.white : orange, fontSize: 16)),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  entry.value['n'].toUpperCase(),
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w900,
                      color: isFirst ? Colors.white : (isDark ? Colors.white : blue),
                      fontSize: 13,
                      height: 1.1
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 10),
              Text(entry.value['v'], style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, color: isFirst ? Colors.white : orange, fontSize: 24, letterSpacing: -1)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailCard(BuildContext context, IconData icon, String label, String value, Color color, {String? sub}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF001D3D) : Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: orange, size: 24)
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : blue,
                    height: 1.1
                ),
                softWrap: true,
                maxLines: 2,
              ),
              if(sub != null) ...[
                const SizedBox(height: 2),
                Text(sub, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: orange)),
              ]
            ]),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 2)),
    );
  }

  // --- MODIFICA RICHIESTA: EMPTY STATE CON ANNATA DINAMICA ---
  Widget _buildEmptyState(BuildContext context, String year) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              Icons.analytics_outlined,
              size: 60,
              color: isDark ? Colors.white.withOpacity(0.1) : blue.withOpacity(0.1)
          ),
          const SizedBox(height: 20),
          Text(
              "NESSUN DATO PER L'ANNATA $year",
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[400],
                  fontSize: 11,
                  letterSpacing: 1.2
              )
          ),
        ],
      ),
    );
  }
}
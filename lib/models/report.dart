// lib/models/report.dart
class Report {
  String nomereport;
  String cognomereport;
  int annoreport;
  String squadrareport;
  String piede;
  String ruoloSpecifico;
  String fisico;
  String costituzione;
  String segnalatore;
  Map<String, int> valutazioni;
  String? note;
  int totale;

  Report({
    required this.nomereport,
    required this.cognomereport,
    required this.annoreport,
    required this.squadrareport,
    required this.piede,
    required this.ruoloSpecifico,
    required this.fisico,
    required this.costituzione,
    required this.segnalatore,
    required this.valutazioni,
    this.note,
    required this.totale,
  });

  // Metodo per convertire da mappa (Firebase) a oggetto Report
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      nomereport: map['nomereport'] ?? '',
      cognomereport: map['cognomereport'] ?? '',
      annoreport: map['annoreport'] ?? 0,
      squadrareport: map['squadrareport'] ?? '',
      piede: map['piede'] ?? '',
      ruoloSpecifico: map['ruoloSpecifico'] ?? '',
      fisico: map['fisico'] ?? '',
      costituzione: map['costituzione'] ?? '',
      segnalatore: map['segnalatore'] ?? '',
      valutazioni: Map<String, int>.from(map['valutazioni'] ?? {}),
      note: map['note'],
      totale: map['totale'] ?? 0,
    );
  }

  // Metodo per convertire l'oggetto Report in mappa (per salvare su Firebase)
  Map<String, dynamic> toMap() {
    return {
      'nomereport': nomereport,
      'cognomereport': cognomereport,
      'annoreport': annoreport,
      'squadrareport': squadrareport,
      'piede': piede,
      'ruoloSpecifico': ruoloSpecifico,
      'fisico': fisico,
      'costituzione': costituzione,
      'segnalatore': segnalatore,
      'valutazioni': valutazioni,
      'note': note,
      'totale': totale,
    };
  }
}

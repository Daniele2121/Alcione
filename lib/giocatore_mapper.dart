// lib/giocatore_mapper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/giocatore.dart';
import '../models/report.dart';

class GiocatoreMapper {
  static Map<String, dynamic> toMap(Giocatore g) {
    return {
      'nome': g.nome,
      'cognome': g.cognome,
      'annoNascita': g.annoNascita,
      'ruolo': g.ruolo,
      'squadra': g.squadra,
      'segnalatore': g.segnalatore,
      'dataPartita': Timestamp.fromDate(g.dataPartita),
      'partitaVisionata': g.partitaVisionata,
      'report': g.report != null ? _reportToMap(g.report!) : null,
    };
  }

  static Giocatore fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return Giocatore(
      id: doc.id,
      nome: d['nome'],
      cognome: d['cognome'],
      annoNascita: d['annoNascita'],
      ruolo: d['ruolo'],
      squadra: d['squadra'],
      segnalatore: d['segnalatore'],
      dataPartita: (d['dataPartita'] as Timestamp).toDate(),
      partitaVisionata: d['partitaVisionata'],
      report: d['report'] != null ? _reportFromMap(d['report']) : null,
    );
  }

  static Map<String, dynamic> _reportToMap(Report r) => {
    'nomereport': r.nomereport,
    'cognomereport': r.cognomereport,
    'annoreport': r.annoreport,
    'squadrareport': r.squadrareport,
    'piede': r.piede,
    'ruoloSpecifico': r.ruoloSpecifico,
    'fisico': r.fisico,
    'costituzione': r.costituzione,
    'segnalatore': r.segnalatore,
    'note': r.note,
    'valutazioni': r.valutazioni,
    'totale': r.totale,
  };

  static Report _reportFromMap(Map<String, dynamic> m) => Report(
    nomereport: m['nomereport'],
    cognomereport: m['cognomereport'],
    annoreport: m['annoreport'],
    squadrareport: m['squadrareport'],
    piede: m['piede'],
    ruoloSpecifico: m['ruoloSpecifico'],
    fisico: m['fisico'],
    costituzione: m['costituzione'],
    segnalatore: m['segnalatore'],
    note: m['note'],
    valutazioni: Map<String, int>.from(m['valutazioni']),
    totale: m['totale'],
  );
}

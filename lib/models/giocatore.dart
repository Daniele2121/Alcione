import 'package:cloud_firestore/cloud_firestore.dart';
import 'report.dart';

class Giocatore {
  final String id;
  final String nome;
  final String cognome;
  final int annoNascita;
  final String ruolo;
  final String? ruoloSpecifico; // <--- AGGIUNTO
  final String squadra;
  final String? logoSquadra;
  final String segnalatore;
  final DateTime dataPartita;
  final String partitaVisionata;
  Report? report;

  Giocatore({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.annoNascita,
    required this.ruolo,
    this.ruoloSpecifico, // <--- AGGIUNTO
    required this.squadra,
    this.logoSquadra,
    required this.segnalatore,
    required this.dataPartita,
    required this.partitaVisionata,
    this.report,
  });

  factory Giocatore.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Giocatore(
      id: doc.id,
      nome: data['nome'] ?? '',
      cognome: data['cognome'] ?? '',
      annoNascita: data['annoNascita'] ?? 0,
      ruolo: data['ruolo'] ?? '',
      // Se il campo non esiste nel vecchio DB, mettiamo una stringa vuota
      ruoloSpecifico: data['ruoloSpecifico'] ?? '',
      squadra: data['squadra'] ?? '',
      logoSquadra: data['logoSquadra'] ?? data['urlLogo'] ?? data['logo'],
      segnalatore: data['segnalatore'] ?? '',
      dataPartita: data['dataPartita'] != null
          ? (data['dataPartita'] as Timestamp).toDate()
          : DateTime.now(),
      partitaVisionata: data['partitaVisionata'] ?? '',
      report: data['report'] != null
          ? Report.fromMap(Map<String, dynamic>.from(data['report']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cognome': cognome,
      'annoNascita': annoNascita,
      'ruolo': ruolo,
      'ruoloSpecifico': ruoloSpecifico, // <--- AGGIUNTO
      'squadra': squadra,
      'logoSquadra': logoSquadra,
      'segnalatore': segnalatore,
      'dataPartita': Timestamp.fromDate(dataPartita),
      'partitaVisionata': partitaVisionata,
      'report': report?.toMap(),
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/giocatore.dart';
import '../giocatore_mapper.dart'; // Assicurati che il percorso sia corretto

class GiocatoriService {
  final _db = FirebaseFirestore.instance;
  final _col = FirebaseFirestore.instance.collection('giocatori');

  // STREAM IN TEMPO REALE
  Stream<List<Giocatore>> streamGiocatori() {
    return _col
        .orderBy('dataPartita', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => GiocatoreMapper.fromDoc(doc)).toList());
  }

  // AGGIUNGI GIOCATORE
  Future<void> aggiungi(Giocatore g) async {
    await _col.add(GiocatoreMapper.toMap(g));
  }

  // AGGIORNA GIOCATORE
  Future<void> aggiorna(String id, Giocatore g) async {
    await _col.doc(id).update(GiocatoreMapper.toMap(g));
  }

  // ELIMINA GIOCATORE
  Future<void> elimina(String id) async {
    await _col.doc(id).delete();
  }
}

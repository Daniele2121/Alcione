import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/giocatore.dart';
import 'giocatore_mapper.dart';

class GiocatoriRepository {
  final _ref = FirebaseFirestore.instance.collection('giocatori');

  Stream<List<Giocatore>> streamGiocatori() {
    return _ref
        .orderBy('dataPartita', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(GiocatoreMapper.fromDoc).toList());
  }

  Future<void> add(Giocatore g) =>
      _ref.add(GiocatoreMapper.toMap(g)); // ✅ qui

  Future<void> update(String id, Giocatore g) =>
      _ref.doc(id).update(GiocatoreMapper.toMap(g)); // ✅ qui

  Future<void> delete(String id) =>
      _ref.doc(id).delete();
}

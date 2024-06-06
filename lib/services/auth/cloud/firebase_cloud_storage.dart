import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/auth/cloud/cloud_note.dart';
import 'package:mynotes/services/auth/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/auth/cloud/cloud_storage_exceptions.dart';

class FireBaseCloudStorage {
  static final FireBaseCloudStorage _shared = FireBaseCloudStorage._sharedInstance();
  FireBaseCloudStorage._sharedInstance();
  factory FireBaseCloudStorage() => _shared;

  final notes = FirebaseFirestore.instance.collection('notes');
 

  Future<CloudNote> createNewNote({required String ownerID}) async {
    final document = await notes.add({
      ownerUserIdFieldName: ownerID,
      textFieldName: '',
    });
    final fetchedNote = await document.get();
    return CloudNote(fetchedNote.id, ownerID, '');
  }
  
Future<Iterable<CloudNote>> getNotes({required String ownerID}) async {
  try {
    final querySnapshot = await notes.where(
      ownerUserIdFieldName,
      isEqualTo: ownerID
    ).get();
    
    return querySnapshot.docs.map((doc) => CloudNote.fromSnapshot(doc));
  } catch (e) {
    throw CouldNotGetAllNotesException();
  }
}


  Future<void> deleteNote({
    required String docId
  }) async {
    try {
      await notes.doc(docId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<void> updateNote({
    required String docId,
    required String text,
  }) async {
    try {
      notes.doc(docId).update({textFieldName: text});
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Stream<Iterable<CloudNote>> allNotes({required String ownerID}) {
  return notes.snapshots().map((snapshot) => snapshot.docs
    .map((doc) => CloudNote.fromSnapshot(doc))
    .where((note) => note.ownerId == ownerID));
}

}
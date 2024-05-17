import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynotes/services/auth/cloud/cloud_note.dart';
import 'package:mynotes/services/auth/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/auth/cloud/cloud_storage_exceptions.dart';

class FireBaseCloudStorage {
  static final FireBaseCloudStorage _shared = FireBaseCloudStorage._sharedInstance();
  FireBaseCloudStorage._sharedInstance();
  factory FireBaseCloudStorage() => _shared;

  final notes = FirebaseFirestore.instance.collection('notes');
 

  void createNewNote({required String ownerID}) async {
    notes .add({
      ownerUserIdFieldName: ownerID,
      textFieldName: '',
    });
  }
  
  Future<Iterable<CloudNote>> getAllNotes({required String ownerID}) async {
    try {
      await notes.where(
        ownerUserIdFieldName,
        isEqualTo: ownerID, 
      ).get()
      .then((value) => value.docs.map(doc) {
      }
      )
    } catch CouldNotGetAllNotesException() {

    }
  } 
}
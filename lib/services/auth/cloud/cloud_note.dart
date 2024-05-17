import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mynotes/services/auth/cloud/cloud_storage_constants.dart';

@immutable
class CloudNote {
  final String documentId;
  final String ownerId;
  final String text;

  const CloudNote (
    this.documentId, 
    this.ownerId,
    this.text
  );
  
  CloudNote.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot):
    documentId = snapshot.id,
    ownerId = snapshot.data()[ownerUserIdFieldName],
    text = snapshot.data()[textFieldName];
}
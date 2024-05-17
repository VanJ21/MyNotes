class CloudStorageException implements Exception {
  const CloudStorageException();
}

// Create (C)
class CouldNotCreateNoteException extends CloudStorageException {}

// Read (R)
class CouldNotGetAllNotesException extends CloudStorageException {}

// Update (U)
class CouldNotUpdateNoteException extends CloudStorageException {}

// Delete (D)
class CouldNotDeleteNoteException extends CloudStorageException {}
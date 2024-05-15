import 'dart:async';
import 'package:mynotes/extensions/list/filter.dart';
import 'package:mynotes/services/auth/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart' show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqlite_api.dart';

class NotesService {
  Database? _db;

  static final NotesService _shared = NotesService._sharedInstance();

  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      }
    );
  }
  
  factory NotesService() => _shared;

  DatabaseUser? _user;

  List<DatabaseNote> _notes = []; 
  late final StreamController<List<DatabaseNote>> _notesStreamController;

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream.filter((note) {
    final currentUser = _user;
    if (currentUser != null) {
      return note.userId == currentUser.id;
    } else {
      throw UserSetBeforeReading();
    }
  });

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final results = await db.query(userTable, 
      limit: 1, 
      where: 'email = ?', 
      whereArgs: [email.toLowerCase()]);

    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase()
    });

    return DatabaseUser(id:userId, email:email);
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(userTable, 
      limit: 1, 
      where: 'email = ?', 
      whereArgs: [email.toLowerCase()]);

    if (results.isEmpty) {
      throw CouldNotFindUserException();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }
  
  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(userTable, 
      where: 'email = ?', 
      whereArgs: [email.toLowerCase()]);

    if (deletedCount != 1) {
      throw CouldNotDeleteUserException();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DataBaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DataBaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DataBaseAlreadyOpenException();
    }

    try {
      final docsPath = await getApplicationDocumentsDirectory(); 
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      await db.execute(createUserTable);
      await db.execute(createNotesTable);
      await _cacheNotes();

    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }

  Future<DatabaseNote> createNote({
    required DatabaseUser owner,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // Ensure the owner exists in the database
    final dbUser = await getUser(email: owner.email);
    if (dbUser.id != owner.id) {
      throw CouldNotFindUserException();
    }

    const text = '';
    final noteId = await db.insert(noteTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedColumn: 1,
    });

    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSynced: true,
    );

    _notes.add(note);

    _notesStreamController.add(_notes);

    return note;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id]);

    if (deletedCount == 0) {
      throw CouldNotDeleteNoteException();
    } else {
      _notes.removeWhere((note) => note.id == id);
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numDelete = await db.delete(noteTable);

    _notes = [];
    _notesStreamController.add(_notes);
    return numDelete;
  }

  Future<DatabaseNote> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable, limit: 1, where: 'id = ?', whereArgs: [id]);

    if (notes.isEmpty) {
      throw CouldNotFindNoteException();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((note) => id == note.id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<List<DatabaseNote>> getAllNotes() async {
  await _ensureDbIsOpen();
  final db = _getDatabaseOrThrow();
  final notes = await db.query(noteTable);

  return notes.map((noteRow) => DatabaseNote.fromRow(noteRow)).toList();
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    await getNote(id: note.id);

    final updatesCount = await db.update(noteTable, {
      textColumn: text,
      isSyncedColumn: 0,
    }, where: 'id = ?',
       whereArgs: [note.id],);

    if (updatesCount == 0) {
      throw CouldNotUpdateException();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((updatedNote) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();

    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseUser> getOrCreateUser({required String email, bool setAsCurrentUser = true})  async{
    await _ensureDbIsOpen();
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CouldNotFindUserException {
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  } 

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DataBaseAlreadyOpenException {
      // do nothing
    }
  }
}



 

class DatabaseUser {
  final int id;
  final String email;

  DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object?> map) 
    : id = map[idColumn] as int,
      email = map[emailColumn] as String;

  @override
  String toString() => 'User, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSynced;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSynced,
  });

  DatabaseNote.fromRow(Map<String, Object?> map) 
    : id = map[idColumn] as int,
      userId = map[userIdColumn] as int,
      text = map[textColumn] as String,
      isSynced = (map[isSyncedColumn] as int) == 1;

  @override
  String toString() => 'Note, ID = $id, userId = $userId, text = $text, isSynced = $isSynced';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedColumn = 'is_synced';

const createNotesTable = '''CREATE TABLE IF NOT EXISTS "note" (
  "id" INTEGER NOT NULL,
  "user_id" INTEGER NOT NULL,
  "text" TEXT,
  "is_synced" INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY("user_id") REFERENCES "user"("id"),
  PRIMARY KEY("id" AUTOINCREMENT)
);''';

const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
  "id" INTEGER NOT NULL,
  "email" TEXT NOT NULL UNIQUE,
  PRIMARY KEY("id" AUTOINCREMENT)
);''';

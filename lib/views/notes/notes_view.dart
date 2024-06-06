import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/cloud/cloud_note.dart';
import 'package:mynotes/services/auth/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/logout_dialog.dart';
import 'package:mynotes/views/notes/notes_list_views.dart';

enum MenuAction {logout}
class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}
class _NotesViewState extends State<NotesView> {

  String get userId => AuthService.firebase().currentUser!.id;
  late final FireBaseCloudStorage _notesService;

  @override
  void initState() {
    _notesService = FireBaseCloudStorage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Notes'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdateNoteRoute);
            }, 
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async{
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    context.read<AuthBloc>().add(
                      const AuthEventLogOut(),
                    );
                  }
              }
            },
            itemBuilder: (context) {
              return [
              const PopupMenuItem(
                value: MenuAction.logout,
                child: Text('Logout'),
              ),
              ];
            },
          )
        ],
      ),
      body: StreamBuilder(
                stream: _notesService.allNotes(ownerID: userId),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      if (snapshot.hasData) {
                        final allNotes = snapshot.data as Iterable<CloudNote>;
                        return NotesListView(
                          notes: allNotes, 
                          onDeleteNote: (note) async {
                            await _notesService.deleteNote(docId: note.documentId);
                          },
                          onTap: (note) {
                            Navigator.of(context).pushNamed(createOrUpdateNoteRoute, arguments: note);
                          });
                      } else {
                        return const CircularProgressIndicator();
                      }
                    default:
                      return const CircularProgressIndicator();
                  }
                }
              )
    );
  }
}


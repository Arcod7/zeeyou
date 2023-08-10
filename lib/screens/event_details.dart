import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:zeeyou/models/event.dart';
import 'package:zeeyou/screens/users_list.dart';
import 'package:zeeyou/screens/chat.dart';
import 'package:zeeyou/tools/sesson_manager.dart';
import 'package:zeeyou/widgets/event_details/event_deails_header.dart';

class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    List<String>? userList;
    Future<void> getUserList() async {
      final eventData = await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .get();
      userList = List.castFrom(eventData.data()!['user_list'] as List);
    }

    Future<String> getUserNamesFromSet(Set<String> userIds) async {
      final usernamesList = await Future.wait(
          userIds.map((userId) async => await getUsername(userId)));
      return usernamesList.join(', ');
    }

    void showSnackBarUserAdded(Set<String> userIds, String lastWord) async {
      final usernames = await getUserNamesFromSet(userIds);
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$usernames $lastWord')));
      }
    }

    getUserList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: event.lightColor,
        actions: [
          IconButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('events')
                  .doc(event.id)
                  .delete();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
          ),
          PopupMenuButton(
            itemBuilder: (ctx) => [
              PopupMenuItem(child: const Text('Donate ?'), onTap: () {}),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Expanded(
          child: Container(
            color: event.lightColor,
            width: double.infinity,
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(44)),
                color: Theme.of(context).colorScheme.background,
              ),
              child: Column(
                children: [
                  EventDetailsHeader(event: event),
                  ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(event.lightColor),
                      foregroundColor: MaterialStateProperty.all(event.color),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ChatScreen(
                            chatType: 'event_chat',
                            chatId: event.id,
                            title: event.title,
                          ),
                        ),
                      );
                    },
                    icon: Icon(MdiIcons.chat),
                    label: const Text('Messages'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final userIds = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => UsersListScreen(
                                title: 'Add users to your event !',
                                filterNotIn: userList,
                              ),
                            ),
                          );
                          await FirebaseFirestore.instance
                              .collection('events')
                              .doc(event.id)
                              .update({
                            "user_list": FieldValue.arrayUnion(userIds.toList())
                          });
                          getUserList();
                          showSnackBarUserAdded(userIds, 'added');
                        },
                        child: const Text('Add users'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final userIds = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) {
                                return UsersListScreen(
                                  title: 'Remove users to your event',
                                  filterIn: userList,
                                );
                              },
                            ),
                          );
                          await FirebaseFirestore.instance
                              .collection('events')
                              .doc(event.id)
                              .update({
                            "user_list":
                                FieldValue.arrayRemove(userIds.toList())
                          });
                          getUserList();
                          showSnackBarUserAdded(userIds, 'removed');
                        },
                        child: const Text('Remove users'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

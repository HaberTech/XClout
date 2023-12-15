import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:xclout/backend/main_api.dart';
import 'package:xclout/backend/widgets.dart';

// Main Chats Home Page
class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Handle search here...
              },
            ),
          ),
        ),
      ),
      body: const ChatsList(),
    );
  }
}

class ChatsList extends StatefulWidget {
  const ChatsList({super.key});

  @override
  State<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> {
  @override
  void initState() {
    super.initState();
    // Set current screen for analytics
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'chats_screen');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getChatList(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // If snapshot has no data
            return const CircularProgressIndicator();
            // NO DATA
          } else {
            // Snapshot has data -- Chats loaded
            List<dynamic> contacts = jsonDecode(snapshot.data.toString());

            // If contacts is empty, show a message
            if (contacts.isEmpty) {
              return const Center(
                child: Text(
                    'No chats available. This works.. Message your friends to get started\n How about joining your class group?'),
              );
            }

            return ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (BuildContext context, int index) {
                Map contact = contacts[index];
                Map<String, dynamic> otherUser = contact['OtherUser'];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        NetworkImage(otherUser['ProfilePicture'].toString()),
                  ),
                  title: UserNameAndPost(user: otherUser),
                  subtitle: Text(
                    contact['Message'].toString(),
                    style: TextStyle(
                        color: ((contact['IsRead'] as int) == 1)
                            ? Colors.grey
                            : Colors.white),
                  ),
                  // trailing: Text("Time"),
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (BuildContext context) => ChatScreen(
                        receiverId: otherUser['UserId'],
                        userDetails: otherUser),
                  )),
                );
              },
            );
          }
        });
  }
}

Future<String> _getChatList() {
  return MainApiCall()
      .callEndpoint(endpoint: 'getConversation', fields: {'type': 'list'});
}

class ChatScreen extends StatelessWidget {
  final int receiverId;
  final Map<String, dynamic> userDetails;

  const ChatScreen(
      {super.key, required this.receiverId, required this.userDetails});

  @override
  Widget build(BuildContext context) {
    // Individual chat between two users
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            chatScreenHeader(),
            Expanded(
              child: ChatScreenBody(between: receiverId),
            ),
            chatScreenFooter(context),
          ],
        ),
      ),
    );
  }

  ListTile chatScreenHeader() {
    return ListTile(
      leading: CircleAvatar(
          backgroundImage: NetworkImage(
        userDetails['ProfilePicture'].toString(),
      )),
      title: UserNameAndPost(user: userDetails),
      subtitle: const Text(
        "Hmmmm",
        style: TextStyle(color: Color.fromARGB(255, 144, 136, 136)),
      ),
    );
  }

  // SEND MESSAGES BAR
  Widget chatScreenFooter(BuildContext context) {
    print({
      'type': 'direct',
      'receiverId': receiverId.toString(),
    });
    final TextEditingController message = TextEditingController();
    // SEND MESSAGES BAR
    return Container(
      padding: const EdgeInsets.all(10),
      child: Card(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  maxLines:
                      null, // this allows the TextField to expand as the user types
                  controller: message,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(10),
                    hintText: "Type a message",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                // SEND MESSAGE
                _sendMessage(message, context);
              },
              icon: const Icon(
                Icons.send,
                size: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(TextEditingController message, BuildContext context) {
    MainApiCall().callPostEndpoint(endpoint: 'sendMessage', fields: {
      'type': 'direct',
      'receiverId': receiverId.toString(),
      'message': message.text,
    }).then(
      (response) => () {
        print('It is NOOOW');
        print(response.body);
        if (response.body == 'Success') {
          // refresh page
          Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                ChatScreen(receiverId: receiverId, userDetails: userDetails),
          ));
        }
      },
    );
  }
}

class ChatScreenBody extends StatefulWidget {
  final int between; //User id of the other user
  const ChatScreenBody({super.key, required this.between});

  @override
  State<ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<ChatScreenBody> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getSingleChat(between: widget.between),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // SNAPSHOT NO DATA - Chats not loaded
          return const CircularProgressIndicator();
          // SNAPSHOT NO DATA - Chats not loaded
        } else {
          // SNAPSHOT HAS DATA - Chats loaded
          List<dynamic> messages = jsonDecode(snapshot.data.toString());
          print(messages);
          return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final int userIdFrom = message['UserId_From'];
                return ListTile(
                  title: SizedBox(
                    height: 50,
                    width: 50,
                    child: Row(
                      mainAxisAlignment:
                          _messageIsFromOther(userIdFrom: userIdFrom)
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: _messageIsFromOther(userIdFrom: userIdFrom)
                                ? Colors.lightGreen.shade200
                                : Colors.blue[400],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message['Message'],
                            style: TextStyle(
                              color: _messageIsFromOther(userIdFrom: userIdFrom)
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
          // SNAPSHOT HAS DATA - Chats loaded
        }
      },
    );
  }

  Future<String> _getSingleChat({required int between}) {
    return MainApiCall().callEndpoint(endpoint: 'getConversation', fields: {
      'type': 'direct',
      'otherUserId': between.toString(),
    });
  }

  bool _messageIsFromOther({required int userIdFrom}) {
    if (userIdFrom == widget.between) {
      return true;
    } else {
      return false;
    }
  }
}

import 'package:flutter/material.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
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
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
                "https://avatars.githubusercontent.com/u/25105821?v=4"),
          ),
          title: Text("Username"),
          subtitle: Text("Message"),
          trailing: Text("Time"),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (BuildContext context) => const ChatScreen())),
        );
      },
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Individual chat between two users
    return Scaffold(
      body: Column(
        children: [
          ChatScreenHeader(),
          Expanded(
            child: ChatScreenBody(),
          ),
          ChatScreenFooter(),
        ],
      ),
    );
  }

  ListTile ChatScreenHeader() {
    return const ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
            "https://avatars.githubusercontent.com/u/25105821?v=6"),
      ),
      title: Text("Username"),
      subtitle: Text(
        "Message",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  // Send messsage bar
  Widget ChatScreenFooter() {
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
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(10),
                    hintText: "Type a message",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
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
}

class ChatScreenBody extends StatefulWidget {
  const ChatScreenBody({super.key});

  @override
  State<ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<ChatScreenBody> {
  final List<Message> messages = [
    Message('Hello!', MessageType.received),
    Message('Hi, how can I help you?', MessageType.sent),
    // Add more messages here
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        reverse: true, // To keep the latest messages at the bottom
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ListTile(
            title: Container(
              height: 50,
              width: 50,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: message.type == MessageType.received
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: message.type == MessageType.received
                          ? Colors.lightGreen.shade200
                          : Colors.blue[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: message.type == MessageType.received
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
  }
}

class Message {
  final String content;
  final MessageType type;

  Message(this.content, this.type);
}

enum MessageType {
  sent,
  received,
}

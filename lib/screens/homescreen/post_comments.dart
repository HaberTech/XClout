import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:xclout/backend/main_api.dart';
import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/backend/widgets.dart';
// Globals
import 'package:xclout/backend/globals.dart' as globals;

class Comment extends StatelessWidget {
  final Map<String, dynamic> comment;

  const Comment({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: SizedBox(
          height: 40,
          width: 40,
          child: MyCORSImage.networkOrData(
              url: comment['User']!['ProfilePicture']!),
        ),
        title: UserNameAndPost(user: comment['User']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(comment['Comment']),
            const TextButton(onPressed: null, child: Text('Reply'))
          ],
        ));
  }
}

class PostComments extends StatefulWidget {
  final int postId;

  const PostComments({super.key, required this.postId});

  @override
  State<PostComments> createState() => _PostCommentsState();
}

class _PostCommentsState extends State<PostComments> {
  @override
  void initState() {
    super.initState();
    // Set current screen for analytics
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'comments_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments"),
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: _getPostComments(postId: widget.postId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final List<dynamic> comments = snapshot.data!;
                return Expanded(
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return Comment(
                        comment: comments[index],
                      );
                    },
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
          _commentInputSection(context)
        ],
      ),
    );
  }

  Future<List<dynamic>> _getPostComments({required int postId}) async {
    var response = await MainApiCall().callEndpoint(
      endpoint: "/comments",
      fields: {
        'action': 'getComments',
        'postId': postId.toString(),
      },
    );
    var comments = jsonDecode(response);

    return comments;
  }

  void _commentOnPost(
      {required int postId,
      required int parentCommentId,
      required String comment,
      required BuildContext context}) {
    MainApiCall().callEndpoint(
      endpoint: "/comments",
      fields: {
        'action': 'commentOnPost',
        'postId': postId.toString(),
        'parentCommentId': parentCommentId.toString(),
        'comment': comment,
      },
    ).then((response) {
      // Log Event
      FirebaseAnalytics.instance.logEvent(
        name: 'comment_on_post',
        parameters: {
          'status': response,
          'postId': postId,
          'parentCommentId': parentCommentId,
          'comment': comment,
        },
      );
      // Show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((response == 'Success')
              ? 'Commented Saved Successfully'
              : ' Something went Wrong'),
        ),
      );
    });
  }

  Widget _commentInputSection(BuildContext context) {
    TextEditingController comment = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: comment,
                  maxLines:
                      null, // this allows the TextField to expand as the user types
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(10),
                    hintText: "Type a comment",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                 FirebaseAnalytics.instance.logEvent(
                    name: 'comment_on_post',
                    parameters: {
                      'IsUserLoggedIn': globals.isLoggedIn.toString()
                    },
                  );
                continueElseLogin(ifLoggedIn: () {
                  _commentOnPost(
                    postId: widget.postId,
                    parentCommentId: 0,
                    comment: comment.text,
                    context: context,
                  );
                  comment.clear();
                  // Reload Comments
                  setState(() {});
                });
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
}

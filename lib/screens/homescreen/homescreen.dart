import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:xclout/backend/main_api.dart';
import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/backend/widgets.dart';
import 'package:xclout/screens/chat/chat.dart';

import 'package:xclout/screens/homescreen/posts_card.dart';
import 'package:xclout/backend/globals.dart' as globals;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _pageIfIsLoggedIn(BuildContext context) {
    return FutureBuilder(
      // future: MainApiCall().loadCookies(),
      future:
          MainApiCall().callEndpoint(endpoint: '/isUserLoggedIn', fields: null),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // On cookies fetched successfully
          // if (snapshot.data != null) {
          if (snapshot.data == '1') {
            // If user is logged in
            globals.isLoggedIn = true;
            return const FeedPage(
              title: 'Xclout',
            );
          } else {
            // If user is not logged in
            // return const SignUpScreen(
            //   formToShow: SignUpForm(),
            //   title: "Sign Up",
            // );
            globals.isLoggedIn = false;
            return const FeedPage(
              title: 'Xclout',
            );
          }
        } else if (snapshot.hasError) {
          // On cookies fetch error
          return Text('${snapshot.error}');
        } else {
          // While cookies are being fetched
          return const CircularProgressIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _pageIfIsLoggedIn(context);
  }
}

class FeedPage extends StatefulWidget {
  final String title;

  const FeedPage({super.key, required this.title});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Post> posts = [];
  final ScrollController _scrollController = ScrollController();

  bool isLoading = false;
  bool hasMorePosts =
      true; // Add this variable to track if there are more posts to load

  Future _showUsersNotice(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Notice! Notice! Notice!"),
          content: const Text(
              "This app is still in development and in a very early alpha stage. Use it and expect issues. \nAlways report and provide feedback icluding issues, what you like and ideas you want implemented to the developer (Cedrick) \nLogin or signup for full access."),
          actions: [
            ElevatedButton(
              style: myButtonStyle(),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("I Understand"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'FeedsPage');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUsersNotice(context);
      _loadPosts(); // Call _loadPosts() here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(
                name: 'upload_post',
                parameters: {'isLoggedIn': globals.isLoggedIn.toString()},
              );
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  duration: Duration(seconds: 8),
                  content: Text(
                      'Upload your posts and have them visble to anyone who folows your school.. Send your regards')));
            },
            icon: const Icon(Icons.cloud_upload_rounded),
          ),
          IconButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(
                name: 'chat_page_button',
                parameters: {'isLoggedIn': globals.isLoggedIn.toString()},
              );
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatsPage(),
                  ));
            },
            icon: const Icon(Icons.telegram_rounded),
          )
        ],
        title: Text(widget.title),
      ),
      body: homePageBody(),
    );
  }

  Center homePageBody() {
    return Center(
      child: _buildPosts(context),
    );
  }

  Future<bool> _loadPosts() async {
    if (!hasMorePosts) return false;
    // If there are no more posts to load, return
    setState(() => isLoading = true);
   
    print('Number of posts: ${posts.length}');
    // If posts are not empty and some have already been loaded, set the last post ids
    if (posts.isNotEmpty) {
      print('Posts are not empty');
      // Assuming that the posts are sorted by newest first
      LastViewedPost.setLastViewedPostIds(
          newestViewedPostId: posts.first.postId,
          oldestViewedPostId: posts.last.postId);
    }

    // Fetch posts here...
    Map<String, int> lastViewedPostIds =
        await LastViewedPost.getLastViewedPostIds();
    print(lastViewedPostIds);

    final String responseJson = await MainApiCall().callEndpoint(
      endpoint: '/getPostsOfFollowing',
      fields: {
        'newestViewedPostId':
            lastViewedPostIds['newestViewedPostId'].toString(),
        'oldestViewedPostId': lastViewedPostIds['oldestViewedPostId'].toString()
      },
    );
    final List<dynamic> newPostsList = jsonDecode(responseJson);

    final List<Post> newPosts = [];
    for (var post in newPostsList) {
      newPosts.add(Post.fromJson(post));
    }

    hasMorePosts = newPosts.isNotEmpty;
    if (hasMorePosts) {
      posts.addAll(newPosts);
    }

    setState(() => isLoading = false);
    return true;
  }

  Widget _buildPosts(BuildContext context) {
    print('Is loading ${isLoading.toString()}');
    if (posts.isEmpty && isLoading) {
      // If no posts have been loaded and _loadPosts() is in progress
      return const CircularProgressIndicator();
    } else if (posts.isEmpty && !isLoading) {
      // If no posts have been loaded and _loadPosts() is not in progress
      return const Text('No posts available');
    } else {
      // If posts have been loaded
      return ListView.builder(
        itemCount: posts.length + (isLoading ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          Post post = posts[index]; // Get the post to be shown
          if (index == posts.length) {
            // If this is the last item // show a loading indicator
            return const CircularProgressIndicator();
          } else {
            if (post.resources == []) {
              return Container(); // Return an empty container instead of using continue
            } else {
              // print(post.user);
              // SHOW THE POST IN IT'S CARD
              return PostCard(post: post);
            }
          }
        },
        controller: _scrollController
          ..addListener(() {
            if (!isLoading &&
                hasMorePosts &&
                _scrollController.position.extentAfter < 500) {
              // If the scroll position is less than 500px from the bottom
              _loadPosts(); // Load more posts
            }
          }),
      );
    }
  }
}

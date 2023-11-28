import 'package:xclout/backend/main_api.dart';
import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/backend/widgets.dart';
import 'package:xclout/screens/chat/chat.dart';

import 'package:xclout/screens/homescreen/posts_card.dart';
import 'package:xclout/screens/account/signup.dart'
    show SignUpScreen, SignUpForm;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _pageIfIsLoggedIn(BuildContext context) {
    return FutureBuilder(
      // future: MainApiCall().loadCookies(),
      future:
          MainApiCall().callEndpoint(endpoint: '/isUserLoggedIn', fields: {}),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // On cookies fetched successfully
          // if (snapshot.data != null) {
          if (snapshot.data == '1') {
            // If user is logged in
            return const FeedPage(
              title: 'Xclout',
            );
          } else {
            // If user is not logged in
            return const SignUpScreen(
              formToShow: SignUpForm(),
              title: "Sign Up",
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
  final _scrollController = ScrollController();

  bool isLoading = false;

  Future _showUsersNotice(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Notice! Notice! Notice!"),
          content: const Text(
              "This app is still in development and in a very early alpha stage. Use it and expect issues. \nAlways report and provide feedback icluding issues, what you like and ideas you want implemented to the developer (Cedrick)"),
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
  @override
  void initState() {
    super.initState();
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Here you will be able to upload.. Send your regards')));
            },
            icon: const Icon(Icons.cloud_upload_rounded),
          ),
          IconButton(
            onPressed: () {
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
      //   child: FutureBuilder(
      //     future: _loadPosts(),
      //     builder: (context, snapshot) {
      //       if (snapshot.hasData) {
      //         // On posts fetched successfully
      //         return _buildPosts(context, snapshot);
      //       } else if (snapshot.hasError) {
      //         // On posts fetch error
      //         return Text('${snapshot.error}');
      //       } else {
      //         // While posts are being fetched
      //         return const CircularProgressIndicator();
      //       }
      //     },
      //   ),
      // );
    );
  }

  bool hasMorePosts =
      true; // Add this variable to track if there are more posts to load
  Future<bool> _loadPosts() async {
    if (!hasMorePosts) return false;
    // If there are no more posts to load, return
    setState(() {
      isLoading = true;
    });

    // Fetch posts here...
    int lastViewPostId = await LastViewedPost.getLastViewPostId();
    lastViewPostId = (lastViewPostId == 0) ? 1 : lastViewPostId;
    print(lastViewPostId);
    final String responseJson = await MainApiCall().callEndpoint(
        endpoint: '/getPostsOfFollowing',
        fields: {'lastViewedPostId': lastViewPostId.toString()});
    final List<dynamic> newPostsList = jsonDecode(responseJson);

    final List<Post> newPosts = [];
    for (var post in newPostsList) {
      newPosts.add(Post.fromJson(post));
    }

    if (newPosts.isEmpty) {
      hasMorePosts =
          false; // If no new posts were fetched, set hasMorePosts to false
    } else {
      setState(() {
        isLoading = false;
        posts.addAll(newPosts);
      });
    }

    return true;
  }

  Widget _buildPosts(BuildContext context) {
    if (posts.isEmpty && isLoading) {
      // If no posts have been loaded and _loadPosts() is in progress
      return const CircularProgressIndicator();
    } else if (posts.isEmpty && !isLoading) {
      // If no posts have been loaded and _loadPosts() is not in progress
      return const Text('No posts available');
    } else {
      return ListView.builder(
        itemCount: posts.length + (isLoading ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          Post post = posts[index]; // Get the post to be shown
          LastViewedPost.setLastViewPostId(post.postId); // Set last viewed post
          if (index == posts.length) {
            // If this is the last item, show a loading indicator
            return const CircularProgressIndicator();
          } else {
            if (post.resources == []) {
              return Container(); // Return an empty container instead of using continue
            } else {
              print(post.user);
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

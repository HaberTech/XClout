import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'package:xclout/screens/chat/chat.dart';
import 'package:xclout/screens/homescreen/posts_card.dart';

import 'package:xclout/backend/main_api.dart';
import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/backend/widgets.dart';
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
          return const Center(child: CircularProgressIndicator());
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
  late Post lastFirstPost;
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
              "Tap the phone icon in the upper right corner to contact the developers for support! \nThis app is still in development and in a very early alpha stage. Use it and expect issues. \nAlways report and provide feedback icluding issues and ideas you want implemented to the developer \nLogin or signup for full access."),
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
    FirebaseAnalytics.instance.logScreenView(screenName: 'FeedPage');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUsersNotice(context);
      _loadPosts(); // Call _loadPosts() here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <IconButton>[
          IconButton(
            onPressed: () async {
              final Uri whatsappUri =
                  Uri.parse("https://wa.me/256787483408?text=Hello,%20There!");
              FirebaseAnalytics.instance.logEvent(
                name: 'contact_developer',
                parameters: {'isLoggedIn': globals.isLoggedIn.toString()},
              );
              if (await url_launcher.canLaunchUrl(whatsappUri)) {
                await url_launcher.launchUrl(whatsappUri);
              } else {
                print("Please try that again");
              }
            },
            icon: const Icon(Icons.phone_forwarded_rounded),
          ),
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
    print('Loading posts...');
    if (!hasMorePosts) return false;
    // If there are no more posts to load, return
    setState(() => isLoading = true);

    print('Number of posts: ${posts.length}');
    // If posts are not empty and some have already been loaded, set the last post ids
    if (posts.isNotEmpty) {
      print('Posts are not empty');
      // Assuming that the posts are sorted by newest first
      await LastViewedPost.setLastViewedPostIds(
        newestViewedPostId: lastFirstPost.newestViewedPostId ?? 0,
        oldestViewedPostId: lastFirstPost.oldestViewedPostId ?? 0,
      );
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
      // print(newPosts[0].newestViewedPostId);
    }

    // Store the new last first post
    lastFirstPost = newPosts.first;
    print(newPosts.first.toJson());
    setState(() => isLoading = false);
    return true;
  }

  Widget _buildPosts(BuildContext context) {
    print('Is loading ${isLoading.toString()}');

    if (posts.isEmpty) {
      // Show a loading indicator if posts are being loaded, otherwise show a text message
      return isLoading
          ? const CircularProgressIndicator()
          : const Text('No posts available');
    } else {
      // Show the list of posts
      return ListView.builder(
        itemCount: posts.length + (isLoading ? 1 : 0),
        itemBuilder: _buildPost,
        controller: _scrollController..addListener(_scrollListener),
      );
    }
  }

  Widget _buildPost(BuildContext context, int index) {
    if (index == posts.length) {
      // If this is the last item, show a loading indicator
      return const CircularProgressIndicator();
    } else {
      // Get the post to be shown
      Post post = posts[index];

      if (post.resources.isEmpty) {
        // If the post has no resources, return an empty container
        return Container();
      } else {
        // Show the post in its card
        return PostCard(post: post);
      }
    }
  }

  void _scrollListener() {
    if (!isLoading &&
        hasMorePosts &&
        _scrollController.position.extentAfter < 500) {
      // If the scroll position is less than 500px from the bottom
      _loadPosts(); // Load more posts
    }
  }
}

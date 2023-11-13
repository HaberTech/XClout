import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/screens/homescreen/posts_card.dart';
import 'package:xclout/screens/account/signup.dart'
    show SignUpScreen, SignUpForm;

class FeedPage extends StatelessWidget {
  final String title;

  const FeedPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const SignUpScreen(formToShow: SignUpForm())));
              },
              icon: const Icon(Icons.nightlight_outlined))
        ],
        title: Text(title),
      ),
      body: homePageBody(),
    );
  }

  Center homePageBody() {
    return Center(
      child: FutureBuilder(
        future: PostCard.loadStrings(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // On posts fetched successfully
            _buildPosts(context, snapshot);
          } else if (snapshot.hasError) {
            // On posts fetch error
            return Text('${snapshot.error}');
          } else {
            // While posts are being fetched
            return const CircularProgressIndicator();
          }
          // Reloads
          return _buildPosts(context, snapshot);
        },
      ),
    );
  }

  Widget _buildPosts(
      BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
    if (snapshot.hasData) {
      List<dynamic> deduplicatedPosts = snapshot.data!.toSet().toList();
      return ListView.builder(
        itemCount: deduplicatedPosts.length,
        itemBuilder: (BuildContext context, int index) {
          var post = deduplicatedPosts[index];
          return PostCard(post: post);
        },
      );
    } else if (snapshot.hasError) {
      return Text("${snapshot.error}");
    } else {
      return const CircularProgressIndicator();
    }
  }
}

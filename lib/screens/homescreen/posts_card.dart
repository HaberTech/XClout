import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;
import 'package:carousel_slider/carousel_slider.dart';

import 'package:xclout/backend/widgets.dart';
import 'package:xclout/backend/universal_imports.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();

  static Future<List<dynamic>> loadStrings() async {
    List<dynamic> allPosts = [];
    final String gayazaPosts =
        await rootBundle.loadString('assets/schoolMedias/GYZA_media_list.json');
    final String namilyangoPosts =
        await rootBundle.loadString('assets/schoolMedias/NGO_media_list.json');

    List gayazaPostsList = jsonDecode(gayazaPosts);
    List namilyangoPostsList = jsonDecode(namilyangoPosts);
    allPosts.addAll(gayazaPostsList);
    allPosts.addAll(namilyangoPostsList);

    // Sort all posts by date
    allPosts.sort((a, b) {
      var adate = a['taken_at'];
      var bdate = b['taken_at'];
      return -adate.compareTo(bdate);
    });

    // Remove duplicates
    Set uniquePosts = {};
    List deduplicatedPosts = [];
    for (var post in allPosts) {
      if (uniquePosts.add(post)) {
        deduplicatedPosts.add(post);
      }
    }

    return deduplicatedPosts;
  }
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(color: Theme.of(context).dividerColor),
        PostCardHeader(widget: widget),
        PostCardBody(post: widget.post),
        PostCardReactionButtons(widget: widget),
        PostCardCaptionAndComments(widget: widget),
        // Parse date string
        // Format date
        // Display formatted date
        Text(
          '     ${intl.DateFormat.yMMMMd().format(DateTime.parse(widget.post['taken_at']))}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class PostCardCaptionAndComments extends StatelessWidget {
  const PostCardCaptionAndComments({
    super.key,
    required this.widget,
  });

  final PostCard widget;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16.0, color: Colors.white),
        text: "     ",
        children: <TextSpan>[
          TextSpan(
            text: widget.post['user']['username'] + " ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: widget.post["caption_text"],
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }
}

class PostCardReactionButtons extends StatelessWidget {
  const PostCardReactionButtons({
    super.key,
    required this.widget,
  });

  final PostCard widget;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.thumb_up_outlined),
              onPressed: () {},
            ),
            Text("${widget.post['like_count']}"),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.thumb_down_outlined),
              onPressed: () {},
            ),
            const Text("12"),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.comment_rounded),
              onPressed: () {},
            ),
            const Text("26"),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.telegram_outlined),
              onPressed: () {},
            ),
            const Text("35"),
          ],
        ),
      ],
    );
  }
}

class PostCardHeader extends StatelessWidget {
  const PostCardHeader({
    super.key,
    required this.widget,
  });

  final PostCard widget;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        height: 40,
        width: 40,
        child: MyCORSImage.network(
          url: widget.post['user']['username'] == "ig.gayaza"
              ? "https://gayazahs.sc.ug/wp-content/uploads/2023/02/cropped-GHS-Badge-3.png"
              : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRI7ZDmITB-BgZT_cBo0ROxaObVWfsK_xNjnXiivihoHg&s",
        ),
      ),
      title: Text(widget.post['user']['username'] == "ig.gayaza"
          ? "Gayaza High School"
          : "Namilyango College"),
      subtitle: Row(children: [
        Text(widget.post['user']['username']),
        const SizedBox(width: 5),
        Icon(Icons.verified, color: Colors.blue, size: 15),
      ]),
    );
  }
}

class PostCardBody extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostCardBody({super.key, required this.post});

  @override
  State<PostCardBody> createState() => _PostCardBodyState();
}

class _PostCardBodyState extends State<PostCardBody> {
  int _currentIndex = 0;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Arrange the image index above the image
      children: <Widget>[
        postCarouselSlider(), // Images
        postIndex(),
        // Image Index
        // Show arrows if is web
        if ((kIsWeb) && (MediaQuery.of(context).size.width > 768)) ...[
          // Next Image and  Previous Image arrows... only for web and is desktop
          previousImage(), // Previous Image
          nextImage(), // Next Image
        ]
      ],
    );
    // After Images.. reaction Buttons
  }

  CarouselSlider postCarouselSlider() {
    return CarouselSlider.builder(
      carouselController: _controller,
      itemCount: widget.post['resources'].length,
      itemBuilder: (BuildContext context, int index, int realIndex) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: MyCORSImage.network(
                url: widget.post['resources'][index]['thumbnail_url'],
              ),
            ),
          ),
        );
      },
      options: postCarouselOptions(),
    );
  }

  Positioned postIndex() {
    return Positioned.directional(
      top: 0,
      start: 5,
      textDirection: TextDirection.rtl,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "${_currentIndex + 1}/${widget.post['resources'].length}",
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

// Move to next image
  Positioned nextImage() {
    return Positioned.directional(
      top: 100,
      start: 100,
      textDirection: TextDirection.rtl,
      child: Tooltip(
        message: "Next Image",
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                _controller.nextPage();
              },
            ),
          ),
        ),
      ),
    );
  }

// Move back to previous image
  Positioned previousImage() {
    return Positioned.directional(
      top: 100,
      start: 100,
      textDirection: TextDirection.ltr,
      child: Tooltip(
        message: "Previous Image",
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                _controller.previousPage();
              },
            ),
          ),
        ),
      ),
    );
  }

  CarouselOptions postCarouselOptions() {
    return CarouselOptions(
      height: 400,
      aspectRatio: 16 / 9,
      viewportFraction: 0.95,
      initialPage: 0,
      enableInfiniteScroll: false,
      enlargeCenterPage: true,
      onPageChanged: (index, reason) {
        setState(() => _currentIndex = index);
      },
      scrollDirection: Axis.horizontal,
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart' as intl;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:xclout/backend/main_api.dart';

import 'package:xclout/backend/widgets.dart';
import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/screens/homescreen/post_comments.dart';

part 'posts_card.g.dart';

@JsonSerializable()
class Post {
  //   "Caption": "I am 21 tryna live up here right here",
  //   "DateAdded": "Mon, 13 Nov 2023 02:19:09 GMT",
  //   "Liked": null,
  //   "NumberOfShares": 2,
  // "SchoolName"
  //   "PostId": 1,
  //   "PostStats": {
  //     "NumberOfComments": 0,
  //     "NumberOfDislikes": "0",
  //     "NumberOfLikes": "1",
  //     "NumberOfShares": 2
  //   },
  //   "Resources": "[\"link1\", \"link2\", \"link3\"]",
  //   "SourcePlatform": "",
  //   "SourceUsername": "cedrick__j",
  //   "User": {
  //     "ProfilePicture": "profile",
  //     "SchoolName": "Namilyango College",
  //     "SchoolPost": "Founder",
  //     "ShowPost": 1.0,
  //     "UserId": 1,
  //     "Username": "cedrick__j",
  //     "Verfied": 1,
  //     "VerificationType": "executive"
  //   },
  //   "UserId": 1
  // }

  @JsonKey(name: 'Caption')
  final String caption;
  @JsonKey(name: 'DateAdded')
  final String dateAdded;
  @JsonKey(name: 'Liked')
  String likeStatus;
  @JsonKey(name: 'NumberOfShares')
  final int numberOfShares;
  @JsonKey(name: 'PostId')
  final int postId;
  @JsonKey(name: 'PostStats')
  final Map<String, int> postStats;
  @JsonKey(name: 'Resources')
  final List<String> resources;
  @JsonKey(name: 'ResourceTypes')
  final List<int> resourceTypes;
  @JsonKey(name: 'SourcePlatform')
  final String sourcePlatform;
  @JsonKey(name: 'SourceUsername')
  final String sourceUsername;
  @JsonKey(name: 'SchoolId')
  final String schoolId;
  @JsonKey(name: 'SchoolName')
  final String schoolName;
  @JsonKey(name: 'SchoolLogo')
  final String schoolLogo;
  @JsonKey(name: 'User')
  final Map<String, dynamic> user;
  @JsonKey(name: 'UserId')
  final int userId;

  Post({
    required this.caption,
    required this.dateAdded,
    required this.likeStatus,
    required this.numberOfShares,
    required this.postId,
    required this.postStats,
    required this.resources,
    required this.resourceTypes,
    required this.sourcePlatform,
    required this.sourceUsername,
    required this.schoolId,
    required this.schoolName,
    required this.schoolLogo,
    required this.user,
    required this.userId,
  });

  // factory Post.fromJson(List oldJson) {
  //   final json = oldJson[0];
  //   print(json['User']);
  //   return Post(
  //     caption: json['Caption'],
  //     dateAdded: json['DateAdded'],
  //     liked: json['Liked'],
  //     numberOfShares: json['NumberOfShares'],
  //     postId: json['PostId'],
  //     postStats: json['PostStats'],
  //     resources: (jsonDecode(json['Resources']) as List)
  //         .map((item) => item as String)
  //         .toList(),
  //     sourcePlatform: json['SourcePlatform'],
  //     sourceUsername: json['SourceUsername'],
  //     schoolId: json['SchoolId'],
  //     schoolName: json['SchoolName'],
  //     schoolLogo: json['SchoolLogo'],
  //     user: (json['User'] as Map<String, dynamic>)
  //         .map((key, value) => MapEntry(key, value.toString())),
  //     userId: json['UserId'],
  //   );
  // }
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();

  // static Future<List<dynamic>> loadStrings() async {
  //   List<dynamic> allPosts = [];
  //   final String gayazaPosts =
  //       await rootBundle.loadString('assets/schoolMedias/GYZA_media_list.json');
  //   final String namilyangoPosts =
  //       await rootBundle.loadString('assets/schoolMedias/NGO_media_list.json');

  //   List gayazaPostsList = jsonDecode(gayazaPosts);
  //   List namilyangoPostsList = jsonDecode(namilyangoPosts);
  //   allPosts.addAll(gayazaPostsList);
  //   allPosts.addAll(namilyangoPostsList);

  //   // Sort all posts by date
  //   allPosts.sort((a, b) {
  //     var adate = a['taken_at'];
  //     var bdate = b['taken_at'];
  //     return -adate.compareTo(bdate);
  //   });

  //   // Remove duplicates
  //   Set uniquePosts = {};
  //   List deduplicatedPosts = [];
  //   for (var post in allPosts) {
  //     if (uniquePosts.add(post)) {
  //       deduplicatedPosts.add(post);
  //     }
  //   }

  //   return deduplicatedPosts;
  // }
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
        // Number of comments
        GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PostComments(postId: widget.post.postId)));
          },
          child: Text(
            "     ${widget.post.postStats['NumberOfComments']}  Comments",
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        // Parse date string
        // Format date
        // Display formatted date
        Text(
          '     ${intl.DateFormat.yMMMMd().format(DateTime.parse(widget.post.dateAdded))}',
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
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 16.0, color: Colors.white),
        text: "     ",
        children: <TextSpan>[
          TextSpan(
            text: widget.post.user['Username']! + " ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: widget.post.caption,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }
}

class PostCardReactionButtons extends StatefulWidget {
  const PostCardReactionButtons({
    super.key,
    required this.widget,
  });

  final PostCard widget;

  @override
  State<PostCardReactionButtons> createState() =>
      _PostCardReactionButtonsState();
}

class _PostCardReactionButtonsState extends State<PostCardReactionButtons> {
  late String likeStatus;
  late int numberOfLikes;
  late int numberOfDislikes;

  @override
  void initState() {
    super.initState();
    likeStatus = widget.widget.post.likeStatus;
    numberOfLikes = widget.widget.post.postStats['NumberOfLikes'] ?? 0;
    numberOfDislikes = widget.widget.post.postStats['NumberOfDislikes'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    print('Rebuilding => $likeStatus');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.thumb_up_outlined,
                  color: (likeStatus == 'like') ? Colors.blue : Colors.grey),
              onPressed: () async {
                await MainApiCall()
                    .callEndpoint(endpoint: '/likeOrDislikePost', fields: {
                  'postId': widget.widget.post.postId.toString(),
                  'likeSetting': 'like',
                  'removeReaction':
                      (likeStatus == 'like') ? 1.toString() : 0.toString(),
                });
                setState(() {
                  if (likeStatus == 'like') {
                    numberOfLikes -= 1;
                    likeStatus == 'none';
                  } else {
                    numberOfLikes += 1;
                    likeStatus == 'like';
                  }
                });
              },
            ),
            Text("$numberOfLikes"),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.thumb_down_outlined,
                  color: (likeStatus == 'dislike') ? Colors.blue : Colors.grey),
              onPressed: () {
                MainApiCall()
                    .callEndpoint(endpoint: '/likeOrDislikePost', fields: {
                  'postId': widget.widget.post.postId.toString(),
                  'likeSetting': 'dislike',
                  'removeReaction':
                      (likeStatus == 'dislike') ? 1.toString() : 0.toString(),
                });
                setState(() {
                  if (likeStatus == 'dislike') {
                    numberOfDislikes -= 1;
                    likeStatus == 'none';
                  } else {
                    numberOfDislikes += 1;
                    likeStatus == 'dislike';
                  }
                });
              },
            ),
            Text("$numberOfDislikes"),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.comment_rounded),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PostComments(postId: widget.widget.post.postId)));
              },
            ),
            Text(widget.widget.post.postStats['NumberOfComments'].toString()),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.telegram_outlined),
              onPressed: () {},
            ),
            Text(widget.widget.post.numberOfShares.toString()),
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
          child: MyCORSImage.network(url: widget.post.schoolLogo),
        ),
        title: Text(widget.post.schoolName),
        subtitle: UserNameAndPost(user: widget.post.user));
  }
}

class PostCardBody extends StatefulWidget {
  final Post post;
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
      itemCount: widget.post.resources.length,
      itemBuilder: (BuildContext context, int index, int realIndex) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: MyCORSImage.network(
                url: widget.post.resources[index],
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
            "${_currentIndex + 1}/${widget.post.resources.length}",
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

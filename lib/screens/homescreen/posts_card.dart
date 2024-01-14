import 'dart:async';
import 'package:intl/intl.dart' as intl;
import 'package:json_annotation/json_annotation.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:developer' as developer;

import 'package:xclout/backend/main_api.dart';
import 'package:xclout/backend/widgets.dart';
import 'package:xclout/backend/universal_imports.dart';
import 'package:xclout/backend/globals.dart' as globals;
import 'package:xclout/screens/homescreen/post_comments.dart';

part 'posts_card.g.dart';

@JsonSerializable()
class Post {
  //   "Caption": "I am 21 tryna live up here right here",
  //   "DateAdded": "Mon, 13 Nov 2023 02:19:09 GMT",
  //   "DatePosted" : "Mon, 13 Nov 2023 02:19:09 GMT",
  //   "Liked": null,
  //   "NumberOfShares": 2,
  // "SchoolName"
  // "SchoolLogo"
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
  // @JsonKey(name: 'NumberOfShares')
  // final int numberOfShares;

  @JsonKey(name: 'Caption')
  final String caption;
  @JsonKey(name: 'DatePosted')
  final String datePosted;
  @JsonKey(name: 'Liked')
  String likeStatus;
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
  // Only in the first post
  @JsonKey(name: 'NewestViewedPostId')
  final int? newestViewedPostId;
  @JsonKey(name: 'OldestViewedPostId')
  final int? oldestViewedPostId;

  Post({
    required this.caption,
    required this.datePosted,
    required this.likeStatus,
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
    this.newestViewedPostId,
    this.oldestViewedPostId,
  });

  // factory Post.fromJson(List oldJson) {
  //   final json = oldJson[0];
  //   print(json['User']);
  //   return Post(
  //     caption: json['Caption'],
  //     datePosted: json['DatePosted'],
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
}

class _PostCardState extends State<PostCard> {
  final String baseCdnUrl =
      'https://xclout-cdn.habertech.info/schools_external/';

  @override
  void initState() {
    super.initState();
    // Format the Resource Urls
    for (int i = 0; i < widget.post.resources.length; i++) {
      String resource = widget.post.resources[i];
      // Only format if they hadn't been formatted before
      if (!resource.startsWith('http')) {
        Map<String, bool> mediaTypes = getMediaTypeOfUrl(resource);
        String directory = mediaTypes['image']! ? 'images/' : 'videos/';
        widget.post.resources[i] = baseCdnUrl + directory + resource;
      }
    }
  }

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
                settings: const RouteSettings(name: 'Comments'),
                builder: (context) => PostComments(postId: widget.post.postId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Text(
              "${widget.post.postStats['NumberOfComments']}  Comments",
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: Text(
            intl.DateFormat.yMMMMd()
                .format(DateTime.parse(widget.post.datePosted)),
            style: const TextStyle(color: Colors.grey),
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 16.0, color: Colors.white),
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
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.thumb_up_outlined,
                  color: (likeStatus == 'like') ? Colors.blue : Colors.grey),
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(
                  name: 'like_post',
                  parameters: {'IsUserLoggedIn': globals.isLoggedIn.toString()},
                );
                continueElseLogin(ifLoggedIn: () {
                  MainApiCall()
                      .callEndpoint(endpoint: '/likeOrDislikePost', fields: {
                    'postId': widget.widget.post.postId.toString(),
                    'likeSetting': 'like',
                    'removeReaction':
                        (likeStatus == 'like') ? 1.toString() : 0.toString(),
                  });
                  setState(() {
                    if (likeStatus == 'like') {
                      numberOfLikes -= 1;
                      likeStatus = 'none';
                    } else {
                      if (likeStatus == 'dislike') {
                        numberOfDislikes -= 1;
                      }
                      numberOfLikes += 1;
                      likeStatus = 'like';
                    }
                  });
                }); // Continue if logged in
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
                FirebaseAnalytics.instance.logEvent(
                  name: 'dislike_post',
                  parameters: {'IsUserLoggedIn': globals.isLoggedIn.toString()},
                );
                continueElseLogin(ifLoggedIn: () {
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
                      likeStatus = 'none';
                    } else {
                      if (likeStatus == 'like') {
                        numberOfLikes -= 1;
                      }
                      numberOfDislikes += 1;
                      likeStatus = 'dislike';
                    }
                  });
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
                FirebaseAnalytics.instance.logEvent(
                  name: 'comment_post',
                  parameters: {'IsUserLoggedIn': globals.isLoggedIn.toString()},
                );
                continueElseLogin(ifLoggedIn: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: const RouteSettings(name: 'Comments'),
                          builder: (context) =>
                              PostComments(postId: widget.widget.post.postId)));
                });
              },
            ),
            Text(widget.widget.post.postStats['NumberOfComments'].toString()),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.telegram_outlined),
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(
                  name: 'share_post',
                  parameters: {'IsUserLoggedIn': globals.isLoggedIn.toString()},
                );
              },
            ),
            Text(widget.widget.post.postStats['NumberOfShares'].toString()),
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
          child: MyCORSImage.networkOrData(url: widget.post.schoolLogo),
        ),
        title: Text(
          widget.post.schoolName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: UserNameAndPost(user: widget.post.user));
  }
}

class PostCardBody extends StatefulWidget {
  final Post post;
  const PostCardBody({super.key, required this.post});

  @override
  State<PostCardBody> createState() => _PostCardBodyState();
}

class _PostCardBodyState extends State<PostCardBody>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  double? postAspectRatio;
  final CarouselController _controller = CarouselController();

// Enable AutomaticKeepAliveClientMixin to keep the state on
  @override
  bool get wantKeepAlive => true;

// Get the aspect ratio of the first resource and assume all the rest have the same aspect ratio
  @override
  void initState() {
    super.initState();
    postAspectRatio ?? _fetchAspectRatio();
  }

  void _fetchAspectRatio() async {
    postAspectRatio =
        postAspectRatio ?? await getAspectRatio(widget.post.resources[0]);
    mounted
        ? setState(() {})
        : null; // Call setState to trigger a rebuild of the widget.
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // This is neccesary for AutomaticKeepAliveClientMixin
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
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: (widget.post.resourceTypes[index] == 1)
                ? MyCORSImage.networkOrData(url: widget.post.resources[index])
                : PostVideoPlayer(
                    videoUrl: Uri.parse(widget.post.resources[index])),
          ),
        );
      },
      options: postCarouselOptions(),
    );
  }

// SHOW POST RESOURCE INDEX
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
    final double screenWidth = MediaQuery.of(context).size.width;
    double viewportFraction;
    if (screenWidth < 600) {
      // Phone
      viewportFraction = 0.98;
    } else if (screenWidth < 1200) {
      // Tablet
      viewportFraction = 0.6;
    } else {
      // Desktop
      viewportFraction = 0.4;
    }

    return CarouselOptions(
      aspectRatio: postAspectRatio ?? 1,
      viewportFraction: viewportFraction,
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

// Video Player for video resources
class PostVideoPlayer extends StatefulWidget {
  final Uri videoUrl;
  const PostVideoPlayer({super.key, required this.videoUrl});

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  late final VideoPlayerController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    try {
      _controller = VideoPlayerController.networkUrl(widget.videoUrl)
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {});
        });
    } catch (e) {
      developer.log('Error initializing VideoPlayerController: $e');
    }
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // This is neccesary for AutomaticKeepAliveClientMixin
    return _controller.value.isInitialized
        ? VisibilityDetector(
            key: Key(widget.videoUrl.toString()),
            onVisibilityChanged: (visibilityInfo) {
              // double visiblePercentage = visibilityInfo.visibleFraction * 100;
              visibilityInfo.visibleFraction == 0
                  ? _controller.pause()
                  : _controller.play();
            },
            child: // ... rest of your widget
                Stack(
              children: [
                // Video player
                VideoPlayer(_controller),
                // Play button
                if (!_controller.value.isPlaying)
                  Icon(Icons.play_arrow, size: 64.0, color: Colors.grey[700]),
                // Transparent container to capture gestures
                GestureDetector(
                  onTap: () {
                    // Wrap the play or pause in a call to `setState`.
                    setState(() {
                      // If the video is playing, pause it.
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                      // If the video is paused, play it.
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          )
        : const Center(
            child: ListTile(
              title: CircularProgressIndicator(),
              subtitle: Text('Video is loading...'),
            ),
          );
  }
}

// Get the media's aspect ratio form the url for both images and videos
Future<double> getAspectRatio(String url) async {
  double aspectRatio = 1;
  Map<String, bool> mediaTypes = getMediaTypeOfUrl(url);
  try {
    if (mediaTypes['image']!)
    // It's an image
    {
      developer.log('It is an image!!!');
      Completer<double> completer = Completer<double>();
      Image.network(url)
          .image
          .resolve(const ImageConfiguration())
          .addListener(ImageStreamListener((ImageInfo imageInfo, bool _) {
        int width = imageInfo.image.width;
        int height = imageInfo.image.height;
        aspectRatio = (width / height);
        imageInfo.image
            .dispose(); // Release the image handle after the listener has been called.
        completer.complete(aspectRatio);
      }));
      aspectRatio = await completer.future;
    } else if (mediaTypes['video']!) {
      // It's a video
      developer.log('It is a video');
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      aspectRatio = controller.value.aspectRatio;
      developer.log('Video Aspect Ratio: $aspectRatio');
    } else {
      throw Exception('Unsupported file type');
    }
    return aspectRatio;
  } catch (error) {
    developer.log('Error getting aspect ratio: $error');
    return 1;
  }
}

// Is Getting URL media types
// {'image' : true, 'video': false}
Map<String, bool> getMediaTypeOfUrl(String url) {
  Map<String, bool> mediaTypes = {'image': false, 'video': false};
  if (url.endsWith('.jpg') ||
      url.endsWith('.png') ||
      url.endsWith('.jpeg') ||
      url.endsWith('.webp') ||
      url.endsWith('.heic'))
  // It's an image
  {
    mediaTypes['image'] = true;
  } else if (url.endsWith('.mp4')) {
    // It's a video
    mediaTypes['video'] = true;
  } else {
    developer.log(url);
    throw Exception('Unsupported file type');
  }
  return mediaTypes;
}

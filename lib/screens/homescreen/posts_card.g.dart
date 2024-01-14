// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      caption: json['Caption'] as String,
      datePosted: json['DatePosted'] as String,
      likeStatus: json['Liked'] as String,
      postId: json['PostId'] as int,
      postStats: Map<String, int>.from(json['PostStats'] as Map),
      resources:
          (json['Resources'] as List<dynamic>).map((e) => e as String).toList(),
      resourceTypes: (json['ResourceTypes'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      sourcePlatform: json['SourcePlatform'] as String,
      sourceUsername: json['SourceUsername'] as String,
      schoolId: json['SchoolId'] as String,
      schoolName: json['SchoolName'] as String,
      schoolLogo: json['SchoolLogo'] as String,
      user: json['User'] as Map<String, dynamic>,
      userId: json['UserId'] as int,
      newestViewedPostId: json['NewestViewedPostId'] as int?,
      oldestViewedPostId: json['OldestViewedPostId'] as int?,
    );

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'Caption': instance.caption,
      'DatePosted': instance.datePosted,
      'Liked': instance.likeStatus,
      'PostId': instance.postId,
      'PostStats': instance.postStats,
      'Resources': instance.resources,
      'ResourceTypes': instance.resourceTypes,
      'SourcePlatform': instance.sourcePlatform,
      'SourceUsername': instance.sourceUsername,
      'SchoolId': instance.schoolId,
      'SchoolName': instance.schoolName,
      'SchoolLogo': instance.schoolLogo,
      'User': instance.user,
      'UserId': instance.userId,
      'NewestViewedPostId': instance.newestViewedPostId,
      'OldestViewedPostId': instance.oldestViewedPostId,
    };

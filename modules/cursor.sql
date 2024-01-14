    SET @row_number = 0;
    SET @@session.sql_require_primary_key = 0; /* Don't require Primary key */
    SET @@session.sql_mode = ''; /* Avoid issues with the configuration */
    CREATE TABLE DateArrangedPosts AS
    SELECT (@row_number:=@row_number + 1) AS DateArrangedId, t.*
    FROM (
        SELECT Posts.*, Schools.SchoolName, /* Schools.SchoolId => Avoid duplicate key, */ Schools.SchoolLogo, Schools.IG_Username
        FROM Posts 
        INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId 
        WHERE Posts.UserId = 1
        ORDER BY DATE(Posts.DateAdded) DESC, Posts.DatePosted DESC, Posts.PostId DESC
    ) t;
    ALTER TABLE DateArrangedPosts ADD PRIMARY KEY (DateArrangedId);

          SET @row_number = 0;
          SET @@session.sql_require_primary_key = 0; /* Don't require Primary key */
          SET @@session.sql_mode = ''; /* Avoid issues with the configuration */
          CREATE TEMPORARY TABLE TempTable AS
          SELECT (@row_number:=@row_number + 1) AS DateArrangedId, t.*
          FROM (
               SELECT Posts.*, Schools.SchoolName, /* Schools.SchoolId => Avoid duplicate key, */ Schools.SchoolLogo, Schools.IG_Username
               FROM Posts 
               INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId 
               WHERE Posts.UserId = 1
               ORDER BY DATE(Posts.DateAdded) DESC, Posts.DatePosted DESC, Posts.PostId DESC

SELECT 
     p.*, 
     lds.LikedStatus, 
     u.UserId, u.Username, u.SchoolId, u.ProfilePicture, u.Verified, u.SchoolPost, u.ShowPost, u.VerificationType,
     CAST(SUM(ld.LikedStatus = 'like') AS UNSIGNED) AS NumberOfLikes, 
     CAST(SUM(ld.LikedStatus = 'dislike') AS UNSIGNED) AS NumberOfDislikes, 
     (SELECT COUNT(*) FROM Comments WHERE Comments.PostId = p.PostId) AS NumberOfComments, 
     p.NumberOfShares
FROM DateArrangedPosts AS p
LEFT JOIN Users AS u ON p.UserId = u.UserId
LEFT JOIN LikesAndDislikes AS ld ON p.PostId = ld.PostId
LEFT JOIN LikesAndDislikes AS lds ON p.PostId = lds.PostId AND lds.UserId = 2
GROUP BY p.PostId, p.DateArrangedId
ORDER BY DATE(p.DateAdded) DESC, p.DatePosted DESC, p.PostId DESC
LIMIT 20;


SELECT 
   p.*, 
   u.Username, u.ProfilePicture, u.Verified, u.SchoolPost, u.ShowPost, u.VerificationType,
   (SELECT NumberOfShares FROM Posts WHERE PostId = p.PostId) AS RealNumberOfShares,
   (SELECT LikedStatus FROM LikesAndDislikes WHERE PostId = p.PostId  AND UserId = 2) AS LikedStatus,
   (SELECT COUNT(*) FROM Comments WHERE PostId = p.PostId) AS NumberOfComments, 
   (SELECT COUNT(*) FROM LikesAndDislikes WHERE PostId = p.PostId AND LikedStatus = 'like') AS NumberOfLikes,
   (SELECT COUNT(*) FROM LikesAndDislikes WHERE PostId = p.PostId AND LikedStatus = 'dislike') AS NumberOfDislikes
FROM DateArrangedPosts AS p
LEFT JOIN Users AS u ON p.UserId = u.UserId
LIMIT 20;

SELECT 
     p.*, 
     lds.LikedStatus,
     u.Username, u.ProfilePicture, u.Verified, u.SchoolPost, u.ShowPost, u.VerificationType,
     COUNT(c.comment) AS NumberOfComments, 
     SUM(ld.LikedStatus = 'like')  AS NumberOfLikes, 
     SUM(ld.LikedStatus = 'dislike')  AS NumberOfDislikes
FROM DateArrangedPosts AS p
LEFT JOIN Comments AS c ON p.postId = c.postId
LEFT JOIN Users AS u ON p.UserId = u.UserId
LEFT JOIN LikesAndDislikes AS ld ON p.PostId = ld.PostId
LEFT JOIN LikesAndDislikes AS lds ON p.PostId = lds.PostId AND lds.UserId = 2
GROUP BY p.PostId, p.DateArrangedId
ORDER BY DATE(p.DateAdded) DESC, p.DatePosted DESC, p.PostId DESC
LIMIT 20;

              SELECT 
                    p.*, 
                    u.Username, u.ProfilePicture, u.Verified, u.SchoolPost, u.ShowPost, u.VerificationType,
                    (SELECT NumberOfShares FROM Posts WHERE PostId = p.PostId) AS RealNumberOfShares,
                    (SELECT LikedStatus FROM LikesAndDislikes WHERE PostId = p.PostId  AND UserId = 2) AS LikedStatus,
                    (SELECT COUNT(*) FROM Comments WHERE PostId = p.PostId) AS NumberOfComments, 
                    (SELECT COUNT(*) FROM LikesAndDislikes WHERE PostId = p.PostId AND LikedStatus = 'like') AS NumberOfLikes,
                    (SELECT COUNT(*) FROM LikesAndDislikes WHERE PostId = p.PostId AND LikedStatus = 'dislike') AS NumberOfDislikes
               FROM DateArrangedPosts AS p
               LEFT JOIN Users AS u ON p.UserId = u.UserId
               WHERE p.DateArrangedId < ( SELECT DateArrangedId FROM DateArrangedPosts WHERE PostId = 16438
               ) 
               OR p.DateArrangedId > ( SELECT DateArrangedId FROM DateArrangedPosts WHERE PostId = 3455 
               ) 
               LIMIT 20;
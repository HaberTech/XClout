# import 'database_connection.py'
import json
from modules.main import databaseConnection, getShortUserProfile
from modules.posts import getRealIdsForNotLoggedInUSers


def getFollowing(userId: int):
     cursor = databaseConnection.cursor()
     cursor.execute("SELECT UserId_Following FROM Followings WHERE UserId_Follower = %s", (userId))
     return cursor.fetchall()

def getFollowers(userId: int):
     cursor = databaseConnection.cursor()
     cursor.execute("SELECT UserId_Follower FROM Followings WHERE UserId_Following = %s", (userId))
     return cursor.fetchall()

def getPostStats(postId: int):
     cursor = databaseConnection.cursor()
     sqlQuery = f'''
     SELECT 
          CAST(SUM(LikesAndDislikes.LikedStatus = 'like') AS UNSIGNED) AS NumberOfLikes, 
          CAST(SUM(LikesAndDislikes.LikedStatus = 'dislike') AS UNSIGNED) AS NumberOfDislikes, 
          (SELECT COUNT(*) FROM Comments WHERE Comments.PostId = Posts.PostId) AS NumberOfComments, 
          Posts.NumberOfShares 
     FROM 
          Posts
     INNER JOIN 
          LikesAndDislikes ON Posts.PostId = LikesAndDislikes.PostId 
     WHERE 
          Posts.PostId = {postId};
     '''

     cursor.execute(sqlQuery)
     postStats = cursor.fetchone()

     # If no likes or dislikes
     for key in postStats:
        if postStats[key] is None:
            postStats[key] = 0

     return postStats

def getPostsOfUser(userId: int):
        cursor = databaseConnection.cursor()
        # Get short user profile only onnce
        userId = int(1)
        shortUserProfile = getShortUserProfile(userId)
        posts = cursor.execute("SELECT Posts.*, Schools.SchoolId, Schools.SchoolName, Schools.SchoolLogo  FROM Posts INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId WHERE UserId = %s", (userId))

     # Format post add username, profile picture, and school name i.e short user profile
        posts = cursor.fetchall()
        for post in posts:
          post['User'] = shortUserProfile

          post['Resources'] = json.loads(post['Resources'])
          post['ResourceTypes'] = json.loads(post['ResourceTypes'])

          post['Liked'] = getLikedPostStatus(post['PostId'], userId)
          post['PostStats'] = getPostStats(post['PostId'])

        # Convert date to ISO format
        if 'DatePosted' in post:
          post['DateAdded'] = post['DateAdded'].isoformat()
          post['DatePosted'] = post['DatePosted'].isoformat()
        return posts

def getLikedPostStatus(postId:int, userId:int):
     cursor = databaseConnection.cursor()
     cursor.execute("SELECT LikedStatus FROM LikesAndDislikes WHERE PostId = %s AND UserId = %s", (int(postId), int(userId)))
     row = cursor.fetchone()
     if row is not None :
          return row['LikedStatus']
     else: return 'none'

def getPostStatistics(postId: int):
    cursor = databaseConnection.cursor()
    cursor.execute("SELECT * FROM PostStatistics WHERE PostId = %s", (postId))
    return cursor.fetchone()

def getPostsOfFollowing(userId: int):
    following = getFollowing(int(userId))
    # Add the school account
    following.append({'UserId_Following': '1'}) # Add the school account
    posts = []
    for row in following:
        posts.append(getPostsOfUser(row['UserId_Following']))
    return posts

def updateViewedPostIds(userId: int, newestViewedPostId: int, oldestViewedPostId: int):
    
     if userId == 2 or newestViewedPostId == 0 or oldestViewedPostId == 0:
           # If the user is not logged in then return the newest and oldest viewed post IDs
          return newestViewedPostId, oldestViewedPostId
     
     cursor = databaseConnection.cursor()

     # Create a temporary table with row numbers
     # DateArrangedPosts

     # Update the Users table with the greatest and least viewed post IDs
     # The GREATEST function is used to update the NewestViewedPostId. It compares two values: the DateArrangedId of the newestViewedPostId from the DateArrangedPosts, and the DateArrangedId of the current NewestViewedPostId in the Users table. It sets NewestViewedPostId to the greater of these two values.
     # The LEAST function is used to update the OldestViewedPostId. It compares two values: the DateArrangedId of the oldestViewedPostId from the DateArrangedPosts, and the DateArrangedId of the current OldestViewedPostId in the Users table. It sets OldestViewedPostId to the lesser of these two values.
     #  IF NULL, the IFNULL function will return 0. This is done to ensure that the GREATEST and LEAST functions have valid values to compare.
     cursor.execute(f"""
          UPDATE Users
          SET 
               NewestViewedPostId = GREATEST(
                    (SELECT DateArrangedId FROM DateArrangedPosts WHERE PostId = {newestViewedPostId}),
                    IFNULL(NewestViewedPostId, 0)
               ),
               OldestViewedPostId = LEAST(
                    (SELECT DateArrangedId FROM DateArrangedPosts WHERE PostId = {oldestViewedPostId}),
                    IFNULL(OldestViewedPostId, 0)
               )
          WHERE UserId = {userId}
     """)
     databaseConnection.commit()

     # Fetch the updated NewestViewedPostId and OldestViewedPostId from the Users table
     cursor.execute(f"""
          SELECT NewestViewedPostId, OldestViewedPostId
          FROM Users 
          WHERE UserId = {userId}
     """)
     result = cursor.fetchone()
     newestViewedPostId = result['NewestViewedPostId']
     oldestViewedPostId = result['OldestViewedPostId']

     # Return the updated newest and oldest viewed post IDs
     return newestViewedPostId, oldestViewedPostId
 # Create a temporary table with row numbers
     # Use the semi permanent table made => DateArrangedPosts

def getPostsOfSchool(userId: int, newestViewedPostId: int, oldestViewedPostId: int):
     databaseCursor = databaseConnection.cursor()

     # If the IDs are not provided or any is 0, then just get the 20 newest posts
     if newestViewedPostId is None or oldestViewedPostId is None or newestViewedPostId == 0 or oldestViewedPostId == 0:
          query = """
               SELECT 
                    p.*, 
                    u.Username, u.ProfilePicture, u.Verified, u.SchoolPost, u.ShowPost, u.VerificationType,
                    (SELECT NumberOfShares FROM Posts WHERE PostId = p.PostId) AS RealNumberOfShares,
                    (SELECT LikedStatus FROM LikesAndDislikes WHERE PostId = p.PostId  AND UserId = %s) AS LikedStatus,
                    (SELECT COUNT(*) FROM Comments WHERE PostId = p.PostId) AS NumberOfComments, 
                    (SELECT COUNT(*) FROM LikesAndDislikes WHERE PostId = p.PostId AND LikedStatus = 'like') AS NumberOfLikes,
                    (SELECT COUNT(*) FROM LikesAndDislikes WHERE PostId = p.PostId AND LikedStatus = 'dislike') AS NumberOfDislikes
               FROM DateArrangedPosts AS p
               LEFT JOIN Users AS u ON p.UserId = u.UserId
               LIMIT 20;
          """
          databaseCursor.execute(query, (userId,))
     else:
          # Get the id of the newest and oldest viewed posts will return the same values if the user has not viewed any posts or not logged in
          newestViewedPostId, oldestViewedPostId = updateViewedPostIds(userId, newestViewedPostId, oldestViewedPostId)

          # Get 20 unviewed posts for the User
          query = """
              SELECT 
                    p.*, 
                    u.Username, u.ProfilePicture, u.Verified, u.SchoolPost, u.ShowPost, u.VerificationType,
                    (SELECT NumberOfShares FROM Posts WHERE PostId = p.PostId) AS RealNumberOfShares,
                    (SELECT LikedStatus FROM LikesAndDislikes WHERE PostId = p.PostId  AND UserId = %s) AS LikedStatus,
                    (SELECT COUNT(*) FROM Comments WHERE PostId = p.PostId) AS NumberOfComments, 
                    (SELECT COUNT(*) FROM LikesAndDislikes WHERE PostId = p.PostId AND LikedStatus = 'like') AS NumberOfLikes,
                    (SELECT COUNT(*) FROM LikesAndDislikes WHERE PostId = p.PostId AND LikedStatus = 'dislike') AS NumberOfDislikes
               FROM DateArrangedPosts AS p
               LEFT JOIN Users AS u ON p.UserId = u.UserId
               WHERE p.DateArrangedId < ( SELECT DateArrangedId FROM DateArrangedPosts WHERE PostId = %s
               ) 
               OR p.DateArrangedId > ( SELECT DateArrangedId FROM DateArrangedPosts WHERE PostId = %s
               ) 
               LIMIT 20;
          """
          databaseCursor.execute(query, (userId, newestViewedPostId, oldestViewedPostId))

     # Fetch all posts
     posts = databaseCursor.fetchall()
     
     # If the user is not logged in, then get the actual Ids
     if userId == 2:
          # Get the actual Ids
          newestViewedPostId_second = posts[0]['PostId']; oldestViewedPostId_second = posts[-1]['PostId']
          # Return the actual Ids
          newestViewedPostId, oldestViewedPostId = getRealIdsForNotLoggedInUSers(newestViewedPostId, oldestViewedPostId, newestViewedPostId_second, oldestViewedPostId_second)
     # Not logged in user actul ids
           
     # Process posts and return
     posts = processPosts(posts, newestViewedPostId=newestViewedPostId, oldestViewedPostId=oldestViewedPostId)

     return posts
     ## Drop the temporary table
     # cursor.execute("DROP TEMPORARY TABLE IF EXISTS DateArrangedPosts;") # Since we are not closing the connection, we need to drop the temporary table
     ## Return the posts  
 
# Format post add username, profile picture, and school name i.e short user profile
def processPosts(posts, newestViewedPostId, oldestViewedPostId):
     if len(posts) == 0:
          return []
     
     newPosts = []
     for post in posts:
          user = {}
          newPost = {}
          postStatistics = {}
          newPost['Resources'] = json.loads(post['Resources'])
          newPost['ResourceTypes'] = json.loads(post['ResourceTypes'])

          newPost['Liked'] = post['LikedStatus'] if post['LikedStatus'] is not None else 'none'

          newPost['Caption'] = post['Caption']
          newPost['UserId'] = post['UserId']
          newPost['PostId'] = post['PostId']
          newPost['NumberOfShares'] = post['NumberOfShares']
          newPost['SourceUsername'] = post['SourceUsername']
          newPost['SourcePlatform'] = post['SourcePlatform']
          newPost['DateAdded'] = post['DateAdded'].isoformat()  # Convert date to ISO format
          newPost['DatePosted'] = post['DatePosted'].isoformat()

          newPost['SchoolId'] = post['SchoolId']
          newPost['SchoolName'] = post['SchoolName']
          newPost['SchoolLogo'] = post['SchoolLogo']

          user['UserId'] = post['UserId']
          user['SchoolId'] = post['SchoolId']
          user['SchoolName'] = post['SchoolName']
          user['SchoolLogo'] = post['SchoolLogo']

          # Post Statistics
          postStatistics['NumberOfLikes'] = post['NumberOfLikes']
          postStatistics['NumberOfDislikes'] = post['NumberOfDislikes']
          postStatistics['NumberOfComments'] = post['NumberOfComments']
          postStatistics['NumberOfShares'] = post['RealNumberOfShares']

          # BIOGRAPHY
          if post['UserId'] != 1:
               # It is an individual post
               user['Username'] = post['Username']
               user['Verified'] = post['Verified']
               user['ShowPost'] = post['ShowPost']
               user['ProfilePicture'] = post['ProfilePicture']
               user['VerificationType'] = post['VerificationType']
               
          else:
               # Is a School post
               user['Username'] = post['IG_Username']
               user['ProfilePicture'] = post['SchoolLogo']
               user['VerificationType'] = 'IgSchool'
               user['Verified'] = 1
               user['ShowPost'] = 0
               user['SchoolPost'] = ''
       
          newPost['User'] = user
          newPost['PostStats'] = postStatistics
          newPosts.append(newPost)

           # Add the PostIds to the first post
          newPosts[0]['NewestViewedPostId'] = newestViewedPostId
          newPosts[0]['OldestViewedPostId'] = oldestViewedPostId
     return newPosts


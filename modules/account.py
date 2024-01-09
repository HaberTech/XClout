# import 'database_connection.py'
from hmac import new
import json

from flask import jsonify
from modules.main import databaseConnection, getShortUserProfile

def getLikedPostStatus(postId:int, userId:int):
     cursor = databaseConnection.cursor()
     cursor.execute("SELECT LikedStatus FROM LikesAndDislikes WHERE PostId = %s AND UserId = %s", (int(postId), int(userId)))
     row = cursor.fetchone()
     if row is not None :
          return row['LikedStatus']
     else: return 'none'


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
        if 'DateAdded' in post:
            post['DateAdded'] = post['DateAdded'].isoformat()
        return posts


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

def getLastViewedPostIds(userId: int, newestViewedPostId: int, oldestViewedPostId: int):
     # Check if the newessViewedPostId is newer than the one in the databse and oldestViewedPostId is older thn the one in the database
     # If they are newer and older then update the database
     # Return the true newestViewedPostId and oldestViewedPostId
     cursor = databaseConnection.cursor()

def updateViewedPostIds(userId: int, newestViewedPostId: int, oldestViewedPostId: int):
    
     if userId == 2 or newestViewedPostId == 0 or oldestViewedPostId == 0:
           # If the user is not logged in then return the newest and oldest viewed post IDs
          return newestViewedPostId, oldestViewedPostId
     
     cursor = databaseConnection.cursor()

     # Create a temporary table with row numbers
     # cursor.execute("""
     #      SET @row_number = 0;
     #      CREATE TEMPORARY TABLE TempTable AS
     #      SELECT (@row_number:=@row_number + 1) AS DateArrangedId, t.*
     #      FROM (
     #           SELECT Posts.*, Schools.SchoolName, Schools.SchoolId, Schools.SchoolLogo, Schools.IG_Username
     #           FROM Posts 
     #           INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId 
     #           WHERE Posts.UserId = 1
     #           ORDER BY Posts.DateAdded DESC, Posts.PostId DESC
     #      ) t;
     # """)

     # Update the Users table with the greatest and least viewed post IDs
     # The GREATEST function is used to update the NewestViewedPostId. It compares two values: the DateArrangedId of the newestViewedPostId from the TempTable, and the DateArrangedId of the current NewestViewedPostId in the Users table. It sets NewestViewedPostId to the greater of these two values.
     # The LEAST function is used to update the OldestViewedPostId. It compares two values: the DateArrangedId of the oldestViewedPostId from the TempTable, and the DateArrangedId of the current OldestViewedPostId in the Users table. It sets OldestViewedPostId to the lesser of these two values.
     #  IF NULL, the IFNULL function will return 0. This is done to ensure that the GREATEST and LEAST functions have valid values to compare.
     cursor.execute(f"""
          UPDATE Users
          SET 
               NewestViewedPostId = GREATEST(
                    (SELECT DateArrangedId FROM TempTable WHERE PostId = {newestViewedPostId}),
                    IFNULL((SELECT DateArrangedId FROM TempTable WHERE PostId = NewestViewedPostId), 0)
               ),
               OldestViewedPostId = LEAST(
                    (SELECT DateArrangedId FROM TempTable WHERE PostId = {oldestViewedPostId}),
                    IFNULL((SELECT DateArrangedId FROM TempTable WHERE PostId = OldestViewedPostId), 0)
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


def getPostsOfSchool(userId: int, newestViewedPostId: int, oldestViewedPostId: int):
     cursor = databaseConnection.cursor()
     # Create a temporary table with row numbers
     cursor.execute("""
          SET @row_number = 0;
          CREATE TEMPORARY TABLE TempTable AS
          SELECT (@row_number:=@row_number + 1) AS DateArrangedId, t.*
          FROM (
               SELECT Posts.*, Schools.SchoolName, Schools.SchoolId, Schools.SchoolLogo, Schools.IG_Username
               FROM Posts 
               INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId 
               WHERE Posts.UserId = 1
               ORDER BY Posts.DateAdded DESC, Posts.PostId DESC
          ) t;
     """)

     # If the IDs are not provided or any is 0, then just get the 20 newest posts
     if newestViewedPostId is None or oldestViewedPostId is None or newestViewedPostId == 0 or oldestViewedPostId == 0:
          cursor.execute("SELECT * FROM TempTable LIMIT 20;")
          posts = cursor.fetchall()
     else: 
          # Get the id of the newest and oldest viewed posts will return the same values if the user has not viewed any posts or not logged in
          newestViewedPostId, oldestViewedPostId = updateViewedPostIds(userId, newestViewedPostId, oldestViewedPostId)

          # Get 20 unviewed posts for the User
          cursor.execute(f"""
               SELECT * 
               FROM TempTable 
               WHERE DateArrangedId > (
                    SELECT DateArrangedId 
                    FROM TempTable 
                    WHERE PostId = {newestViewedPostId}
               ) 
               OR DateArrangedId < (
                    SELECT DateArrangedId 
                    FROM TempTable 
                    WHERE PostId = {oldestViewedPostId}
               ) 
               ORDER BY DateAdded DESC, PostId DESC 
               LIMIT 20;
          """)
          posts = cursor.fetchall()

     # Process posts and return
     posts = processPosts(posts, userId)
     ## Drop the temporary table
     cursor.execute("DROP TEMPORARY TABLE IF EXISTS TempTable;") # Since we are not closing the connection, we need to drop the temporary table
     ## Return the posts
     return posts
    
# Format post add username, profile picture, and school name i.e short user profile
def processPosts(posts, userId):
    if len(posts) == 0:
        return []

    for post in posts:
        post['User'] = {}
        post['Resources'] = json.loads(post['Resources'])
        post['ResourceTypes'] = json.loads(post['ResourceTypes'])

        post['Liked'] = getLikedPostStatus(post['PostId'], userId)
        post['PostStats'] = getPostStats(post['PostId'])

        # Add short user profile to post 
        post['User']['UserId'] = post['UserId']
        post['User']['SchoolId'] = post['SchoolId']
        post['User']['Username'] = post['IG_Username']
        post['User']['ProfilePicture'] = post['SchoolLogo']
        post['User']['SchoolName'] = post['SchoolName']
        post['User']['VerificationType'] = 'IgSchool'

        post['User']['Verified'] = 1
        post['User']['ShowPost'] = 0
        post['User']['SchoolPost'] = ''

        # Convert date to ISO format
        if 'DateAdded' in post:
            post['DateAdded'] = post['DateAdded'].isoformat()

    return posts


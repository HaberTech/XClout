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

     # If the user is not logged in then return the newest and oldest viewed post IDs
     if userId == 2 or newestViewedPostId == 0 or oldestViewedPostId == 0:
          return newestViewedPostId, oldestViewedPostId
     # Return if user is not logged in
     
     cursor = databaseConnection.cursor()
    # Fetch the DateAdded of the newest and oldest viewed post IDs from the database
     cursor.execute(f"""
        SELECT 
            (SELECT DateAdded FROM Posts WHERE PostId = {newestViewedPostId}) as newestDate,
            (SELECT DateAdded FROM Posts WHERE PostId = {oldestViewedPostId}) as oldestDate
    """)
     result = cursor.fetchone()
     newestViewedPostDate = result['newestDate'] if result else None
     oldestViewedPostDate = result['oldestDate'] if result else None

    # Fetch the DateAdded of the NewestViewedPostId and OldestViewedPostId from the Users table
     cursor.execute(f"""
        SELECT 
            (SELECT DateAdded FROM Posts WHERE PostId = NewestViewedPostId) as dbNewestViewedPostDate,
            (SELECT DateAdded FROM Posts WHERE PostId = OldestViewedPostId) as dbOldestViewedPostDate,
             NewestViewedPostId as dbNewestViewedPostId,
             OldestViewedPostId as dbOldestViewedPostId            
        FROM Users 
        WHERE UserId = {userId}
    """)
     result = cursor.fetchone()
     dbNewestViewedPostDate = result['dbNewestViewedPostDate'] if result else None
     dbOldestViewedPostDate = result['dbOldestViewedPostDate'] if result else None
     dbNewestViewedPostId = result['dbNewestViewedPostId'] if result else None
     dbOldestViewedPostId = result['dbOldestViewedPostId'] if result else None

    # Check if the provided post IDs are newer and older than the ones in the database
     if (dbNewestViewedPostDate is None or newestViewedPostDate > dbNewestViewedPostDate) and (dbOldestViewedPostDate is None or oldestViewedPostDate < dbOldestViewedPostDate):
        # If they are, update the Users table
        cursor.execute(f"""
            UPDATE Users
            SET 
                NewestViewedPostId = {newestViewedPostId},
                OldestViewedPostId = {oldestViewedPostId}
            WHERE UserId = {userId}
        """)
        databaseConnection.commit()
     else:
        # If they are not, return the true newest and oldest viewed post IDs from the database
        newestViewedPostId = dbNewestViewedPostId
        oldestViewedPostId = dbOldestViewedPostId

    # Return the true newest and oldest viewed post IDs
     return newestViewedPostId, oldestViewedPostId

def getPostsOfSchool(userId: int, newestViewedPostId: int, oldestViewedPostId: int):
     cursor = databaseConnection.cursor()
     
     # if the ids are Not provided or any is 0 then just get the newest posts
     if newestViewedPostId is None or oldestViewedPostId is None:
          sqlQuery = f'''
               SELECT Posts.*, Schools.SchoolName, Schools.SchoolId, Schools.SchoolLogo, Schools.IG_Username
               FROM Posts 
               INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId 
               WHERE Posts.UserId = {1}
               ORDER BY Posts.DateAdded DESC, Posts.PostId DESC
               LIMIT 20
          '''
     else: 
          # Update the newestViewedPostId and oldestViewedPostId in the database
          newestViewedPostId, oldestViewedPostId = updateViewedPostIds(userId, newestViewedPostId, oldestViewedPostId)
          
          # Fetch the DateAdded of the newest and oldest viewed post IDs from the database
          sqlQuery = f'''
          (
          SELECT Posts.*, Schools.SchoolName, Schools.SchoolId, Schools.SchoolLogo, Schools.IG_Username
          FROM Posts 
          INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId 
          WHERE Posts.UserId = {1} AND (Posts.DateAdded > (SELECT DateAdded FROM Posts WHERE PostId = {newestViewedPostId}) OR (Posts.DateAdded = (SELECT DateAdded FROM Posts WHERE PostId = {newestViewedPostId}) AND Posts.PostId > {newestViewedPostId}))
          ORDER BY Posts.DateAdded DESC, Posts.PostId DESC
          LIMIT 20
          )
          UNION ALL
          (
          SELECT Posts.*, Schools.SchoolName, Schools.SchoolId, Schools.SchoolLogo, Schools.IG_Username
          FROM Posts 
          INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId 
          WHERE Posts.UserId = {1} AND (Posts.DateAdded < (SELECT DateAdded FROM Posts WHERE PostId = {oldestViewedPostId}) OR (Posts.DateAdded = (SELECT DateAdded FROM Posts WHERE PostId = {oldestViewedPostId}) AND Posts.PostId < {oldestViewedPostId}))
          ORDER BY Posts.DateAdded DESC, Posts.PostId DESC
          LIMIT 20
          )
          ORDER BY DateAdded DESC, PostId DESC
          LIMIT 20
          '''
         
          
          # Geneare a query statement that selects the posts that the user has not viewed yet #
          # Get posts and order them by DateAdded descending and postId descending.
          # remeber that posts maybe have the same DateAdded so we need to order them by postId descending to get the newest and oldest posts
          # we select the posts that have a date greater than the newest viewed post date or if the date is equal then we select the posts that have a postId greater than the newest viewed post id
          # and for the older posts we select the posts that have a date less than the oldest viewed post date or if the date is equal then we select the posts that have a postId less than the oldest viewed post id
          # Then get the 20 posts that are newer than the newestViewedPost and if the posts newer are less than 20 
          #...then get and add posts that are older than the oldestViewedPost to make the total posts 20
          # Does my above query statement make logical sense assuming that the selected posts will be the posts that the user has not viewed yet?

     cursor.execute(sql=sqlQuery)
     posts = cursor.fetchall()
    
     if len(posts) == 0:
          return jsonify([])
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
          post['User']['ShowPost'] = 1
          post['User']['SchoolPost'] = 'IG'

          # Convert date to ISO format
          if 'DateAdded' in post:
               post['DateAdded'] = post['DateAdded'].isoformat()
     return posts


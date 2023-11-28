# import 'database_connection.py'
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
    following.append({'UserId_Following': '4'}) # Add the school account
    posts = []
    for row in following:
        posts.append(getPostsOfUser(row['UserId_Following']))
    return posts

def getPostsOfSchool(userId: int, lastPostId: int):
     cursor = databaseConnection.cursor()

     sqlQuery = f'''
     SELECT Posts.*, Schools.SchoolName, Schools.SchoolId, Schools.SchoolLogo, Schools.IG_Username
    FROM Posts 
    INNER JOIN Schools ON Posts.SchoolId = Schools.SchoolId 
    WHERE Posts.UserId = {'4'} AND (Posts.DateAdded < (SELECT DateAdded FROM Posts WHERE PostId = {lastPostId}) OR (Posts.DateAdded = (SELECT DateAdded FROM Posts WHERE PostId = {lastPostId}) AND Posts.PostId < {lastPostId}))
    ORDER BY Posts.DateAdded DESC, Posts.PostId DESC
    LIMIT 15
    '''
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
          post['User']['SchoolPost'] = 1
          post['User']['ShowPost'] = 1

          # Convert date to ISO format
          if 'DateAdded' in post:
               post['DateAdded'] = post['DateAdded'].isoformat()
     print(posts)
     return posts


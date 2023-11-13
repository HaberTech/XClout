# import 'database_connection.py'
from modules.main import databaseConnection


class ShortUserProfile:
     def __init__(self, userId, username, profilePicture, verified, schoolPost, showPost, verificationType, schoolName):
          self.userId = userId
          self.username = username
          self.profilePicture = profilePicture
          self.verified = verified
          self.schoolPost = schoolPost
          self.showPost = showPost
          self.verificationType = verificationType
          self.schoolName = schoolName

def getShortUserProfile(userId: int) -> ShortUserProfile:
     cursor = databaseConnection.cursor()
     # Select from Users, Schools, in one query
     cursor.execute("SELECT Users.UserId, Users.Username, Users.ProfilePicture, Users.Verfied, Users.SchoolPost, Users.ShowPost, Users.VerificationType, Schools.SchoolName FROM Users INNER JOIN Schools ON Users.SchoolId = Schools.SchoolId WHERE Users.UserId = %s;", (userId))
     return cursor.fetchone()

def getLikedPostStatus(postId:int, userId:int):
     cursor = databaseConnection.cursor()
     cursor.execute("SELECT LikedPost FROM LikesAndDislikes WHERE PostId = %s AND UserId = %s", (int(postId), int(userId)))
     print(int(cursor.fetchone()['LikedPost']))
     row = cursor.fetchone()
     return bool(int(cursor.fetchone()['LikedPost'])) if row is not None else None


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
          SUM(LikesAndDislikes.LikedPost = 1) AS NumberOfLikes, 
          SUM(LikesAndDislikes.LikedPost = 0) AS NumberOfDislikes, 
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
     return postStats

def getPostsOfUser(userId: int):
        cursor = databaseConnection.cursor()
        # Get short user profile only onnce
        userId = 1
        shortUserProfile = getShortUserProfile(userId)
        posts = cursor.execute("SELECT * FROM Posts WHERE UserId = %s", (userId))

     # Format post add username, profile picture, and school name i.e short user profile
        posts = cursor.fetchall()
        for post in posts:
            post['Liked'] = getLikedPostStatus(post['PostId'], userId)
            post['User'] = getShortUserProfile(post['UserId'])
            post['PostStats'] = getPostStats(post['PostId'])
        return posts


def getPostStatistics(postId: int):
    cursor = databaseConnection.cursor()
    cursor.execute("SELECT * FROM PostStatistics WHERE PostId = %s", (postId))
    return cursor.fetchone()

def getPostsOfFollowing(userId: int):
    following = getFollowing(userId)
    posts = []
    for row in following:
        posts.append(getPostsOfUser(row['UserId_Following']))
    return posts

import json
from modules.account import getShortUserProfile
from  modules.main import databaseConnection
from flask import session

from datetime import datetime

class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super(DateTimeEncoder, self).default(obj)

def likeOrDislikePost(post_id, likeSetting:str, removeReaction):
    #like = True -> like
    #like = False -> dislike
    #post_id = id of post to like or dislike
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT * FROM LikesAndDislikes WHERE PostId = %s AND UserId = %s
    """, (post_id, session['userId']))
    result = cursor.fetchone()
    if result:
        if bool(int(removeReaction)):
            cursor.execute("""
                UPDATE LikesAndDislikes
                SET LikedStatus = 'none'
                WHERE PostId = %s AND UserId = %s
            """, (post_id, session['userId']))
        elif likeSetting is not None:
            cursor.execute("""
                UPDATE LikesAndDislikes
                SET LikedStatus = %s
                WHERE PostId = %s AND UserId = %s
            """, ('like', post_id, session['userId'])) if (likeSetting == 'like') else cursor.execute('''   UPDATE LikesAndDislikes
                SET LikedStatus = %s
                WHERE PostId = %s AND UserId = %s
            ''', ('dislike', post_id, session['userId'])) 
    else:
        if likeSetting is not None:
            cursor.execute("""
                INSERT INTO LikesAndDislikes(PostId, UserId, LikedStatus)
                VALUES (%s, %s, %s)
            """, (post_id, session['userId'], likeSetting))
    databaseConnection.commit()
    return 'Success', 200

def commentOnPost(post_id, comment, parentCommentId):
    # Check if parentCommentId is 0 then set it to SQL NULL
    if parentCommentId == '0':
        parentCommentId = None
        
    cursor = databaseConnection.cursor()
    cursor.execute("""
        INSERT INTO Comments(PostId, UserId, Comment, ParentCommentId)
        VALUES (%s, %s, %s, %s)
    """, (post_id, session['userId'], comment, parentCommentId))
    databaseConnection.commit()
    return 'Success', 200

def getComments(post_id):
    cursor = databaseConnection.cursor()

    def fetch_comments(parent_id):
        cursor.execute("""
            SELECT * FROM Comments WHERE ParentCommentId = %s
        """, (parent_id,))
        comments = cursor.fetchall()
        for comment in comments:
            comment['User'] = getShortUserProfile(comment['UserId'])
            comment['children'] = fetch_comments(comment['CommentId'])
        return comments

    cursor.execute("""
        SELECT * FROM Comments WHERE PostId = %s AND ParentCommentId IS NULL
    """, (post_id,))
    top_level_comments = cursor.fetchall()

    for comment in top_level_comments:
        comment['User'] = getShortUserProfile(comment['UserId'])
        comment['children'] = fetch_comments(comment['CommentId'])

    return json.dumps(top_level_comments, cls=DateTimeEncoder)

# def getRealIdsForNotLoggedInUSers(newestViewedPostId_first: int, oldestViewedPostId_first: int, newestViewedPostId_second: int, oldestViewedPostId_second: int): 
#      # Check if the newId is newer than the newestViewedPostId and if it is, then return the newId
#      # Also check if the oldId is older than the oldestViewedPostId and if it is, then return the oldId
#     cursor = databaseConnection.cursor()
#      # Get the IDs
#           # Fetch DateArrangedId for the given PostId
#     cursor.execute("""
#                SELECT 
#                     PostId,
#                     DateArrangedId AS DateArrangedId
#                FROM DateArrangedPosts
#                WHERE PostId IN (%s, %s, %s, %s)
#      """, (newestViewedPostId_first, newestViewedPostId_second, oldestViewedPostId_first, oldestViewedPostId_second))
     
#     dateArrangedIds = cursor.fetchall()
#     dateArrangedId_dict = {result['PostId']: result['DateArrangedId'] for result in dateArrangedIds}

#     newestViewedDateArrangedId_first = dateArrangedId_dict.get(newestViewedPostId_first, 0)
#     oldestViewedDateArrangedId_first = dateArrangedId_dict.get(oldestViewedPostId_first, 0)
#     newestViewedDateArrangedId_second = dateArrangedId_dict.get(newestViewedPostId_second, 0)
#     oldestViewedDateArrangedId_second = dateArrangedId_dict.get(oldestViewedPostId_second, 0)
     
#     # Execute the main query
#         # Execute the main query using PostId
#     cursor.execute("""
#             SELECT 
#                 MAX(CASE WHEN DateArrangedId IN (%s, %s) THEN PostId ELSE NULL END) as NewestViewedPostId,
#                 MIN(CASE WHEN DateArrangedId IN (%s, %s) THEN PostId ELSE NULL END) as OldestViewedPostId
#             FROM DateArrangedPosts
#             WHERE DateArrangedId IN (%s, %s, %s, %s)
#     """, (newestViewedDateArrangedId_second, newestViewedDateArrangedId_first, oldestViewedDateArrangedId_second, oldestViewedDateArrangedId_first, newestViewedDateArrangedId_second, newestViewedDateArrangedId_first, oldestViewedDateArrangedId_second, oldestViewedDateArrangedId_first))
    
#     result = cursor.fetchone()
#     newestViewedPostId = result['NewestViewedPostId'] if result['NewestViewedPostId'] is not None else 0
#     oldestViewedPostId = result['OldestViewedPostId'] if result['OldestViewedPostId'] is not None else 0
#     return newestViewedPostId, oldestViewedPostId

def getRealIdsForNotLoggedInUSers(newestViewedPostId_first: int, oldestViewedPostId_first: int, newestViewedPostId_second: int, oldestViewedPostId_second: int): 
    print((newestViewedPostId_first, newestViewedPostId_second, oldestViewedPostId_first, oldestViewedPostId_second))
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT
            (SELECT PostId FROM DateArrangedPosts WHERE DateArrangedId = 
                (SELECT MIN(DateArrangedId) FROM DateArrangedPosts WHERE PostId IN (%s, %s, %s, %s))) 
                AS NewestViewedPostId,
            (SELECT PostId FROM DateArrangedPosts WHERE DateArrangedId = 
                (SELECT MAX(DateArrangedId) FROM DateArrangedPosts WHERE PostId IN (%s, %s, %s, %s))) 
                AS OldestViewedPostId
    """, (newestViewedPostId_first, newestViewedPostId_second, oldestViewedPostId_first, oldestViewedPostId_second, newestViewedPostId_first, newestViewedPostId_second, oldestViewedPostId_first, oldestViewedPostId_second))
    
    results = cursor.fetchone()
    newestViewedPostId = results['NewestViewedPostId'] if results['NewestViewedPostId'] is not None else 0
    oldestViewedPostId = results['OldestViewedPostId'] if results['OldestViewedPostId'] is not None else 0
    print(newestViewedPostId, oldestViewedPostId)
    # newestViewedPostId = next((result['NewestViewedPostId'] for result in results if 'NewestViewedPostId' in result), 0)
    # oldestViewedPostId = next((result['OldestViewedPostId'] for result in results if 'OldestViewedPostId' in result), 0)

    return newestViewedPostId, oldestViewedPostId
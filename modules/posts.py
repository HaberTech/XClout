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

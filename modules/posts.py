from  modules.main import databaseConnection
from flask import session


def likeOrDislikePost(post_id, like, removeReaction):
    #like = True -> like
    #like = False -> dislike
    #post_id = id of post to like or dislike
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT * FROM LikedPosts WHERE PostId = %s AND UserId = %s
    """, (post_id, session['userId']))
    result = cursor.fetchone()
    if result:
        if like is not None:
            cursor.execute("""
                UPDATE LikesAndDislikes
                SET LikedPost = %s
                WHERE PostId = %s AND UserId = %s
            """, (int(like), post_id, session['userId']))
        elif removeReaction:
            cursor.execute("""
                UPDATE LikesAndDislikes
                SET LikedPost = NULL
                WHERE PostId = %s AND UserId = %s
            """, (post_id, session['userId']))
    else:
        if like is not None:
            cursor.execute("""
                INSERT INTO LikedAndDislikes(PostId, UserId, LikedPost)
                VALUES (%s, %s, %s)
            """, (post_id, session['userId'], int(like)))
    databaseConnection.commit()

def commentOnPost(post_id, comment, parentCommentId):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        INSERT INTO Comments(PostId, UserId, Comment, ParentCommentId)
        VALUES (%s, %s, %s, %s)
    """, (post_id, session['userId'], comment, parentCommentId))
    databaseConnection.commit()

def getComments(post_id):
    cursor = databaseConnection.cursor()

    def fetch_comments(parent_id):
        cursor.execute("""
            SELECT * FROM Comments WHERE ParentCommentId = %s
        """, (parent_id,))
        comments = cursor.fetchall()
        for comment in comments:
            comment['children'] = fetch_comments(comment['CommentId'])
        return comments

    cursor.execute("""
        SELECT * FROM Comments WHERE PostId = %s AND ParentCommentId IS NULL
    """, (post_id,))
    top_level_comments = cursor.fetchall()

    for comment in top_level_comments:
        comment['children'] = fetch_comments(comment['CommentId'])

    return top_level_comments

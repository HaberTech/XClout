from flask import Flask

from modules.main import *
from modules.account import getFollowing, getPostsOfFollowing, getPostsOfSchool
from modules.posts import commentOnPost, getComments, likeOrDislikePost
from modules.signup import loginUser, signUp
from modules.chat import getChatContacts, getConversation, sendGroupMessage, sendMessage

@app.route('/')
def hello_world():
    return 'Hello, World!'

# Check if user is logged in
@app.route('/isUserLoggedIn')
def isuserloggedin():
    return '1' if Session.get('userId') is not None else '0' 

@app.route('/getFollowing/<userId>')
def getfollowing(userId):
    return getFollowing(userId)

# Get posts of following
@app.route('/getPostsOfFollowing')
def getpostsoffollowing():
    # return getPostsOfFollowing(Session.get('userId'))
    userId: int = Session.get('userId')
    lastPostId: int = request.args.get('lastViewedPostId')
    # return (f'userId: {userId}, lastPostId: {lastPostId}')
    return getPostsOfSchool(userId=userId, lastPostId=lastPostId)

@app.route('/getListOfSchools')
def getListOfSchools():
    cursor = databaseConnection.cursor()
    cursor.execute("SELECT SchoolId, SchoolName FROM Schools")
    return cursor.fetchall()

@app.route('/signUp', methods=['POST'])
def signp():
    return signUp(request, 'uploads')

@app.route('/loginUser', methods=['POST'])
def loginuser():
    return loginUser(request, Session)

@app.route('/likeOrDislikePost', methods=['GET'])
def likeordislikepost():
    return likeOrDislikePost(request.args.get('postId'), request.args.get('likeSetting'), request.args.get('removeReaction'))

@app.route('/comments', methods=['GET'])
def comments():
    print(dict(request.args))
    if(request.args.get('postId') is None):
        return 'Missing required fields', 400
    if(request.args.get('action') == 'getComments'):
        print('getComments')
        return getComments(request.args.get('postId'))
    elif(request.args.get('action') == 'commentOnPost'):
        return commentOnPost(request.args.get('postId'), request.args.get('comment'), request.args.get('parentCommentId'))
    
@app.route('/getConversation')
def get_conversation():
    if(request.args.get('type') == 'list'):
        print('List')
        return getChatContacts(Session.get('userId'))
    elif(request.args.get('type') == 'direct'):
        print('Singular')
        return getConversation(user_id_receiver=Session.get('userId'), user_id_sender=request.args.get('otherUserId'))
    
@app.route('/sendMessage', methods=['POST'])
def send_message():
    if(request.args.get('type') == 'direct'):
        print(request.form.get('receiverId'))
        print('Singular')
        return sendMessage(from_user_id= Session.get('userId'), to_user_id=request.form.get('receiverId'), message=request.form.get('message'))
    elif(request.args.get('type') == 'group'):
        print('Group')
        return sendGroupMessage(group_id=request.args.get('groupId'), from_user_id= Session.get('userId'), message= request.form.get('message'))

if __name__ == '__main__':
    app.run(debug=True, port=8000, host='0.0.0.0')
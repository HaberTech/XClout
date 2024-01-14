import os
import time, requests, threading
from flask import Flask, request, session as Session, send_from_directory
from flask_cors import CORS

from modules.main import *
from modules.account import getFollowing, getPostsOfFollowing, getPostsOfSchool
from modules.posts import commentOnPost, getComments, likeOrDislikePost
from modules.signup import loginUser, signUp
from modules.chat import getChatContacts, getConversation, sendGroupMessage, sendMessage

app = Flask(__name__)
app.secret_key = 'TheTempoaryXcloutDebugSecret'
CORS(app)

appHasRunBefore:bool = False;
FLUTTER_BASE_DIRECTORY:str = os.environ.get('FLUTTER_BASE_DIRECTORY', '/Users/cedrick/Projects/Flutter/Xclout/build/web')
print("Current Flutter Base Directory => ", FLUTTER_BASE_DIRECTORY)

# Ping this to check if server is up
@app.route('/api/ping')
def ping():
    return 'OK'

# Check if user is logged in
@app.route('/api/isUserLoggedIn')
def isuserloggedin():
    return '1' if Session.get('userId') is not None else '0' 

@app.route('/api/getFollowing/<userId>')
def getfollowing(userId):
    return getFollowing(userId)

# Get posts of following
@app.route('/api/getPostsOfFollowing')
def getpostsoffollowing():
    # return getPostsOfFollowing(Session.get('userId'))
    userId: int = Session.get('userId')
    newestViewedPostId: int = int(request.args.get('newestViewedPostId'))
    oldestViewedPostId: int = int(request.args.get('oldestViewedPostId'))
    if userId is None:
        userId = 2;
    print('newestViewedPostId: ' + str(newestViewedPostId), 'oldestViewedPostId: ' + str(oldestViewedPostId), 'userId: ' + str(userId))
    return getPostsOfSchool(userId=userId, newestViewedPostId=newestViewedPostId, oldestViewedPostId=oldestViewedPostId)

@app.route('/api/getListOfSchools')
def getListOfSchools():
    cursor = databaseConnection.cursor()
    cursor.execute("SELECT SchoolId, SchoolName FROM Schools")
    return cursor.fetchall()

@app.route('/api/signUp', methods=['POST'])
def signp():
    return signUp(request, 'uploads')

@app.route('/api/loginUser', methods=['POST'])
def loginuser():
    return loginUser(request, Session)

@app.route('/api/likeOrDislikePost', methods=['GET'])
def likeordislikepost():
    return likeOrDislikePost(request.args.get('postId'), request.args.get('likeSetting'), request.args.get('removeReaction'))

@app.route('/api/comments', methods=['GET'])
def comments():
    print(dict(request.args))
    if(request.args.get('postId') is None):
        return 'Missing required fields', 400
    if(request.args.get('action') == 'getComments'):
        print('getComments')
        return getComments(request.args.get('postId'))
    elif(request.args.get('action') == 'commentOnPost'):
        return commentOnPost(request.args.get('postId'), request.args.get('comment'), request.args.get('parentCommentId'))
    
@app.route('/api/getConversation')
def get_conversation():
    if(request.args.get('type') == 'list'):
        print('List')
        return getChatContacts(Session.get('userId'))
    elif(request.args.get('type') == 'direct'):
        print('Singular')
        return getConversation(user_id_receiver=Session.get('userId'), user_id_sender=request.args.get('otherUserId'))
    
@app.route('/api/sendMessage', methods=['POST'])
def send_message():
    if(request.args.get('type') == 'direct'):
        print(request.form.get('receiverId'))
        print('Singular')
        return sendMessage(from_user_id= Session.get('userId'), to_user_id=request.form.get('receiverId'), message=request.form.get('message'))
    elif(request.args.get('type') == 'group'):
        print('Group')
        return sendGroupMessage(group_id=request.args.get('groupId'), from_user_id= Session.get('userId'), message= request.form.get('message'))
    

@app.route('/')
def serve_flutter_home():
    return send_from_directory(FLUTTER_BASE_DIRECTORY, 'index.html')

@app.route('/show/uploads/<path:path>')
def serveUploads(path):
    return send_from_directory('modules/server/uploads', path)

@app.route('/<path:path>')
def serve_flutterweb_resource(path):
    print(path)
    return send_from_directory(FLUTTER_BASE_DIRECTORY, path)

# @app.before_request
# def firstRun():
#     global appHasRunBefore
#     if not appHasRunBefore:
#         # Replace 'your_service_url' with the actual URL of your service
#         thread = threading.Thread(target=keep_alive, args=())
#         thread.start()
#         appHasRunBefore = True


def keep_alive():
    interval:int = 600
    url:str = os.environ.get('SERVICE_URL', 'https://xclout.habertech.info/api/ping')
    while True:
        try:
            requests.get(url, verify=False)
            print(f"########### PINGED SELF ##########")
            time.sleep(interval)
        except requests.exceptions.RequestException as e:
            print(f"Error pinging {url}: {str(e)}")
            time.sleep(60)

if __name__ == '__main__':
    app.run(debug=True, port=8000, host='0.0.0.0')
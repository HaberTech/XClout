from flask import Flask

from modules.main import *
from modules.account import getFollowing, getPostsOfFollowing
from modules.signup import signUp

@app.route('/')
def hello_world():
    return 'Hello, World!'

@app.route('/getFollowing/<userId>')
def getfollowing(userId):
    return getFollowing(userId)

# Get posts of following
@app.route('/getPostsOfFollowing/<userId>')
def getpostsoffollowing(userId):
    return getPostsOfFollowing(userId)

@app.route('/getListOfSchools')
def getListOfSchools():
    cursor = databaseConnection.cursor()
    # cursor.execute("SELECT SchoolId, SchoolName FROM Schools")
    return cursor.fetchall("SELECT SchoolId, SchoolName FROM Schools")

@app.route('/signUp', methods=['POST'])
def signp():
    return signUp(request, 'uploads')

if __name__ == '__main__':
    app.run(debug=True, port=8000, host='0.0.0.0')
import os
from flask import request as FlaskRequest, session as FlaskSession
from modules.main import databaseConnection, app

def signUp(request: FlaskRequest, saveDirectory: str):
    username: str = request.form.get('userName')
    schoolId = request.form.get('schoolId')
    email = request.form.get('email')
    phoneNumber = request.form.get('phoneNumber')
    password = request.form.get('password')
    confirmPassword = request.form.get('confirmPassword')
    fullName = request.form.get('fullName')

    schoolIdPhoto = request.files.get('schoolIdPhoto')
    verfificationPhoto = request.files.get('verificationPhoto')

    if not username or not password or not email or not confirmPassword or not fullName or not schoolIdPhoto or not verfificationPhoto:
        return 'Missing required fields', 400
    
    # Check if passwords match
    if password != confirmPassword:
        return 'Passwords do not match', 400
    
    # Check if username is taken
    if isUsernameTaken(username):
        return 'Username is taken', 400
    
    schoolIdPhotoPath = f'{username}_{email}_schoolIdPhoto.jpg'
    verfificationPhotoPath = f'{username}_{email}_verificationPhoto.jpg'

    schoolIdPhoto.save(os.path.join(saveDirectory, schoolIdPhotoPath))
    verfificationPhoto.save(os.path.join(saveDirectory, verfificationPhotoPath))


    cursor = databaseConnection.cursor()
    cursor.execute("INSERT INTO Users (Username, PassKey, Email, PhoneNumber, FullName, SchoolIdPhoto, VerificationPhoto, SchoolId, Name) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)", (username, password, email, phoneNumber, fullName, schoolIdPhotoPath, verfificationPhotoPath, schoolId, fullName))
    databaseConnection.commit()
    return 'Account-Created', 200


def loginUser(request: FlaskRequest, session: FlaskSession):
    username = request.form.get('username')
    password = request.form.get('password')

    if not username or not password:
        return 'Missing required fields', 400

    cursor = databaseConnection.cursor()
    cursor.execute("SELECT * FROM UserName WHERE Username = %s AND Password = %s", (username, password))
    user = cursor.fetchone()
    if user is None:
        return 'Invalid username or password', 400
    session['userId'] = user['UserId']
    return 'Logged-In', 200

@app.route('/isUsernameTaken/<username>')
# Check if username is taken
def isUsernameTaken(username: str):
    cursor = databaseConnection.cursor()
    # cursor.execute("SELECT Username FROM Users WHERE Username = %s", (username))
    if cursor.fetchone("SELECT Username FROM Users WHERE Username = %s", (username)) is not None:
        return True
    return False

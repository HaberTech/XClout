from modules.main import databaseConnection

def getConversations(user_id):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT UserId_From, UserId_To, Message, DateSent
        FROM Messages
        WHERE UserId_From = %s OR UserId_To = %s
        UNION ALL
        SELECT UserId_From, GroupId AS UserId_To, Message, DateSent
        FROM GroupMessages
        WHERE UserId_From = %s
        ORDER BY DateSent
    """, (user_id, user_id, user_id))
    return cursor.fetchall()

def sendGroupMessage(group_id, from_user_id, message):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        INSERT INTO GroupMessages (GroupId, UserId_From, Message)
        VALUES (%s, %s, %s)
    """, (group_id, from_user_id, message))
    databaseConnection.commit()
    
def sendMessage(from_user_id, to_user_id, message):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        INSERT INTO Messages (UserId_From, UserId_To, Message, IsRead)
        VALUES (%s, %s, %s, %s)
    """, (from_user_id, to_user_id, message, False))
    databaseConnection.commit()

def getConversation(user_id_1, user_id_2):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT * FROM Messages
        WHERE (UserId_From = %s AND UserId_To = %s) OR (UserId_From = %s AND UserId_To = %s)
        ORDER BY DateSent
    """, (user_id_1, user_id_2, user_id_2, user_id_1))
    messages = cursor.fetchall()
    
    # Mark all messages from the other user as read
    cursor.execute("""
        UPDATE Messages SET IsRead = %s
        WHERE UserId_From = %s AND UserId_To = %s
    """, (True, user_id_2, user_id_1))
    databaseConnection.commit()
    return messages

def getGroupConversation(group_id):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT * FROM GroupMessages
        WHERE GroupId = %s
        ORDER BY DateSent
    """, (group_id,))
    return cursor.fetchall()

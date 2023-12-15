import json
from modules.main import databaseConnection, getShortUserProfile

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

def getChatContacts(user_id):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT m.UserId_From, m.UserId_To, m.Message, m.DateSent, m.IsRead
        FROM Chats m
        JOIN (
            SELECT LEAST(UserId_From, UserId_To) AS UserId1, GREATEST(UserId_From, UserId_To) AS UserId2, MAX(DateSent) AS MaxDate
            FROM Chats
            WHERE UserId_From = %s OR UserId_To = %s
            GROUP BY UserId1, UserId2
        ) subq ON ((m.UserId_From = subq.UserId1 AND m.UserId_To = subq.UserId2) OR (m.UserId_From = subq.UserId2 AND m.UserId_To = subq.UserId1)) AND m.DateSent = subq.MaxDate
        UNION ALL
        SELECT gm.UserId_From, gm.GroupId AS UserId_To, gm.Message, gm.DateSent, NULL AS IsRead
        FROM GroupChats gm
        JOIN (
            SELECT UserId_From, GroupId, MAX(DateSent) AS MaxDate
            FROM GroupChats
            WHERE UserId_From = %s
            GROUP BY UserId_From, GroupId
        ) subq ON (gm.UserId_From = subq.UserId_From AND gm.GroupId = subq.GroupId AND gm.DateSent = subq.MaxDate)
        ORDER BY DateSent
    """, (user_id, user_id, user_id))

    contacts = cursor.fetchall()
    for contact in contacts:
        otherUserId = contact['UserId_From'] if contact['UserId_From'] != user_id else contact['UserId_To']
        contact['OtherUser'] = getShortUserProfile(otherUserId)
    
    if(len(contacts) == 0):
        return json.dumps([])
    return contacts

def sendGroupMessage(group_id, from_user_id, message):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        INSERT INTO GroupChats (GroupId, UserId_From, Message)
        VALUES (%s, %s, %s)
    """, (group_id, from_user_id, message))
    databaseConnection.commit()
    return 'Success', 200
    
def sendMessage(from_user_id, to_user_id, message):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        INSERT INTO Chats (UserId_From, UserId_To, Message, IsRead)
        VALUES (%s, %s, %s, %s)
    """, (from_user_id, to_user_id, message, False))
    databaseConnection.commit()
    return 'Success', 200

def getConversation(user_id_sender, user_id_receiver):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT * FROM Chats
        WHERE (UserId_From = %s AND UserId_To = %s) OR (UserId_From = %s AND UserId_To = %s)
        ORDER BY DateSent
    """, (user_id_sender, user_id_receiver, user_id_receiver, user_id_sender))
    messages = cursor.fetchall()
    
    # Mark all messages from the other user as read
    cursor.execute("""
        UPDATE Chats SET IsRead = %s
        WHERE UserId_From = %s AND UserId_To = %s
    """, (True, user_id_sender, user_id_receiver))
    databaseConnection.commit()
    return messages, 200

def getGroupConversation(group_id):
    cursor = databaseConnection.cursor()
    cursor.execute("""
        SELECT * FROM GroupMessages
        WHERE GroupId = %s
        ORDER BY DateSent
    """, (group_id,))
    return cursor.fetchall()

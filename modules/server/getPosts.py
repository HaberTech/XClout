import json
from random import randint
from time import sleep

from instagrapi import *
from instagrapi.types import Media

from typing import List
import sys
sys.path.append('/Users/cedrick/Projects/Python/Xclout-Backend')
from modules.main import databaseConnection


# # GO THROUGH SCHOOLS IN DATABASE
# cursor = databaseConnection.cursor()
# cursor.execute("SELECT SchoolId, SchoolName, IG_Username FROM Schools")
# schools = cursor.fetchall()


# for school in schools:
#     school_id = school['SchoolId']
#     school_name = school['SchoolName']
#     school_ig_username = school['IG_Username']

def getSchoolMedia(school_ig_username):
    print('\nRetrieving posts for ' + school_ig_username + '...')

    school_ig_id = cl.user_id_from_username(school_ig_username)
    media = cl.user_medias(school_ig_id)

    print('Successfully retrieved ' + str(len(media)) + ' posts for ' + school_ig_username + '!')
    return media

def storeSchoolMediaInDatabase(school_id:int, school_ig_username:str, media:List[Media]):
    print('Storing posts for ' + school_ig_username + ' in database...')

    global totalNoOfNewPosts
    global totalNoOfPostsStored
    cursor = databaseConnection.cursor()

    for post in media:
        # get the resources 'thumbnail_url's and use them as resources
        resources = [resource.thumbnail_url for resource in post.resources]
        # get the resource types and use them as resource types
        resource_types = [resource.media_type for resource in post.resources]


        cursor.execute("""
            INSERT INTO Posts (UserId, SchoolId, Caption, Resources, ResourceTypes, SourcePlatform, SourceUsername, MediaPk, DateAdded, NumberOfShares)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            /* Check if the post exists */
            ON DUPLICATE KEY UPDATE
            UserId = VALUES(UserId), 
            SchoolId = VALUES(SchoolId), 
            Caption = VALUES(Caption), 
            Resources = VALUES(Resources), 
            ResourceTypes = VALUES(ResourceTypes), 
            SourcePlatform = VALUES(SourcePlatform), 
            DateAdded = VALUES(DateAdded), 
            NumberOfShares = VALUES(NumberOfShares)
        """, ('4', school_id, post.caption_text, json.dumps(resources), json.dumps(resource_types), 'IG', post.user.username, int(post.pk), post.taken_at, post.like_count))

        # # Reset AUTO_INCREMENT value
        # cursor.execute("""
        #     ALTER TABLE Posts AUTO_INCREMENT = 0
        # """)
    databaseConnection.commit()
    totalNoOfPostsStored = totalNoOfPostsStored + len(media)
    print('Successfully stored ' + str(len(media)) + ' posts for ' + school_ig_username + ' in database!')
    print(f"Total number of new posts: {str(totalNoOfNewPosts)} == Total number of posts stored: {str(totalNoOfPostsStored)} ")

def uploadPostsForSchool(school_id:int, school_ig_username:str):
    media = getSchoolMedia(school_ig_username)
    storeSchoolMediaInDatabase(school_id=school_id, school_ig_username=school_ig_username, media=media)

def refreshAllSchoolsPosts():
    # GO THROUGH SCHOOLS IN DATABASE
    cursor = databaseConnection.cursor()
    cursor.execute("SELECT SchoolId, SchoolName, IG_Username FROM Schools")
    schools = cursor.fetchall()
    print('Refreshing posts for ' + str(len(schools)) + ' schools...')
    schoolsToAvoid:List  = ['ig.bweranyangi', 'ig_men.go', 'ig_kawempe_muslim', 'buddo_ss_001', 'greenhillacademyug', 'ig_spena', 'kabojja_international__school', 'gisuinfo','hana_ig', 'viennacollegenamugongo', 'heritage.uganda', '7hillsinternationalschool','ig_viva_', 'elite_coolkids', 'agakhan.high', 'ig.gayaza', 'kiira_college','smack_ist','ig_namugongo','macosians_','ig_maryhill_', 'ig_tricona', 'ig.sunsas', 'ig.namagunga', 'ig._namilyango','ndejje.an', 'ntare_sch', 'ig_joginsa1', 'rubaga.girls_ss', 'olgc_ig', 'bishopciprianokihangire', 'smaskgram_official','seetahighschools','ig._taibah']

    for school in schools:
        school_id = school['SchoolId']
        school_ig_username = school['IG_Username']

        if((school_ig_username == None or school_id== None) or
            (school_ig_username == '' or school_ig_username== '') or 
            school_ig_username in schoolsToAvoid):
            print('Skipping ', school)
            continue
        else:
            uploadPostsForSchool(school_id=school_id, school_ig_username=school_ig_username)
            timeToSleep = randint(3, 7)
            print(f"Sleeping for {timeToSleep} seconds...")
            sleep(timeToSleep);

if __name__ == '__main__':
    global totalNoOfNewPosts
    global totalNoOfPostsStored

    totalNoOfNewPosts:int = 0;
    totalNoOfPostsStored:int = 0;

    cl = Client();
    cl.login_by_sessionid("37565592330%3Aq7Y2YxWEm6l1mF%3A14%3AAYduRr3hO2Zd_KNQYesBuU-W3CR654VSTWhHP-RlRQ")
    try:
        thisBot = cl.account_info()
        print(f"Logged in as {thisBot.username}\n")
        try: refreshAllSchoolsPosts();
        except Exception as e : raise e
    except Exception as e2:
        print("Login Error. FUCK!!!!!!...\n")
        raise e2
#  caffeinate -i -s /opt/homebrew/bin/python3 /Users/cedrick/Projects/Python/Xclout-Backend/modules/server/getPosts.py
from datetime import datetime, timedelta
import json
import os
from random import randint
from time import sleep

from instagrapi import *
from instagrapi.types import Media

from typing import List
import sys

from regex import P
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

def storeSchoolsLastCheckedDate(schoolId:int, school_ig_username:str):
    # Load the existing data
    with open('modules/server/schools_done.json', 'r') as f:
        schoolsLastCheckedDate = json.load(f)

    # Update the data
    schoolsLastCheckedDate[schoolId] = {
        'igUsername': school_ig_username,
        'lastChecked': datetime.now().strftime("%d/%m/%Y, %H:%M:%S")
    }

    # Save the updated data
    with open('modules/server/schools_done.json', 'w') as f:
        json.dump(schoolsLastCheckedDate, f)
  

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
        """, ('1', school_id, post.caption_text, json.dumps(resources), json.dumps(resource_types), 'IG', post.user.username, int(post.pk), post.taken_at, post.like_count))

        # # Reset AUTO_INCREMENT value
        # cursor.execute("""
        #     ALTER TABLE Posts AUTO_INCREMENT = 0
        # """)
    databaseConnection.commit()
    totalNoOfPostsStored = totalNoOfPostsStored + len(media)
    storeSchoolsLastCheckedDate(schoolId=school_id, school_ig_username=school_ig_username)
    print('Successfully stored ' + str(len(media)) + ' posts for ' + school_ig_username + ' in database!')
    print(f"Total number of new posts: {str(totalNoOfNewPosts)} == Total number of posts stored: {str(totalNoOfPostsStored)} ")

def uploadPostsForSchool(school_id:int, school_ig_username:str):
    media = getSchoolMedia(school_ig_username)
    storeSchoolMediaInDatabase(school_id=school_id, school_ig_username=school_ig_username, media=media)

def refreshAllSchoolsPosts():
    # GO THROUGH SCHOOLS IN DATABASE
    # Load file /modules/server/schools_done.json
    cursor = databaseConnection.cursor()
    cursor.execute("SELECT SchoolId, SchoolName, IG_Username FROM Schools")
    schools = cursor.fetchall()
    print('Refreshing posts for ' + str(len(schools)) + ' schools...')
    schoolsToAvoid:List = []
    #  ['heritage.uganda', 'gisuinfo', '7hillsinternationalschool']
    schoolsDone:List  = ['ig.bweranyangi', 'ig_men.go', 'ig_kawempe_muslim',
    # 'buddo_ss_001', 'greenhillacademyug', 'ig_spena', 'kabojja_international__school', 'gisuinfo','hana_ig', 'viennacollegenamugongo', 'heritage.uganda', '7hillsinternationalschool','ig_viva_', 'elite_coolkids', 'agakhan.high', 'ig.gayaza', 'kiira_college','smack_ist','ig_namugongo','macosians_','ig_maryhill_', 'ig_tricona', 'ig.sunsas', 'ig.namagunga', 'ig._namilyango','ndejje.an', 'ntare_sch', 'ig_joginsa1', 'rubaga.girls_ss', 'olgc_ig', 'bishopciprianokihangire', 'smaskgram_official','seetahighschools','ig._taibah'
    ]

        # Load file /modules/server/schools_done.json
    with open('modules/server/schools_done.json', 'r') as f:
        schoolsLastCheckedDate = json.load(f)

    for school in schools:
        school_id = school['SchoolId']
        school_ig_username = school['IG_Username']

        # Check if the school's Instagram username or ID is None or empty
        if not school_ig_username or not school_id:
            print('Skipping due to bad school object', school)
            continue
        print(schoolsLastCheckedDate)
        print(school_id, school_ig_username)
        # Check if the school was checked before
        if school_id not in schoolsLastCheckedDate or schoolsLastCheckedDate[school_id]['lastChecked'] is None:
            print(f'No check date for {school_ig_username}, processing it now')
        else:
            last_checked_date = datetime.strptime(schoolsLastCheckedDate[school_id]['lastChecked'], '%d/%m/%Y, %H:%M:%S')

            # Check if the school was checked less than 3 days ago
            if (datetime.now() - last_checked_date) < timedelta(days=3):
                print(f'Skipping {school_ig_username}, it was checked less than 3 days ago')
                continue

        # Everything fine, continue
        uploadPostsForSchool(school_id=school_id, school_ig_username=school_ig_username)
        timeToSleep = randint(3*60, 5*60) # 3 to 5 minutes
        print(f"Sleeping for {timeToSleep/60} Minutes...")
        sleep(timeToSleep);
      

def initialiseIgClient():
    cl = Client();
    # USERNAME = 'ask_ur_mom_to_follow_me_coz_i'
    USERNAME = 'dking_rw'
    PASSWORD = 'donaldtrump2'
    settings_path = f'modules/server/{USERNAME}-settings.json'


    # Check if the file is empty or does not exist
    if not os.path.exists(settings_path) or os.stat(settings_path).st_size == 0:
        # If it is, initialize cl with default settings
        print('Initialising client with default settings...')
        cl.set_locale('en_UG')
        cl.set_country_code(256)
        cl.set_timezone_offset(-3 * 60 * 60) # UTC-3
        cl.login(username=USERNAME, password=PASSWORD)
        cl.dump_settings(path=settings_path)
    else:
        print('Initialising client with saved settings...')
        # Load the settings into th client
        cl.load_settings(path=settings_path)
        cl.login(username=USERNAME, password=PASSWORD)

    return cl

if __name__ == '__main__':
    global totalNoOfNewPosts
    global totalNoOfPostsStored

    totalNoOfNewPosts:int = 0;
    totalNoOfPostsStored:int = 0;

    cl = initialiseIgClient();
    try:
        thisBot = cl.account_info()
        print(f"Logged in as {thisBot.username}\n")
        try: refreshAllSchoolsPosts();
        except Exception as e : raise e
    except Exception as e2:
        print("Login Error. FUCK!!!!!!... Retrying\n")
        try:
            cl.relogin()
            print('Success 1')
            refreshAllSchoolsPosts()
        except Exception as e:
            print('Failed 1', e)
            try:
                cl.relogin()
                print('Success 2')
                refreshAllSchoolsPosts()
            except Exception as e:
                print('Failed 2', e)
#  caffeinate -i -s /opt/homebrew/bin/python3 /Users/cedrick/Projects/Python/Xclout-Backend/modules/server/getPosts.py
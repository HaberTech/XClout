import os
import json
import requests

from time import sleep
from typing import List
from random import randint
from datetime import datetime, timedelta

from instagrapi import *
from instagrapi.types import Media


import sys
sys.path.append('/Users/cedrick/Projects/Python/Xclout-Backend')
from modules.main import databaseConnection

# Store the resource in the approipriate folders
def storePostResources(school_ig_username, resources, resource_types):
    newResources = []
    mainResourceFolder = ''
    mediaDownloadIndex = 1

    for i, resource in enumerate(resources):
        subFolder = 'images' if resource_types[i] == 1 else 'videos'
        # Split the url then remove the query string
        ig_filename = resource.split('/')[-1].split('?')[0]
        filename = school_ig_username + '--' + ig_filename
        filepath = os.path.join(mainResourceFolder, subFolder, filename)

        # If file exists in the folder, skip it
        if os.path.exists(filepath):
            newResources.append(filename)
            continue

        # Download the file
        try:
            print(f'Downloading {subFolder} as resource {mediaDownloadIndex}...')
            response = requests.get(resource, stream=True)
            response.raise_for_status()  # Raise an exception if the GET request was unsuccessful

            # Save the file
            with open(filepath, 'wb') as f:
                # for chunk in response.iter_content(chunk_size=8192):
                for chunk in response.iter_content(chunk_size=2097152): #2MB
                    f.write(chunk)
            newResources.append(filename)
            # print(f'Successfully downloaded {resource}!')
        except Exception as e:
            print(f'Failed to download {resource}!')
            print(e)
        mediaDownloadIndex+=1

    return newResources


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
    global totalNoOfNewPosts
    global totalNoOfPostsStored
    postsIndex = 1
    cursor = databaseConnection.cursor()

    for post in media:        
        # Get to store the resources and resource types
        oldResources = []
        resource_types = []

        # If the post is a single post with only one post then the whole post is the resource
        if(post.media_type != 8):
            # Convert the whole post to the resource and resource type
            oldResources.append(str(post.thumbnail_url if post.media_type == 1 else str(post.video_url)))
            resource_types.append(post.media_type)
        else:
            # If it is and album get the resources urls and use them to download the neccessary files
            for resource in post.resources:
                oldResources.append(str(resource.thumbnail_url) if resource.media_type == 1 else str(resource.video_url))
            resource_types = [resource.media_type for resource in post.resources]

        resources = storePostResources(school_ig_username=school_ig_username, resources=oldResources, resource_types=resource_types);
       
        print(f'Preparing post {postsIndex} for {school_ig_username} to be stored in database...')
        cursor.execute("""
            INSERT INTO Posts (UserId, SchoolId, Caption, Resources, ResourceTypes, SourcePlatform, SourceUsername, MediaPk, DatePosted, NumberOfShares)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            /* Check if the post exists */
            ON DUPLICATE KEY UPDATE
            UserId = VALUES(UserId), 
            SchoolId = VALUES(SchoolId), 
            Caption = VALUES(Caption), 
            Resources = VALUES(Resources), 
            ResourceTypes = VALUES(ResourceTypes), 
            SourcePlatform = VALUES(SourcePlatform), 
            DatePosted = VALUES(DatePosted), 
            NumberOfShares = VALUES(NumberOfShares)
        """, ('1', school_id, post.caption_text, json.dumps(resources), json.dumps(resource_types), 'IG', post.user.username, int(post.pk), post.taken_at, post.like_count))
        postsIndex += 1;

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
    schoolsDone:List  = [
        # 'ig.bweranyangi', 'ig_men.go', 'kawe_mpe_hub256, 'buddo_ss_001', 'greenhillacademyug', 'ig_spena', 'kabojja_international__school', 'gisuinfo','hana_ig', 'viennacollegenamugongo', 'heritage.uganda', '7hillsinternationalschool','ig_viva_', 'elite_coolkids', 'agakhan.high', 'ig.gayaza', 'kiira_college','smack_ist','ig_namugongo','macosians_','ig_maryhill_', 'ig_tricona', 'ig.sunsas', 'ig.namagunga', 'ig._namilyango','ndejje.an', 'ntare_sch', 'ig_joginsa1', 'rubaga.girls_ss', 'olgc_ig', 'bishopciprianokihangire', 'smaskgram_official','seetahighschools','ig._taibah'
    ]

        # Load file /modules/server/schools_done.json
    with open('modules/server/schools_done.json', 'r') as f:
        schoolsLastCheckedDate = json.load(f)

    for school in schools:
        school_id = school['SchoolId']
        school_ig_username = school['IG_Username']

        # Check if the school's Instagram username or ID is None or empty
        if not school_ig_username or not school_id or school_ig_username in ['ig_kawempe_muslim']:
            print('Skipping due to bad school object or forbidden', school)
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
    USERNAME = 'ask_ur_mom_to_follow_me_coz_i'
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
    totalNoOfNewPosts:int = 0
    totalNoOfPostsStored:int = 0

    cl = initialiseIgClient()
    try:
        thisBot = cl.get_timeline_feed()
        print("Logged in successfully")
        refreshAllSchoolsPosts()
    except Exception as e:
        print("Login Error. Retrying...")
        print('Error:', e)
        try:
            cl.relogin()
            print('Relogin attempt 1 successful')
            refreshAllSchoolsPosts()
        except Exception as e:
            print('Relogin attempt 1 failed:', e)
            try:
                cl.relogin()
                print('Relogin attempt 2 successful')
                refreshAllSchoolsPosts()
            except Exception as e:
                print('Relogin attempt 2 failed:', e)
#  caffeinate -i -s /opt/homebrew/bin/python3 /Users/cedrick/Projects/Python/Xclout-Backend/modules/server/getPosts.py
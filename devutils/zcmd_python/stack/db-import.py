STACK_ENV_VERSIONINFO="20190416.1"

import boto3
import botocore
import os, sys, datetime
from os.path import dirname, abspath
import subprocess
import zipfile
import shutil
from shutil import copyfile
import shlex
import argparse

ERRORCOUNT=0

print("STARTING IMPORT VERSION " + STACK_ENV_VERSIONINFO)

#Parse all the arguments
parser = argparse.ArgumentParser(description='Import application database')
parser.add_argument('APP_PLATFORM_NAME', help='AUTOMATIC App platform name (e.g., drupal)')
parser.add_argument('APP_PLATFORM_MAJOR_VERSION', help='AUTOMATIC App platform major version number (e.g., 7 or 8)')
parser.add_argument('SRC_FOLDERNAME', nargs='?', default='?', help='REQUIRED subfolder name (environment name from the export operation, ignored if -lc flag is used)')
parser.add_argument('SRC_FILENAME', nargs='?', default='?', help='REQUIRED filename to import (or ? to get listing of available files)')
parser.add_argument('--localcopy', '-lc', help='Import from local file system instead of s3', action='store_true')
parser.add_argument('--keepzip', '-kz', help='Keep the downloaded zip file instead of deleting it at the end', action='store_true')
args = parser.parse_args()

#Assign arguments to our internal variables
APP_PLATFORM_NAME=args.APP_PLATFORM_NAME
APP_PLATFORM_MAJOR_VERSION=args.APP_PLATFORM_MAJOR_VERSION
src_env_name = args.SRC_FOLDERNAME
file_name = args.SRC_FILENAME
LOCAL_FILES=args.localcopy
KEEP_ZIP=args.keepzip

print("... LOCAL_FILES = " + str(LOCAL_FILES))
print("... KEEP_ZIP = " + str(KEEP_ZIP))

if LOCAL_FILES and KEEP_ZIP:
    raise Exception("The --keepzip flag is only relevant for s3 downloads!")

APP_PLATFORM_ID = APP_PLATFORM_NAME+APP_PLATFORM_MAJOR_VERSION

print("## Importing database for " + APP_PLATFORM_ID)

if not LOCAL_FILES:
    print("## From environment " + src_env_name)

print("## From file name " + file_name)

from hostlib import environment

myenv = environment.Environment()

#Set some important values now
DOCKER_WEBSERVER = myenv.env_profile_vars['WEB_CONTAINERNAME'].strip()

BUCKET_NAME = myenv.env_profile_vars['SHARED_S3_STAGING_BUCKET_NAME']
BUCKET_PATH = myenv.env_profile_vars['S3_DBDUMPS_FILEDIR'] + "/" + APP_PLATFORM_ID

ENVNAME = myenv.env_profile_vars['ENVIRONMENT_NAME']
PROJECT = myenv.env_profile_vars['PROJECT_NAME']
BUCKET_ENV_PATH = BUCKET_PATH + '/' + ENVNAME

DRUSH_PATH_TO_WEBROOT = myenv.env_profile_vars['DOCROOT_PATH']

REPO_FOLDER_NAME = myenv.env_profile_vars['REPO_FOLDER_NAME']
WEB_DOCROOT_PATH = myenv.env_profile_vars['WEB_DOCROOT_PATH']
STACK_FOLDER_PATH = myenv.env_profile_vars['FOLDER_PATH']

WEB_HOST_SHARED_TMP_PATH=myenv.env_profile_vars['WEB_HOST_SHARED_TMP_PATH']
WEB_INTERNAL_SHARED_TMP_PATH=myenv.env_profile_vars['WEB_INTERNAL_SHARED_TMP_PATH']

print("## WEB_HOST_SHARED_TMP_PATH = " + WEB_HOST_SHARED_TMP_PATH)
print("## WEB_INTERNAL_SHARED_TMP_PATH = " + WEB_INTERNAL_SHARED_TMP_PATH)

#Check the platform name and version parameters
if APP_PLATFORM_NAME=='drupal':
    if APP_PLATFORM_MAJOR_VERSION == '7':
        DRUSH_DROP_CMD='sql-drop'
    elif APP_PLATFORM_MAJOR_VERSION == '8':
        DRUSH_DROP_CMD='sql:drop'
    else:
        raise Exception("INVALID APP_PLATFORM_MAJOR_VERSION="+APP_PLATFORM_MAJOR_VERSION)
else:
    raise Exception("INVALID APP_PLATFORM_NAME="+APP_PLATFORM_NAME)

SHARED_TMP_DBBACKUPS = WEB_HOST_SHARED_TMP_PATH + '/db-backups'
print("## SHARED_TMP_DBBACKUPS="+SHARED_TMP_DBBACKUPS)

SCHEMA_FILE_PATH=WEB_INTERNAL_SHARED_TMP_PATH + '/db-backups/db-schema.sql'
DATA_FILE_PATH=WEB_INTERNAL_SHARED_TMP_PATH+'/db-backups/db-data.sql'

#Find the real running container name
realContainerName = myenv.getRunningDockerContainerName(DOCKER_WEBSERVER)
if not realContainerName:
    print("FAILED to find a running container matching name " + DOCKER_WEBSERVER)
    exit(1)
DOCKER_WEBSERVER=realContainerName
print("## DOCKER_WEBSERVER = " + DOCKER_WEBSERVER)

IS_PRODUCTION = myenv.env_profile_vars['IS_PRODUCTION']
if ( IS_PRODUCTION != 'YES' and IS_PRODUCTION != 'NO' ):
    print('ENVIRONMENT ERROR: Missing or invalid value for IS_PRODUCTION!')
    print(' IS_PRODUCTION="' + IS_PRODUCTION + '"')
    print(' TIP: Fix this by editing your environment.txt file.')
    exit(2)

DB_BACKUPS_DIRECTORY = STACK_FOLDER_PATH + '/host-utils/db-backups'
DB_BACKUPS_DIRECTORY_LOCAL = STACK_FOLDER_PATH + '/host-utils/db-backups-local'

if not os.path.isdir(SHARED_TMP_DBBACKUPS):
    os.makedirs(SHARED_TMP_DBBACKUPS)
    print("Created SHARED_TMP_DBBACKUP directory %s was created." %SHARED_TMP_DBBACKUPS)

BUCKET_ENV_PATH = BUCKET_PATH + '/' + src_env_name
s3_key = BUCKET_ENV_PATH + '/' + file_name

def downloadS3File(fileS3Path):
    '''
    Download the file from S3 and return True or fail and return False
    '''
    print("Will download " + fileS3Path)
    try:

        s3client = boto3.client('s3')
        s3client.download_file(BUCKET_NAME, fileS3Path, DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped/' + file_name)
        print("Downloaded " + fileS3Path)
        return True

    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            print("Did not find file",fileS3Path,"in",BUCKET_NAME)
            return False
        else:
            raise

def showFolders(prefixFilter):
    '''
    Show all the S3 folders in the path
    '''
    print("## START Available Folders in", prefixFilter)
    prefixLen1=len(prefixFilter)+1
    s3client = boto3.resource('s3')
    THEBUCKET=s3client.Bucket(BUCKET_NAME)
    THEBUCKET.objects.filter(Prefix=prefixFilter)
    thingsfound={}
    for object in THEBUCKET.objects.filter(Prefix=prefixFilter):
        foundthing=object.key[prefixLen1:]
        slashpos=foundthing.find('/')
        if slashpos > -1:
            nicename=object.key[prefixLen1:prefixLen1 + slashpos]
            thingsfound[nicename]=nicename

    thenum=0
    for nicename in thingsfound:
        thenum+=1
        print(thenum,")\t",nicename)

    print("## END Available Folders in", prefixFilter)

def showS3Files(prefixFilter):
    '''
    Show all the S3 files in the path
    '''
    print("## START Available Files in", prefixFilter)
    prefixLen1=len(prefixFilter)+1
    s3client = boto3.resource('s3')
    THEBUCKET=s3client.Bucket(BUCKET_NAME)
    THEBUCKET.objects.filter(Prefix=prefixFilter)
    thenum=0
    for object in THEBUCKET.objects.filter(Prefix=BUCKET_ENV_PATH):
        thenum+=1
        print(thenum,")\t",object.key[prefixLen1:])
    print("## END Available Files in", prefixFilter)

def showLocalFiles(dirpath, suffixFilter):
    '''
    Show all the files in the path
    '''
    print("## START Available Files in", dirpath)
    if not os.path.isdir(dirpath):
        print("ERROR directory is MISSING!")    
    else:    
        files = os.listdir(dirpath)
        thenum=0
        for file in files:
            if suffixFilter == None or file.endswith(suffixFilter):
                thenum+=1
                print(thenum,")\t",file)

    print("## END Available Files in", dirpath)

if ( IS_PRODUCTION == 'YES' ):

    print("WARNING: You are going to replace database in PRODUCTION!")

    yyyymmdd = datetime.datetime.today().strftime('%Y-%m-%d')
    magicText = "OVERWRITE_PRODUCTION_NOW_" + yyyymmdd

    print('Type "' + magicText + '" to proceed')
    userinput = input()

    print( 'debug userinput=' + userinput )

    if ( userinput != magicText):
        #Too bad!
        print("Wrong input --- aborting now!!!")
        exit(2)

    print()
    print("OK --- we will now OVERWRITE existing PRODUCTION database!")
    print()

#Just show listing?
if LOCAL_FILES:
    #From local filesystem
    if file_name == '?':
        print("Missing the FILENAME argument!")
        showLocalFiles(DB_BACKUPS_DIRECTORY_LOCAL, '.zip')
        print("NOTE: Use the --help argument to see full usage information")
        exit(2)

    if os.path.isfile(DB_BACKUPS_DIRECTORY_LOCAL + '/' + file_name):
        print("Will import from " + DB_BACKUPS_DIRECTORY_LOCAL + '/' + file_name)
    else:
        print("ERROR no file found with name", file_name)
        showLocalFiles(DB_BACKUPS_DIRECTORY_LOCAL, '.zip')
        print("NOTE: Use the --help argument to see full usage information")
        exit(2)

else:
    #From s3
    if src_env_name == '?':
        print("Missing the FOLDER NAME (source environment) argument!")
        showFolders(BUCKET_PATH)
        print("NOTE: Use the --help argument to see full usage information")
        exit(2)
    if file_name == '?':
        print("Missing the FILENAME argument!")
        showS3Files(BUCKET_ENV_PATH)
        print("NOTE: Use the --help argument to see full usage information")
        exit(2)

#Create local folder if missing
if not os.path.exists(DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped'):
    os.makedirs(DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped')
    print("Created ", DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped')

# GET THE BACKUP FILE
try:
    if LOCAL_FILES:
        zip_ref = zipfile.ZipFile(DB_BACKUPS_DIRECTORY_LOCAL + '/' + file_name, 'r')
        zip_ref.extractall(DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped')
        print("Extracted files to " + DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped')
        zip_ref.close()
    else:
        # DOWNLOAD ZIPPED DB-BACKUP FROM S3
        if not downloadS3File(s3_key):
            showS3Files(BUCKET_ENV_PATH)
            exit(3)
            
        # UNZIP THE BACKUP FILE
        zip_ref = zipfile.ZipFile(DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped/' + file_name, 'r')
        zip_ref.extractall(DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped')
        print("Extracted files to " + DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped')
        zip_ref.close()
        print("Downloaded zip file extracted")

        DOWNLOADEDZIP=DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped/' + file_name
        if KEEP_ZIP:
            print("Keeping " + file_name) 
            copyfile(DOWNLOADEDZIP, DB_BACKUPS_DIRECTORY_LOCAL + '/' + file_name)
        else:
            os.remove(DOWNLOADEDZIP)
            print("Deleted " + DOWNLOADEDZIP)

except:
    print("ERROR FAILED GETTING " + file_name)
    print("DETAILS:", sys.exc_info()[0])
    exit(2)

try:
    # DROP THE CURRENT DATABASE
    print('Dropping all the tables in the current database.')
    resultdropcode = subprocess.call(
        ['docker', 'exec', '--user=web.mgmt', DOCKER_WEBSERVER, 'drush', DRUSH_DROP_CMD, '-y', '--root=' + DRUSH_PATH_TO_WEBROOT])
    if (resultdropcode != 0):
        # TODO WRITE TO LOG
        print("DETECTED ERROR DROPPING DATABASE TABLES!")
    else:
        print('Current database has been flushed.')

except:
    e = sys.exc_info()[0]
    print("ERROR FAILED DROPPING CURRENT DATABASE " + str(e))
    print("DETAILS:", sys.exc_info()[0])
    exit(2)


# MOVE db-schema.sql FILE INTO THE SHARED SPACE
try:

    print("Will now copy SCHEMA file to ", SHARED_TMP_DBBACKUPS + '/db-schema.sql')
    copyfile(DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped/db-schema.sql', SHARED_TMP_DBBACKUPS + '/db-schema.sql')
    print("Finished copy SCHEMA file to ", SHARED_TMP_DBBACKUPS + '/db-schema.sql')

except ex:
    print("ERROR FAILED COPY! ", ex)
    print("DETAILS:", sys.exc_info()[0])
    exit(2)

# Import the schema file
print("Will now import SCHEMA file from " + SCHEMA_FILE_PATH)
RUNTHIS=shlex.split('docker exec --user=web.mgmt ' + DOCKER_WEBSERVER + ' sh -c "drush --root=' + DRUSH_PATH_TO_WEBROOT + ' sql-cli <  ' + SCHEMA_FILE_PATH + '"')
resultschemacode = subprocess.call(RUNTHIS)
if (resultschemacode != 0):
    # TODO WRITE TO LOG
    print("DETECTED ERROR IMPORTING DATABASE SCHEMA!")
    ERRORCOUNT+=1
else:
    print('Database schema imported')

# MOVE db-data.sql FILE INTO THE SHARED SPACE
print("Will now copy DATA file to ", SHARED_TMP_DBBACKUPS + '/db-data.sql')
copyfile(DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped/db-data.sql', SHARED_TMP_DBBACKUPS + '/db-data.sql')
print("Finished copy DATA file to ", SHARED_TMP_DBBACKUPS + '/db-data.sql')

# Import the data file
print("Will now import DATA file from " + DATA_FILE_PATH)
RUNTHIS=shlex.split('docker exec --user=web.mgmt ' + DOCKER_WEBSERVER + ' sh -c "drush --root=' + DRUSH_PATH_TO_WEBROOT + ' sql-cli <  ' + DATA_FILE_PATH + '"')
resultDataCode = subprocess.call(RUNTHIS)

if (resultDataCode != 0):
    # TODO WRITE TO LOG
    print("DETECTED ERROR IMPORTING DATABASE DATA!")
    ERRORCOUNT+=1
else:
    print('Database data imported')

if ERRORCOUNT == 0:
    # Only remove these files if we did not have errors -- so easier to debug
    os.remove(SHARED_TMP_DBBACKUPS + '/db-schema.sql')
    os.remove(SHARED_TMP_DBBACKUPS + '/db-data.sql')
    print("Removed SQL files from " + SHARED_TMP_DBBACKUPS)
    shutil.rmtree(DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped')
    print("Removed unzipped files from " + DB_BACKUPS_DIRECTORY_LOCAL + '/unzipped')

if(ERRORCOUNT > 0):
    print('## Import of ' + APP_PLATFORM_ID + ' data finished with ' + str(ERRORCOUNT) + ' errors')
    exit(2)

print('## Import of ' + APP_PLATFORM_ID + ' data finished with ' + str(ERRORCOUNT) + ' errors')

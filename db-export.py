STACK_ENV_VERSIONINFO="20190201.1"

import boto3
import os, sys
from os import listdir
from os.path import dirname, abspath
import subprocess
import zipfile
import datetime
import shutil
import argparse

ERRORCOUNT=0

print("STARTING EXPORT VERSION " + STACK_ENV_VERSIONINFO)

#Parse all the arguments
parser = argparse.ArgumentParser(description='Export application database')
parser.add_argument('APP_PLATFORM_NAME', help='AUTOMATIC App platform name (e.g., drupal)')
parser.add_argument('APP_PLATFORM_MAJOR_VERSION', help='AUTOMATIC App platform major version number (e.g., 7 or 8)')
parser.add_argument('--localcopy', '-lc', help='Save export to local file system', action='store_true')
parser.add_argument('--nos3', help='Do not export to s3', action='store_true')
args = parser.parse_args()

#Assign arguments to our internal variables
APP_PLATFORM_NAME=args.APP_PLATFORM_NAME
APP_PLATFORM_MAJOR_VERSION=args.APP_PLATFORM_MAJOR_VERSION
NO_S3=args.nos3
LOCAL_FILES=args.localcopy

#Check the platform name and version parameters
APP_PLATFORM_ID = APP_PLATFORM_NAME+APP_PLATFORM_MAJOR_VERSION
if APP_PLATFORM_NAME=='drupal':
    if APP_PLATFORM_MAJOR_VERSION == '7':
        DRUSH_CMD='sql-dump'
        DRUSH_EXTRA_ARG='--extra=--no-data'
    elif APP_PLATFORM_MAJOR_VERSION == '8':
        DRUSH_CMD='sql:dump'
        DRUSH_EXTRA_ARG='--extra-dump=--no-data'
    else:
        raise Exception("INVALID APP_PLATFORM_MAJOR_VERSION="+APP_PLATFORM_MAJOR_VERSION)
else:
    raise Exception("INVALID APP_PLATFORM_NAME="+APP_PLATFORM_NAME)

print("## Exporting database for " + APP_PLATFORM_ID)
    

from hostlib import environment
myenv=environment.Environment()

#Set some important values now
DOCKER_WEBSERVER = myenv.env_profile_vars['WEB_CONTAINERNAME'].strip()
BUCKET_NAME = myenv.env_profile_vars['SHARED_S3_STAGING_BUCKET_NAME']
BUCKET_PATH = myenv.env_profile_vars['S3_DBDUMPS_FILEDIR'] + "/" + APP_PLATFORM_ID

ENVNAME = myenv.env_profile_vars['ENVIRONMENT_NAME']
PROJECT = myenv.env_profile_vars['PROJECT_NAME']
BUCKET_ENV_PATH = BUCKET_PATH + '/' + ENVNAME

DRUSH_PATH_TO_WEBROOT = myenv.env_profile_vars['DOCROOT_PATH']

WEBROOT_DIRECTORY = myenv.env_profile_vars['WEB_DOCROOT_PATH']
STACK_FOLDER_PATH = myenv.env_profile_vars['FOLDER_PATH']

if not os.path.exists(STACK_FOLDER_PATH):
    raise Exception("INVALID STACK_FOLDER_PATH="+STACK_FOLDER_PATH)
    exit(1)

print("## STACK_FOLDER_PATH="+STACK_FOLDER_PATH)

#Find the real running container name
realContainerName = myenv.getRunningDockerContainerName(DOCKER_WEBSERVER)
if not realContainerName:
    print("FAILED to find a running container matching name " + DOCKER_WEBSERVER)
    exit(1)
print("Running container name is " + realContainerName)
DOCKER_WEBSERVER=realContainerName

DB_BACKUPS_DIRECTORY = STACK_FOLDER_PATH + '/host-utils/db-backups'
DB_BACKUPS_DIRECTORY_LOCAL = STACK_FOLDER_PATH + '/host-utils/db-backups-local'

if not os.path.exists(DB_BACKUPS_DIRECTORY):
   os.makedirs(DB_BACKUPS_DIRECTORY)

os.chdir(WEBROOT_DIRECTORY)

# Check current working directory.
# retval = os.getcwd()

s = open(DB_BACKUPS_DIRECTORY + "/db-schema.sql", "w")
print ('Empty database schema file created')

sresultcode=subprocess.call(['docker', 'exec', '--user=web.mgmt', DOCKER_WEBSERVER, 'drush', DRUSH_CMD, DRUSH_EXTRA_ARG, '--root=' + DRUSH_PATH_TO_WEBROOT], stdout=s)
if(sresultcode != 0):
    # TODO WRITE TO LOG
    print("DETECTED ERROR BACKUPING DATABASE SCHEMA!")
    ERRORCOUNT+=1
else:
    print('Database schema file populated')

d = open(DB_BACKUPS_DIRECTORY + "/db-data.sql", "w")
print ('Empty database data file created')

dresultcode=subprocess.call(['docker', 'exec', '--user=web.mgmt', DOCKER_WEBSERVER, 'drush', DRUSH_CMD, '--skip-tables-list=cache,cache_*', '--data-only', '--root=' + DRUSH_PATH_TO_WEBROOT], stdout=d)
if(dresultcode != 0):
    # TODO WRITE TO LOG
    print("DETECTED ERROR BACKUPING DATABASE DATA!")
    ERRORCOUNT+=1
else:
    print('Database data file populated')

db_backup_list = os.listdir(DB_BACKUPS_DIRECTORY)
date = datetime.datetime.today().strftime('%Y-%m-%d--%H-%M')
zfilename = PROJECT + '--' + ENVNAME + '--' + APP_PLATFORM_ID + '--' + date + '.zip'
zfilepath = DB_BACKUPS_DIRECTORY + '/' + zfilename

for list in db_backup_list:
    if (list[:1] != '.'):
        get_file = os.path.join(DB_BACKUPS_DIRECTORY, list)
        zip_name = zipfile.ZipFile(zfilepath, 'a', zipfile.ZIP_DEFLATED)
        zip_name.write(get_file, list)
        zip_name.close()
zip_size = os.path.getsize(zfilepath) >> 20
print ('Created ' + zfilename + ' Size(MB): ' + str(zip_size)) 

if NO_S3:
    print('No file sent to s3')
else:
    s3client = boto3.client('s3')
    s3_key = BUCKET_ENV_PATH + '/' + zfilename

    print("Will upload to " + s3_key)
    s3client.upload_file(zfilepath, BUCKET_NAME, s3_key)
    print ('Uploaded zip file to s3')

if LOCAL_FILES:
    if not os.path.exists(DB_BACKUPS_DIRECTORY_LOCAL):
        os.makedirs(DB_BACKUPS_DIRECTORY_LOCAL)

    os.rename(zfilepath, DB_BACKUPS_DIRECTORY_LOCAL + '/' + zfilename)
    print('Zip file moved to local directory')

if ERRORCOUNT == 0:
    #Keep the files if we have errors for easier debugging
    shutil.rmtree(DB_BACKUPS_DIRECTORY)

print('## Export of ' + APP_PLATFORM_ID + ' data finished with ' + str(ERRORCOUNT) + ' errors')


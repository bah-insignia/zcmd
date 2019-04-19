import boto3
import os, sys, datetime
from os.path import dirname, abspath
import subprocess

STACK_ENV_VERSIONINFO = "20181227.1"

print("#\n#Retrieving ZCMD environment values for python execution ...\n#")

from hostlib import environment
myenv=environment.Environment()

myenv.printAll()

print("#\n#Finished showing all retrieved ZCMD environment values available in python.\n#")

"""
Helper for environment related things expected to be run on the HOST CONTEXT
Must use python3!

To load stack.env, provide environment variable ...
ZCMD_STACK_PATH=<path of the stack folder>

"""
VERSIONINFO = "20190416.1"

import inspect, os, sys
from os.path import dirname, abspath
import subprocess

THISFILE = inspect.getfile(inspect.currentframe())
THISFILENAME = os.path.basename(THISFILE)
THISFILENOEXT, THISFILEEXT = os.path.splitext(THISFILENAME)
THISFILEFOLDERPATH = os.path.dirname(os.path.realpath(__file__))
ZCMD_ROOT_DIR = dirname(dirname(dirname(dirname(dirname(abspath(__file__))))))
ZCMD_USER_ENVIRONMENT_FILE = ZCMD_ROOT_DIR + '/custom-profile.env'
ZCMD_TEAM_ENVIRONMENT_FILE = ZCMD_ROOT_DIR + '/team-profile.env'
ZCMD_DEFAULT_ENVIRONMENT_FILE = ZCMD_ROOT_DIR + '/devutils/default-docker-env.txt'

class Environment:

    def getRunningDockerContainerName(self, startswithText):

        proc=subprocess.Popen(['docker','ps'], stdout=subprocess.PIPE)
        output = proc.stdout.read()
        lines_list=str(output).split("\\n")
        for line in lines_list:
            pos=line.rfind(" ")
            name=str(line[pos:]).strip()
            if (name.startswith(startswithText)):
                return name
        
        return None

    def printAll(self):
        print("=== ALL ENVIRONMENT START ===")
        for name in self.env_profile_vars:
            print(name + "=" + self.env_profile_vars[name])
        print("=== ALL ENVIRONMENT FINISH ===")
        return

    def loadEnvironmentFileValues(self, filepath):
        """
        Load as literal from the file if value in OS ENVIRON is not found for name.
        """
        with open(filepath, "r") as ins:
            array = []
            for line in ins:
                if line[0:1] != "#":
                    parts = line.strip().split("=")
                    if len(parts) > 1 and not (' ' in parts[0]):
                        if (self.verbose):
                            print("...has parts " + str(parts))
                        name = parts[0].strip()
                        #debug print("CHECKING " + name + " OS ENV has " + os.environ.get(name,"XXXX"))
                        value = parts[1].translate({ord(c): None for c in '"'})
                        #Set from the file ONLY if not already set in the OS environment!
                        self.env_profile_vars[name] = os.environ.get(name, value)
    
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.env_profile_vars = {}

        if (verbose):
            print("Starting initialization of " + THISFILE + " v" + str(VERSIONINFO))
            print("Python version " + sys.version)

        if (sys.version[0] != '3'):
            raise Exception("Must use python3 NOT " + sys.version)

        try:

            self.env_profile_vars['HOME'] = os.environ['HOME']
            self.env_profile_vars['ZCMD_STACK_PATH'] = os.environ.get('ZCMD_STACK_PATH',os.getcwd())
            
            #Extract as many variable settings as we find in default file first
            with open(ZCMD_DEFAULT_ENVIRONMENT_FILE, "r") as ins:
                array = []
                for line in ins:
                    if line[0:1] != "#":
                        parts = line.strip().split("=")
                        if len(parts) > 1 and not (' ' in parts[0]) :
                            if (self.verbose):
                                print("...has parts " + str(parts))
                            name = parts[0].strip()
                            value = parts[1].translate({ord(c): None for c in '"'})
                            #self.env_profile_vars[name] = value
                            #Set from the file ONLY if not already set in the OS environment!
                            self.env_profile_vars[name] = os.environ.get(name, value)

            #Extract all the team variables next
            self.loadEnvironmentFileValues(ZCMD_TEAM_ENVIRONMENT_FILE)

            #Extract all the user variables next
            self.loadEnvironmentFileValues(ZCMD_USER_ENVIRONMENT_FILE)

            #Extract all the stack variables last
            if self.env_profile_vars['ZCMD_STACK_PATH']:
                stack_env_path=self.env_profile_vars['ZCMD_STACK_PATH'] + "/stack.env"
                self.loadEnvironmentFileValues(stack_env_path)

            if os.environ.get('PROJECT_NAME', 'MISSING') == 'MISSING':
                raise Exception("Missing required environment value PROJECT_NAME!")

            self.env_profile_vars['WEB_CONTAINERNAME'] = os.environ.get('WEB_CONTAINERNAME','stack_webserver_'+self.env_profile_vars['PROJECT_NAME'])

            return

        except Exception as e:
            print("Failed initialization!")
            raise e

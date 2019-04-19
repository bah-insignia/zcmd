PURPOSE
=======
The ZCMD framework is a collection of bash and python utilities and configuration
conventions that facilitate the operation and management of 
docker containers and collections of containers ("zcmd stacks").

The framework is intended to be appropriate for use in DEV, STAGE, and
PROD environments.

REQUIREMENTS
============
You have the following environment variable ...

    export ZCMD_HOME=$HOME/zcmd

And your PATH has the following added to it ...

    $ZCMD_HOME/devutils

Also make sure you copy the following templates and fill them out:

#"team-profile-template.env" to the name "team-profile.env" 
#"custom-profile-template.env" to the name "custom-profile.env" 

Some of the commands assume you have the following installed on your host:

    * docker         <-- required for everything
    * docker-compose <-- required for almost everything
    * aws utilities  <-- required for S3 interations
    * mysql-client   <-- required for most database actions
    * python3        <-- required for some operations

Important Configuration Settings
--------------------------------
Update your ".bashrc" file, or ".profile" and log back in.

    * ZCMD_HOME="$HOME/zcmd"
    * PATH="$PATH:$ZCMD_HOME/devutils"
    * alias cdutil=". ${ZCMD_HOME}/devutils/cdutil.sh"

    * alias python="python3"
    * alias pip="pip3"

HELLO WORLD EXAMPLE STACK
=========================
Follow these steps to launch a simple demonstration stack using zcmd and
then shut it down.

Create the place where we recommend placing your stacks...
**Step 1: Create ~/docker-repos folder**

Clone the demonstration stack...
**Step 2: git clone https://github.com/frankfont/zcmd-demo-stack.git**

Go into the stack folder of your demonstration stack... 
**Step 3: cd ~/docker-repos/stack**

Now, start the demonstration stack
**Step 4: zcmd up**

Give the demonstration stack about a minute to start then have a look
at the webpage available at localhost:11080

And finally, use one of the following commands to shut down your stack when you are done with it.
* zcmd down <--- shuts down just the current stack
* zcmd kill-all-containers <-- shuts down ALL stacks running 

Tip: Edit the stack.env if you want to use a different port number.  More details about that stack are available on the https://github.com/frankfont/zcmd-demo-stack website.

SOME FOLDERS EXPLAINED
======================

devutils

    Utilities that are helpful when working with Docker.  Put it on your path!

devutils/zcmd_helpers

    This is where all the commands are defined as individual scripts in the 
    following subdirectories:

        global  -- commands that run from any folder

        machine -- commands that only run in a machine image folder
                   NOTE: An image folder has "machine.env" file.

        stack   -- commands that only run from a docker stack folder
                   NOTE: A stack folder has "stack.env" file. 

devutils/zcmd_python

    Scripts written in python that can be launched by zcmd directly.

plugins

    Environment declarations for specific applications.

runtime_stack

    Docker compositions of a few core stacks to be shared by many applications.  
    Only core stacks should be here.  All application specific stacks belong 
    in their own git repos elsewhere.

ENVIRONMENT COMPATIBILITY
=========================
The framework has been successfully used in Linux and Mac OSX.  It has 
not been tested using Docker in native Windows.

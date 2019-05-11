PURPOSE
=======
The ZCMD framework is a collection of bash and python utilities and configuration
conventions that facilitate the operation and management of 
docker containers and collections of containers ("zcmd stacks").

![ZCMD Logo](https://github.com/bah-insignia/zcmd-docs/blob/master/category/core/images/logo_400.png)

The framework is intended to be appropriate for use in DEV, STAGE, and
PROD environments.

REQUIREMENTS
============
You've installed the contents of this git repo into the following location ...

    $HOME/zcmd

You have the following environment variable ...

    export ZCMD_HOME=$HOME/zcmd

And your PATH has the following added to it ...

    $ZCMD_HOME/devutils

Also you copied the following templates from the $HOME/zcmd folder and filled them out:

* "team-profile-template.env" to the name "team-profile.env" 
* "custom-profile-template.env" to the name "custom-profile.env" 

Some of the commands assume you have the following installed on your host:

    * docker         <-- required for everything (you dont have this, you dont have docker)
    * docker-compose <-- required for almost everything (how to build "zcmd stacks")
    * aws utilities  <-- required for S3 interactions (e.g., backup files to S3/restore files from S3)
    * mysql-client   <-- required for most database actions where mysql is persistend on the host
    * python3        <-- required for some operations

Important Configuration Settings
--------------------------------
Update your ".bashrc" file, or ".profile" and log back in.

    * ZCMD_HOME="$HOME/zcmd"
    * PATH="$PATH:$ZCMD_HOME/devutils"
    * alias cdutil=". ${ZCMD_HOME}/devutils/cdutil.sh"

    * alias python="python3"
    * alias pip="pip3"

Other Configuration Tweaks
--------------------------
Copy the zcmd/custom-profile-template.env file to zcmd/custom-profile.env and set
the values to be appropriate for your host computer and user details.

If you work in a team of people, consider sharing a single zcmd/team-profile.env
based on the pattern shown in the zcmd/team-profile-template.env file.

HELLO WORLD EXAMPLE STACK
=========================
Follow these steps to launch a simple demonstration stack using zcmd and
then shut it down.

Create the place where we recommend placing your stacks...

* **Step 1: Create ~/docker-repos folder**

Clone the demonstration stack...

* **Step 2: git clone https://github.com/bah-insignia/zcmd-demo-stack**

Go into the stack folder of your demonstration stack... 

* **Step 3: cd ~/docker-repos/zcmd-demo-stack/stack**

Now, start the demonstration stack

* **Step 4: zcmd up**

Give the demonstration stack about a minute to start then have a look
at the webpage available at localhost:11080 in your browser.

And finally, use one of the following commands to shut down your stack when you are done with it.
* zcmd down <--- shuts down just the current stack
* zcmd kill-all-containers <-- shuts down ALL stacks running 

Tip: Edit the stack.env if you want to use a different port number.  More details about that stack are available on the https://github.com/bah-insignia/zcmd-demo-stack website.

CORE UTILITIES IN THE FRAMEWORK
===============================
The framework includes several user callable helper utilities, all located in the zcmd/devutils directory.

ZCMD Utility
------------
The main utility of the framework is invoked by typing **zcmd** at the command prompt of a properly configured host computer's terminal.  Some command examples ...

 * zcmd up <-- Starts a stack
 * zcmd psa <-- Lists all existing container instances
 * zcmd ct <-- Opens a terminal in a running container
 * zcmd down <-- Shuts down a stack
 * zcmd --help <-- Display all available options for the zcmd utility
 * zcmd --help up <-- Display detailed help for the up command

SOME FOLDERS EXPLAINED
======================

devutils

    Utilities that are helpful when working with Docker.  Put it on your path!

devutils/zcmd_helpers

    This is where all the commands are defined as individual scripts in the 
    following subdirectories:

        global  -- commands that run from any folder

        machine -- commands that only run in a machine image folder
                   NOTE: An image folder has **"machine.env" file**.

        stack   -- commands that only run from a docker stack folder
                   NOTE: A stack folder has **"stack.env" file**. 

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

```
docker --version
Docker version 18.09.5, build e8ff056
```

```
docker-compose --version
docker-compose version 1.22.0, build f46880fe
```

WHERE CAN I READ MORE?
======================
You can start with the wiki content at https://github.com/bah-insignia/zcmd/wiki

HOW TO CONTRIBUTE?
==================
Contact us via this github site if you have ideas for refinements/enhancements or quirk fixes.

#!/bin/bash

VERSIONINFO="20171229.1"

echo "Starting $0 v$VERSIONINFO ..."

source $HOME/zcmd/devutils/default-docker-env.txt

HAS_ERRORS="TBD"
HAS_WARNINGS="TBD"

APACHE_GROUPNAME="www-data"
DOCKER_GROUPNAME="docker"

WHOAMI=$(whoami)

function showUsage()
{
    echo "USAGE: $0 [WEB_VOLUME_NAME]"
}

if [ "$1" = "--help" ]; then
    showUsage
    exit 1
fi

WEB_VOLUME_NAME=$1

function checkWebVolume()
{
    local VOLUME_NAME=$1

    echo "Checking group membership of files in $VOLUME_NAME..."

    THE_VOLUME_UTIL="$HOME/zcmd/devutils/zc-docker-volume.sh"
    CMD="$THE_VOLUME_UTIL $VOLUME_NAME JUST_GET_HOST_PATH"
    HOST_PATH="$(eval $CMD)"

    echo "... web volume name: $VOLUME_NAME"
    echo "... web volume path: $HOST_PATH"

    #Look for permission denied
    CMD_LISTING="cd $HOST_PATH && ls -Rla | awk '{print \$NF}'"
    LIST_FILES_RESULT="$(eval $CMD_LISTING)" 
    FOUND_BAD_COUNT=0
    FOUND_PERMISSIONDENIED_COUNT=0
    FOUND_FILE_COUNT=0
    for ONELINE in $LIST_FILES_RESULT
    do
        FOUND_FILE_COUNT=$((FOUND_FILE_COUNT + 1))
    #    if [ "$ONELINE" = "Permission denied" ]; then
    #        FOUND_PERMISSIONDENIED_COUNT=$((FOUND_PERMISSIONDENIED_COUNT + 1))
    #        FOUND_BAD_COUNT=$((FOUND_BAD_COUNT + 1))
    #    fi
    done
    echo "... examined file count: $FOUND_FILE_COUNT"

    #CMD_LISTING="cd $HOST_PATH && sudo ls -Rla | awk '{print \$4}'"
    CMD_LISTING="cd $HOST_PATH && ls -Rla | awk '{print \$4}'"
    GROUP_FILE_RESULT="$(eval $CMD_LISTING)" 
    for GROUPNAME in $GROUP_FILE_RESULT
    do
        if [ ! "$GROUPNAME" = "$APACHE_GROUPNAME" ]; then
            FOUND_BAD_COUNT=$((FOUND_BAD_COUNT + 1))
        fi
    done
    if [ $FOUND_BAD_COUNT -ne 0 ]; then
        HAS_WARNINGS="YES"
        echo "!!! WARNING: Found ${FOUND_BAD_COUNT} web volume files NOT in the '$APACHE_GROUPNAME' group or with permission issues!"
        if [ $FOUND_PERMISSIONDENIED_COUNT -ne 0 ]; then
            echo "        ... Permission denied count = $FOUND_PERMISSIONDENIED_COUNT"
        fi
        echo "        TIP: To fix web file ownership and permission issues run these commands..."
        echo "        sudo chown -R ${WHOAMI}:${APACHE_GROUPNAME} $HOST_PATH"
        echo "        ... and ..."
        echo "        sudo chmod -R 0755 $HOST_PATH"
    else
        echo "... OK"
    fi
}

function ensureApacheGroupExists()
{
    echo "Checking existance of group $APACHE_GROUPNAME..."
    #CMD_GROUPGREP="sudo cat /etc/group | grep $APACHE_GROUPNAME"
    CMD_GROUPGREP="groups | grep $APACHE_GROUPNAME"
    echo "$CMD_GROUPGREP"
    GREP_RESULT=$(eval $CMD_GROUPGREP)
    if [ $? -ne 0 ]; then
        HAS_ERRORS="YES"
    fi
    if [ -z "$GREP_RESULT" ]; then
        echo "WARNING: Host is MISSING groupname '$APACHE_GROUPNAME'"
        echo "TIP: You can create the group with this command (LINUX) ..."
        echo "     sudo groupadd $APACHE_GROUPNAME"
        echo " ... then add yourself to the new group (LINUX) ..."
        echo "     sudo usermod -aG $APACHE_GROUPNAME $WHOAMI"
        HAS_ERRORS="YES"
    else
        echo "... OK"
    fi
}

function ensureUserMemberships()
{
    echo "Checking user membership in key groups..."
    APACHE_GROUPNAME_FOUND="NO"
    DOCKER_GROUPNAME_FOUND="NO"

    #Check one by one, not just a grep otherwise substrings will fail it!
    for GROUPNAME in $(groups)
    do
        if [ "$GROUPNAME" = "$APACHE_GROUPNAME" ]; then
            APACHE_GROUPNAME_FOUND="YES"
            echo "... $GROUPNAME is OK"
        fi
        if [ "$GROUPNAME" = "$DOCKER_GROUPNAME" ]; then
            DOCKER_GROUPNAME_FOUND="YES"
            echo "... $GROUPNAME is OK"
        fi
    done

    if [ "NO" = "$APACHE_GROUPNAME_FOUND" ]; then
        echo "WARNING: Host user account is missing membership in '$APACHE_GROUPNAME'"
        echo "IMPACT: Membership in this group is required for website git-repo/edit interactions"
        echo "TIP: You can add the account to the group with this command (LINUX) ..."
        echo "     sudo usermod -aG $APACHE_GROUPNAME $WHOAMI"
        HAS_WARNINGS="YES"
    fi
    if [ "NO" = "$DOCKER_GROUPNAME_FOUND" ]; then
        echo "WARNING: Host user account is missing membership in '$DOCKER_GROUPNAME'"
        echo "IMPACT: Membership in this group is required for docker commands."
        echo "TIP: You can add the account to the group with this command (LINUX) ..."
        echo "     sudo usermod -aG $DOCKER_GROUPNAME $WHOAMI"
        echo "NOTE: For MAC not sure this matters. (https://forums.docker.com/t/no-more-docker-group/9123)"
        HAS_WARNINGS="YES"
    fi

}

echo "... running as user $WHOAMI"
ensureApacheGroupExists
ensureUserMemberships
if [ ! -z "$WEB_VOLUME_NAME" ]; then
    checkWebVolume $WEB_VOLUME_NAME
fi

if [ "YES" = "$HAS_ERRORS" ]; then
    #Failed if we are here
    echo "################################################################################"
    echo "Found one or more user account configuration errors"
    echo "################################################################################"
    exit 2
fi

if [ "YES" = "$HAS_WARNINGS" ]; then
    #Failed if we are here
    echo "################################################################################"
    echo "Found one or more user account configuration WARNINGS"
    echo "################################################################################"
    read -p "Are you sure you want to proceed? y/N " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "TREATING THESE WARNINGS AS ERRORS!"
        exit 2
    fi
    echo "Proceeding..."
fi

#Success if we are here
echo "################################################################################"
echo "No user account configuration errors detected"
echo "################################################################################"

if [ "YES" = "$HAS_WARNINGS" ]; then
    echo "FINAL NOTE: Exit code set to warning value"
    exit 1
fi

#No warnings, no errors.
exit 0

    



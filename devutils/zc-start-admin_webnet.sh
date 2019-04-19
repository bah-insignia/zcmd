#!/bin/bash
#Starts the admin_webnet network if not already running

VERSIONINFO="20190412.2"
echo "Started $0 v$VERSIONINFO"

ADMIN_NETWORK_NAME="admin_webnet"
ADMIN_STUB_NAME="admin_zcmd_stub"
ADMIN_STACK_HOME="$HOME/zcmd/runtime_stack/admin/"
PARAM_CUSTOM_ADMIN_STACK_PATH="$1"

CORE_ADMIN_WAS_DOWN="UNKNOWN"
NEEDS_CHECKING="YES"
LAUNCH_CUSTOM_TOO="NO"

echo "# ... ZCMD ADMIN_NETWORK_NAME      = $ADMIN_NETWORK_NAME"
echo "# ... ZCMD ADMIN_STACK_HOME        = $ADMIN_STACK_HOME"
if [ -z "$PARAM_CUSTOM_ADMIN_STACK_PATH" ]; then
    echo "# ... ZCMD CUSTOM ADMIN STACK HOME = ** NONE **"
else
    echo "# ... ZCMD CUSTOM ADMIN STACK HOME = $PARAM_CUSTOM_ADMIN_STACK_PATH"
    LAUNCH_CUSTOM_TOO="YES"
fi

function upCoreAdminStack()
{
    (cd $ADMIN_STACK_HOME; zcmd up)
    sleep 5
}

function upCustomAdminStack()
{
    echo "# Starting custom admin stack at $PARAM_CUSTOM_ADMIN_STACK_PATH ..."
    (cd $PARAM_CUSTOM_ADMIN_STACK_PATH; zcmd up)
    sleep 5
}

function checkAdminNetwork()
{

    MISSING_TEXT="No such network"

    echo "# Checking '$ADMIN_NETWORK_NAME' network status ..."

    RESULT_CONTENT=$(eval "docker network inspect $ADMIN_NETWORK_NAME")

    GREP_NAME_CHECK="echo \"${RESULT_CONTENT}\" | grep '${ADMIN_NETWORK_NAME}'"
    GREP_MISSING_CHECK="echo \"${RESULT_CONTENT}\" | grep '${MISSING_TEXT}'"

    FIND_NAME_TEXT=$(eval "$GREP_NAME_CHECK")

    if [ ! -z "$FIND_NAME_TEXT" ]; then

        echo "# Network '$ADMIN_NETWORK_NAME' is available"
        NEEDS_CHECKING="NO"

    else

        CORE_ADMIN_WAS_DOWN="YES"

        #Show user all active networks...
        docker network ls

        #Try to start the admin project
        echo "# Network '$ADMIN_NETWORK_NAME' not found, will attempt to start now ..."

        upCoreAdminStack

        NEEDS_CHECKING="YES"
    fi
}

function checkAdminStub()
{

    MISSING_TEXT="No such service!"

    echo "# Checking '$ADMIN_STUB_NAME' service status ..."

    RESULT_CONTENT=$(eval "docker container ls")

    GREP_NAME_CHECK="echo \"${RESULT_CONTENT}\" | grep '${ADMIN_STUB_NAME}' | awk '{print $NF}'"
    GREP_MISSING_CHECK="echo \"${RESULT_CONTENT}\" | grep '${MISSING_TEXT}'"

    FIND_NAME_TEXT=$(eval "$GREP_NAME_CHECK")

    if [ ! -z "$FIND_NAME_TEXT" ]; then
        echo "# Container '$ADMIN_STUB_NAME' is available"
        NEEDS_CHECKING="NO"
    else

        CORE_ADMIN_WAS_DOWN="YES"

        #Show user all active containers...
        docker container ls

        #Try to start the admin project
        echo "# Running container '$ADMIN_STUB_NAME' not found, will attempt to start now ..."

        upCoreAdminStack

        NEEDS_CHECKING="YES"
    fi
}

checkAdminNetwork
checkAdminStub

if [ "YES" = "$NEEDS_CHECKING" ]; then
    checkAdminNetwork
    if [ "YES" = "$NEEDS_CHECKING" ]; then
        echo "FAILED to start the '$ADMIN_NETWORK_NAME' network!"
        echo "Check $ADMIN_STACK_HOME"
        exit 1
    fi
fi

if [ "YES" = "$LAUNCH_CUSTOM_TOO" ]; then
    if [ "YES" = "$CORE_ADMIN_WAS_DOWN" ]; then
        upCustomAdminStack
    fi
fi

echo "Successful completion of $0"

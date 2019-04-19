#!/bin/bash
#Calls all the down scripts

VERSIONINFO="20171212.1"
echo "Started $0 v$VERSIONINFO"

RUNTIME_STACK_ROOT="$HOME/zcmd/runtime_stack"
ADMIN_NETWORK_NAME="admin_webnet"
ADMIN_STACK_HOME="$HOME/zcmd/runtime_stack/admin/"

echo "Checking $RUNTIME_STACK_ROOT"
for dir in ${RUNTIME_STACK_ROOT}/*/
do
    dir=${dir%*/}
    if [ ! "${RUNTIME_STACK_ROOT}/admin" = "$dir" ]; then
	STACKPATH="$dir/stack.env"
	echo "CHECKING $dir"
	if [ -f $STACKPATH ]; then
		echo "Launching down.sh in $dir now ..."
		(cd $dir; zcmd down)
		sleep 2
		echo "Finished ${dir}!"
	else
		echo "Skipping $dir"
	fi
    fi
done
echo "Done checking $RUNTIME_STACK_ROOT"

ADMIN_NET_EXISTS="YES"

function checkAdminNetwork()
{

	MISSING_TEXT="No such network"

	echo "Checking '$ADMIN_NETWORK_NAME' network status ..."

	RESULT_CONTENT=$(eval "docker network inspect $ADMIN_NETWORK_NAME")

	GREP_NAME_CHECK="echo \"${RESULT_CONTENT}\" | grep '${ADMIN_NETWORK_NAME}'"
	GREP_MISSING_CHECK="echo \"${RESULT_CONTENT}\" | grep '${MISSING_TEXT}'"

	FIND_NAME_TEXT=$(eval "$GREP_NAME_CHECK")

	if [ ! -z "$FIND_NAME_TEXT" ]; then
		echo "Network '$ADMIN_NETWORK_NAME' is active"

		#Show user all active networks...
		docker network ls
		ADMIN_NET_EXISTS="YES"
        else
		#Show user all active networks...
		docker network ls
		ADMIN_NET_EXISTS="NO"
	fi
}

function downAdmin()
{
    docker network ls
    sleep 2
    echo "Launching down in $ADMIN_STACK_HOME now ..."
    #(cd $ADMIN_STACK_HOME; zcmd down.sh; docker network rm $ADMIN_NETWORK_NAME)
    (cd $ADMIN_STACK_HOME; zcmd down)
    echo "Finished ${ADMIN_STACK_HOME}!"
}

#Pause for a moment before moving on to the admin network
sleep 1

ENDMSG="Without Errors"

#Last, call down on the admin stack
downAdmin
checkAdminNetwork
if [ "YES" = "$ADMIN_NET_EXISTS" ]; then
    echo "Pausing before trying to shut off $ADMIN_NETWORK_NAME network"
    sleep 5
    downAdmin
    checkAdminNetwork
    if [ "YES" = "$ADMIN_NET_EXISTS" ]; then
        echo "Pausing again before trying to shut off $ADMIN_NETWORK_NAME network"
        sleep 5
        downAdmin
        checkAdminNetwork
    fi
    if [ "YES" = "$ADMIN_NET_EXISTS" ]; then
            echo "FAILED TO REMOVE THE '$ADMIN_NETWORK_NAME' NETWORK!"
            echo "Check $ADMIN_STACK_HOME"
            ENDMSG="WITH ERRORS"
    fi
fi

echo "##################################################################"
echo "##################################################################"
echo "Completed $ENDMSG $0"
echo "##################################################################"
echo "##################################################################"
docker ps -a
docker network ls


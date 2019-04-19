#!/bin/bash
VERSIONINFO=20181126.1
echo "Starting $0 v$VERSIONINFO"

function showUsage()
{
    echo
    echo "THIS IS A DANGEROUS SCRIPT!  USE IT ONLY IF YOU KNOW WHAT YOU ARE DOING!"
    echo
    echo "USAGE: $0 [BRANCH_NAME]"
    echo "Select a BRANCH_NAME and it will be OBLITERATED everywhere!!!"
    echo
    echo "WARNING: Both local AND REMOTE instances of the branch will be DELETED!!!"
    echo
}


showUsage

BRANCH_NAME=$1
git status

function pickBranchName()
{
    BRANCH_NAME=""
    CMD_GET_NAMES="git branch --list"
    echo "LISTING AVAILABLE BRANCHES: $CMD_GET_NAMES"

    unset options i
    i=0
    for NAME in $(eval $CMD_GET_NAMES | grep -v '*' | grep -v 'master'); do
        if [ ! "\*" = "$NAME" ]; then
            options[i++]="$NAME"
        fi
    done

    select OPT in "${options[@]}" "QUIT"; do
      case $OPT in
        "QUIT")
          echo "No branch selected"
          echo
          BRANCH_NAME=""
          break
          ;;
        *)
          echo "BRANCH_NAME named $OPT selected ..."
          echo
          BRANCH_NAME="$OPT"
          break
          ;;
      esac
    done

}

if [ -z "$BRANCH_NAME" ]; then
    pickBranchName
    if [ -z "$BRANCH_NAME" ]; then
        echo
        echo "Quitting the script without removing any branch!"
        echo
        exit 1
    fi
fi

#Contruct the commands
LOCAL_NUKE_CMD="git branch -d ${BRANCH_NAME}"
REMOTE_NUKE_CMD="git push --delete origin ${BRANCH_NAME}"

#Prompt the user with the commands and last chance to abort
echo
echo "The commands to DELETE the ${BRANCH_NAME} branch ..."
echo "LOCAL DELETE  = $LOCAL_NUKE_CMD"
echo "REMOTE DELETE = $REMOTE_NUKE_CMD"
echo 
echo "#####################################################################"
echo 
read -p "CAUTION: Press any key to DELETE the branch EVERYWHERE now (or CTRL-C to abort now)... " -n1 -s
echo 

#Do the deleting now ...
echo "Running $LOCAL_NUKE_CMD"
eval $LOCAL_NUKE_CMD
RC=$?
if [ $RC -ne 0 ]; then
    echo
    echo "#################################################"
    echo "FAILED LOCAL: NON-ZERO EXIT CODE FROM GIT=$RC"
    echo "#################################################"
    echo
    exit 2
fi
echo
echo "Running $REMOTE_NUKE_CMD"
eval $REMOTE_NUKE_CMD
RC=$?
if [ $RC -ne 0 ]; then
    echo
    echo "#################################################"
    echo "FAILED REMOTE: NON-ZERO EXIT CODE FROM GIT=$RC"
    echo "#################################################"
    echo
    exit 2
fi

#If we are here, deletion ran without errors.
echo
echo "Finished $0 DELETION of $BRANCH_NAME"
echo 

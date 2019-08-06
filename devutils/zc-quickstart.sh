#!/bin/bash
VERSIONINFO=20190804.1
echo "Starting $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt


SELECTED_REPOURI=""
unset options i
i=0
options[i++]="https://github.com/bah-insignia/zcmd-demo-rudimentary"
options[i++]="https://github.com/bah-insignia/zcmd-demo-stack"
function pickSourceRepo()
{

    select OPT in "${options[@]}" "QUIT"; do
      case $OPT in
        "QUIT")
          echo "Exiting the script now!"
          echo
          FULLPATH=""
          break
          ;;
        *)
          offset=$(($REPLY-1))
          if [ "-1" == "$offset" ]; then
            if [ "q" == "$REPLY" ] || [ "Q" == "$REPLY" ]; then
                #Friendly quit option
                echo "Exiting the script now!"
                echo
                FULLPATH=""
                break
            fi
            #They are crazy with this input!
            echo "Invalid input '$REPLY'"
          else
            #We got a path!
            SELECTED_REPOURI="${options[$offset]}"
            break
          fi
          ;;
      esac
    done

}

QS_MAP=""
QS_PATH_SOURCE_REPO=""
cloneSourceRepo()
{
    local URI=$1
    local BASE_DIR=/tmp/zcmd/quickstart

    local REPO_NAME=$(basename $URI)
    echo "# SOURCE REPO_NAME=$REPO_NAME"

    if [ -d "$BASE_DIR/$REPO_NAME" ]; then
        echo "Getting latest $1"
        local CMD="cd $BASE_DIR/$REPO_NAME && git pull"
    else
        mkdir -p $BASE_DIR
        echo "Getting latest $1"
        local CMD="cd $BASE_DIR && git clone $URI"
    fi

    echo "$CMD"
    eval "$CMD"

    # Get the quickstart.map.txt
    local QS_MAPFILE_PATH="$BASE_DIR/$REPO_NAME/.quickstart/map.txt"

    echo "TODO look $QS_MAPFILE_PATH";

    if [ ! -f "$QS_MAPFILE_PATH" ]; then
      QS_MAP=""
    else  
      QS_MAP=$(cat $QS_MAPFILE_PATH)
    fi

    QS_PATH_SOURCE_REPO=$(cd "$BASE_DIR" && cd "$REPO_NAME" && pwd)

    #echo "CLONED REPO = $TMP_CLONED_REPO"
}

function getSourcePathOptions()
{
    BASEFOLDER="$1"
    unset options i
    unset fullpaths
    i=0
    for NAME in $(ls -d ${BASEFOLDER}/*/ | awk '{print $NF}'); do
        if [ ! "$NAME" = "NAMES" ]; then
            FNAME=$(basename $NAME)
            for SUBFPATH in $(ls -d ${NAME}*/ | awk '{print $NF}'); do
                options[i]="$FNAME -> $SUBFPATH"
                fullpaths[i++]="$SUBFPATH"

                echo "TODO thing $FNAME -> $SUBFPATH"
            done
        fi
    done

}

SELECTED_SOURCE_PATH=""
pickSourceProject()
{
    unset options i
    i=0

    ls $TMP_CLONED_REPO

    echo "MAP = $QS_MAP"

}

pickSourceRepo
if [ -z "$SELECTED_REPOURI" ]; then
    exit 1
fi

cloneSourceRepo "$SELECTED_REPOURI"

pickSourceProject
if [ -z "$QS_PATH_SOURCE_REPO" ]; then
    exit 1
fi


echo "QS_MAP=$QS_MAP"


if [ ! -z "$QS_MAP" ]; then
  #Loop through the map
  for DIRBRANCH in $QS_MAP; do
  
    echo "LOOK DIRBRANCH = $DIRBRANCH"
    START_PATH="$QS_PATH_SOURCE_REPO/$DIRBRANCH"

    echo "START PATH = $START_PATH"
    getSourcePathOptions $START_PATH

  done
fi


echo "Finished $0 v$VERSIONINFO"

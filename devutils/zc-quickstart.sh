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
function cloneSourceRepo()
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

CANDIDATE_TARGET_NAME="MyQuickstart"
SELECTED_SOURCE_PATH=""
function pickSourceProject()
{
    BASEFOLDER="$1"
    REMOVE_PREFIX="$2"

    unset options i
    unset fullpaths
    i=0
    for NAME in $(ls -d ${BASEFOLDER}/*/ | awk '{print $NF}'); do
        if [ ! "$NAME" = "NAMES" ]; then
            FNAME=$(basename $NAME)
            for SUBFPATH in $(ls -d ${NAME}*/ | awk '{print $NF}'); do
                showpath=${SUBFPATH#"$REMOVE_PREFIX"}
                clean=${showpath:1:(-1)}
                options[i]="$clean"
                fullpaths[i++]="$SUBFPATH"
            done
        fi
    done

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
                CANDIDATE_TARGET_NAME=""
                SELECTED_SOURCE_PATH=""
                break
            fi
            #They are crazy with this input!
            echo "Invalid input '$REPLY'"
          else
            #We got a path!
            CANDIDATE_TARGET_NAME=$(echo "${options[$offset]}" | tr "/" "_")
            SELECTED_SOURCE_PATH="${fullpaths[$offset]}"
            break
          fi
          ;;
      esac
    done

}

function pickMapBranch()
{
  local BASEDIR=$1
  local MAP=$2

  unset options i
  unset fullpaths
  i=0
  for DIRBRANCH in $MAP; do

    options[i++]="$DIRBRANCH"

  done

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
              SELECTED_DIRBRANCH=""
              break
          fi
          #They are crazy with this input!
          echo "Invalid input '$REPLY'"
        else
          #We got a path!
          SELECTED_DIRBRANCH="${options[$offset]}"
          break
        fi
        ;;
    esac
  done

}

function copyProject()
(
  local SOURCE_DIR=$1
  local TARGET_DIR=$2

  CMD="cp -Ra $SOURCE_DIR $TARGET_DIR"

  if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
  fi

  echo "$CMD"
  eval "$CMD"
  RC=$?

  if [ $RC -ne 0 ]; then

    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERROR - Unable to create the quickstart content at $TARGET_DIR"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 2

  fi
)

#Start the process here

pickSourceRepo
if [ -z "$SELECTED_REPOURI" ]; then
    exit 1
fi

cloneSourceRepo "$SELECTED_REPOURI"
if [ -z "$QS_PATH_SOURCE_REPO" ]; then
    exit 1
fi


echo "QS_MAP=$QS_MAP"


if [ -z "$QS_MAP" ]; then

  SELECTED_SOURCE_PATH=$QS_PATH_SOURCE_REPO
  CANDIDATE_TARGET_NAME="MyQuickstart"

else
  pickMapBranch "$QS_PATH_SOURCE_REPO" "$QS_MAP"

  if [ -z "$SELECTED_DIRBRANCH" ]; then
    exit 1
  fi

  echo ""
  echo "Pick Project from '$SELECTED_DIRBRANCH' context ..."

  START_PATH="$QS_PATH_SOURCE_REPO/$SELECTED_DIRBRANCH"
  pickSourceProject "$START_PATH" "$START_PATH"
  CANDIDATE_TARGET_NAME="${SELECTED_DIRBRANCH}_${CANDIDATE_TARGET_NAME}"

fi

echo "SELECTED_SOURCE_PATH=$SELECTED_SOURCE_PATH"

echo "TODO pick target folder"
TARGET_BASEDIR="$HOME/zcmd-quickstart"
TARGET_FOLDERNAME=$CANDIDATE_TARGET_NAME

TARGET_PATH="$TARGET_BASEDIR/$TARGET_FOLDERNAME"

echo
copyProject "$SELECTED_SOURCE_PATH" "$TARGET_PATH"

echo
echo "Finished $0 v$VERSIONINFO"

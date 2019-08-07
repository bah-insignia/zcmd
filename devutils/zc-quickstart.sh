#!/bin/bash
VERSIONINFO=20190806.4
echo "Starting $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt

#Declare where we download things
TMP_BASE_DIR="/tmp/zcmd/quickstart"

#Read the arguments
ARG1=$1
KEEP_CLONED_REPO="NO"
if [ "KEEP_CLONED_REPO" = "$ARG1" ]; then
  #Prevent deletion of the TMP_BASE_DIR at end of process
  KEEP_CLONED_REPO="YES"
fi

#Declare all the curated REPO URLS in this array.
unset repo_options i
i=0
repo_options[i++]="https://github.com/bah-insignia/zcmd-demo-rudimentary"
repo_options[i++]="https://github.com/bah-insignia/zcmd-demo-stack"

###########################################
# Sets USER_ANSWER to YES or NO
###########################################
function askYesNo()
{
    PROMPT_TXT=$1
    if [ -z "$PROMPT_TXT" ]; then
      PROMPT_TXT="Quit program?"
    fi
    USER_ANSWER="UNKNOWN"
    while true; do
      read -p "$PROMPT_TXT (y/n)" yn
      case $yn in
          [Yy]* ) USER_ANSWER="YES"; break;;
          [Nn]* ) USER_ANSWER="NO"; break;;
          * ) echo "Please press 'y' for yes or 'n' for no";;
      esac
    done  
}

###########################################
# Sets QUIT_PROGRAM to YES or NO
###########################################
function introBlurb()
{
  echo
  echo "================================================================"
  echo "Welcome to the ZCMD Quickstart utility!  Use this to quickly"
  echo "install starter projects from curated web repositories."
  echo
  echo "Currently available curated repositories are the following..."
  echo
  for oneurl in "${repo_options[@]}"
  do
    echo "  $oneurl"
  done
  echo
  echo "Visit the above URLs in your Web Browser for details about them."
  echo "================================================================"
  echo
  QUIT_PROGRAM="UNKNOWN"
  askYesNo "Continue?"
  if [ "YES" = "$USER_ANSWER" ]; then
    QUIT_PROGRAM="NO"
  else
    QUIT_PROGRAM="YES"
  fi
}

SELECTED_REPOURI=""
###########################################
# Blank SELECTED_REPOURI for none.
###########################################
function pickSourceRepo()
{

    echo
    echo "Pick the source of your quickstart project."
    echo

    select OPT in "${repo_options[@]}" "QUIT"; do
      case $OPT in
        "QUIT")
          echo "Quiting!"
          echo
          SELECTED_REPOURI=""
          break
          ;;
        *)
          offset=$(($REPLY-1))
          if [ "-1" == "$offset" ]; then
            if [ "q" == "$REPLY" ] || [ "Q" == "$REPLY" ]; then
                #Friendly quit option
                echo "Quiting!"
                echo
                SELECTED_REPOURI=""
                break
            fi
            #They are crazy with this input!
            echo "Invalid input '$REPLY'"
          else
            #We got a path!
            SELECTED_REPOURI="${repo_options[$offset]}"
            break
          fi
          ;;
      esac
    done

}

QS_MAP=""
QS_PATH_SOURCE_REPO=""
###########################################
# QS_PATH_SOURCE_REPO is blank on fail
# Contents of map put into QS_MAP
###########################################
function cloneSourceRepo()
{
    local URI=$1

    local REPO_NAME=$(basename $URI)

    echo
    echo "# SOURCE REPO_NAME=$REPO_NAME"

    if [ -d "$TMP_BASE_DIR/$REPO_NAME" ]; then
        echo "Getting latest $1"
        local CMD="cd $TMP_BASE_DIR/$REPO_NAME && git pull"
    else
        mkdir -p $TMP_BASE_DIR
        echo "Getting latest $1"
        local CMD="cd $TMP_BASE_DIR && git clone $URI"
    fi

    echo "$CMD"
    eval "$CMD"

    # Get the quickstart.map.txt
    local QS_MAPFILE_PATH="$TMP_BASE_DIR/$REPO_NAME/.quickstart/map.txt"

    if [ ! -f "$QS_MAPFILE_PATH" ]; then
      # There is no fancy quickstart map
      QS_MAP=""
    else  
      # Get the conntents of the fancy map
      QS_MAP=$(cat $QS_MAPFILE_PATH)
    fi

    QS_PATH_SOURCE_REPO=$(cd "$TMP_BASE_DIR" && cd "$REPO_NAME" && pwd)

}

CANDIDATE_TARGET_NAME="MyQuickstart"
SELECTED_SOURCE_PATH=""
###########################################
# Empty SELECTED_SOURCE_PATH for quit.
###########################################
function pickSourceProject()
{
    BASEFOLDER="$1"
    REMOVE_PREFIX="$2"

    echo
    echo "Pick one of the available starter projects."
    echo

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
          echo "Quiting!"
          echo
          SELECTED_SOURCE_PATH=""
          break
          ;;
        *)
          offset=$(($REPLY-1))
          if [ "-1" == "$offset" ]; then
            if [ "q" == "$REPLY" ] || [ "Q" == "$REPLY" ]; then
                #Friendly quit option
                echo "Quiting!"
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

###########################################
# No selection is blank SELECTED_DIRBRANCH
###########################################
function pickMapBranch()
{
  local BASEDIR=$1
  local MAP=$2

  echo
  echo "Pick one of the source directory branches."
  echo

  unset options i
  unset fullpaths
  i=0
  for DIRBRANCH in $MAP; do

    options[i++]="$DIRBRANCH"

  done

  select OPT in "${options[@]}" "QUIT"; do
    case $OPT in
      "QUIT")
        echo "Quiting!"
        echo
        SELECTED_DIRBRANCH=""
        break
        ;;
      *)
        offset=$(($REPLY-1))
        if [ "-1" == "$offset" ]; then
          if [ "q" == "$REPLY" ] || [ "Q" == "$REPLY" ]; then
              #Friendly quit option
              echo "Quiting!"
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

###########################################
# If fails, sets QUIT_PROGRAM="YES"
###########################################
function copyProject()
(
  local SOURCE_DIR=$1
  local TARGET_DIR=$2

  QUIT_PROGRAM="NO"

  CMD="cp -Ra $SOURCE_DIR/* $TARGET_DIR"

  if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
  else
    echo "ls -la $TARGET_DIR"
    eval "ls -la $TARGET_DIR"
    echo
    echo "WARNING! Target directory already exists!"
    echo
    echo "  $TARGET_DIR"
    echo

    USER_ANSWER="NO"
    askYesNo "Continue and overwrite existing files?"
    if [ "YES" = "$USER_ANSWER" ]; then
      QUIT_PROGRAM="NO"
    else
      QUIT_PROGRAM="YES"
    fi

  fi

  if [ "NO" = "$QUIT_PROGRAM" ]; then

    echo
    echo "$CMD"
    eval "$CMD"
    RC=$?

    if [ $RC -ne 0 ]; then

      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "ERROR - Unable to create the quickstart content at $TARGET_DIR"
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      QUIT_PROGRAM="YES"

    fi

    if [ "NO" = "$KEEP_CLONED_REPO" ]; then
      echo
      echo "# Removing quickstart temporary base directory"
      CMD="rm -rf $TMP_BASE_DIR"
      echo "$CMD"
      eval "$CMD"
    fi

  fi
)

#Start the process here
introBlurb
if [ "YES" = "$QUIT_PROGRAM" ]; then
  echo
  echo "Quiting!"
  echo
  exit 1
fi

pickSourceRepo
if [ -z "$SELECTED_REPOURI" ]; then
    exit 1
fi

cloneSourceRepo "$SELECTED_REPOURI"
if [ -z "$QS_PATH_SOURCE_REPO" ]; then
    exit 1
fi

#echo "QS_MAP=$QS_MAP"

if [ -z "$QS_MAP" ]; then

  SELECTED_SOURCE_PATH=$QS_PATH_SOURCE_REPO
  CANDIDATE_TARGET_NAME="MyQuickstart"

else
  pickMapBranch "$QS_PATH_SOURCE_REPO" "$QS_MAP"
  if [ -z "$SELECTED_DIRBRANCH" ]; then
    exit 1
  fi

  echo
  echo "You have selected the '$SELECTED_DIRBRANCH' context ..."

  START_PATH="$QS_PATH_SOURCE_REPO/$SELECTED_DIRBRANCH"
  pickSourceProject "$START_PATH" "$START_PATH"
  CANDIDATE_TARGET_NAME="${SELECTED_DIRBRANCH}_${CANDIDATE_TARGET_NAME}"

fi

echo "SELECTED_SOURCE_PATH=$SELECTED_SOURCE_PATH"

TARGET_BASEDIR="$HOME/zcmd-quickstart"
TARGET_FOLDERNAME=$CANDIDATE_TARGET_NAME
TARGET_PATH="$TARGET_BASEDIR/$TARGET_FOLDERNAME"

echo
QUIT_PROGRAM="UNKNOWN"
copyProject "$SELECTED_SOURCE_PATH" "$TARGET_PATH"
if [ "YES" = "$QUIT_PROGRAM" ]; then
  echo
  echo "Quiting program without completing installation."
  echo
  exit 1
fi

echo $SELECTED_REPOURI > "$TARGET_PATH/.zcmd-quickstart-source-info.txt"

echo
echo "Quickstart installation complete!"
echo 
CMD="ls -la $TARGET_PATH"
echo "$CMD"
eval "$CMD"
echo

echo "######################################################################"
echo 
echo "Quickstart project has been installed to directory ..."
echo
echo "  $TARGET_PATH"
echo
README_PATH="$TARGET_PATH/README.md"
if [ -f "$README_PATH" ]; then
  echo "Tips and information can be found here ..."
  echo
  echo "  $README_PATH"
  echo
fi
echo "######################################################################"

echo
echo "Finished $0 v$VERSIONINFO"

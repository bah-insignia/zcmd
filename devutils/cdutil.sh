#!/bin/bash
VERSIONINFO=20190908.1

# This utility only works if you source it (helps you jump to zcmd stacks)
# Consider adding this to your .bashrc file...
# alias cdutil=". ~/zcmd/devutils/cdutil.sh"

THISUTILFILENAME="cdutil.sh"
THISUTILALIASNAME="cdutil"

# Check for existing alias and give advice if missing.
ALIASCHECK=$(alias | grep "$THISUTILFILENAME")
if [ -z "$ALIASCHECK" ]; then
    echo
    echo "NOTE: This utility will FAIL to change your folder unless you source it!"
    echo "      A better way to run it is to create the following alias first:"
    echo '      alias cdutil=". ~/zcmd/devutils/cdutil.sh"'
    echo
fi
echo "USAGE: $THISUTILFILENAME [FILTER1 [FILTER2]]"
echo "       Optional arguments FILTER1 and FILTER2 reduce the output size."
echo

source $HOME/zcmd/plugins/configs/cdutil.env
source $HOME/zcmd/devutils/default-docker-env.txt

FILTER=$1
if [ ! -z "$FILTER" ]; then
    echo "FILTER1 = $FILTER"
    FILTER2=$2
    if [ ! -z "$FILTER2" ]; then
        echo "FILTER2 = $FILTER2"
    fi
else
    echo "No filter ..."
fi

if [ -z "$CDUTIL_BASEFOLDER_LIST" ]; then
    echo "WARNING: Did not find environment variable CDUTIL_BASEFOLDER_LIST"
    CDUTIL_BASEFOLDER_LIST=( "${HOME}/docker-repos" )
fi

FULLPATH=""

# Adds found paths into the options list
function _addFullPathOptions()
{
    echo "Checking base $BASEFOLDER"
    if [ -d "$BASEFOLDER" ]; then
        subdircount=`find $BASEFOLDER -maxdepth 1 -type d | wc -l`
        if [ $subdircount -eq 1 ]; then
            THINGS=()
        else
            THINGS=$(ls -d ${BASEFOLDER}/*/ | awk '{print $NF}')
        fi
        for NAME in ${THINGS[@]}; do
            if [ ! "$NAME" = "NAMES" ]; then
                FNAME=$(basename $NAME)
                subdircount=`find $NAME -maxdepth 1 -type d | wc -l`
                if [ $subdircount -eq 1 ]; then
                    SUBTHINGS=()
                else
                    SUBTHINGS=$(ls -d ${NAME}*/ | awk '{print $NF}')
                fi
                if [ -z "$FILTER" ] || [ $(echo "$NAME" | grep "$FILTER") ]; then
                    HERE_STACK="${NAME}/stack.env"
                    if [ -f "$HERE_STACK" ]; then
                        options[i]="$FNAME -> $NAME"
                        fullpaths[i++]="$NAME"
                    else
                        HERE_MACHINE="${NAME}/machine.env"
                        if [ -f "$HERE_MACHINE" ]; then
                            options[i]="$FNAME -> $NAME"
                            fullpaths[i++]="$NAME"
                        fi
                    fi
                fi    
                for SUBFPATH in ${SUBTHINGS[@]}; do

                    if [ -z "$FILTER" ] || [ $(echo "$SUBFPATH" | grep "$FILTER") ]; then

                        if [ $(echo "$SUBFPATH" | grep "$FILTER2") ]; then
                            options[i]="$FNAME -> $SUBFPATH"
                            fullpaths[i++]="$SUBFPATH"
                        fi
                        DOCROOTPATH="${SUBFPATH}webserver/docroot"
                        if [ -d "$DOCROOTPATH" ] && [ $(echo "$DOCROOTPATH" | grep "$FILTER2") ]; then
                            options[i]="$FNAME -> $DOCROOTPATH"
                            fullpaths[i++]="$DOCROOTPATH"
                        else
                            DOCROOTPATH="${SUBFPATH}webserver"
                            if [ -d "$DOCROOTPATH" ] && [ $(echo "$DOCROOTPATH" | grep "$FILTER2") ]; then
                                options[i]="$FNAME -> $DOCROOTPATH"
                                fullpaths[i++]="$DOCROOTPATH"
                            else
                                DOCROOTPATH="${SUBFPATH}docroot"
                                if [ -d "$DOCROOTPATH" ] && [ $(echo "$DOCROOTPATH" | grep "$FILTER2") ]; then
                                    options[i]="$FNAME -> $DOCROOTPATH"
                                    fullpaths[i++]="$DOCROOTPATH"
                                fi
                            fi
                        fi
                    fi
                done
            fi
        done
    fi
}

# Collect all the paths we will show the user.
function getFullPathOptions()
{
    unset options i
    unset fullpaths
    i=0
    for BASEFOLDER in ${CDUTIL_BASEFOLDER_LIST[@]}; do
        _addFullPathOptions $BASEFOLDER
    done 
    for BASEFOLDER in ${CDUTIL_CUSTOM_LIST[@]}; do
        _addFullPathOptions $BASEFOLDER
    done 
}

# Show user all our collected paths and have them pick one.
function pickFolder()
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
            FULLPATH="${fullpaths[$offset]}"
            break
          fi
          ;;
      esac
    done
}

# Kick off the cool things now
getFullPathOptions
pickFolder

echo
if [ -z "$FULLPATH" ]; then
    echo "NO PATH SELECTED"
else
    # Say what we will do and then do it
    echo "cd $FULLPATH"
    cd $FULLPATH
fi
echo


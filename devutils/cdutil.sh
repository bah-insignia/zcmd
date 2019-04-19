#!/bin/bash
VERSIONINFO=20190417.1

#This utility only works if you source it (helps you jump to zcmd stacks)
#Consider adding this to your .bashrc file...
#alias cdutil=". ~/zcmd/devutils/cdutil.sh"

THISUTILFILENAME="cdutil.sh"
THISUTILALIASNAME="cdutil"

#Check for existing alias and give advice if missing.
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

source $HOME/zcmd/plugins/cdutil.sh
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

FULLPATH=""
function pickFolder()
{
    BASEFOLDER="$1"
    unset options i
    unset fullpaths
    i=0
    for NAME in $(ls -d ${BASEFOLDER}/*/ | awk '{print $NF}'); do
        if [ ! "$NAME" = "NAMES" ]; then
            FNAME=$(basename $NAME)
            for SUBFPATH in $(ls -d ${NAME}*/ | awk '{print $NF}'); do

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

if [ -z "$CDUTIL_BASEFOLDER" ]; then
    pickFolder "${HOME}/docker-repos"
else
    pickFolder "$CDUTIL_BASEFOLDER"
fi

echo
if [ -z "$FULLPATH" ]; then
    echo "NO PATH SELECTED"
else
    #Say what we will do and then do it
    echo "cd $FULLPATH"
    cd $FULLPATH
fi
echo


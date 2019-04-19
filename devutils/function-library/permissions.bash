#MUST ALREADY HAVE default env sourced!
#IMPORTANT: DO NOT OUTPUT MESSAGES ON LOAD BY DEFAULT!

LIBNAME="PERMISSIONS"
VERSIONINFO="20171229.2"
if [ -z "$LOADED_LIB_PERMISSIONS" ]; then
    if [ "load-verbose" = "$1" ]; then
        echo "#Loaded function-library $LIBNAME v$VERSIONINFO"
    fi
fi
LOADED_LIB_PERMISSIONS="YES"

if [ -z "$DEFAULT_ENV_VERSIONINFO" ]; then
    echo "MUST LOAD DEFAULT ENVIRONMENT FIRST!"
    exit 2
fi

function lib_ensureDirPermissions775()
{
    local DIRPATH=$1
    local VERBOSE_FLAG=$2
    if [ ! "VERBOSE" = "$VERBOSE_FLAG" ]; then
        VERBOSE_FLAG="QUIET"
    fi
    local DIRNAME=$(basename "$DIRPATH")
    local CREATE_MISSING_DIR="YES"

    local SEE_EXPECTED_PERM="drwxrwxr-x"
    local SET_EXPECTED_PERM="775"

    #echo "DIRPATH=$DIRPATH"
    #echo "DIRNAME=$DIRNAME"

    if [ -z "$DIRPATH" ]; then
        echo "INTERNAL ERROR --- NOT DIRPATH PROVIDED!"
        return 2
    fi

    CMD_GET_PERMISSIONS="ls -la ${DIRPATH}/.. | grep '${DIRNAME}' | awk '{print \$1}'"
    CMD_CHECK_PERMISSIONS="${CMD_GET_PERMISSIONS} | grep '$SEE_EXPECTED_PERM'"

    #echo "###CMD_GET_PERMISSIONS=$CMD_GET_PERMISSIONS"
    #echo "###CMD_CHECK_PERMISSIONS=$CMD_CHECK_PERMISSIONS"

    THE_PERM_GET=$(eval "$CMD_GET_PERMISSIONS")
    THE_PERM_CHECK_GREP=$(eval "$CMD_CHECK_PERMISSIONS")

    #echo ">>>CHECK PERM CMD=$CMD_CHECK_PERMISSIONS"

    if [ "YES" = "$CREATE_MISSING_DIR" ]; then
        if [ ! -d "${DIRPATH}" ]; then
            if [ "VERBOSE" = "$VERBOSE_FLAG" ]; then
                echo "CREATING ${DIRPATH}"
            fi
            mkdir -p ${DIRPATH}
        fi
        if [ ! -d "${DIRPATH}" ]; then
            if [ "VERBOSE" = "$VERBOSE_FLAG" ]; then
                #TRY AS SUDO
                sudo mkdir -p ${DIRPATH}
            fi
        fi
        if [ ! -d "${DIRPATH}" ]; then
            if [ "VERBOSE" = "$VERBOSE_FLAG" ]; then
                echo "WARNING MISSING ${DIRPATH}"
            fi
            return 1
        fi
    fi

    if [ ! -z "$THE_PERM_CHECK_GREP" ]; then
        if [ "VERBOSE" = "$VERBOSE_FLAG" ]; then
           echo "PERMISSIONS AT ${DIRPATH}: $THE_PERM_GET -- OK"
        fi
    else
        #Has different permissions -- change them
        if [ ! "VERBOSE" = "$VERBOSE_FLAG" ]; then
            return 2
        else
            echo "PERMISSIONS AT ${DIRPATH}: $THE_PERM_GET -- TROUBLE"
            echo "...... Expected $SEE_EXPECTED_PERM"
            CMD="sudo chmod $SET_EXPECTED_PERM $DIRPATH"
            echo "$CMD"
            eval "$CMD"
            if [ $? -ne 0 ]; then
                echo "...... FAILED to update permissions of $DIRNAME!"
                return 2
            else
                echo "...... Updated permissions of $DIRNAME"
            fi
        fi
    fi
    return 0
}

#MUST ALREADY HAVE default env sourced!
#IMPORTANT: DO NOT OUTPUT MESSAGES ON LOAD BY DEFAULT!

LIBNAME="DOCKER"
VERSIONINFO="20181227.1"
if [ -z "$LOADED_LIB_DOCKER" ]; then
    if [ "load-verbose" = "$1" ]; then
        echo "#Loaded function-library $LIBNAME v$VERSIONINFO"
    fi
fi
LOADED_LIB_DOCKER="YES"

if [ -z "$DEFAULT_ENV_VERSIONINFO" ]; then
    echo "MUST LOAD DEFAULT ENVIRONMENT FIRST!"
    exit 2
fi

# Sets RUNTIME_CONTAINERNAME if found
# Returns code 0 if found
function lib_getRuntimeWebContainerName()
{
    local OVERRIDE_CONTAINERNAME=$1

    if [ ! -z "$OVERRIDE_CONTAINERNAME" ]; then
        #Use the override
        WEBSERVER_REFNAME="$OVERRIDE_CONTAINERNAME"
    else
        #Do we have a containername declared for this stack?
        if [ ! -z "$WEB_CONTAINERNAME" ]; then
            #Use the name declared for this stack.
            WEBSERVER_REFNAME="$WEB_CONTAINERNAME"
        else
            echo "Did not find WEB_CONTAINERNAME declaration; will attempt to guess at web container name for stack."
            if [ -z "$PROJECT_NAME" ]; then
                echo "Missing required PROJECT_NAME declaration for this stack!"
                return 2
            fi

            #Take a stab at what the name should be
            WEBSERVER_REFNAME="stack_webserver_${PROJECT_NAME}"

            echo "Guessing container name would be $WEBSERVER_REFNAME"
        fi
    fi

    #Allow for Docker to screw up the declared container name with a serial number suffix
    RUNTIME_CONTAINERNAME=$(docker ps | awk '{if(NR>1) print $NF}' | grep $WEBSERVER_REFNAME)
    if [ -z "$RUNTIME_CONTAINERNAME" ]; then
        #echo "ERROR -- Did not find any container with name $WEBSERVER_REFNAME"
        return 2
    fi

}
    
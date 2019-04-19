#MUST ALREADY HAVE default env sourced!

LIBNAME="CHECK_CONTEXT"
VERSIONINFO="20190311.1"
if [ "load-verbose" = "$1" ]; then
    if [ -z "$LOADED_LIB_CHECK_CONTEXT" ]; then
        echo "#Loaded function-library $LIBNAME v$VERSIONINFO"
    fi
fi
LOADED_LIB_CHECK_CONTEXT="YES"

if [ -z "$DEFAULT_ENV_VERSIONINFO" ]; then
    echo "MUST LOAD DEFAULT ENVIRONMENT FIRST!"
    exit 2
fi

#Return 0 if is machine image folder
function lib_isMachineImageFolder()
{
    PWD=$(pwd)

    if [ ! -f "./machine.env" ]; then
        #echo " "
        #echo "$PWD is NOT a machine image folder"
        return 1
    fi

    echo "# $PWD is a machine image folder"
    return 0
}

#Return 0 if is stack folder
function lib_isRuntimeStackFolder()
{
    PWD=$(pwd)

    if [ ! -f "./stack.env" ]; then
        #echo " "
        #echo "$PWD is NOT a runtime stack folder"
        return 1
    fi

    echo "# $PWD is a runtime stack folder"
    return 0
}



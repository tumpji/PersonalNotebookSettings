#!/bin/bash
############################################################
# Help                                                     #
############################################################

set -o errexit -o pipefail -o noclobber -o nounset

Help()
{
   # Display Help
   echo -e "Syntax: scriptTemplate [-d |-e|-v|-r]"
   echo -e "options:"
   echo -e "h     Print this Help."
   echo -e "v     Verbose mode."
   echo -e "d|disable"
   echo -e "\tt|touch|touchpad\t Disables touchpad"
   echo -e "e|enable"
   echo -e "\tt|touch|touchpad\t Enables touchpad"
   echo -e "r|restart"
   echo -e "\tb|brightness|backlight\t Resets maximal brightness to 100/255"
}

VERBOSE=0
LONGOPTIONS=verbose,enable,start,disable,mode
OPTIONS=v

############################################################
# issue section:
# 
# 
# 
# 
# 
#
#
#
#
#


############################################################
# error handling:

Error() {
    echo "Error: $1"
}

Warning() {
    echo "Warning: $1"
}

Info() {
    echo "Info: $1"
}

VERBOSE=0

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

############################################################
# touchpad

disable_touchpad() 
{
    TOUCHPADID="$(xinput | grep Touchpad | sed 's\.*id=\\' | grep -o '^[0-9]*')"
    if [ $VERBOSE -eq 1 ]; then
        Info "Disabling Touchpad"
        Info "Detected touchpad-id as '$TOUCHPADID'"
    fi

    if [ -z $TOUCHPADID ]; then
        Error "Cannot find touchpad-id"
    else
        xinput disable $TOUCHPADID

        if [ $? -eq 0 ]; then
            if [ $VERBOSE -eq 1 ]; then
                Info "xinput succeded"
            fi
            Info "Touchpad disabled"
        else
            Error "xinput failed"
        fi
    fi
}

enable_touchpad() 
{
    TOUCHPADID="$(xinput | grep Touchpad | sed 's\.*id=\\' | grep -o '^[0-9]*')"
    if [ $VERBOSE -eq 1 ]; then
        Info "Enabling Touchpad"
        Info "Detected touchpad id as '$TOUCHPADID'"
    fi

    if [ -z $TOUCHPADID ]; then
        Error "Cannot find touchpad id"
    else
        xinput enable $TOUCHPADID

        if [ $? -eq 0 ]; then
            if [ $VERBOSE -eq 1 ]; then
                Info "xinput succeded"
            fi
            Info "Touchpad enabled"
        else
            Error "xinput failed"
        fi
    fi
}
############################################################
# keyboard backlight

disable_keyboard_backlight() 
{
    asusctl led-mode static -c 000000
}

enable_keyboard_backlight() 
{
    if [ -z "$1" ]; then
        asusctl led-mode static -c $1
    else
        asusctl led-mode static -c 666666
    fi
}

############################################################
# screen

reset_brightness() 
{
    echo 100 | sudo tee /sys/class/backlight/amdgpu_bl4/brightness
}

reset_brightness() {
    if [ -z "$1" ]; then
        echo $1 | sudo tee /sys/class/backlight/amdgpu_bl4/brightness
    else
        echo 100 | sudo tee /sys/class/backlight/amdgpu_bl4/brightness
    fi
}


############################################################
# mode

set_mode_performance() 
{
    Error Mode setting is not implemented
}

set_mode_balanced()
{
    Error Mode setting is not implemented
}

set_mode_batery()
{
    Error Mode setting is not implemented
}


############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options

! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    Error getopt failed
    exit 1
fi

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name $0 -- $@)
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

eval set -- "$PARSED"

while true;
do
    case "$1" in
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --help|-h)
            Help
            exit 0
            ;;
        --start)
            echo "start"
            shift
            ;;
        --stop)
            echo "stop"
            shift
            ;;
        --enable)
            echo "enable"
            shift
            ;;
        --disable)
            echo "disable"
            shift
            ;;
        --)
            break
            ;;
        *)
            Error "Unknown option '$1'"
            exit 1
    esac
done





exit 0

COMMANDS=""

while getopts ":hvd:e:r:m:" option; do
    case $option in
        h | help) # display Help
            Help
            exit;;
        v)
            echo "Verbose mode on"
            VERBOSE=1
            ;;
        enable | start) 
            echo "hoj"
            echo "$OPTARG"
            case $OPTARG in
                t|touch|touchpad)
                    COMMANDS+="enable_touchpad" 
                    ;;
                k | b | keyboard-backlight)
                    COMMANDS+="enable_keyboard_backlight"
                    ;;
                *) 
                    Error "Invalid option: cannot determine what you want to enable"
                    exit 1
                    ;;
            esac
            ;;
        d | disable | stop) 
            case $OPTARG in
                t | touch | touchpad)
                    COMMANDS+="disable_touchpad" 
                    ;;
                k | b |keyboard-backlight)
                    COMMANDS+="disable_keyboard_backlight"
                    ;;
                *) 
                    Error "Invalid option: cannot determine what you want to disable"
                    exit 1
                    ;;
            esac;;
        r | reset | restart)
            case $OPTARG in
                b | brightness | backlight)
                    COMMANDS="$COMMANDS set_brightness" 
                    ;;
                *) 
                    Error "Invalid option: cannot determine what you want to disable"
                    exit 1
                    ;;
            esac;;
        m | mode)
            case $OPTARG in 
                performance | boost)
                    COMMANDS+='set_mode_performance'
                    ;;
                balanced | normal)
                    COMMANDS+='set_mode_balanced'
                    ;;
                battery | eco)
                    COMMANDS+='set_mode_batery'
                    ;;
                *)
                    Error "Invalid option: cannot determine what mode you want to enable"
                    exit 1
                    ;;
            esac;;
        \?) # Invalid option
            echo "Error: Invalid option"
            Help
            exit
            ;;
    esac
done

for cmd in $COMMANDS;
do
    if [ $VERBOSE -eq 1 ]; then
        Info "Running: $cmd"
    fi
    $cmd
done





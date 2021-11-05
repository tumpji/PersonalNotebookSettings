#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Syntax: scriptTemplate [-d |-e|-v|-r]"
   echo "options:"
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo "d|disable"
   echo "\tt|touch|touchpad\t Disables touchpad"
   echo "e|enable"
   echo "\tt|touch|touchpad\t Enables touchpad"
   echo "r|restart"
   echo "\tb|brightness|backlight\t Resets maximal brightness to 100/255"
}

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


############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
COMMANDS=""

while getopts ":hn:d:v" option; do
    case $option in
        h | help) # display Help
            Help
            exit;;
        v)
            echo "Verbose mode on"
            VERBOSE=1
            ;;
        e | enable | start) 
            case $OPTARG in
                t | touch | touchpad)
                    COMMANDS="$COMMANDS enable_touchpad" 
                    ;;
                k | b |keyboard-backlight)
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
                    COMMANDS="$COMMANDS disable_touchpad" 
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





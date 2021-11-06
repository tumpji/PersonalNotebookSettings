#!/bin/bash
############################################################

# Help                                                     #
############################################################

set -o errexit -o pipefail -o noclobber -o nounset

Help()
{
   # Display Help
   echo -e "Syntax: [--help|-h]"
   echo -e "        [--verbose|-v] {action} {target}"
   echo -e "        [--verbose|-v] set {target_set} args"
   echo -e " where"
   echo -e "   {action} = start|stop]"
   echo -e "   {target} = [touchpad]"
   echo -e "   {target_set} = [brightness|mode]"
   echo -e ""
   echo -e " list of target:"
   echo -e "   touchpad"
   echo -e "     - enables/disables touchpad"
   echo -e ""
   echo -e " list of target_set:"
   echo -e "   brightness [{integer to 255}]"
   echo -e "     - sets maximum brightness (defaults to 100)"
   echo -e "   mode [performance|balanced|battery] "
   echo -e "     - sets power consumtion limit "
   echo -e ""
}


############################################################
# issue section:
#   add enable
#   add options to automaticly detect settings
#   add set_mode
#   
#   set_brightness: check inpu 
#   


############################################################
# error handling:

FatalError() {
    echo "Fatal Error: $1"
    exit 1
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


set_touchpad() {
    # function uses xinput to disable/enable touchpad
    # stop start 

    # detect devicenumber 
    TOUCHPADID="$(xinput | grep Touchpad | sed 's\.*id=\\' | grep -o '^[0-9]*')"
    if [ $VERBOSE -eq 1 ]; then
        Info "Detected touchpad-id as '$TOUCHPADID'"
    fi

    # check return + start 
    if [ -z $TOUCHPADID ]; then
        FatalError "Cannot find touchpad-id"
    elif [ "$1" = 'stop' ]; then
        xinput disable $TOUCHPADID
    elif [ "$1" = 'start' ]; then
        xinput enable $TOUCHPADID
    else
        FatalError "Option $1 is not implemented"
    fi

    # check return
    if [ $? -ne 0  ]; then 
        FatalError "xinput failed"
    elif [ $VERBOSE -eq 1 ]; then
        Info "xinput succeded"
    fi
}

set_keyboard_backlight() {
    # function uses asusctl to set keyboard backlight
    # stop start set

    if [ "$1" = 'stop' ]; then
        asusctl led-mode static -c 000000
    elif [ "$1" = 'start' ]; then
        asusctl led-mode static -c 555555
    elif [ "$1" = 'set' -a -n "$2" ]; then
        asusctl led-mode static -c $2
    else
        FatalError "Option $1 is not implemented"
    fi

    # check return
    if [ $? -ne 0  ]; then 
        FatalError "asusctl failed"
    elif [ $VERBOSE -eq 1 ]; then
        Info "asusctl succeded"
    fi
}

set_brightness() {
    # function sets maximum brightness
    # stop start set

    if [ "$1" = 'stop' ]; then
        echo 5 | sudo tee /sys/class/backlight/amdgpu_bl4/brightness
    elif [ "$1" = 'start' ]; then
        echo 100 | sudo tee /sys/class/backlight/amdgpu_bl4/brightness
    elif [ "$1" = 'set' -a -n $2 ]; then
        echo $2 | sudo tee /sys/class/backlight/amdgpu_bl4/brightness
    else
        Error "Option $1 is not implemented"
    fi

    # check return
    if [ $? -ne 0  ]; then 
        FatalError "changing brightness failed"
    elif [ $VERBOSE -eq 1 ]; then
        Info "asusctl succeded"
    fi
}

set_mode() {
    shift

    performance_mode_options=(performance boost extra speed power)
    balanced_mode_options=(normal balanced)
    battery_mode_options=(battery eco silent)

    for item in "${performance_mode_options[@]}"; do
        if [ "$item" = "$1" ]; then
            Info "Setting up performance mode"
            FatalError "Not implemented"
            return
        fi
    done
    for item in "${performance_mode_options[@]}"; do
        if [ "$item" = "$1" ]; then
            Info "Setting up normal mode"
            FatalError "Not implemented"
            return
        fi
    done
    for item in "${performance_mode_options[@]}"; do
        if [ "$item" = "$1" ]; then
            Info "Setting up battery mode"
            FatalError "Not implemented"
            return
        fi
    done

    FatalError "Cannot find mode '$1'"
}


############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options

VERBOSE=0

STATE=init
COMMAND=

while [ $# -ne 0 ];
do
    ARG="${1#-}"
    ARG="${ARG#-}"

    if [ $VERBOSE -eq 1 ]; then
        Info "Parsing $ARG"
    fi


    if [ $STATE = init ]; 
    then
        case "$ARG" in
            verbose|v)
                VERBOSE=1
                Info "Verbose mode on"
                shift
                ;;
            help|h)
                Help
                exit 0
                ;;
            set) STATE=set; shift;;
            start) STATE=start; shift;;
            stop) STATE=stop; shift;;
            #--enable) STATE=enable shift ;;
            #--disable) STATE=disable shift ;;
            *)
                FatalError "Unknown option '$1'"
                ;;
        esac
    elif [ "$STATE" = start -o "$STATE" = stop -o "$STATE" = set ]; then
        DEVICE="$1"
        shift

        if [ "$DEVICE" = touchpad ]; then
            COMMAND="set_touchpad $STATE "
        elif [ "$DEVICE" = backlight ]; then
            COMMAND="set_brightness $STATE "
        elif [ "$DEVICE" = mode ]; then
            COMMAND="set_mode $STATE "
        elif [ -z "$DEVICE" ]; then
            FatalError "You need to fill up device"
        else
            FatalError "Can not find device '$DEVICE'"
        fi

        # Set handling
        if [ $STATE = set ]; then 
            if [ -z "$1" ]; then
                FatalError "If using set it is required additional argument"
            fi

            COMMAND="$COMMAND $@"
        fi

        if [ $VERBOSE -eq 1 ]; then
            Info "Running code: $COMMAND"
        fi

        $COMMAND
        STATE=init
    else
        FatalError "Unknown state"
    fi
done

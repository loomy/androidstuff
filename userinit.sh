BLINKCONTROL="/sys/class/misc/backlightnotification/blink_control"
# blink interval in microseconds
ONINTERVAL="300000"
OFFINTERVAL="900000"
# Max blinking time in seconds
MAXTIME=900

enable_blinking(){
    now=$(date +%s)
    stoptime=$(expr $now + $MAXTIME)
    run="1"

    while [ "1" == "$run" ] && [ $now -lt $stoptime ]; do
        echo 0 > $BLINKCONTROL
        usleep $ONINTERVAL
        echo 1 > $BLINKCONTROL
        usleep $OFFINTERVAL
        run=$(cat $BLINKCONTROL)
        now=$(date +%s)
    done
}

# blink_control is unmodifiable 0 if 
# there are no notifications
check_blinking(){
    changed=$(cat $BLINKCONTROL)
    if [ "0" == "$changed" ] ;then
        echo 1 > $BLINKCONTROL
        changed=$(cat $BLINKCONTROL)
    else
        #timeout case
        changed=0
    fi
    echo "$changed"
}

main_loop(){
    # androids log cant read from stdin...
    #exec 2>&1 | log -t "[$$] BLN_script"
    log -t "[$$] BLN_script" "starting up..."
    while true; do
        check=$(check_blinking)
        if [ "1" == "$check" ]; then
            enable_blinking
        else
            sleep 10
        fi
    done
    log -t "[$$] BLN_script" "shutting down"
}

echo 1 > /sys/kernel/fast_charge/force_fast_charge 
if [ ! -e /sys/class/misc/backlightnotification/enabled ];then
    log -t "[$$] BLN_CHECK" "No BLN Support in kernel"
else
    echo 1 > /sys/class/misc/backlightnotification/enabled  
    #start main loop in background
    main_loop &
fi

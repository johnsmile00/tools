#!/bin/bash

SOCKDIR=$(mktemp -d)
SOCKF=${SOCKDIR}/usock
WINDOW_NAME="shellWindow"

#shell type can be shell or tty
SHELL_TYPE=${1:-nc}

if [ "$SHELL_TYPE" = "nc" ];then
    SESSION_NAME="${2:-shell}"
else
    SESSION_NAME="${2:-ttyshell}"
fi

#windows type can be tmux/screen/screenW
WINDOW_TYPE=${3:-screen}

if [ "$WINDOW_TYPE" = "screenW" ];then
    screen -ls |grep -v 'No screen session'|grep $SESSION_NAME &>/dev/null
    if [[ $? -eq 1 ]];then
        if [ "$SHELL_TYPE" = "nc" ];then
            screen -dmS $SESSION_NAME bash -c "socat - UNIX-LISTEN:${SOCKF},umask=0077"
        else
            screen -dmS $SESSION_NAME bash -c "socat file:\`tty\`,raw,echo=0 UNIX-LISTEN:${SOCKF},umask=0077"
        fi
    else
        screen -S $SESSION_NAME -X focus bottom
        screen -S $SESSION_NAME -X split -v
        screen -S $SESSION_NAME -X focus bottom
        if [ "$SHELL_TYPE" = "nc" ];then
            screen -S $SESSION_NAME -X screen bash -c "socat - UNIX-LISTEN:${SOCKF},umask=0077"
        else
            screen -S $SESSION_NAME -X screen bash -c "socat file:\`tty\`,raw,echo=0 UNIX-LISTEN:${SOCKF},umask=0077"
        fi
    fi
elif [ "$WINDOW_TYPE" = "screen" ];then
    if [ "$SHELL_TYPE" = "nc" ];then
        screen -dmS $SESSION_NAME bash -c "socat - UNIX-LISTEN:${SOCKF},umask=0077"
    else
        screen -dmS $SESSION_NAME bash -c "socat file:\`tty\`,raw,echo=0 UNIX-LISTEN:${SOCKF},umask=0077"
    fi
else
    tmux has-session -t $SESSION_NAME &>/dev/null
    if [[ $? -eq 1 ]];then
        if [ "$SHELL_TYPE" = "nc" ];then
            tmux new -s $SESSION_NAME -n $WINDOW_NAME -d "socat - exec:'ncat -lnk 9998'"
        else
            tmux new -s $SESSION_NAME -n $WINDOW_NAME -d "socat file:\`tty\`,raw,echo=0 exec:'ncat -lnk 9998'"
        fi
    fi
    # split windown 0
    if [ "$SHELL_TYPE" = "nc" ];then
        tmux split-window -h -t 0 "socat - UNIX-LISTEN:${SOCKF},umask=0077"
    else
        tmux split-window -h -t 0 "socat file:\`tty\`,raw,echo=0 UNIX-LISTEN:${SOCKF},umask=0077"
    fi
    tmux select-pane -t 0
    tmux select-layout -t $WINDOW_NAME main-horizontal
    tmux resize-pane -t 0 -y 2
    while ! $(ncat -z localhost 9998) ;do sleep 1; done;
    # Use socat to ship data between the unix socket and STDIO.
    socat -U STDOUT TCP:localhost:9998 &
fi

# Wait for socket
while test ! -e ${SOCKF} ; do sleep 1 ; done
exec socat STDIO UNIX-CONNECT:${SOCKF}
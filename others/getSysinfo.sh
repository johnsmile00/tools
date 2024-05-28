#!/bin/bash

## GLOBALS
SYSINFOFILE="sysinfo.txt"
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

# <Utils>
fun_cmd() {
    echo "" >> $SYSINFOFILE
    echo "=====================================[$1]======================================" >> $SYSINFOFILE
    eval $2 >> $SYSINFOFILE
}

fun_catfile() {
    f=$1
    if [ -e "$f" ];then
        echo "" >> $SYSINFOFILE
        echo "===========================$f================================" >> $SYSINFOFILE
        grep -Ev '^#|^$' "$f" 2>/dev/null >> $SYSINFOFILE
    fi
}

fun_findfiles() {
    keyword=$1
    place=$2
    searchword=$3
    echo "" >> $SYSINFOFILE
    res=$(find $place -type f -name "$searchword" 2>/dev/null)
    for r in $res
    do
        echo "" >> $SYSINFOFILE
        echo "=========================$r=========================" >> $SYSINFOFILE
        cat $r 2>/dev/null >> $SYSINFOFILE
    done
}

fun_finddir(){
    keyword=$1
    place=$2
    searchword=$3
    echo "" >> $SYSINFOFILE
    res=$(find $place -type d -name "$searchword" 2>/dev/null)
    for r in $res
    do
        echo "" >> $SYSINFOFILE
        echo "==========================Directory $r============================" >> $SYSINFOFILE
        ls -lah $r >> $SYSINFOFILE
    done
}

# </Utils>

# <Core>
whois() {
    echo "[User]: $(whoami)" >> $SYSINFOFILE
    echo "[Uptime]:$(uptime)" >> $SYSINFOFILE
    echo "[Uname]: $(uname -a)" >> $SYSINFOFILE
}

cpu() {
    model=$(grep "model name" /proc/cpuinfo -m 1)
    count=$(grep -c processor /proc/cpuinfo)
    model=${model/model name/}
    model=${model/:/}
    echo "[CPU]: ${count}x ${model/model name  : /}" >> $SYSINFOFILE
}

os() {
    fun_catfile '/etc/issue'
    fun_catfile '/proc/version'
    fun_catfile '/etc/os-release'
    fun_catfile '/etc/lsb-release'
}

versions() {
    echo "" >> $SYSINFOFILE
    echo "================================[Versions]===================================" >> $SYSINFOFILE
    tmp=$(bash --version 2>/dev/null| grep ersion -m 1)
    echo "bash: $tmp" >> $SYSINFOFILE
    tmp=$(python -V 2>/dev/null)
    echo "python: $tmp" >> $SYSINFOFILE
    tmp=$(python2 -V 2>/dev/null)
    echo "python2: $tmp" >> $SYSINFOFILE
    tmp=$(python3 -V 2>/dev/null)
    echo "python3: $tmp" >> $SYSINFOFILE
    tmp=$(perl --version 2>/dev/null|grep -E "\(.*\)" -m 1)
    echo "perl: $tmp" >> $SYSINFOFILE
    tmp=$(php --version 2>/dev/null|grep built)
    echo "php: $tmp" >> $SYSINFOFILE
    tmp=$(java -version 2>&1 |grep version)
    echo "java: $tmp" >> $SYSINFOFILE
    tmp=$(gcc --version 2>/dev/null|grep gcc)
    echo "gcc: $tmp" >> $SYSINFOFILE
    tmp=$(ruby --version 2>/dev/null)
    echo "ruby: $tmp" >> $SYSINFOFILE
}

infofiles() {
    fun_catfile '/etc/hosts'
    fun_catfile '/etc/crontab'
    fun_catfile '/etc/passwd'
    fun_catfile '/etc/group'
    fun_catfile '/etc/shadow'
    fun_catfile '/etc/sudoers'
    fun_catfile '/etc/ssh/sshd_config'
    fun_catfile '/etc/ldap.conf'
}

portscan() {
    which ss >/dev/null
    if [ "$?" == "0" ];then
        fun_cmd 'Port Listen' 'ss -an|grep LISTEN|grep tcp'
        return
    fi

    which netstat >/dev/null
    if [ "$?" == "0" ];then
        fun_cmd 'Port Listen' 'netstat -an|grep LISTEN|grep tcp'
        return
    fi
}

ipinfo() {
    which ip >/dev/null
    if [ "$?" == "0" ];then
        fun_cmd 'Ip Info' 'ip a|grep -v inet6|grep inet'
        fun_cmd 'Route Info' 'ip route'
        return
    fi

    which ifconfig >/dev/null
    if [ "$?" == "0" ];then
        fun_cmd 'Ip Info' 'ifconfig|grep -v inet6|grep inet'
        fun_cmd 'Route Info' 'netstat -r'
        return
    fi
}

cmdInfo() {
    fun_cmd 'Memory Info' 'free -h'   
    fun_cmd 'Arp Info' 'arp -an'
    fun_cmd 'Mount' 'mount'
    fun_cmd 'Netstat' 'netstat -anp|grep -Ev ^unix'
    fun_cmd 'Process' 'ps -ef'
    fun_cmd 'Last log' 'last -w'
}

findfiles() {
    homes=$(cat /etc/passwd|grep -v 'nologin'|grep -v 'shutdown'|awk -F: '{print $6}'|sort|uniq)
    fun_findfiles "hisotry" "$homes" '.*_history'
    fun_findfiles "viminfo" "$homes" '.viminfo'
    fun_findfiles "knownhosts" "$homes" 'known_hosts'
    fun_findfiles "id_rsa" "$homes" 'id_rsa'
    fun_findfiles "id_rsa.pub" "$homes" 'id_rsa.pub'
    fun_findfiles "authorized_keys" "$homes" 'authorized_keys'

    fun_finddir ".ssh" "$homes" '.ssh'
}
# </Core>

# <allMain>
main() {
    echo "" > $SYSINFOFILE
    whois
    cpu
    os
    versions
    ipinfo
    portscan
    cmdInfo
    infofiles
    findfiles
    cat $SYSINFOFILE
}
# </allMain>

main
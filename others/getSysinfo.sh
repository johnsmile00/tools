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
        cat $r >> $SYSINFOFILE
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
    echo "[Current User]: $(whoami)" >> $SYSINFOFILE
}

cpu() {
    model=$(grep "model name" /proc/cpuinfo -m 1)
    count=$(grep -c processor /proc/cpuinfo)
    model=${model/model name/}
    model=${model/:/}
    echo "${count}x ${model/model name  : /}" >> $SYSINFOFILE
}

space() {
    echo "" >> $SYSINFOFILE
    echo "================================[Disk Usage]===================================" >> $SYSINFOFILE
    df -h >> $SYSINFOFILE
}

upstart() {
    echo "[Uptime]:$(uptime)" >> $SYSINFOFILE
}

os() {
    echo "[Uname]: $(uname -a)" >> $SYSINFOFILE

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
    tmp=$(perl --version 2>/dev/null|grep -E "\(.*\)" -m 1)
    echo "perl: $tmp" >> $SYSINFOFILE
    tmp=$(php --version 2>/dev/null|grep built)
    echo "php: $tmp" >> $SYSINFOFILE
    tmp=$(java -version 2>/dev/null|grep version)
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

arpscan() {
    fun_cmd 'Arp Info' 'arp -an'   
}

netstatscan() {
    fun_cmd 'Netstat' 'netstat -anp|grep -Ev ^unix'
}

psscan() {
    fun_cmd 'Process' 'ps -ef'
}

lastlog() {
    fun_cmd 'Last log' 'last'
}

findfiles() {
    fun_findfiles "hisotry" '/root/' '.*_history'
    fun_findfiles "hisotry" '/home/' '.*_history'
    fun_findfiles "id_rsa" '/root/' 'id_rsa'
    fun_findfiles "id_rsa" '/home/' 'id_rsa'
    fun_findfiles "knownhosts" '/root/' 'known_hosts'
    fun_findfiles "knownhosts" '/home/' 'known_hosts'
}

finddir() {
    fun_finddir ".ssh" '/root/' '.ssh'
    fun_finddir ".ssh" '/home/' '.ssh'
}

perm() {
    echo "" >> $SYSINFOFILE
    echo "======================Folders with perm=============================" >> $SYSINFOFILE
    find / -type d -perm -2 -ls 2>/dev/null|grep -v denied >> $SYSINFOFILE
}
# </Core>

# <allMain>
main() {
    echo "" > $SYSINFOFILE
    whois
    upstart
    os
    space
    cpu
    lastlog
    versions
    portscan
    arpscan
    psscan
    netstatscan
    finddir
    infofiles
    perm
    findfiles
    cat $SYSINFOFILE
}
# </allMain>

main
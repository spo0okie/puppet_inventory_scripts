#!/bin/bash
lib_version="0.7nix"

. /usr/local/etc/inventory/priv.conf.sh


if ! echo "$apihost" | egrep -q "^http"; then
    apihost="http://$apihost"
fi


PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

writeln() {
    now=`date +"%F %T"`
    echo $*
    echo $now $* >> $logfile
}

getIPlist() {
    ip -iec -f inet addr | grep inet | grep -v '127.0.0.1' | sed 's/^\s*//' | cut -d' ' -f2 | cut -d'/' -f1
}

getMAClist() {
    ip -iec -f inet link | grep link | grep -v 'loopback' | sed 's/^\s*//' | cut -d' ' -f2 | uniq
}

updRecord() {
    writeln "data gathered:"
    writeln "domain_id=$domain_id"
    writeln "name=$comp"
    writeln "os=$os"
    writeln "raw_hw=$hw"
    writeln "raw_soft="
    writeln "raw_version=$lib_version"
    writeln "ip=$ip"
    writeln "mac=$mac"
    url="$apihost/web/api/comps/push"
    writeln "sending data ..."
    writeln curl -X POST $url
    now=`date -u +"%F %T"`
    curl -X POST \
        -vs \
        --insecure \
        --data-urlencode "name=$comp" \
        --data-urlencode "os=$os" \
        --data-urlencode "raw_hw=$hw" \
        --data-urlencode "raw_soft=" \
        --data-urlencode "raw_version=$lib_version" \
        --data-urlencode "ip=$ip" \
        --data-urlencode "mac=$mac" \
        $url >> $logfile
        echo $? >> $logfile
}

if [ -z "$logfile" ]; then
    logfile=/var/log/inventory.log
fi

writeln script started ---------------------------

writeln "detecting FQDN ..."
comp=`hostname -f | tr [:upper:] [:lower:]`
writeln "complete."

writeln "detecting OS ..."
os=`lsb_release -a 2>/dev/null| grep Description | cut -d ":" -f2 | sed  's/^\s*//'`
writeln "complete."

writeln "detecting IP address list ..."
ip=`getIPlist`
writeln "complete."

writeln "detecting MAC address list ..."
mac=`getMAClist`
writeln "complete."

writeln "detecting hardware ..."
if [ "$virtual" -eq "1" ]; then
    hw=`/usr/local/etc/inventory/fn.hwjson.sh virtual`
else
    hw=`/usr/local/etc/inventory/fn.hwjson.sh`
fi
writeln "complete."

updRecord

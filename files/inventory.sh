#!/bin/bash
lib_version="0.7.2nix"

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
    ip -f inet addr | grep inet | grep -v '127.0.0.1' | sed 's/^\s*//' | cut -d' ' -f2 | cut -d'/' -f1
}

getMAClist() {
    ip -f inet link | grep link | grep -v 'loopback' | sed 's/^\s*//' | cut -d' ' -f2 | uniq
}

#https://gist.github.com/cdown/1163649#gistcomment-4291617
# encode special characters per RFC 3986
urlencode() {
    local LC_ALL=C # support unicode = loop bytes, not characters
    local c i n=${#1}
    for (( i=0; i<n; i++ )); do
        c="${1:i:1}"
        case "$c" in
            [-_.~A-Za-z0-9]) # also encode ;,/?:@&=+$!*'()# == encodeURIComponent in javascript
            #[-_.~A-Za-z0-9\;,/?:@\&=+\$!*\'\(\)#]) # dont encode ;,/?:@&=+$!*'()# == encodeURI in javascript
               printf '%s' "$c" ;;
            *) printf '%%%+02X' "'$c" |sed 's/%FFFFFFFFFFFFFF/%/';;     #у меня тут косяк, что в RHEL5 printf трактует перменную как SIGNED char,
                                                                                                                                        #https://stackoverflow.com/questions/31090616/printf-adds-extra-ffffff-to-hex-print-from-a-char-array
        esac
    done
    echo
}

_test_urlencode() {
  local fname=urlencode
  local auml=$'\xC3\xA4' # ä = %C3%A4
  local euro=$'\xE2\x82\xAC' # € = %E2%82%AC
  local tick=$'\x60' # ` = %60
  local backtick=$'\xC2\xB4' # ´ = %C2%B4
  local input="a:/b c?d=e&f#g-+-;-,-@-\$-!-*-'-(-)-#-$tick-$backtick-$auml-$euro"
  # note: we expect uppercase hex codes from %02X format string
  local expected="a%3A%2Fb%20c%3Fd%3De%26f%23g-%2B-%3B-%2C-%40-%24-%21-%2A-%27-%28-%29-%23-%60-%C2%B4-%C3%A4-%E2%82%AC" # also encode ;,/?:@&=+$!*'()#
  #local expected="a:/b%20c?d=e&f#g-+-;-,-@-\$-!-*-'-(-)-#-%60-%C2%B4-%C3%A4-%E2%82%AC" # dont encode ;,/?:@&=+$!*'()#
  local actual="$($fname "$input")"
  if [[ "$actual" != "$expected" ]]; then
    echo "error in $fname"
    # debug
    echo "input: $input"
    echo "input hex:"; echo -n "$input" | hexdump -v -e '/1 "%02X"' | sed 's/\(..\)/\\x\1/g'; echo
    echo "input hexdump:"; echo -n "$input" | hexdump -C
    printf "actual:   "; echo "$actual"
    printf "expected: "; echo "$expected"
    exit 1
  fi
}
_test_urlencode

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
        #поддержка --data-urlencode добавилась только в curl 7.18, а в Centos 5 используется 7.15
    curl -X POST \
        -vs \
        --insecure \
        --data "name=$( urlencode "$comp" )" \
        --data "os=$( urlencode "$os" )" \
        --data "raw_hw=$( urlencode "$hw" )" \
        --data "raw_soft=" \
        --data "raw_version=$( urlencode "$lib_version" )"\
        --data "ip=$( urlencode "$ip" )"\
        --data "mac=$( urlencode "$mac" )" \
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

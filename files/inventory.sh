#!/bin/bash
lib_version="0.4nix"

. /usr/local/etc/inventory/priv.conf.sh

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

domain=`hostname -f| cut -d'.' -f2 | tr [:lower:] [:upper:]`
comp=`hostname | cut -d'.' -f1 | tr [:lower:] [:upper:]`
os=`lsb_release -a | grep Description | cut -d ":" -f2 | sed  's/^\s*//'`

hw=`/usr/local/etc/inventory/fn.hwjson.sh`

writeln() {
	now=`date +"%F %T"`
	echo $*
	echo $now $* >> $logfile
}

getJson() {
	wget -q -O - $1 | tr -d "{}\"" | sed 's/,/\n/g'
	if [ $? -ne 0 ]; then
		echo "error:$?"
	fi
}

getJsonId() {
	getJson $1 | grep -E "^id:" | cut -f2 -d":"
}

getDomainId() {
	getJsonId "http://$apihost/web/api/domains/$domain"
}

getCompId() {
	getJsonId "http://$apihost/web/api/comps/$domain/$comp"
}


getIPlist() {
	ip -iec -f inet addr | grep inet | grep -v '127.0.0.1' | sed 's/^\s*//' | cut -d' ' -f2 | cut -d'/' -f1
}

updRecord() {
	domain_id=`getDomainId`
	ip=`getIPlist`
	if [ -z "$domain_id" ]; then
		writeln uknown domain $domain
		exit 10
	fi
	writeln "data gathered:"
	writeln "domain_id=$domain_id"
	writeln "name=$comp"
	writeln "os=$os"
	writeln "raw_hw=$hw"
	writeln "raw_soft="
	writeln "raw_version=$lib_version"
	writeln "ip=$ip"

	comp_id=`getCompId`
	if [ -z "$comp_id" ]; then
		url="http://$apihost/web/api/comps"
		method=POST
	else
		url="http://$apihost/web/api/comps/$comp_id"
		method=PUT
	fi
	writeln "sending data ..."
	writeln curl -X $method $url
	now=`date +"%F %T"`
	curl -X $method \
		-d "domain_id=$domain_id" \
		--data-urlencode "name=$comp" \
		--data-urlencode "os=$os" \
		--data-urlencode "raw_hw=$hw" \
		--data-urlencode "raw_soft=" \
		--data-urlencode "raw_version=$lib_version" \
		--data-urlencode "ip=$ip" \
		--data-urlencode "updated_at=$now" \
		$url >> $logfile
		echo $? >> $logfile
}

if [ -z "$logfile" ]; then
	logfile=/var/log/inventory.log
fi

writeln script started ---------------------------
updRecord
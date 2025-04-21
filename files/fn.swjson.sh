#!/bin/bash

#получаем построчный список ПО разделенный через табуляцию
function getSwRaw() {
	if which dpkg-query >/dev/null; then
		dpkg-query -W -f='${Maintainer}\t${Package}-${Version}\n'
	elif which rpm >/dev/null; then
		rpm -qa --queryformat '%{VENDOR}\t%{NAME}-%{VERSION}\n'
	else
		echo "Reviakin labs	No DKPG or RPM found"
	fi
}

source /etc/os-release
publisher=`echo $ID|sed 's/"/\\"/g'`
name=`echo $PRETTY_NAME|sed 's/"/\\"/g'`

#echo '['
getSwRaw | awk -F'\t' '{
    gsub(/"/, "\\\"", $1);  # Экранируем кавычки в VENDOR
    gsub(/"/, "\\\"", $2);  # Экранируем кавычки в NAME-VERSION
    printf "{\"publisher\":\"%s\",\"name\":\"%s\"},\n", $1, $2;
}'

echo "{\"publisher\":\"$publisher\",\"name\":\"$name\"}"
#echo ']'
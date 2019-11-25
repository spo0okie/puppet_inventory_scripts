#!/bin/bash
mb_vendor=`dmidecode  | grep -A4 '^Base Board Information'| grep Manufacturer| cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
mb_product=`dmidecode  | grep -A4 '^Base Board Information'| grep Product| cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
mb_sn=`dmidecode  | grep -A4 '^Base Board Information'| grep Serial| cut -d':' -f2| sed -e 's/^[[:space:]]*//'`

cpu=`cat /proc/cpuinfo | grep "model name"| sort -u | cut -d ":" -f2 | sed -e 's/^[[:space:]]*//'`


echo "{\"motherboard\": {\"manufacturer\":\"$mb_vendor\",\"product\":\"$mb_product\",\"serial\":\"$mb_sn\"}}"
echo ","
echo "{\"processor\": \"$cpu\"}"
for drive in `lsblk -dnrb | cut -d" " -f1`; do
	drive_model=`smartctl -i /dev/$drive | grep "Device Model" | cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
	drive_sn=`smartctl -i /dev/$drive | grep "Serial Number" | cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
	drive_capacity=`lsblk -dnrb |grep $drive | cut -d" " -f4`
	drive_size=$(( $drive_capacity / 1073741824 ))
	echo ","
	echo "{\"harddisk\": {\"model\":\"$drive_model\",\"size\":\"$drive_size\",\"serial\":\"$drive_sn\"}}"
done


dmidecode -t 17 -q |
while IFS= read -r line; do
	if [ "$line" == "Memory Device" ]; then
		mem_vendor=""
		mem_capacity=""
		mem_sn=""
	fi
	if [ -z "$line" ]; then
		if [ "$mem_capacity" != "No" ]; then
			echo ","
			echo "{\"memorybank\": {\"manufacturer\":\"$mem_vendor\",\"capacity\":\"$mem_capacity\",\"serial\":\"$mem_sn\"}}"
		fi
	else
		token=`echo $line | cut -d':' -f1| sed -e 's/^[[:space:]]*//'`
		value=`echo $line | cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
		case $token in
			[Ss]ize)
				mem_capacity=`echo $value | cut -d" " -f1`
			;;
			"Serial Number")
				mem_sn=$value
			;;
			[Mm]anufacturer)
				mem_vendor=$value
			;;
		esac
	fi
done 

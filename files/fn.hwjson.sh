#!/bin/bash
#usage $0 [virtual]
#если указан параметр, то система расценивается как виртуальная
#в таком случае нам нужны скорее количественные характеристики а не качественные

cores=0
for count in `dmidecode -t 4 | grep 'Core Count:'| cut -d':' -f2 | cut -d' ' -f2`; do
	cores=$(( $cores + $count ))
done

#cores=`nproc --all`
if [ -z "$1" ]; then
	#ищем производителя материнской платы и
	mb_vendor=`dmidecode  | grep -A4 '^Base Board Information'| grep Manufacturer| cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
	mb_product=`dmidecode  | grep -A4 '^Base Board Information'| grep Product| cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
	mb_sn=`dmidecode  | grep -A4 '^Base Board Information'| grep Serial| cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
	echo "{\"motherboard\": {\"manufacturer\":\"$mb_vendor\",\"product\":\"$mb_product\",\"serial\":\"$mb_sn\"}}"
	#модель процессора
	#FIXME: ну это как сработает то если 2 разных модели найдется? а если стоит 2 одинаковых? странная байда
	cpu=`grep "model name" /proc/cpuinfo| uniq | cut -d ":" -f2 | sed -e 's/^[[:space:]]*//'`
	echo ","
	echo "{\"processor\": {\"model\":\"$cpu\",\"cores\":\"$cores\"}}"
else
	echo "{\"processor\": {\"model\":\"virtual $cores cores\",\"cores\":\"$cores\"}}"

fi

#test for
#grep: The -P and -z options cannot be combined
grep_test=`echo "" | grep -Pz "" 2>&1 | tr "\0" "\n"`
if [ -z "$grep_test" ]; then
	grep_params=-Poz
else
	grep_params=-Po
fi

if [ -z "$(which lsblk 2>/dev/null)" ]; then
	#наверно этот вариант более универсальный, но появилсся позже, когда пришлось работать с машинами без lsblk
	#поэтому пока используем как план Б на случай отсутствия основного инструмента, чтобы вдруг не отвалились данные на куче машин (толком не протестирована соместимость же)
	lshw_tmp=`mktemp`
	lshw -C disk -quiet > $lshw_tmp
	echo "" >> $lshw_tmp
	lshw_drives=`cat $lshw_tmp| grep -Po "\*-(disk|namespace)(:\d+)\n" | tr "\0" "\n"`

	for drive in $lshw_drives; do
		#cat $lshw_tmp
		#\K скидывает начало match на новую позицию
		#\\ вначале экранирует *-disk
		#(\n.*)+? - не жадный поиск (\n.*)+ - жадный (найдет все строки до конца файлы)
		drive_size=$( cat $lshw_tmp| grep $grep_params "\\$drive(\n.*)+?\s+size:.*\n" | tr "\0" "\n" | grep 'size:'|cut -d':' -f2|cut -d' ' -f2)
		drive_model=$( cat $lshw_tmp| grep $grep_params "\\$drive(\n.*)+?\s+product:.*\n" | tr "\0" "\n" | grep 'product:'|cut -d':' -f2|cut -d' ' -f2)
		drive_sn=$( cat $lshw_tmp| grep $grep_params "\\$drive(\n.*)+?\s+serial:.*\n" | tr "\0" "\n" | grep 'serial:'|cut -d':' -f2|cut -d' ' -f2 )
		#"
		#TiB->GiB<-MiB<-KiB
		if echo $drive_size | grep -q KiB; then
			drive_size=$(( `echo $drive_size | tr -d "KiB"` / 1024 ))MiB
		fi
		if echo $drive_size | grep -q MiB; then
			drive_size=$(( `echo $drive_size | tr -d "MiB"` / 1024 ))
		fi
		if echo $drive_size | grep -q TiB; then
			drive_size=$(( `echo $drive_size | tr -d "TiB"` * 1024 ))
		fi
		if echo $drive_size | grep -q GiB; then
			drive_size=`echo $drive_size | tr -d "GiB"`
		fi
		echo ","
		echo "{\"harddisk\": {\"model\":\"$drive_model\",\"size\":\"$drive_size\",\"serial\":\"$drive_sn\"}}"
	done

	rm -f $lshw_tmp
else
	#легаси вариант
	for drive in `lsblk -dnrb | grep disk | cut -d" " -f1`; do
		if [ -z "$1" ]; then
			drive_model=`smartctl -i /dev/$drive | grep "Device Model" | cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
			drive_sn=`smartctl -i /dev/$drive | grep "Serial Number" | cut -d':' -f2| sed -e 's/^[[:space:]]*//'`
		else
			drive_model=Virtual
			drive_sn=
		fi
		drive_capacity=`lsblk -dnrb |grep $drive | cut -d" " -f4`
		drive_size=$(( $drive_capacity / 1073741824 ))
		echo ","
		echo "{\"harddisk\": {\"model\":\"$drive_model\",\"size\":\"$drive_size\",\"serial\":\"$drive_sn\"}}"
	done
fi


# вот это вот дело законменчено, т.к. почему-то линцукс говорит что у меня памяти меньше чем на самом деле
# в интернетах пишут что мол это винда неправильно считает, типа у них кило это 1024 а в линуксе это 1000, но тогда еще больше должно быть
#потому оставляем как есть
#if [ -z "$1" ]; then
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
					unit=`echo $value | cut -d' ' -f2`
					case $unit in
						[Gg][Bb])
						mem_capacity=$(( $mem_capacity * 1024 ))
						;;
					esac
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
#else
#grep MemTotal /proc/meminfo
#fi

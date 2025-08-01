#!/bin/bash
#usage $0 [virtual]
#если указан параметр, то система расценивается как виртуальная
#в таком случае нам нужны скорее количественные характеристики а не качественные

if which nproc >/dev/null 2>&1; then
	#это был первоначально лучший вариант, сбоев не было, но не везде имеется, потом поменяли на чисто третий, но он не надежный
	#сначала я откатился ко второму, а потом решил вернуть первый как основной кандидат
	cores=`nproc --all`
elif which lscpu >/dev/null 2>&1; then
	#добавлено, т.к. вариант ниже не панацея.
	#на VM с debian11 вместо 8 ядер показал 64
	#на VM с debian9 вместо 4 показал 64
	#на VM с debian10 вместо 1 показал 0
	#на всех них эта команда давала нормальный ответ
	#cores=`lscpu -p | egrep -v '^#' | sort -u -t, -k 2,3 | wc -l`
	cores=`lscpu -p | egrep -v '^#' | cut -d',' -f2,3 | sort -u | wc -l`
else
	cores=0
	for count in `dmidecode -t 4 | awk -F: '/Core Count:/ { gsub(/^[ \t]+/, "", $2); print $2 }'`; do
		[ "$count" != "Unknown" ] && cores=$(( cores + count ))
	done
fi

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

if [ -z "$(which lsblk 2>/dev/null)" ] || [ -z "$(which smartctl 2>/dev/null)" ]; then
	#наверно этот вариант более универсальный, но появилсся позже, когда пришлось работать с машинами без lsblk
	#поэтому пока используем как план Б на случай отсутствия основного инструмента, чтобы вдруг не отвалились данные на куче машин (толком не протестирована соместимость же)
	(echo; lshw -C disk -quiet | sed 's/^[[:space:]]*\(\*\-\)/\1/' )| awk -f /usr/local/etc/inventory/disks.awk -v def=$1
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

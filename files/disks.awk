BEGIN {
	RS = "\n\\*-"  # разделитель записей: начинается с "*-disk" или др.
	FS = "\n"		 # Внутри записи поля — это строки (разделитель — новая строка)
}

# вспомогательная функция trim
function trim(str) {
    gsub(/^[ \t]+|[ \t]+$/, "", str)
    return str
}

# Обрабатываем только записи, начинающиеся с "disk" (исключаем cdrom, medium и пр.)
$1 ~ /^(disk|namespace)/ {
	model = serial = size = ""
	size_val = 0

	for (i = 1; i <= NF; i++) {
		# product:
		if (index($i, "product:") > 0) {
			split($i, a, ":")
			model = trim(a[2])
		}
		# serial:
		else if (index($i, "serial:") > 0) {
			split($i, a, ":")
			serial = trim(a[2])
		}
		# size:
		else if (index($i, "size:") > 0) {
			split($i, a, ":")
			size = trim(a[2])
		}
	
	}

	# Приведение к GiB
	if (size != "") {
		val = size
		sub(/[[:space:]]*\(.*$/, "", val)		# Удалить всё после пробела или скобок
		sub(/[A-Za-z].*$/, "", val)				# Удалить единицы (оставить только число)
		val += 0								# Преобразовать в число

		unit = size
		sub(/^[0-9.]+[[:space:]]*/, "", unit)	# Удалить число — оставить только единицы
		sub(/[[:space:]]*\(.*$/, "", unit)		# Убрать всё после скобок (если есть)

		# Конвертация в GiB
		if (u == "KiB")
			size_val = val / (1024 * 1024)
		else if (u == "MiB")
			size_val = val / 1024
		else if (u == "GiB")
			size_val = val
		else if (u == "TiB")
			size_val = val * 1024
		else if (u == "PiB")
			size_val = val * 1024 * 1024
		else
			size_val = val  # если единицы не распознаны — оставим как есть
	}


	if (size_val > 0) {
		if (model == "") model=def
		print ","
		if (size_val == int(size_val))
			printf "{\"harddisk\": {\"model\":\"%s\", \"size\":\"%.0f\", \"serial\":\"%s\"}}\n", model, size_val, serial
		else
			printf "{\"harddisk\": {\"model\":\"%s\", \"size\":\"%.1f\", \"serial\":\"%s\"}}\n", model, size_val, serial
	}
}

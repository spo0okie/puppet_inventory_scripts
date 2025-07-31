BEGIN {
    RS = "\n\\*-"  # разделитель записей: начинается с "*-disk" или др.
    FS = "\n"		 # Внутри записи поля — это строки (разделитель — новая строка)
}

# Обрабатываем только записи, начинающиеся с "disk" (исключаем cdrom, medium и пр.)
$1 ~ /^(disk|namespace)/ {
    model = serial = size = ""
	size_val = 0

    for (i = 1; i <= NF; i++) {
        if ($i ~ /product:/)
            model = gensub(/.*product:[ \t]+/, "", "g", $i)
        else if ($i ~ /serial:/)
            serial = gensub(/.*serial:[ \t]+/, "", "g", $i)
        else if ($i ~ /size:/)
            size = gensub(/.*size:[ \t]+/, "", "g", $i)
    }

    # Приведение к GiB
    if (size != "") {
        match(size, /^[0-9.]+/, num)
        match(size, /[KMGT]iB/, unit)

        val = num[0] + 0  # Преобразуем в число
        u = unit[0]

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
		print ","
		if (size_val == int(size_val))
        	printf "{\"harddisk\": {\"model\":\"%s\", \"size\":\"%.0f\", \"serial\":\"%s\"}}\n", model, size_val, serial
		else
        	printf "{\"harddisk\": {\"model\":\"%s\", \"size\":\"%.1f\", \"serial\":\"%s\"}}\n", model, size_val, serial
    }
}

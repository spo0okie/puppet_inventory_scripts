# puppet_inventory_scripts
Внешние скрипты для работы с БД инвентаризации для Linux ОС  
*проверено только на Centos6,7,8, ubuntu18, debian 9,10,11*

Сделано сразу в одном репозитории и код самих скриптов и puppet-обвязка для их пуша, 
т.к. без распространения этих скриптов, смысла в них мало.

требует redhat-lsb-core, smartmontools  

именование линукс машин по следующему соглашению
hostname -f должен возвращать fqdn хоста  
это решается этим модулем:  
https://github.com/spo0okie/puppet_centos_hostname/

### History
 * 0.5.1nix: ядра процессора отдаются отдельным параметром в JSON
 * 0.5nix: добавлена опция virtual. Если ее передать явно, то скрипт не пытается подробно сканировать оборудование, а просто возвращает количественные объемы ресурсов.
 * 0.4nix: первая продуктивная версия - работает и создает ОС

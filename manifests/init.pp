class spoo_inv (
	$apihost='inventory.domain.local',	#где находится сервер инвентаризации
	$logfile='/var/log/inventory.log',	#куда логировать работу скрипта
	$virt=0,							#признак виртуальной машины
	$cronmin='*/30',					#расписание для крона (минуты)
	$comp_id_file='/var/lib/inventory/comp.id'	#где хранить ID своей записи в БД
){
	include "logrotate"
	$config="apihost=${apihost}\nlogfile=${logfile}\nvirtual=${virt}\ncomp_id_file=${comp_id_file}"
	file {'/usr/local/etc/inventory/':
		ensure	=> directory,
		require => File['/usr/local/etc']
	} ->
	file {'/usr/local/etc/inventory/priv.conf.sh':
		content	=> $config
	} ->
	#каталог под состояние скрипта (запомненный ID записи в БД)
	file {'/var/lib/inventory/':
		ensure	=> directory
	} ->
	file {'/usr/local/etc/inventory/fn.hwjson.sh':
		source	=> 'puppet:///modules/spoo_inv/fn.hwjson.sh',
		mode	=> '0755'
	} ->
	file {'/usr/local/etc/inventory/fn.swjson.sh':
		source	=> 'puppet:///modules/spoo_inv/fn.swjson.sh',
		mode	=> '0755'
	} ->
	file {'/usr/local/etc/inventory/disks.awk':
		source	=> 'puppet:///modules/spoo_inv/disks.awk',
		mode	=> '0644'
	} ->
	file {'/usr/local/etc/inventory/inventory.sh':
		source	=> 'puppet:///modules/spoo_inv/inventory.sh',
		mode	=> '0755'
	} ->
	cron {'inventory update':
		command	=>  '/usr/local/etc/inventory/inventory.sh',
		user	=>  root,
		minute	=> $cronmin,
	} ->
	file {'/etc/logrotate.d/inventory':
		require => File['/etc/logrotate.d'],
		source => 'puppet:///modules/spoo_inv/logrotate',
		mode => '0644',
	} ->
	mc_conf::hotlist {
		'/usr/local/etc/inventory/': ;
	}

}

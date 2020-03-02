class spoo_inv (
	$apihost='inventory.domain.local',	#где находится сервер инвентаризации
	$logfile='/var/log/inventory.log',	#куда логировать работу скрипта
	$virt=0,							#признак виртуальной машины
	$cronmin='*/47'						#расписание для крона (минуты)
){
	$config="apihost=${apihost}\nlogfile=${logfile}\nvirtual=${virt}"
	file {'/usr/local/etc/inventory/':
		ensure	=> directory,
		source	=> 'puppet:///modules/spoo_inv',
		recurse	=> true,
	} ->
	file {'/usr/local/etc/inventory/priv.conf.sh':
		content	=> $config
	} ->
	cron {'inventory update':
		command	=>  '/usr/local/etc/inventory/inventory.sh',
		user	=>  root,
		minute	=> $cronmin,
	}
}

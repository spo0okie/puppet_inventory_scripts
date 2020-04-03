class spoo_inv (
	$apihost='inventory.domain.local',	#где находится сервер инвентаризации
	$logfile='/var/log/inventory.log',	#куда логировать работу скрипта
	$cronmin='*/47'				#расписание для крона (минуты)
){
	$config="apihost=${apihost}\nlogfile=${logfile}"
	file {'/usr/local/etc/inventory/':
		ensure	=> directory,
		#source	=> 'puppet:///modules/spoo_inv',
		#recurse	=> true,
	} ->
	file {'/usr/local/etc/inventory/priv.conf.sh':
		content	=> $config
	} ->
	file {'/usr/local/etc/inventory/fn.hwjson.sh':
		source	=> 'puppet:///modules/spoo_inv/fn.hwjson.sh',
		mode	=> '0755'
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
	mc_conf::hotlist {
		'/usr/local/etc/inventory/': ;
	}

}

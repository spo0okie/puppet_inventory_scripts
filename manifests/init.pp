class spoo_inv (
	$apihost='inventory.domain.local',	#где находится сервер инвентаризации
	$logfile='/var/log/inventory.log',	#куда логировать работу скрипта
	$virt=0,							#признак виртуальной машины
	$cronmin='*/47'						#расписание для крона (минуты)
){
	include "logrotate"
	$config="apihost=${apihost}\nlogfile=${logfile}\nvirtual=${virt}"
	file {'/usr/local/etc/inventory/':
		ensure	=> directory,
		require => File['/usr/local/etc']
	} ->
	file {'/usr/local/etc/inventory/priv.conf.sh':
		content	=> $config
	} ->
	file {'/usr/local/etc/inventory/fn.hwjson.sh':
		source	=> 'puppet:///modules/spoo_inv/fn.hwjson.sh',
		mode	=> '0755'
	} ->
	file {'/usr/local/etc/inventory/fn.swjson.sh':
		source	=> 'puppet:///modules/spoo_inv/fn.swjson.sh',
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
	file {'/etc/logrotate.d/inventory':
		require => File['/etc/logrotate.d'],
		source => 'puppet:///modules/spoo_inv/logrotate',
		mode => '0644',
	} ->
	mc_conf::hotlist {
		'/usr/local/etc/inventory/': ;
	}

}

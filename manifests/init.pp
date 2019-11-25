class spoo_inv {
	file {'/usr/local/etc/inventory/':
		ensure	=> directory,
		source	=> 'puppet:///modules/spoo_inv',
		recurse	=> true,
	} ->
	cron {'inventory update':
		command	=>  '/usr/local/etc/inventory/inventory.sh',
		user	=>  root,
		minute	=> '*/47',
	}
}


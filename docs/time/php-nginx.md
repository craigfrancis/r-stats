
# PHP Time with Nginx

Add the following code to the beginning of your script:

	<?php

		define('SCRIPT_START', microtime(true));

		function log_shutdown() {
			if (headers_sent()) {
				return;
			}
			if (!defined('SCRIPT_END')) {
				define('SCRIPT_END', number_format(round((microtime(true) - SCRIPT_START), 4), 4));
			}
			header('X-Time-Info: ' . SCRIPT_END);
		}

	?>

Then at the end, add:

	<?php
		log_shutdown();
	?>

You will also need to setup [nginx logging](../../docs/log/nginx.md) to have this recorded in your log file.

It might be possible to use [register_shutdown_function](https://php.net/register-shutdown-function) (like the [Apache version](./php-apache.md)), but I had problems with the headers having already been sent.

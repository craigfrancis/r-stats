
# PHP Time with Apache

Add the following code to the beginning of your script:

	<?php

		define('SCRIPT_START', microtime(true));

		if (function_exists('apache_note')) {

			function log_shutdown() {
				if (!defined('SCRIPT_END')) {
					define('SCRIPT_END', number_format(round((microtime(true) - SCRIPT_START), 4), 4));
				}
				apache_note('TIME_INFO', SCRIPT_END);
			}

			register_shutdown_function('log_shutdown');

		}

		// Now create the page...

	?>

It uses the [apache_note](http://php.net/manual/en/function.apache-note.php) function to record a "TIME_INFO" note.

You will also need to setup [apache logging](../docs-logs/apache.md) to have this recorded in your log file.

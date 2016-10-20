
# Using R to check website performance

When a scripting language such as PHP generates HTML, it can be useful to keep track of how long it takes for every request your website receives.

The notes below will allow you to record and analyse this information.

---

## Recording the time (script)

First we need to record how long it takes for the page to be created.

In PHP, you can do this with:

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

---

## Recording the time (logs)

This TIME_INFO note can then be written into the logs by creating a [LogFormat](http://httpd.apache.org/docs/current/mod/mod_log_config.html#logformat) in your main Apache config:

	LogFormat "%h %l %u [%{LOG_INFO}n] [%{%Y-%m-%d %H:%M:%S}t] [%D/%{TIME_INFO}n] \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" inc_info

Where the VirtualHosts can use it with:

	<VirtualHost 1.2.3.4:443>
		...
		CustomLog /path/to/access_log inc_info
		...
	</VirtualHost>

You will notice that I also have a LOG_INFO note as well; this can be used to record the UserID, timing for specific actions, etc.

---

## Download R

Download and install the [R.app GUI](http://cran.us.r-project.org/bin/macosx/).

---

## Download the logs

Because you want to run this on a regular basis, it's worth creating a `~/.bash_login` function such as:

	function rstats () {
		...
		/path/to/src/start.sh "${NAME}" "${SRC}";
	}

Where you would define $NAME as the project name, and $SRC as the path to the log file (maybe using `scp` to collect it from the Live server).

---

## Starting R

The [start.sh](./src/start.sh) script looks for a project specific `/stats/config.r` file ([examples](./config/)), which allows you to customise your stats for each project.

It then launches R, which looks for and runs a `.Rprofile` file - which I've setup as a symlink to [start.r](./src/start.r).

---

## Parsing the logs

The [start.r](./src/start.r) script defines some functions, and run your project specific config file.

Which may simply run the `data_load` function with:

	data_project = "[NAME]";
	data_path = "[SOURCE]";

	data_all = data_load(data_path);

Or it could be setup to ignore certain URL's which are always going to be slow - for example the members login form ([example](./config/example.r)).

Just as a word of warning, a 50 MB file can take about 30 seconds to parse.

After parsing, the [start.r](./src/start.r) script will create a duplicate of `data_all`, with a few less columns:

	data <- data_drop(data_all, c("apache", "referrer", "agent"));

---

## Using the logs

Now look at the [notes.txt](./notes.txt) file to see what R can do.

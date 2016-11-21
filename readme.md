
# Using R to check website performance

When a scripting language such as PHP generates HTML, it can be useful to keep track of how long it takes for every request your website receives.

The notes below will allow you to record and analyse this information.

---

## Recording the time

First we need to record how long it takes for the page to be created.

The execution time can be recorded with:

* [PHP with Apache](./docs-time/php-apache.md)
* [PHP with Nginx](./docs-time/php-nginx.md)

And this can be written to your logs with:

* [Apache](./docs-log/apache.md)
* [nginx](./docs-log/nginx.md)

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

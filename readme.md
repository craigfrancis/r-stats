
# Using R to check website performance

When generating HTML, it can be useful to keep track of how long it takes.

There is a short [intro article](docs/intro.md) to explain the basics, and the notes below show how you can do this.

---

## Overview

### Recording

First we need to record how long it takes for the page to be created.

The processing time can be recorded with:

* [PHP with Apache](./docs/time/php-apache.md)
* [PHP with Nginx](./docs/time/php-nginx.md)

And this can be written to your logs with:

* [Apache](./docs/log/apache.md)
* [nginx](./docs/log/nginx.md)

### Download R

Download and install the [R.app GUI](http://cran.us.r-project.org/bin/) on your local computer.

### Importing

Open R, and use the `read.table` function to import your log file:

	data = read.table("/path/to/access_log", sep=" ");

This is just like reading a CSV file, so each line in the file will contain values with a numerical offset.

A 50 MB file takes about 30 seconds to parse.

If you have problems with the User Agent string containing quote marks (some bots do this), then use `sed` to convert them into CSV escaped values:

	sed -i '' -e 's/\\"/""/g' "/path/to/access_log";

### Parsing

Lets convert the date/time (ISO formatted) into a POSIX timestamp, extract the processing time, method, url, etc:

	data$timestamp = as.POSIXct(strptime(paste(data[,5], data[,6]), '[%Y-%m-%d %H:%M:%S]'));
	data$timings <- str_match(data[,7], "\\[([0-9]*)/(.*)\\]")[,c(2,3)];
	data$info <- str_match(data[,4], "\\[(.*)\\]")[,2];
	data$request <- str_match(data[,8], "([A-Z]+) (/.*) HTTP")[,c(2,3)];

Give each field a proper name:

	data = cbind(
		timestamp = data[13],
		apache = data[,14][,1],
		time = data[,14][,2],
		ip = data[,1],
		info = data[,15],
		method = data[,16][,1],
		url = data[,16][,2],
		code = data[,9],
		size = data[,10],
		referrer = data[,11],
		agent = data[,12]);

Then do a bit of cleanup, e.g. converting the size to a number:

	data$info <- as.character(data$info);
	data$code <- as.character(data$code);
	data$size <- as.numeric(data$size);
	data$time <- as.numeric(gsub('-', NA, as.character(data$time)));

	data$path <- gsub("\\?.*", "", data$url);

And optionally remove some fields:

	data <- data[,!(names(data) %in% c("referrer", "url", "ip", "apache", "agent"))];

---

##  Using your logs

Lets see how many requests there were in total:

	nrow(data);

The average time it took to process those requests:

	subset <- subset(data, time > 0);

	mean(subset$time);
	median(subset$time);

How many resulted in errors:

	subset(data, code != 200 & code != 301 & code != 302 & code != 304);

Requests that took longer than a second:

	subset <- subset(data, time > 1);

	print(tail(subset[order(subset$time),], n=300), row.names = FALSE, right = FALSE);

A summary of pages that took longer than 100ms (0.1 second), and how often they were requested:

	subset <- subset(data, time >= 0.1 & time < 1);

	counts <- ddply(subset, .(subset$path, subset$method), summarize, freq = length(timestamp));
	names(counts) <- c("path", "method", "requests");
	print(counts[order(counts$requests),c(3,2,1)], row.names = FALSE, right = FALSE);

And a graph of the request times for a specific page:

	subset <- subset(data, path=="/url/to/view/" & time > 0);

	plot(subset$timestamp, subset$time, type='h', ann=FALSE, ylim = c(0,max(subset$time) * 1.1), yaxs="i", xaxt="n");
	axis.POSIXct(1, at=seq(as.Date(min(subset$timestamp)), as.Date(max(subset$timestamp)), by="day"), format="%e %b", las=2, lwd=0, lwd.ticks=1);

![Example Graph](./docs/images/example-1.png)

---

## Extra

If you want to run this on a regular basis, it's worth creating a `~/.bash_login` function such as:

	function rstats () {
		...
		/path/to/src/start.sh "${NAME}" "${SRC}";
	}

Where you would define $NAME as the project name, and $SRC as the path to the log file (maybe using `scp` to collect it from the Live server).

The [start.sh](./src/start.sh) script will then look for a project specific `/stats/config.r` file ([examples](./config/)), which allows you to customise your stats for each project.

It then launches R, which looks for and runs a `.Rprofile` file - which I've setup as a symlink to [start.r](./src/start.r).

### Parsing the logs

The [start.r](./src/start.r) script defines some functions, and executes your project specific config file.

Which could simply run the `data_load` function:

	data_project = "[NAME]";
	data_path = "[SOURCE]";

	data_all = data_load(data_path);

Or it could be setup to ignore certain URL's which are always going to be slow - for example the login form ([example](./config/example.r)).

After parsing, the [start.r](./src/start.r) script will create a duplicate of `data_all`, with a few less fields:

	data <- data_drop(data_all, c("apache", "referrer", "agent"));

Now have a look at [notes.txt](./notes.txt) to see what we can do.

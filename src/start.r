
Sys.setenv(TZ="Europe/London")

par(bg = 'white') # Not transparent

suppressPackageStartupMessages(library("stringr"));
suppressPackageStartupMessages(library("ggplot2"));
suppressPackageStartupMessages(library("plyr"));
suppressPackageStartupMessages(library("data.table"));
suppressPackageStartupMessages(library("dplyr")); # dtplyr does not have the group_by function
suppressPackageStartupMessages(library("splitstackshape"));

data_load <- function(data_path) {

	#--------------------------------------------------

		cat("Loading data...\n");

		data = read.table(data_path, sep=" ")

		cat("  Done\n");

	#--------------------------------------------------

		cat("Parsing data...\n");

		data$timestamp = as.POSIXct(strptime(paste(data[,5], data[,6]), '[%Y-%m-%d %H:%M:%S]'))
		data$timings <- str_match(data[,7], "\\[([0-9]*)/(.*)\\]")[,c(2,3)]
		data$info <- str_match(data[,4], "\\[(.*)\\]")[,2]
		data$request <- str_match(data[,8], "([A-Z]+) (/.*) HTTP")[,c(2,3)]

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
			agent = data[,12])

		data$time <- as.numeric(gsub('-', NA, as.character(data$time)))
		data$size <- as.numeric(gsub('-', NA, as.character(data$size)))
		data$info <- as.character(data$info)
		data$code <- as.character(data$code)
		data$path <- gsub("\\?.*", "", data$url)

		cat("  Done\n");

	#--------------------------------------------------

		cat("Excluding data...\n");

		if (exists('data_ignore_paths')) {
			data <- subset(data, !(path %in% data_ignore_paths));
		}

		cat("  Done\n");

	#--------------------------------------------------

		if (exists('data_info')) {
			cat("Parsing info...\n");
			info = data.frame(do.call(rbind, strsplit(data$info, "/")), stringsAsFactors = FALSE);
			names(info) <- data_info;
			data = cbind(data, info);
			cat("  Done\n");
		}

	#--------------------------------------------------

		if (exists('data_info_timings')) { # http://stackoverflow.com/questions/34590381/parsing-and-calculating-numbers-in-r
			cat("Parsing timings...\n");
			data_info_timings2 <- paste(data_info_timings, "_2", sep="");
			setDT(data, keep.rownames = TRUE);
			data <- data %>%
				cSplit(data_info_timings, ",", "long") %>%               # split, long format, by ","
				cSplit(data_info_timings, "=") %>%                       # split, wide format, by "="
				group_by(rn) %>%                                         # group by row names
				summarise(time = time[1],                                # first value of time...
				          time_ext = round(sum(info_timings_2), 4)) %>%  # sum of values
				replace(is.na(.), 0) %>%                                 # change na into 0
				mutate(time_php = round((time - time_ext), 4)) %>%       # calculate the difference
				left_join(data, by=c("rn", "time")) %>%                  # merge with original data
				select(timestamp, everything());                         # put timestamp first
			setorder(data, "timestamp");
			# data <- as.data.frame.matrix(data);
			setDF(data);
			data <- data_drop(data, c("rn"));
			cat("  Done\n");
		}

	#--------------------------------------------------

		if (exists('data_order')) {
			data <- data[data_order];
		}

	#--------------------------------------------------

		return(data);

}

data_drop <- function(data, fields) {
	data[,!(names(data) %in% fields)]
}

#--------------------------------------------------

stats_range <- function() {
	print(head(subset[order(subset$time),]))
	print(tail(subset[order(subset$time),]))
}

stats_max <- function(data, size = 30) {
	print(tail(subset[order(data$time),], n=size))
}

stats_group <- function(data, field) {
	fr <- count(data, field);
	print(fr[order(fr$freq),c(2,1)], row.names = FALSE, right = FALSE);
}

stats_percent <- function(data, seconds) {
	round((nrow(subset(data, time > 0 & time < seconds)) / nrow(subset(data, time > 0)) * 100), 3);
}

#--------------------------------------------------

graph_dots <- function(subset, group = "path") {
	#ggplot(subset, aes(x = time)) + geom_density(aes_string(fill="path"), alpha=I(.5))
	#ggplot(subset, aes(x = time)) + geom_density(aes_string(fill=group), alpha=I(.5))
	ggplot(subset, aes_string(x="time", fill=group)) + stat_bindot(stackgroups=TRUE, binwidth = diff(range(subset$time))/60, method='histodot') + scale_y_continuous(name = "", breaks = NULL) + scale_x_continuous(name = "");
}

graph_history <- function(subset) {
	plot(subset$timestamp, subset$time, type='h', ann=FALSE, ylim = c(0,max(subset$time) * 1.1), yaxs="i", xaxt="n", panel.first = abline(h = 0.1, col = "red"));
	axis.POSIXct(1, at=seq(as.Date(min(subset$timestamp)), as.Date(max(subset$timestamp)), by="day"), format="%e %b", las=2, lwd=0, lwd.ticks=1);
}

#--------------------------------------------------

show_subset <- function(subset, order_field = "time", file = NULL) {
	if (missing(file)) {
		print(tail(subset[order(subset[[order_field]]),], n=300), row.names = FALSE, right = FALSE);
	} else {
		write.csv(subset[order(subset[[order_field]]),], file=file, row.names = FALSE);
	}
}

show_count <- function(subset) {
	show_subset(subset);
	graph_dots(subset);
}

show_history <- function(subset) {
	show_subset(subset);
	graph_history(subset);
}

show_paths <- function(subset) {
	stats_group(subset, "path");
}

show_method_paths <- function(subset, min_time, file) {
	if (missing(min_time)) {
		counts <- ddply(subset, .(subset$path, subset$method), summarize, mean = round(mean(time), 3), min = round(min(time), 3), max = round(max(time), 3), freq = length(timestamp));
		names(counts) <- c("path", "method", "mean", "min", "max", "requests");
		counts <- subset(counts, requests > 0);
		counts <- counts[order(-counts$requests),c(6,2,1,3,4,5)];
	} else {
		counts <- ddply(subset, .(subset$path, subset$method), summarize, mean = round(mean(time), 3), min = round(min(time), 3), max = round(max(time), 3), freq = length(timestamp), exceeds = sum(time >= min_time));
		names(counts) <- c("path", "method", "mean", "min", "max", "requests", "exceeds");
		counts <- subset(counts, exceeds > 0);
		counts$percent = paste(round(((counts$exceeds / counts$requests) * 100), 0), "%", sep="");
		counts <- counts[order(-counts$exceeds),c(7,8,2,1,3,4,5,6)];
	}
	if (missing(file)) {
		print(counts, row.names = FALSE, right = FALSE);
	} else {
		write.csv(counts, file=file, row.names = FALSE);
	}
}

show_access <- function(subset, field = NULL) {
	if (is.null(field)) {
		counts <- ddply(subset, .(subset$ip), nrow);
		names(counts) <- c("ip", "requests");
		print(counts[order(counts$requests),c(2,1)], row.names = FALSE, right = FALSE);
	} else {
		counts <- ddply(subset, .(subset$ip, subset[,field]), nrow);
		names(counts) <- c("ip", field, "requests");
		print(counts[order(counts$requests),c(3,2,1)], row.names = FALSE, right = FALSE);
	}
}

#--------------------------------------------------

save_subset <- function(path, subset) {
	write.csv(subset, file=path, row.names = FALSE);
}

save_screenshot <- function(path, height = 500) {
	dev.copy(png, path, width=800, height=height, units="px");
	dev.off();
}

save_path_get <- function(subset) {
	date = mean(subset$timestamp);
	if (exists('data_stats_path')) {
		path = data_stats_path;
	} else {
		path = file.path("/Volumes/WebServer/Projects", data_project, "stats");
	}
	return(file.path(path, format(date, format="%Y"), format(date, format="%V")));
}

save_path_focus <- function(subset, id, height = 500) {

	path = save_path_get(subset);

	cat(max(subset$path), file=paste(path, "/focus-", id, ".txt", sep=""));

	dev.copy(png, paste(path, "/focus-", id, ".png", sep=""), width=800, height=height, units="px");
	dev.off();

}

save_stats <- function(admin_ip) {

	#--------------------------------------------------

		path = save_path_get(subset);

		dir.create(path, showWarnings=FALSE, recursive=TRUE);

	#--------------------------------------------------

		subset <- subset(data, !grepl("^/a/js/", path) & time > 0);

		cat(nrow(subset),        file=file.path(path, "stats-requests.txt"));
		cat(mean(subset$time),   file=file.path(path, "stats-mean.txt"));
		cat(median(subset$time), file=file.path(path, "stats-median.txt"));
		cat(sd(subset$time),     file=file.path(path, "stats-sd.txt"));

		very_slow_subset <- subset(data, ip != admin_ip & time >= 1);
		very_slow_order_1 <- "time_php"
		very_slow_order_2 <- paste("*", very_slow_order_1, "*", sep = "")
		colnames(very_slow_subset)[colnames(very_slow_subset)==very_slow_order_1] <- very_slow_order_2
		show_subset(very_slow_subset, very_slow_order_2, file.path(path, "slow-very.csv"));

		show_method_paths(subset <- subset(data, !grepl("^/a/js/", path) & ip != admin_ip & time > 0 & time < 1), 0.1, file.path(path, "slow-summary.csv"));

		save_subset(file.path(path, "errors-500.csv"), subset(data, ip != admin_ip & time > 0 & code == 500));

		errors_subset = subset(data, ip != admin_ip & time > 0 & code != 200 & code != 206 & code != 301 & code != 302 & code != 304 & code != 500);
		setorder(errors_subset, "url");
		save_subset(file.path(path, "errors-other.csv"), errors_subset);

		for (k in data_user_types) {

			subset <- subset(data, path == k$login_url & method == "POST" & code != 302);
			counts <- ddply(subset, .(subset$ip), nrow);
			names(counts) <- c("ip", "errors");
			write.csv(counts[order(-counts$errors),c(2,1)], paste(path, "/requests-login-errors-", k$name, ".csv", sep=""), row.names = FALSE);

			subset <- subset(data, path == k$login_url & method == "POST" & code == 302);
			counts <- ddply(subset, .(subset$ip, subset[[k$field]]), nrow);
			names(counts) <- c("ip", k$field, "requests");
			write.csv(counts[order(-counts$requests),c(3,1,2)], paste(path, "/requests-login-success-", k$name, ".csv", sep=""), row.names = FALSE);

		}

		for (k in data_user_types) {

			table <- as.data.table(subset(data, time > 0));
			table$val <- gsub("->.*", "", table[[k$field]]);
			table <- table[ table[['val']] != "-" , ];
			table <- table[ table[['val']] != "0" , ];

			table2 <- table[ , .(requests = .N, ips = paste(unique(ip), collapse = ", ")), by = val]
			setcolorder(table2, c("requests", "val", "ips"));
			setorder(table2, -"requests");
			names(table2) <- c("requests", k$field, "ips");
			write.csv(table2, paste(path, "/requests-account-", k$name, ".csv", sep=""), row.names = FALSE);

			table2 <- table[ , .(requests = .N, "val" = paste(unique(val), collapse = ", ")), by = ip]
			setcolorder(table2, c("requests", "ip", "val"));
			setorder(table2, -"requests");
			names(table2) <- c("requests", "ip", k$field);
			write.csv(table2, paste(path, "/requests-ip-", k$name, ".csv", sep=""), row.names = FALSE);

		}

		subset <- subset(data, size > 0 & ip != admin_ip);
		subset <- subset[c("size", "path")];
		subset <- head(subset[order(-subset$size),], n=30);
		save_subset(file.path(path, "requests-size.csv"), subset);

	#--------------------------------------------------

# TODO: Also limit to POST?

		if (exists('data_slow_paths')) {
			data_perf <- subset(data, !(path %in% data_slow_paths));
		} else {
			data_perf <- data;
		}

		subset <- subset(data_perf, !grepl("^/a/js/", path) & time > 0 & time < 1 & ip != admin_ip);

		cat(stats_percent(subset, 0.1), file=file.path(path, "stats-percent.txt"));

		subset$hour = as.POSIXct(format(subset$timestamp, format='%Y-%m-%d %H'), format='%Y-%m-%d %H')
		means <- aggregate(time ~ hour, subset, mean)
		plot(means$hour, means$time, type='h', ann=FALSE, ylim=c(0, 0.2), yaxs="i", xaxt="n", panel.first = abline(h = 0.1, col = "red"));
		axis.POSIXct(1, at=seq(as.Date(min(means$hour)), as.Date(max(means$hour)), by="day"), format="%e %b", las=2, lwd=0, lwd.ticks=1);
		save_screenshot(file.path(path, "stats-averages.png"));

		plot(subset$timestamp, subset$time, type='h', ann=FALSE, ylim=c(0, 1), yaxs="i", xaxt="n", panel.first = abline(h = 0.1, col = "red"));
		axis.POSIXct(1, at=seq(as.Date(min(subset$timestamp)), as.Date(max(subset$timestamp)), by="day"), format="%e %b", las=2, lwd=0, lwd.ticks=1);
		save_screenshot(file.path(path, "stats-access.png"));

	#--------------------------------------------------

		return(path);

}

#--------------------------------------------------

source("./.Rconfig");

data <- data_drop(data_all, c("apache", "referrer", "agent"));

subset <- subset(data, time > 0);

#--------------------------------------------------

if (exists('auto_save_stats_ip')) {
	stats_path = save_stats(auto_save_stats_ip);
	system2('open', args = c(stats_path));
	quit(save = 'no');
}

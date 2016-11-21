
# Apache Logs

The TIME_INFO note can be written to logs by creating a [LogFormat](http://httpd.apache.org/docs/current/mod/mod_log_config.html#logformat) in your main Apache config:

	LogFormat "%h %l %u [%{LOG_INFO}n] [%{%Y-%m-%d %H:%M:%S}t] [%D/%{TIME_INFO}n] \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" inc_info

Where the VirtualHosts can use this with:

	<VirtualHost 1.2.3.4:443>
		...
		CustomLog /path/to/access_log inc_info
		...
	</VirtualHost>

You will notice that I've added a LOG_INFO note as well; this can be used to record the UserID, timing for specific actions, etc.

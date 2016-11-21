
# Nginx Logs

The Time-Info header can be written to logs by creating a [log_format](http://nginx.org/en/docs/http/ngx_http_log_module.html) in your nginx config:

	log_format inc_info '$remote_addr - $remote_user [$sent_http_x_log_info] [$time_iso8601] [$request_time/$sent_http_x_time_info] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';

Where the "server" can use this with:

	server {
		...
		access_log /path/to/access_log inc_info;
		...
	}

You will notice that I've added a Log-Info value as well; this can be used to record the UserID, timing for specific actions, etc.


data_project = "[NAME]";
data_path = "[SOURCE]";

data_info = c("user_id", "admin_id", "timings");

data_timings = "timings";

data_order = c("timestamp", "time", "time_ext", "time_php", "user_id", "admin_id", "timings", "method", "path", "code", "size", "ip", "url", "info", "apache", "referrer", "agent");

data_ignore_paths = c(
		"/a/api/cli-diff-db/",
		"/admin/setup/email/"
	);

data_slow_paths = c(
		"/member/login/",
		"/admin/login/"
	);

data_user_types = list(
		list(name="user",  field="user_id",  login_url="/member/login/"),
		list(name="admin", field="admin_id", login_url="/admin/login/")
	);

data_all = data_load(data_path);

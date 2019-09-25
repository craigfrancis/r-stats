
data_project = "[NAME]";
data_path_detail = "[SRC_DETAIL]";
data_path_errors = "[SRC_ERRORS]";

data_fields_detail = c('timestamp','ref','user_id','ip','method','url','code','time','timings');
data_fields_errors = NULL;

# data_info = c("user_id", "admin_id", "timings");

data_field_timings_detail = "timings";
data_field_timings_errors = NULL;

data_field_order_detail = c("timestamp", "time", "time_ext", "time_php", "user_id", "admin_id", "timings", "method", "path", "code", "size", "ip", "url", "info", "apache", "referrer", "agent");
data_field_order_errors = NULL;

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

data_all_detail = data_load(data_path_detail, data_fields_detail, data_field_timings_detail, data_field_order_detail);
data_all_errors = data_load(data_path_errors, data_fields_errors, data_field_timings_errors, data_field_order_errors);

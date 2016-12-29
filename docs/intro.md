# Using R for stats

The main performance issue for most websites is the network - i.e. number of requests, large files, slow connection, etc.

However the time it takes to create the HTML is also a factor (ideally less than 100ms).

For example, I create websites that manage customer records, orders, reports, etc. So I need to make sure the server does not take several seconds to create the HTML.

So I've set up my servers to record how long this takes, then I use R to analyse those log files on a weekly basis.

This allows me to:

1. Ensure I don't have any requests that take longer than 1 second to process.
2. Summarise the pages that take longer than 100ms, and how often they are used.
3. See how performance is affected over time (e.g. when the backups run).
4. Show how changes to the website affects performance.

You can also see individual requests that took much longer than expected, for example:

1. When using a domain name to connect to the database, the DNS lookup can take a few seconds.
2. When using PHP sessions, a slow response can affect other requests as well (due to the session lock).
3. When checking if email addresses include a valid domain name, it can take a few seconds for a response.
4. When using a third party API, a timeout might not work as you expect (e.g. [fsockopen](https://php.net/fsockopen) vs [stream_set_timeout](https://php.net/stream_set_timeout)).
5. Hard drives can start having problems, or the CPU may be busy on other things (especially on a virtual machine).

And while not strictly related to performance, you can also see:

1. General stats, like the number of requests over time.
2. A list of 404 errors.
3. How often customers have problems filling out a form (error message could use a 200 response, success a 302).
4. How many times the admin log in (i.e. a POST to the login form, with a 302 or a 200 response).
5. Search terms being used by customers, and how effective the results are (i.e. looking at the referrer).

All you need to do is record the time it takes to create the response, then load the log file into R with:

	data = read.table("/path/to/access_log", sep=" ");

My full notes on how to cleanup the data, and create tables and graphs can be seen at:

[https://github.com/craigfrancis/r-stats/](https://github.com/craigfrancis/r-stats/)
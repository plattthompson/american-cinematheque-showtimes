load("render.star", "render")
load("time.star", "time")
load("http.star", "http")
load("cache.star", "cache")
load("encoding/base64.star", "base64")

# ---------------------------------------------------------------------------- #
#                                   CONSTANTS                                  #
# ---------------------------------------------------------------------------- #

# Test data
# all_locations_movie_list = [
# 	{
# 		'title': 'Raging Bull',
# 		'event_start_date_unix': 1674153800,
# 		'event_end_date_unix': 1674153800,
# 		'event_start_time': "22:00:00",
# 		'event_location': [54]
# 	},
# 	{
# 		'title': 'Goodfellas',
# 		'event_start_date_unix': 1674118700,
# 		'event_end_date_unix': 1674118700,
# 		'event_start_time': "12:15:00",
# 		'event_location': [102]
# 	},
# 	{
# 		'title': 'Taxi Driver',
# 		'event_start_date_unix': 1674116000,
# 		'event_end_date_unix': 1674116000,
# 		'event_start_time': "11:30:00",
# 		'event_location': [102]
# 	},
# 	{
# 		'title': 'The Irishman',
# 		'event_start_date_unix': 1674145700,
# 		'event_end_date_unix': 1674145700,
# 		'event_start_time': "19:45:00",
# 		'event_location': [102]
# 	},
# ]

CAMERA_ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABUAAAAXCAYAAADk3wSdAAAAAXNSR0IArs4c6QAAAR1JREFUSEtjZGBgYFAwrPsPokEgszoMTJeH6DASkoPpQacZkQ1EN3h66yoMfeiWYjMYq6HqJppgtTfPXMfQA5PbOTsS7JMhbih6ZKB7DznMifE6yDyc4YIrvGDiIMsWrSokPkzRVd6/v43BI7QYLgyLQJChgQ5RcHFeMVMGkBg49j+/Oo3TYSCFIG9jSwmg5NWVX8qw/sAysOEgtSAxuKEgAXQAsowYQ0284hjObFuE3VBkF4MMI9ZQmGOwuhSfoci+gAUFzPtUMRSW22BZFmveh3kTX5jiikls2ZXo2CfZUEIJHZaTsKnD6lJkhcLSnvByFST+9ul2snIciiZkQ0HJ48H5pkFuKCWuxCilYMUcKGLwleyEIhYlzAa1oQARYMFWHZmc4wAAAABJRU5ErkJggg==")

CINEMATHEQUE_SHOWTIMES_URL = "https://www.americancinematheque.com/wp-json/wp/v2/algolia_get_events?environment=production&startDate={start_time}&endDate={end_time}"

THEATER_CODES = {
	'los feliz 3': 102,
	'aero theatre': 54,
	'other': 68
}

# FF3333 is probably the furthest we want to go without being too aggressively red (maybe FF2222)
SHOWTIME_COLORS = {
	0: '#FF3333',
	1: '#FF4444',
	2: '#FF5555',
	3: '#FF6666',
	4: '#FF7777',
	5: '#FF8888',
	6: '#FF9999',
	7: '#FFAAAA',
	8: '#FFBBBB',
	9: '#FFCCCC',
	10: '#FFDDDD',
	11: '#FFEEEE',
	12: '#FFFFFF',
	13: '#FFFFFF',
	14: '#FFFFFF',
	15: '#FFFFFF',
	16: '#FFFFFF',
	17: '#FFFFFF',
	18: '#FFFFFF',
	19: '#FFFFFF',
	20: '#FFFFFF',
	21: '#FFFFFF',
	22: '#FFFFFF',
	23: '#FFFFFF',
	24: '#FFFFFF',
}

DAY_IN_SECONDS = 86400
HOUR_IN_SECONDS = 3600
MINUTE_IN_SECONDS = 60

# ---------------------------------------------------------------------------- #
#                                    HELPERS                                   #
# ---------------------------------------------------------------------------- #

# TODO: BUILD HELPER FUNCTIONS

# def find_hours_until_movie():

# def fetch_showtimes():

# def calculate_unix_time_period():

# def build_showtimes_url(current_time):

# def create_time_query_params():

def show_error_fetching_data():
	print('Error fetching data')
	return render.Root(
		child = render.Column(
			children = [
				render.Row(
					children = [
						render.Padding(
							child = render.Image(src = CAMERA_ICON),
							pad = 1
						),
						render.Column(
							children = [
								render.Text("Sorry -", font = "tb-8", color = "#FF2222"),
								render.Text("we can't", font = "tom-thumb", color = "#FF2222"),
								render.Text("connect to", font = "tom-thumb", color = "#FF2222"),
								render.Text("American", font = "tom-thumb", color = "#FF2222"),
							],
							cross_align = "end"
						)
					]
				),
				render.Padding(
					child = render.Text("Cinematheque :(", font = "tom-thumb", color = "#FF2222"),
					pad = (3, 0, 0, 0)
				)
			]
		)
	)

# ---------------------------------------------------------------------------- #
#                                     MAIN                                     #
# ---------------------------------------------------------------------------- #

def main(config):
	local_theater = config.get("theater") or "Los Feliz 3"
	local_theater_code = THEATER_CODES[local_theater.lower()]

	timezone = config.get("timezone") or "America/Los_Angeles"
	current_time = time.now().in_location(timezone)

	hours_to_seconds = int(current_time.hour) * HOUR_IN_SECONDS
	minutes_to_seconds = int(current_time.minute) * MINUTE_IN_SECONDS
	seconds = int(current_time.second)

	seconds_since_midnight = hours_to_seconds + minutes_to_seconds + seconds

	# The AmCin API requires you to query the current day's showtimes using the previous day's Unix timestamps for some reason
	beginning_of_current_day_unix = current_time.unix - seconds_since_midnight - DAY_IN_SECONDS
	end_of_current_day_unix = current_time.unix - seconds_since_midnight

	showtimes_url = CINEMATHEQUE_SHOWTIMES_URL.format(
		start_time = str(beginning_of_current_day_unix),
		end_time = str(end_of_current_day_unix)
	)

	# ------------------------------------------------ #
	#              FETCHING SHOWTIMES DATA             #
	# ------------------------------------------------ #
	res = http.get(showtimes_url)

	if res.status_code != 200:
		return show_error_fetching_data()
	
	all_locations_movie_list = res.json()["hits"]

	unsorted_movie_list = [movie for movie in all_locations_movie_list if local_theater_code in movie['event_location']]
	# Sort movie list by showtime and truncate (the device can only display four showtimes before running out of screen space)
	movie_list = sorted(unsorted_movie_list, key=lambda x: x['event_start_time'])[:4]

	return render.Root(
		child = render.Stack(
			children = [
				render.Row(
					main_align = "end",
					expanded = True,
					children = [
						render.Column(
							main_align = "end",
							children = [
								render.Marquee(
									width = 45,
									child = render.Text(movie['title'], font = "tom-thumb", color = "#89ACD4"),
									offset_start = 0,
									offset_end = 0,
									align = "start"
								) for movie in movie_list
							]
						),

						render.Column(
							main_align = "end",
							cross_align = "end",
							children = [
								render.Text(
									time.parse_time(movie['event_start_time'], "15:04:05").format("3:04"),
									font = "tom-thumb",
									color = SHOWTIME_COLORS.get(
										(int(time.parse_time(movie['event_start_time'], "15:04:05").hour) - current_time.hour),
										"#FF2222"
									)
								) for movie in movie_list
							]
						)
					]
				),

				render.Column(
					main_align = "end",
					expanded = True,
					children = [
						render.Column(
							main_align = "end",
							expanded = True,
							children = [
								render.Padding(
									child = render.Text(local_theater.upper(), font = "CG-pixel-4x5-mono", color = "#FFDD48"),
									pad = 1,
									color = "#222"
								)
							]
						)
					]
				),
			]
		)
	)

# def get_schema():
# 	return schema.Schema(
# 		version = "1",
# 		fields = [
# 			schema.Location(
# 				id = "location",
# 				name = "Location",
# 				desc = "Location for which to display time.",
# 				icon = "locationDot",
# 			)
# 		]
# 	)
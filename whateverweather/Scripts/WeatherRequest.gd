extends HTTPRequest
@export_node_path("Label") var uiText
@export_node_path("Label") var errorText
@export_node_path("GridContainer") var tableParent
@export_node_path("Label") var moonPhaseText

func _ready():
	request_completed.connect(_on_request_completed)

	# Perform a GET request. The URL below returns JSON as of writing.
	var error = request("https://api.open-meteo.com/v1/forecast?latitude=56.4691&longitude=-2.9749&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant&hourly=temperature_2m,precipitation_probability,wind_speed_10m,apparent_temperature,weather_code,cloud_cover,wind_gusts_10m,wind_direction_10m&timezone=GMT&past_days=7&forecast_days=14")
	if error != OK:
		get_node_or_null(uiText).text = "An error occurred in the HTTP request."
		#push_error("An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		get_node_or_null(uiText).text = "The HTTP request was unsuccesful"
		#push_error("The HTTP request was unsuccesful")
	
	var openMeteoJSON = JSON.parse_string(body.get_string_from_utf8())
	if (openMeteoJSON != null):
		populateForecastTable(openMeteoJSON)

func populateForecastTable(openMeteoJSON):
	var date = getWeekdayString(Time.get_date_dict_from_system().weekday) + " " + str(Time.get_date_dict_from_system(false).day) + " " + getMonthString(Time.get_date_dict_from_system(false).month) + " " + str(Time.get_date_dict_from_system(false).year)
	get_node_or_null(uiText).text = date
	
	var scene = preload("res://Scenes/label_table_entry.tscn")
	
	#print(openMeteoJSON["hourly"]["temperature_2m"].size())
	for h in openMeteoJSON["hourly"]["temperature_2m"].size():
		if h >= 168 and h < 192:
			for x in 5:
				var tableLabel = scene.instantiate()
				get_node(tableParent).add_child(tableLabel)
				if x == 0:
					tableLabel.text = str(h - 168)
				if x == 1:
					tableLabel.text = str(openMeteoJSON["hourly"]["temperature_2m"][h])
				if x == 2:
					tableLabel.text = str(openMeteoJSON["hourly"]["precipitation_probability"][h])
				if x == 3:
					tableLabel.text = str(openMeteoJSON["hourly"]["wind_speed_10m"][h])
				if x == 4:
					tableLabel.text = getWMOCode(openMeteoJSON["hourly"]["weather_code"][h])
				
	getLunarPhase()

func getWMOCode(wmo):
	if wmo == 0:
		return "Clear sky"
	elif wmo == 1:
		return "Mainly clear"
	elif wmo == 2:
		return "Partly cloudy"
	elif wmo == 3:
		return "Overcast"
	elif wmo == 45 or wmo == 48:
		return "Fog" #Fog and depositing rime fog"
	elif wmo == 51 or wmo == 53 or wmo == 55:
		return "Light drizzle" #Drizzle: Light, moderate, and dense intensity"
	elif wmo == 56 or wmo == 57:
		return "Freezing drizzle" #Freezing Drizzle: Light and dense intensity"
	elif wmo == 61 or wmo == 63 or wmo == 65:
		return "Light rain" #Rain: Slight, moderate and heavy intensity"
	elif wmo == 66 or wmo == 67:
		return "Freezing rain" #Freezing Rain: Light and heavy intensity"
	elif wmo == 71 or wmo == 73 or wmo == 75:
		return "Snow" #Snow fall: Slight, moderate, and heavy intensity"
	elif wmo == 77:
		return "Snow grains"
	elif wmo == 80 or wmo == 81 or wmo == 82:
		return "Rain showers" #Rain showers: Slight, moderate, and violent"
	elif wmo == 85 or wmo == 86:
		return "Snow showers" #Snow showers slight and heavy"
	elif wmo == 95:
		return "Thunderstors" #Thunderstorm: Slight or moderate"
	elif wmo == 96 or wmo == 99:
		return "Thunderstorms and hail" #Thunderstorm with slight and heavy hail"

func getWeekdayString(weekday):
	if weekday == 0:
		return "Sunday"
	elif weekday == 1:
		return "Monday"
	elif weekday == 2:
		return "Tuesday"
	elif weekday == 3:
		return "Wednesday"
	elif weekday == 4:
		return "Thursday"
	elif weekday == 5:
		return "Friday"
	elif weekday == 6:
		return "Saturday"

func getMonthString(month):
	if month == 1:
		return "January"
	elif month == 2:
		return "February"
	elif month == 3:
		return "March"
	elif month == 4:
		return "April"
	elif month == 5:
		return "May"
	elif month == 6:
		return "June"
	elif month == 7:
		return "July"
	elif month == 8:
		return "August"
	elif month == 9:
		return "September"
	elif month == 10:
		return "October"
	elif month == 11:
		return "November"
	elif month == 12:
		return "December"

func getLunarPhase():
	var date1 = "2026-02-17T12:03:00.00"
	var date2 = Time.get_unix_time_from_system()
	var seconds = date2 - Time.get_unix_time_from_datetime_string(date1)
	var days = float(seconds) / 60.0 / 60.0 / 24.0
	var age = fmod(days, 29.53059)
	#print(age)
	if age >= 0.0 and age < 1.0:
		get_node_or_null(moonPhaseText).text = "New Moon"
	elif age >= 1.0 and age < 5.0:
		get_node_or_null(moonPhaseText).text = "Waxing Crescent"
	elif age >= 5.0 and age < 9.0:
		get_node_or_null(moonPhaseText).text = "First Quarter"
	elif age >= 9.0 and age < 13.0:
		get_node_or_null(moonPhaseText).text = "Waxing Gibbous"
	elif age >= 13.0 and age < 17.0:
		get_node_or_null(moonPhaseText).text = "Full Moon"
	elif age >= 17.0 and age < 21.0:
		get_node_or_null(moonPhaseText).text = "Waning Gibbous"
	elif age >= 21.0 and age < 25.0:
		get_node_or_null(moonPhaseText).text = "Last Quarter"
	elif age >= 25.0:
		get_node_or_null(moonPhaseText).text = "Waning Crescent"

# TO-DO
# You have to wait for a request to finish before sending another one. Making multiple request at once requires you to have one node per request. A common strategy is to create and delete HTTPRequest nodes at runtime as necessary.
# Need more feedback if HTTP request unsuccesful, e.g. prompt to connect to internet

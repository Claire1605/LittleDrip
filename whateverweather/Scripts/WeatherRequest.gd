extends HTTPRequest
@export_node_path("Node") var control
@export_node_path("Label") var locationText
@export_node_path("Label") var dateText
@export_node_path("Label") var errorText
@export_node_path("GridContainer") var tableParent
@export_node_path("Label") var moonPhaseText
@export_node_path("TextureRect") var moonPhaseTexture
@export_node_path("TextureRect") var moonPhaseTexturePrevious
@export_node_path("TextureRect") var moonPhaseTextureNext
@export_node_path("Node") var saveDataPath
@export_node_path("Node") var previousDayPanel
@export_node_path("Node") var nextDayPanel
@export_node_path("TextureButton") var clock
@export_node_path("TextureButton") var clockNight
@export_node_path("Label") var clockPreviousDay
@export_node_path("Label") var clockNextDay
@export var tempText: Array[Label] = []
@export var windText: Array[Label] = []
@export var cloudText: Array[Label] = []
@export var precText: Array[Label] = []
@export var weatherText: Array[Label] = []
@export var moonTextures: Array[Texture] = []
@export var dayDateText: Array[Label] = []
@export var dayWMOText: Array[Label] = []
@export var dayTempText: Array[Label] = []
@export var dayAppTempText: Array[Label] = []
@export var dayWindText: Array[Label] = []
@export var daySunText: Array[Label] = []
var saveData
var startDay: int = 7
var clockDay: int = 7
var openMeteoJSON
var todayUnix: float
var selectedDateUnix: float
var tableLabelScene
var gridChildren: Array[Node]
var clockHourDates: Array[int]
var clockDatePreviousUnix: float
var clockDateNextUnix: float

func _ready():
	saveData = get_node_or_null(saveDataPath)
	saveData.load_game()
	get_node_or_null(locationText).text = saveData.placeName
	
	for x in 24:
		clockHourDates.append(startDay)
	
	tableLabelScene = preload("res://Scenes/label_table_entry.tscn")
	todayUnix = Time.get_unix_time_from_system()
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	request_completed.connect(_on_request_completed)
	weatherRequest()

func weatherRequest():
	# Perform a GET request. The URL below returns JSON as of writing.
	var error = request("https://api.open-meteo.com/v1/forecast?latitude=" + str(saveData.latitude) + "&longitude=" + str(saveData.longitude) + "&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant&hourly=temperature_2m,precipitation_probability,wind_speed_10m,apparent_temperature,weather_code,cloud_cover,wind_gusts_10m,wind_direction_10m&timezone=auto&past_days=7&forecast_days=14&wind_speed_unit=mph")
	if error != OK:
		get_node_or_null(dateText).text = "An error occurred in the HTTP request."
		#push_error("An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		get_node_or_null(dateText).text = "The HTTP request was unsuccesful"
		#push_error("The HTTP request was unsuccesful")
	else:
		get_node_or_null(clock).requestReady = true

	openMeteoJSON = JSON.parse_string(body.get_string_from_utf8())
	if (openMeteoJSON != null):
		populateForecastTable(openMeteoJSON)
		daySummarySetup()
		clockRotation()
		resetClockDates()
	
	getLunarPhase()

func populateForecastTable(openMeteoJSON):
	var selectedDate = Time.get_datetime_dict_from_unix_time(selectedDateUnix) # 86400 is 1 day in unix time
	var date = getWeekdayString(selectedDate.weekday) + " " + str(selectedDate.day) + " " + getMonthString(selectedDate.month) + " " + str(selectedDate.year)
	
	get_node_or_null(dateText).text = date
	
	#if !gridChildren.is_empty():
	#	for g in gridChildren:
	#		if is_instance_valid(g):
	#			g.queue_free()

	var hour = -1
	for h in openMeteoJSON["hourly"]["temperature_2m"].size():
		if h >= (startDay * 24) and h < ((startDay + 1) * 24):
			hour += 1
			for x in 6:
				#var tableLabel = tableLabelScene.instantiate()
				#get_node(tableParent).add_child(tableLabel)
				#gridChildren.append(tableLabel as Node)
				
				#if x == 0:
					#tableLabel.text = str(hour)
				if x == 1:
					#tableLabel.text = str(openMeteoJSON["hourly"]["temperature_2m"][h]) + " (" + str(openMeteoJSON["hourly"]["apparent_temperature"][h]) + ")"
					tempText[hour].text = str(openMeteoJSON["hourly"]["temperature_2m"][h]) + "°C\n (" + str(openMeteoJSON["hourly"]["apparent_temperature"][h]) + "°C)"
				if x == 2:
					#tableLabel.text = str(openMeteoJSON["hourly"]["precipitation_probability"][h])
					precText[hour].text = str(openMeteoJSON["hourly"]["precipitation_probability"][h]) + "% p."
				if x == 3:
					#tableLabel.text = str(openMeteoJSON["hourly"]["cloud_cover"][h])
					cloudText[hour].text = str(openMeteoJSON["hourly"]["cloud_cover"][h]) + "% cc"
				if x == 4:
					#tableLabel.text = str(openMeteoJSON["hourly"]["wind_speed_10m"][h]) + " / " + str(openMeteoJSON["hourly"]["wind_gusts_10m"][h]) + " / " + str(openMeteoJSON["hourly"]["wind_direction_10m"][h]) + "°"
					windText[hour].text = str(openMeteoJSON["hourly"]["wind_speed_10m"][h]) + "mph\n" + str(openMeteoJSON["hourly"]["wind_gusts_10m"][h]) + " gust\n" + str(openMeteoJSON["hourly"]["wind_direction_10m"][h]) + "°"
				if x == 5:
					#tableLabel.text = getWMOCode(openMeteoJSON["hourly"]["weather_code"][h])
					weatherText[hour].text = getWMOCode(openMeteoJSON["hourly"]["weather_code"][h])

func daySummarySetup():
	if startDay > 0:
		get_node_or_null(previousDayPanel).show()
		populateDaySummary(openMeteoJSON, startDay - 1, 0)
	else:
		get_node_or_null(previousDayPanel).hide()
	
	populateDaySummary(openMeteoJSON, startDay, 1)
	
	if startDay < 20:
		get_node_or_null(nextDayPanel).show()
		populateDaySummary(openMeteoJSON, startDay + 1, 2)
	else:
		get_node_or_null(nextDayPanel).hide()

func populateDaySummary(openMeteoJSON, day, position):
	var d = 0
	if position == 0:
		d = -86400
	elif position == 2:
		d = 86400
		
	var selectedDate = Time.get_datetime_dict_from_unix_time(selectedDateUnix + d) # 86400 is 1 day in unix time
	var date2 = getWeekdayString(selectedDate.weekday).erase(3,100) + " " + str(selectedDate.day) + " " + getMonthString(selectedDate.month).erase(3,100)
	dayDateText[position].text = date2
	dayWMOText[position].text = getWMOCode(openMeteoJSON["daily"]["weather_code"][day])
	dayTempText[position].text = str(openMeteoJSON["daily"]["temperature_2m_min"][day]) + "°C - "+ str(openMeteoJSON["daily"]["temperature_2m_max"][day]) + "°C"
	dayAppTempText[position].text = "(" + str(openMeteoJSON["daily"]["apparent_temperature_min"][day]) + "°C - "+ str(openMeteoJSON["daily"]["apparent_temperature_max"][day]) + "°C)"
	dayWindText[position].text = str(openMeteoJSON["daily"]["wind_speed_10m_max"][day]) + " mph, " + str(openMeteoJSON["daily"]["wind_gusts_10m_max"][day]) + " mph gusts, at "+ str(openMeteoJSON["daily"]["wind_direction_10m_dominant"][day]) + "°"

	var sunrise = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunrise"][day]) + ":00", false)
	var sunset = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunset"][day]) + ":00", false)
	daySunText[position].text = "Sun: " +  str("%02d" % sunrise.hour) + ":" + str("%02d" % sunrise.minute) + " - " + str("%02d" % sunset.hour) + ":" + str("%02d" % sunset.minute)
	
	var sunriseFraction = float(sunrise.hour) + (float(sunrise.minute) / 60.0)
	var sunsetFraction = float(sunset.hour) + (float(sunset.minute) / 60.0)
	
	var sr = 0.0
	var ss = 0.0
	
	if sunriseFraction >= 12.0:
		sr = ((sunriseFraction - 12.0) / 12.0) * 0.5
	else:
		sr = ((sunriseFraction / 12.0) * 0.5) + 0.5
		
	if sunsetFraction >= 12.0:
		ss = ((sunsetFraction - 12.0) / 12.0) * 0.5
	else:
		ss = ((sunsetFraction / 12.0) * 0.5) + 0.5
	
	sundial(sr, ss)
	#clockDateLabels()
	
func getWMOCode(wmo):
	# https://www.nodc.noaa.gov/archive/arc0021/0002199/1.1/data/0-data/HTML/WMO-CODE/WMO4677.HTM
	match wmo:
		0.0: return "Clear sky"
		1.0: return "Mainly clear"
		2.0: return "Partly cloudy"
		3.0: return "Overcast"
		4.0: return "Smokey"
		5.0: return "Haze"
		6.0: return "Light dust"
		7.0: return "Heavy dust"
		8.0: return "Dust whirl"
		9.0: return "Duststorm"
		10.0: return "Mist"
		11.0: return "Shallow fog"
		12.0: return "Shallow fog"
		13.0: return "Lightning"
		14.0: return "Precipitation nearby"
		15.0: return "Precipitation nearby"
		16.0: return "Precipitation nearby"
		17.0: return "Thunderstorm"
		18.0: return "Squalls"
		19.0: return "Funnel cloud"
		20.0: return "Drizzle"
		21.0: return "Rain"
		22.0: return "Snow"
		23.0: return "Rain and snow"
		24.0: return "Freezing drizzle"
		25.0: return "Rain showers"
		26.0: return "Snow showers"
		27.0: return "Hail showers"
		28.0: return "Recent fog"
		29.0: return "Thunderstorm"
		30.0: return "Slight duststorm"
		31.0: return "Slight duststorm"
		32.0: return "Slight duststorm"
		33.0: return "Severe duststorm"
		34.0: return "Severe duststorm"
		35.0: return "Severe duststorm"
		36.0: return "Slight blowing snow"
		37.0: return "Heavy drifting snow"
		38.0: return "Slight blowing snow"
		39.0: return "Heavy drifting snow"
		40.0: return "Fog or ice fog"
		41.0: return "Fog or ice fog"
		42.0: return "Fog or ice fog"
		43.0: return "Fog or ice fog"
		44.0: return "Fog or ice fog"
		45.0: return "Fog or ice fog"
		46.0: return "Fog or ice fog"
		47.0: return "Fog or ice fog"
		48.0: return "Fog and rime"
		49.0: return "Fog and rime"
		50.0: return "Slight drizzle"
		51.0: return "Slight drizzle"
		52.0: return "Moderate drizzle"
		53.0: return "Moderate drizzle"
		54.0: return "Heavy drizzle"
		55.0: return "Heavy drizzle"
		56.0: return "Slight freezing drizzle"
		57.0: return "Heavy freezing drizzle"
		58.0: return "Slight drizzle and rain"
		59.0: return "Heavy drizzle and rain"
		60.0: return "Slight rain"
		61.0: return "Slight rain"
		62.0: return "Moderate rain"
		63.0: return "Moderate rain"
		64.0: return "Heavy rain"
		65.0: return "Heavy rain"
		66.0: return "Slight freezing rain"
		67.0: return "Heavy freezing rain"
		68.0: return "Slight rain and snow"
		69.0: return "Heavy rain and snow"
		70.0: return "Slight snow"
		71.0: return "Slight snow"
		72.0: return "Moderate snow"
		73.0: return "Moderate snow"
		74.0: return "Heavy snow"
		75.0: return "Heavy snow"
		76.0: return "Diamond dust"
		77.0: return "Snow grains"
		78.0: return "Snow crystals"
		79.0: return "Ice pellets"
		80.0: return "Slight rain showers"
		81.0: return "Moderate rain showers"
		82.0: return "Heavy rain showers"
		83.0: return "Slight sleet showers"
		84.0: return "Heavy sleet showers"
		85.0: return "Slight snow showers"
		86.0: return "Heavy snow showers"
		87.0: return "Small hail showers"
		88.0: return "Small hail showers"
		89.0: return "Hail showers"
		90.0: return "Hail showers"
		91.0: return "Slight rain"
		92.0: return "Heavy rain"
		93.0: return "Slight snow and hail"
		94.0: return "Heavy snow and hail"
		95.0: return "Thunderstorm"
		96.0: return "Thunderstorm and hail"
		97.0: return "Heavy thunderstorm"
		98.0: return "Thunder and dust storm"
		99.0: return "Heavy thunder and hail"
		_: return "Unknown"

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
	var dateReference = "2026-02-17T12:03:00.00" #recent known new moon
	var dateSelected = selectedDateUnix
	
	var seconds = dateSelected - Time.get_unix_time_from_datetime_string(dateReference)
	var days = float(seconds) / 60.0 / 60.0 / 24.0
	var age = fmod(days, 29.53059)
	
	var daysPrevious = float(seconds - 86400) / 60.0 / 60.0 / 24.0
	var agePrevious = fmod(daysPrevious, 29.53059)
	
	var daysNext = float(seconds + 86400) / 60.0 / 60.0 / 24.0
	var ageNext = fmod(daysNext, 29.53059)
	
	if (age >= 0.0 and age < 0.75) or age >= 28.75:
		get_node_or_null(moonPhaseText).text = "New Moon"
	elif age >= 0.75 and age < 6.65:
		get_node_or_null(moonPhaseText).text = "Waxing Crescent Moon"
	elif age >= 6.65 and age < 8.15:
		get_node_or_null(moonPhaseText).text = "First Quarter Moon" #7.4
	elif age >= 8.15 and age < 14.05:
		get_node_or_null(moonPhaseText).text = "Waxing Gibbous Moon"
	elif age >= 14.05 and age < 15.55:
		get_node_or_null(moonPhaseText).text = "Full Moon" #14.8
	elif age >= 15.55 and age < 21.45:
		get_node_or_null(moonPhaseText).text = "Waning Gibbous Moon"
	elif age >= 21.45 and age < 22.95:
		get_node_or_null(moonPhaseText).text = "Last Quarter Moon" #22.2
	elif age >= 22.95:
		get_node_or_null(moonPhaseText).text = "Waning Crescent Moon"
		
	var moonIndex: float = floor((age / 29.53059) * 29.0)
	var moonIndexPrevious: float = floor((agePrevious / 29.53059) * 29.0)
	var moonIndexNext: float = floor((ageNext / 29.53059) * 29.0)
	get_node_or_null(moonPhaseTexture).texture_normal = moonTextures[moonIndex]
	get_node_or_null(moonPhaseTexturePrevious).texture_normal = moonTextures[moonIndexPrevious]
	get_node_or_null(moonPhaseTextureNext).texture_normal = moonTextures[moonIndexNext]
	
	if startDay > 0:
		get_node_or_null(moonPhaseTexturePrevious).show()
	else:
		get_node_or_null(moonPhaseTexturePrevious).hide()
		
	if startDay < 20:
		get_node_or_null(moonPhaseTextureNext).show()
	else:
		get_node_or_null(moonPhaseTextureNext).hide()

func updateLocation(placeName: String, lat: float, long: float):
	saveData.save_game(placeName, lat, long)	
	get_node_or_null(locationText).text = saveData.placeName
	weatherRequest()

func _on_today_button_pressed() -> void:
	today()

func today():
	startDay = 7
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	populateForecastTable(openMeteoJSON)
	daySummarySetup()
	getLunarPhase()
	clockRotation()
	resetClockDates()

func _on_previous_day_button_pressed() -> void:
	previousDay()
	decreaseClockDates()

func previousDay():
	startDay -= 1
	clockDay -= 1
	if startDay < 0:
		startDay = 0
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	populateForecastTable(openMeteoJSON)
	daySummarySetup()
	getLunarPhase()

func on_next_day_button_pressed() -> void:
	nextDay()
	increaseClockDates()

func nextDay():
	startDay += 1
	clockDay += 1
	if startDay > 20:
		startDay = 20
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	populateForecastTable(openMeteoJSON)
	daySummarySetup()
	getLunarPhase()

func getDayWeatherCodeAverage(day):
	var code: float = 0
	for h in 24:
		code += openMeteoJSON["hourly"]["weather_code"][h]
	code /= 24.0
	return getWMOCode(round(code))

func clockRotation():
	var h = Time.get_datetime_dict_from_system().hour
	var m = Time.get_datetime_dict_from_system().minute
	get_node_or_null(clock).set_rotation_degrees((-15.0 * h) - (15.0 / 60.0 * m) -90)

func resetClockDates():
	var r = wrap(get_node_or_null(clock).get_rotation_degrees(), 0.0, 360.0)
	
	if r > 90 and r < 270:
		clockDatePreviousUnix = todayUnix + 86400 # today
		clockDateNextUnix = todayUnix + 86400 + 86400 # tomorrow
	elif r < 90 or r > 270:
		clockDatePreviousUnix = todayUnix # yesterday
		clockDateNextUnix = todayUnix + 86400 # today
	
	updateClockLabels()

func increaseClockDates():
	clockDatePreviousUnix += 86400
	clockDateNextUnix += 86400
	updateClockLabels()

func decreaseClockDates():
	clockDatePreviousUnix -= 86400
	clockDateNextUnix -= 86400
	updateClockLabels()

func updateClockLabels():
	var selectedDatePrevious = Time.get_datetime_dict_from_unix_time(clockDatePreviousUnix)
	var selectedDateNext = Time.get_datetime_dict_from_unix_time(clockDateNextUnix)
	var dateShortPrevious = getWeekdayString(selectedDatePrevious.weekday).erase(3,100) + "\n " + str(selectedDatePrevious.day) + " " + getMonthString(selectedDatePrevious.month).erase(3,100)
	var dateShortNext = getWeekdayString(selectedDateNext.weekday).erase(3,100) + "\n " + str(selectedDateNext.day) + " " + getMonthString(selectedDateNext.month).erase(3,100)
	
	var r = wrap(get_node_or_null(clock).get_rotation_degrees(), 0.0, 360.0)
	#print(r)
	
	get_node_or_null(clockPreviousDay).text = dateShortPrevious
	get_node_or_null(clockNextDay).text = dateShortNext
	
	if clockDay > 0:
		get_node_or_null(clockPreviousDay).show()
	else:
		if r < 90 or r > 270:
			get_node_or_null(clockPreviousDay).show()
		else:
			get_node_or_null(clockPreviousDay).hide()
		
	if clockDay < 20:
		get_node_or_null(clockNextDay).show()
	else:
		if r > 90 and r < 270:
			get_node_or_null(clockNextDay).show()
		else:
			get_node_or_null(clockNextDay).hide()


func sundial(sunrise, sunset):
	get_node_or_null(clockNight).material.set_shader_parameter("cooldown_progress", sunrise)
	get_node_or_null(clockNight).material.set_shader_parameter("cooldown_offset", sunset)

# TO-DO
# You have to wait for a request to finish before sending another one. Making multiple request at once requires you to have one node per request. A common strategy is to create and delete HTTPRequest nodes at runtime as necessary.
# Need more feedback if HTTP request unsuccesful, e.g. prompt to connect to internet

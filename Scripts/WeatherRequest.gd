class_name WeatherRequest

extends HTTPRequest
@export_node_path("Node") var control
@export_node_path("Label") var debug
@export_node_path("Label") var locationText
@export_node_path("Label") var dateText
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
@export var tempText: Array[RichTextLabel] = []
@export var tempColourBorers: Array[TextureRect] = []
@export var tempColours: Array[Color] = []
@export var windText: Array[RichTextLabel] = []
@export var windRotation: Array[Node] = []
@export var cloudText: Array[Label] = []
@export var cloudImage: Array[TextureRect] = []
@export var cloudLevel: Array[Texture] = []
@export var cloudLevelNight: Array[Texture] = []
@export var rainLevel: Array[Texture] = []
@export var rainLevelMedium: Array[Texture] = []
@export var rainLevelSmall: Array[Texture] = []
@export var lightning: Array[TextureRect] = []
@export var snowLevel: Array[Texture] = []
@export var rainImage: Array[TextureRect] = []
@export var precText: Array[Label] = []
@export var weatherText: Array[Label] = []
@export var moonTextures: Array[Texture] = []
@export var dayDateText: Array[Label] = []
@export var dayWMOText: Array[Label] = []
@export var dayTempText: Array[Label] = []
@export var dayAppTempText: Array[Label] = []
@export var dayWindText: Array[Label] = []
@export var daySunText: Array[Label] = []
@export var creditsPanel: Node
@export var settingsPanel: Node
var saveData
var startDay: int = 7
var openMeteoJSON
var todayUnix: float
var selectedDateUnix: float
var tableLabelScene
var gridChildren: Array[Node]
var requestProcessing = false
var waitForRequest = false
var updatingTempUnit = false;

func _ready():
	saveData = get_node_or_null(saveDataPath)
	saveData.load_game()
	get_node_or_null(locationText).text = saveData.placeName
	
	tableLabelScene = preload("res://Scenes/label_table_entry.tscn")
	todayUnix = Time.get_unix_time_from_system()
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	request_completed.connect(_on_request_completed)
	clockRotation()
	TryWeatherRequest()

func TryWeatherRequest():
	if !requestProcessing:
		weatherRequest()
	else:
		waitForRequest = true

func weatherRequest():
	# Perform a GET request. The URL below returns JSON as of writing.
	# tempUnit: blank = celsius, temperature_unit=fahrenheit
	# windUnit: blank = km/h, wind_speed_unit=mph wind_speed_unit=ms wind_speed_unit=kn
	
	var temp = ""
	if saveData.tempUnit != "":
		temp = "&temperature_unit=" + saveData.tempUnit
	var wind = ""
	if saveData.windUnit != "":
		wind = "&wind_speed_unit=" + saveData.windUnit
	requestProcessing = true
	var error = request("https://api.open-meteo.com/v1/forecast?latitude=" + str(saveData.latitude) + "&longitude=" + str(saveData.longitude) + "&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant&hourly=temperature_2m,precipitation_probability,rain,snowfall,wind_speed_10m,apparent_temperature,weather_code,cloud_cover,wind_gusts_10m,wind_direction_10m&timezone=auto&past_days=7&forecast_days=14" + wind + temp)
	if error != OK:
		get_node_or_null(dateText).text = ""
		#push_error("An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
	requestProcessing = false
	if result != HTTPRequest.RESULT_SUCCESS:
		get_node_or_null(dateText).text = "Could not retrieve weather data, please restart app"
		#push_error("The HTTP request was unsuccesful")
	else:
		get_node_or_null(clock).requestReady = true

	openMeteoJSON = JSON.parse_string(body.get_string_from_utf8())
	if openMeteoJSON != null:
		#clockRotation()
		updatingTempUnit = false
		populateForecastTable()
		populateInitialWindDirection()
		daySummarySetup()
	
	getLunarPhase()

func _process(delta: float) -> void:
	if get_node_or_null(clock).requestReady:
		populateForecastTable()
	
	if waitForRequest:
		if !requestProcessing:
			waitForRequest = false
			weatherRequest()

func populateInitialWindDirection(): # this is separate so that it only happens once and not every frame
	for h in range(0,24):
		var day = get_node_or_null(clock).clockHourDates[h]
		var i = (day * 24) + h
		if !(day < 0 or day > 20):
			windRotation[h].SetInitialRotation(wrapf(openMeteoJSON["hourly"]["wind_direction_10m"][i] + 180.0, 0.0, 360.0), windRotation[h].get_parent().get_rotation_degrees() ,get_node_or_null(clock).get_rotation_degrees())

func populateForecastTable():
	var selectedDate = Time.get_datetime_dict_from_unix_time(selectedDateUnix) # 86400 is 1 day in unix time
	var date = getWeekdayString(selectedDate.weekday) + " " + str(selectedDate.day) + " " + getMonthString(selectedDate.month) + " " + str(selectedDate.year)
	get_node_or_null(dateText).text = date

	for h in range(0,24):
		var day = get_node_or_null(clock).clockHourDates[h]
		var i = (day * 24) + h
		var weatherCodeText = getWMOCode(openMeteoJSON["hourly"]["weather_code"][i])
		
		if day < 0 or day > 20:
			tempText[h].get_parent().visible = false
			precText[h].get_parent().visible = false
			cloudImage[h].visible = false
			windText[h].get_parent().visible = false
			weatherText[h].get_parent().visible = false
		else:
			tempText[h].get_parent().visible = true
			precText[h].get_parent().visible = true
			cloudImage[h].visible = true
			windText[h].get_parent().visible = true
			weatherText[h].get_parent().visible = true
			tempText[h].text = "[font_size=44]" + str(roundi(openMeteoJSON["hourly"]["temperature_2m"][i])) + "°\n[font_size=36]"+ str(roundi(openMeteoJSON["hourly"]["apparent_temperature"][i])) + "°[/font_size]"
			
			#Temperature
			if !updatingTempUnit:
				var temperature_color = tempColours[getTemperatureColor(roundi(openMeteoJSON["hourly"]["temperature_2m"][i]))]
				if saveData.tempUnit == "fahrenheit":
					var f = (openMeteoJSON["hourly"]["temperature_2m"][i] - 32) * (5.0/9.0)
					temperature_color = tempColours[getTemperatureColor(roundi(f))] #conversion from fahrenheit to celsius
				if saveData.tempColours:
					tempText[h].get_parent().material = tempText[h].get_parent().material.duplicate()
					tempText[h].get_parent().material.set_shader_parameter('colour', temperature_color)
					tempColourBorers[h].hide()
				else:
					tempText[h].get_parent().material = tempText[h].get_parent().material.duplicate()
					tempText[h].get_parent().material.set_shader_parameter('colour', Color.WHITE)
					tempColourBorers[h].show()
					tempColourBorers[h].material = tempText[h].get_parent().material.duplicate()
					tempColourBorers[h].material.set_shader_parameter('colour', temperature_color)
			
			var sunrise = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunrise"][day]) + ":00", false)
			var sunset = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunset"][day]) + ":00", false)
	
			#Cloud Cover
			if openMeteoJSON["hourly"]["cloud_cover"][i] >= 0 and openMeteoJSON["hourly"]["cloud_cover"][i] <= 25:
				if isHourInDaylight(h, sunrise.hour, sunset.hour):
					cloudImage[h].texture = cloudLevel[0]
				else:
					cloudImage[h].texture = cloudLevelNight[0]
			elif openMeteoJSON["hourly"]["cloud_cover"][i] > 25 and openMeteoJSON["hourly"]["cloud_cover"][i] <= 50:
				if isHourInDaylight(h, sunrise.hour, sunset.hour):
					cloudImage[h].texture = cloudLevel[1]
				else:
					cloudImage[h].texture = cloudLevelNight[1]
			elif openMeteoJSON["hourly"]["cloud_cover"][i] > 50 and openMeteoJSON["hourly"]["cloud_cover"][i] <= 75:
				if isHourInDaylight(h, sunrise.hour, sunset.hour):
					cloudImage[h].texture = cloudLevel[2]
				else:
					cloudImage[h].texture = cloudLevelNight[2]
			elif openMeteoJSON["hourly"]["cloud_cover"][i] > 75 and openMeteoJSON["hourly"]["cloud_cover"][i] <= 100:
				if isHourInDaylight(h, sunrise.hour, sunset.hour):
					cloudImage[h].texture = cloudLevel[3]
				else:
					cloudImage[h].texture = cloudLevelNight[3]
			
			#Rain and Snow
			precText[h].text = str(roundi(openMeteoJSON["hourly"]["precipitation_probability"][i])) + "%"
			if h == 0:
				print("day: " + str(day))

			#Rain
			if openMeteoJSON["hourly"]["precipitation_probability"][i] > 15:
				if weatherCodeText.containsn("rain"):
					rainImage[h].texture = rainLevel[3]
				elif weatherCodeText.containsn("drizzle"):
					rainImage[h].texture = rainLevelMedium[3]
				else:
					rainImage[h].texture = rainLevelSmall[3]
			else:
				rainImage[h].texture = rainLevel[0]
			
			#Snow
			if openMeteoJSON["hourly"]["snowfall"][i] > 0 or (weatherCodeText.containsn("snow") or weatherCodeText.contains("hail") or weatherCodeText.containsn("ice ") or weatherCodeText.containsn("sleet")):
				if (openMeteoJSON["hourly"]["snowfall"][i] > 0 and openMeteoJSON["hourly"]["snowfall"][i] <= 0.15) or weatherCodeText.containsn("sleet") or weatherCodeText.containsn("slight"):
					#print("1: " + str(i) + str(openMeteoJSON["hourly"]["snowfall"]))
					rainImage[h].texture = snowLevel[1]
				elif openMeteoJSON["hourly"]["snowfall"][i] > 0.3 or weatherCodeText.containsn("heavy"):
					#print("3: " + str(i) + str(openMeteoJSON["hourly"]["snowfall"]))
					rainImage[h].texture = snowLevel[3]
				elif openMeteoJSON["hourly"]["snowfall"][i] > 0.15 and openMeteoJSON["hourly"]["snowfall"][i] <= 0.3:
					#print("2: " + str(i) + str(openMeteoJSON["hourly"]["snowfall"]))
					rainImage[h].texture = snowLevel[2]
			
			#Lightning
			if weatherCodeText.containsn("thunder") or weatherCodeText.containsn("lightning"):
				lightning[h].show()
			else:
				lightning[h].hide()
			
			populateInitialWindDirection()
			var amp = clampi(roundi(openMeteoJSON["hourly"]["wind_speed_10m"][i]) * 2, 0, 40)
			if saveData.windUnit == "": #kmh
				amp = clampi(roundi(openMeteoJSON["hourly"]["wind_speed_10m"][i]) * 2 * 0.62, 0, 40)
			elif saveData.windUnit == "ms":
				amp = clampi(roundi(openMeteoJSON["hourly"]["wind_speed_10m"][i]) * 2 * 2.24, 0, 40)
			elif saveData.windUnit == "kn":
				amp = clampi(roundi(openMeteoJSON["hourly"]["wind_speed_10m"][i]) * 2 * 1.15, 0, 40)
			
			if !saveData.windAnim:
				amp = 0;
			
			windText[h].text = "[font_size=40]" + "[wave amp=" + str(amp) + " freq=5.0 connected=1]" + str(roundi(openMeteoJSON["hourly"]["wind_speed_10m"][i])) + "\n" + "[font_size=32]" + str(roundi(openMeteoJSON["hourly"]["wind_gusts_10m"][i])) + "[/font_size][/wave]"
			weatherText[h].text = weatherCodeText
			
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
	dayTempText[position].text = str(roundi(openMeteoJSON["daily"]["temperature_2m_min"][day])) + "° to "+ str(roundi(openMeteoJSON["daily"]["temperature_2m_max"][day])) + "°"
	dayAppTempText[position].text = "feels " + str(roundi(openMeteoJSON["daily"]["apparent_temperature_min"][day])) + "° to "+ str(roundi(openMeteoJSON["daily"]["apparent_temperature_max"][day])) + "°"
	var windUnit = "mph"
	if saveData.windUnit == "":
		windUnit = "kmh"
	elif saveData.windUnit == "ms":
		windUnit = "ms"
	elif saveData.windUnit == "kn":
		windUnit = "kn"
	
	dayWindText[position].text = getWindDirection(roundi(openMeteoJSON["daily"]["wind_direction_10m_dominant"][day])) + " wind\n" + str(roundi(openMeteoJSON["daily"]["wind_speed_10m_max"][day])) + " " + windUnit + "\n" + str(roundi(openMeteoJSON["daily"]["wind_gusts_10m_max"][day])) + " " + windUnit + " gusts"

	var sunrise = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunrise"][day]) + ":00", false)
	var sunset = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunset"][day]) + ":00", false)
	daySunText[position].text = "Sun " +  str("%02d" % sunrise.hour) + ":" + str("%02d" % sunrise.minute) + "\nto " + str("%02d" % sunset.hour) + ":" + str("%02d" % sunset.minute)
	
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
	
func getWindDirection(dir):
	if dir >= 337.5 and dir < 22.5:
		return "North"
	elif dir >= 22.5 and dir < 67.5:
		return "Northeast"
	elif dir >= 67.5 and dir < 112.5:
		return "East"
	elif dir >= 112.5 and dir < 157.5:
		return "Southeast"
	elif dir >= 157.5 and dir < 292.5:
		return "South"
	elif dir >= 202.5 and dir < 247.5:
		return "Southwest"
	elif dir >= 247.5 and dir < 292.5:
		return "West"
	elif dir >= 292.5 and dir < 337.5:
		return "Northwest"
	
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
		9.0: return "Dust storm"
		10.0: return "Mist"
		11.0: return "Shallow fog"
		12.0: return "Shallow fog"
		13.0: return "Lightning"
		14.0: return "Precipitation nearby"
		15.0: return "Precipitation nearby"
		16.0: return "Precipitation nearby"
		17.0: return "Thunder storm"
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
		29.0: return "Thunder storm"
		30.0: return "Slight dust storm"
		31.0: return "Slight dust storm"
		32.0: return "Slight dust storm"
		33.0: return "Severe dust storm"
		34.0: return "Severe dust storm"
		35.0: return "Severe dust storm"
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
		95.0: return "Thunder storm"
		96.0: return "Thunder storm and hail"
		97.0: return "Heavy thunder storm"
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

func updateLocation(placeName: String, adminName: String, lat: float, long: float):
	saveData.save_game(placeName + " (" + adminName + ")", lat, long, saveData.tempUnit, saveData.windUnit, saveData.windAnim, saveData.tempColours, saveData.mapConnect)	
	get_node_or_null(locationText).text = saveData.placeName
	TryWeatherRequest()

func _on_today_button_pressed() -> void:
	today()

func today():
	todayUnix = Time.get_unix_time_from_system()
	startDay = 7
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	populateForecastTable()
	daySummarySetup()
	getLunarPhase()
	clockRotation()

func _on_previous_day_button_pressed() -> void:
	previousDay()

func previousDay():
	print("previous day")
	startDay -= 1
	if startDay < 0:
		startDay = 0
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	get_node_or_null(clock).updateRotationData()
	populateForecastTable()
	daySummarySetup()
	getLunarPhase()

func on_next_day_button_pressed() -> void:
	nextDay()

func nextDay():
	print("next day")
	startDay += 1
	if startDay > 20:
		startDay = 20
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	get_node_or_null(clock).updateRotationData()
	populateForecastTable()
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

func updateClockLabels(previous, next):
	var selectedDatePrevious = Time.get_datetime_dict_from_unix_time(todayUnix + (86400 * (previous - 7)))
	var selectedDateNext = Time.get_datetime_dict_from_unix_time(todayUnix + (86400 * (next - 7)))
	var dateShortPrevious = getWeekdayString(selectedDatePrevious.weekday).erase(3,100) + "\n " + str(selectedDatePrevious.day) + " " + getMonthString(selectedDatePrevious.month).erase(3,100)
	var dateShortNext = getWeekdayString(selectedDateNext.weekday).erase(3,100) + "\n " + str(selectedDateNext.day) + " " + getMonthString(selectedDateNext.month).erase(3,100)
	
	get_node_or_null(clockPreviousDay).text = dateShortPrevious
	get_node_or_null(clockNextDay).text = dateShortNext

	if previous < 0:
		get_node_or_null(clockPreviousDay).hide()
	else:
		get_node_or_null(clockPreviousDay).show()
	
	if next >20:
		get_node_or_null(clockNextDay).hide()
	else:
		get_node_or_null(clockNextDay).show()

func sundial(sunrise, sunset):
	get_node_or_null(clockNight).material.set_shader_parameter("cooldown_progress", sunrise)
	get_node_or_null(clockNight).material.set_shader_parameter("cooldown_offset", sunset)

func isHourInDaylight(hour, sunriseHour, sunsetHour):
	if hour > sunriseHour and hour <= sunsetHour:
		return true
	else:
		return false

func getTemperatureColor(temp):
	#Colours from https://www.bbc.co.uk/weather/features/66293839
	
	if temp <= -22:
		return 0
	elif temp > -22 and temp <= -16:
		return 1
	elif temp > -16 and temp <= -11:
		return 2
	elif temp > -11 and temp <= -6:
		return 3
	elif temp > -6 and temp <= -3:
		return 4
	elif temp > -3 and temp <= 0:
		return 5
	elif temp > 0 and temp <= 2:
		return 6
	elif temp > 2 and temp <= 4:
		return 7
	elif temp > 4 and temp <= 6:
		return 8
	elif temp > 6 and temp <= 8:
		return 9
	elif temp > 8 and temp <= 10:
		return 10
	elif temp > 10 and temp <= 12:
		return 11
	elif temp > 12 and temp <= 14:
		return 12
	elif temp > 14 and temp <= 16:
		return 13
	elif temp > 16 and temp <= 18:
		return 14
	elif temp > 18 and temp <= 20:
		return 15
	elif temp > 20 and temp <= 24:
		return 16
	elif temp > 24 and temp <= 29:
		return 17
	elif temp > 29 and temp <= 35:
		return 18
	elif temp > 35 and temp <= 40:
		return 19
	elif temp > 40:
		return 20
	
# TO-DO
# You have to wait for a request to finish before sending another one. Making multiple request at once requires you to have one node per request. A common strategy is to create and delete HTTPRequest nodes at runtime as necessary.
# Need more feedback if HTTP request unsuccesful, e.g. prompt to connect to internet


func _on_location_text_pressed() -> void:
	#https://www.cartograph.eu/v3/using-the-geo-uri-scheme-in-cartograph-maps/
	#https://forum.godotengine.org/t/android-how-to-open-a-web-browser-at-a-specific-address/137838/8
	if saveData.mapConnect:
		OS.shell_open("geo:" + str(saveData.latitude) + "," + str(saveData.longitude) + "?z=12")

func _on_credits_button_pressed() -> void:
	creditsPanel.show()

func _on_back_button_pressed() -> void:
	creditsPanel.hide()

func _on_settings_button_pressed() -> void:
	settingsPanel.show()

func _on_back_settings_button_pressed() -> void:
	settingsPanel.hide()

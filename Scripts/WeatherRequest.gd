class_name WeatherRequest

# Weather warnings may be available through https://metoffice.github.io/nswws-public-api/

extends HTTPRequest
@export_node_path("Node") var control
@export_node_path("Label") var debug
@export_node_path("LineEdit") var locationInput
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
@export var weatherWarningIcon : Node
@export var weatherWarningText : Label
@export var hour12: Array[Node] = []
@export var hour24: Array[Node] = []
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
@export var daySummaryIcons: Array[Texture] = []
@export var creditsPanel: Node
@export var settingsPanel: Node
@export var locationPanel: Node
@export var weatherWarningPanel: Node
@export var weatherWarningDetailPanel : Node
@export var saveLocationButton: Button
@export var removeLocationButton: Button
@export var maxFavourites : Node
@export_node_path("AnimationPlayer") var anim
@export var daySummaryWeatherCodeIcons: Array[TextureRect]
@export var daySummaryWindRotations: Array[Node]
@export var daySummaryWindTexts: Array[RichTextLabel]
@export var daySummaryTempTexts: Array[RichTextLabel]
@export var daySummaryTempColourBorders: Array[TextureRect]
@export var daySummaryTextNodes: Array[Node]
@export var daySummaryIconNodes: Array[Node]
@export var xmlRequest : Warnings_XML_Request
var saveData
var startDay: int = 7
var openMeteoJSON
var todayUnix: float
var selectedDateUnix: float
var tableLabelScene
var gridChildren: Array[Node]
var requestProcessing = false
var waitForRequest = false
var updatingTempUnit = false
var tzLocal = 0
var tzOffset = 0
var previousDayHourlyWMO: Array[int]
var currentDayHourlyWMO: Array[int]
var nextDayHourlyWMO: Array[int]
var ukLocation : bool = true

func _ready():
	saveData = get_node_or_null(saveDataPath)
	saveData.load_game()
	get_node_or_null(locationText).text = saveData.placeName
	updateSummaryIcons()
	updateClock24()
	
	previousDayHourlyWMO.resize(24)
	currentDayHourlyWMO.resize(24)
	nextDayHourlyWMO.resize((24))
	
	tableLabelScene = preload("res://Scenes/label_table_entry.tscn")
	todayUnix = Time.get_unix_time_from_system()
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	request_completed.connect(_on_request_completed)
	get_node_or_null(locationInput).editable = true
	TryWeatherRequest()

func _process(delta: float) -> void:
	if get_node_or_null(clock).requestReady:
		populateForecastTable()
	
	if waitForRequest:
		if !requestProcessing:
			waitForRequest = false
			weatherRequest()

func TryWeatherRequest():
	if !requestProcessing: # We don't want to start another request until the previous one has finished
		weatherRequest()
	else:
		waitForRequest = true

func weatherRequest():
	get_node_or_null(clock).requestReady = false
	
	# Perform a GET request. The URL below returns JSON as of writing.
	get_node_or_null(locationInput).editable = false # Set location search disabled until http request finished
	
	if saveData.placeName.contains("(England)") or saveData.placeName.contains("(Scotland)") or saveData.placeName.contains("(Wales)") or saveData.placeName.contains("(Northern Ireland)"):
		ukLocation = true
		weatherWarningText.text = "Checking for weather warnings..."
	else:
		ukLocation = false
		weatherWarningText.text = ""
		
	# Get temperature and wind units from save data
	var temp = ""
	if saveData.tempUnit != "":
		temp = "&temperature_unit=" + saveData.tempUnit
	var wind = ""
	if saveData.windUnit != "":
		wind = "&wind_speed_unit=" + saveData.windUnit
	
	requestProcessing = true
	
	# HTTP request
	var error = request("https://api.open-meteo.com/v1/forecast?latitude=" + str(saveData.latitude) + "&longitude=" + str(saveData.longitude) + "&daily=moon_phase,weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant&hourly=temperature_2m,precipitation_probability,rain,snowfall,wind_speed_10m,apparent_temperature,weather_code,cloud_cover,wind_gusts_10m,wind_direction_10m&timezone=auto&past_days=7&forecast_days=14" + wind + temp)
	if error != OK:
		get_node_or_null(dateText).text = "HTTP request error. Check internet connection"

func _on_request_completed(result, response_code, headers, body):
	requestProcessing = false
	get_node_or_null(locationInput).editable = true
	
	if result != HTTPRequest.RESULT_SUCCESS:
		get_node_or_null(dateText).text = "Could not retrieve data, please restart app"
		return
		#TryWeatherRequest() #This might make a loop and crash if it's just not working...
	
	openMeteoJSON = JSON.parse_string(body.get_string_from_utf8())
	
	if openMeteoJSON.has("error") and openMeteoJSON["error"] == true:
		get_node_or_null(dateText).text = "Could not retrieve data, please try again"
		return
	else:
		get_node_or_null(clock).requestReady = true

	
	if openMeteoJSON != null and openMeteoJSON.has("timezone_abbreviation"):
		# Get the timezone offset in a usable format... there's probably a simpler way to do this!
		var tz = openMeteoJSON["timezone_abbreviation"]
		tzLocal = "0"
		var tzH = "0"
		var tzM = "0"
		if tz.contains("+"):
			tzLocal = tz.substr(4, -1)
			if tzLocal.contains(":"):
				tzH = tzLocal.substr(0,tzLocal.find(':'))
				tzM = tzLocal.substr(tzLocal.find(':') + 1, -1)
			else:
				tzH = tzLocal
		if tz.contains("-"):
			tzLocal = "-" + tz.substr(4, -1)
			if tzLocal.contains(":"):
				tzH = tzLocal.substr(0,tzLocal.find(':'))
				tzM = "-" + tzLocal.substr(tzLocal.find(':') + 1, -1)
			else:
				tzH = tzLocal
		
		tzLocal = int(float(tzH) * 60) + int(tzM)
		tzOffset = tzLocal - Time.get_time_zone_from_system().bias
		
		# Convert to UNIX format
		todayUnix = Time.get_unix_time_from_system() + (60 * tzLocal)
		selectedDateUnix = todayUnix + (86400 * (startDay - 7))
		
		updatingTempUnit = false
		clockRotation()
		populateForecastTable()
		populateInitialWindDirection()
		daySummarySetup()
		getLunarPhase()
		if ukLocation:
			xmlRequest.StartWarningRequest()

func populateForecastTable():
	var selectedDate = Time.get_datetime_dict_from_unix_time(selectedDateUnix) # 86400 is 1 day in unix time
	var date = getWeekdayString(selectedDate.weekday) + " " + str(selectedDate.day) + " " + getMonthString(selectedDate.month) + " " + str(selectedDate.year)
	get_node_or_null(dateText).text = date

	for h in range(0,24): # Each hour in 24 hours
		var day = get_node_or_null(clock).clockHourDates[h]
		var i = (day * 24) + h # Index in JSON hourly data across 21 forecast days

		if day < 0 or day > 20 or i > 504: # If we are at either extreme end of forecast. 504 = 21 days * 24 hours
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
			
			# TEMPERATURE
			if !updatingTempUnit:
				var temperature_color = tempColours[getTemperatureColor(roundi(openMeteoJSON["hourly"]["temperature_2m"][i]))]
				if saveData.tempUnit == "fahrenheit":
					var f = (openMeteoJSON["hourly"]["temperature_2m"][i] - 32) * (5.0/9.0) #conversion from fahrenheit to celsius
					temperature_color = tempColours[getTemperatureColor(roundi(f))]
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
			
			# SUNRISE AND SUNSET
			var sunrise = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunrise"][day]) + ":00", false)
			var sunset = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunset"][day]) + ":00", false)
	
			# CLOUD COVER
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
			
			# PRECIPITATION
			var weatherCodeText = getWMOCode(openMeteoJSON["hourly"]["weather_code"][i])
			if openMeteoJSON["hourly"]["precipitation_probability"][i] != null:
				precText[h].text = str(roundi(openMeteoJSON["hourly"]["precipitation_probability"][i])) + "%"
			else: 
				precText[h].text = "no data"
			# Rain
			if openMeteoJSON["hourly"]["precipitation_probability"][i] != null and openMeteoJSON["hourly"]["precipitation_probability"][i] > 15:
				if weatherCodeText.containsn("rain"):
					rainImage[h].texture = rainLevel[3]
				elif weatherCodeText.containsn("drizzle"):
					rainImage[h].texture = rainLevelMedium[3]
				else:
					rainImage[h].texture = rainLevelSmall[3]
			else:
				rainImage[h].texture = rainLevel[0]
			
			# Snow
			if openMeteoJSON["hourly"]["snowfall"][i] > 0 or (weatherCodeText.containsn("snow") or weatherCodeText.contains("hail") or weatherCodeText.containsn("ice ") or weatherCodeText.containsn("sleet")):
				if (openMeteoJSON["hourly"]["snowfall"][i] > 0 and openMeteoJSON["hourly"]["snowfall"][i] <= 0.15) or weatherCodeText.containsn("sleet") or weatherCodeText.containsn("slight"):
					rainImage[h].texture = snowLevel[1]
				elif openMeteoJSON["hourly"]["snowfall"][i] > 0.3 or weatherCodeText.containsn("heavy"):
					rainImage[h].texture = snowLevel[3]
				elif openMeteoJSON["hourly"]["snowfall"][i] > 0.15 and openMeteoJSON["hourly"]["snowfall"][i] <= 0.3:
					rainImage[h].texture = snowLevel[2]
			
			# Lightning
			if weatherCodeText.containsn("thunder") or weatherCodeText.containsn("lightning"):
				lightning[h].show()
			else:
				lightning[h].hide()
			
			# WIND
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

func populateInitialWindDirection(): # this is separate so that it only happens once and not every frame
	for h in range(0,24):
		var day = get_node_or_null(clock).clockHourDates[h]
		var i = (day * 24) + h
		if !(day < 0 or day > 20):
			windRotation[h].SetInitialRotation(wrapf(openMeteoJSON["hourly"]["wind_direction_10m"][i] + 180.0, 0.0, 360.0), windRotation[h].get_parent().get_rotation_degrees() ,get_node_or_null(clock).get_rotation_degrees())

func daySummarySetup():
	if startDay > 0:
		for h in range(0,24):
			previousDayHourlyWMO[h] = int(openMeteoJSON["hourly"]["weather_code"][((startDay - 1) * 24) + h])
		get_node_or_null(previousDayPanel).show()
		populateDaySummary(openMeteoJSON, startDay - 1, 0)
	else:
		get_node_or_null(previousDayPanel).hide()
	
	for h in range(0,24):
		currentDayHourlyWMO[h] = int(openMeteoJSON["hourly"]["weather_code"][(startDay * 24) + h])
	populateDaySummary(openMeteoJSON, startDay, 1)
	
	if startDay < 20:
		for h in range(0,24):
			nextDayHourlyWMO[h] = int(openMeteoJSON["hourly"]["weather_code"][((startDay + 1) * 24) + h])
		get_node_or_null(nextDayPanel).show()
		populateDaySummary(openMeteoJSON, startDay + 1, 2)
	else:
		get_node_or_null(nextDayPanel).hide()

func populateDaySummary(openMeteoJSON, day, position):
	var d = 0
	if position == 0: # Previous day's summary
		d = -86400
	elif position == 2: # Next day's summary
		d = 86400
		
	var selectedDate = Time.get_datetime_dict_from_unix_time(selectedDateUnix + d) # 86400 is 1 day in unix time
	var date2 = getWeekdayString(selectedDate.weekday).erase(3,100) + " " + str(selectedDate.day) + " " + getMonthString(selectedDate.month).erase(3,100)
	
	# Weather code icon
	updateDailyWMO(dayWMOText[position], daySummaryWeatherCodeIcons[position], day, position)
	
	# Update date and temperature
	dayDateText[position].text = date2
	#dayTempText[position].text = str(roundi(openMeteoJSON["daily"]["temperature_2m_min"][day])) + "° to "+ str(roundi(openMeteoJSON["daily"]["temperature_2m_max"][day])) + "°"
	#dayAppTempText[position].text = "feels " + str(roundi(openMeteoJSON["daily"]["apparent_temperature_min"][day])) + "° to "+ str(roundi(openMeteoJSON["daily"]["apparent_temperature_max"][day])) + "°"
	
	dayTempText[position].text = str(roundi(openMeteoJSON["daily"]["temperature_2m_max"][day])) + "° (feels " + str(roundi(openMeteoJSON["daily"]["apparent_temperature_max"][day])) + "°)"
	
	# Temperature
	daySummaryTempTexts[position].text = "[font_size=44]" + str(roundi(openMeteoJSON["daily"]["temperature_2m_max"][day])) + "°\n[font_size=36]"+ str(roundi(openMeteoJSON["daily"]["apparent_temperature_max"][day])) + "°[/font_size]"
	
	if !updatingTempUnit:
		var temperature_color = tempColours[getTemperatureColor(roundi(openMeteoJSON["daily"]["temperature_2m_max"][day]))]
		if saveData.tempUnit == "fahrenheit":
			var f = (openMeteoJSON["daily"]["temperature_2m_max"][day] - 32) * (5.0/9.0) #conversion from fahrenheit to celsius
			temperature_color = tempColours[getTemperatureColor(roundi(f))]
		if saveData.tempColours:
			daySummaryTempTexts[position].get_parent().material = daySummaryTempTexts[position].get_parent().material.duplicate()
			daySummaryTempTexts[position].get_parent().material.set_shader_parameter('colour', temperature_color)
			daySummaryTempColourBorders[position].hide()
		else:
			daySummaryTempTexts[position].get_parent().material = daySummaryTempTexts[position].get_parent().material.duplicate()
			daySummaryTempTexts[position].get_parent().material.set_shader_parameter('colour', Color.WHITE)
			daySummaryTempColourBorders[position].show()
			daySummaryTempColourBorders[position].material = daySummaryTempTexts[position].get_parent().material.duplicate()
			daySummaryTempColourBorders[position].material.set_shader_parameter('colour', temperature_color)
	
	# Get saved wind unit
	var windUnit = "mph"
	if saveData.windUnit == "":
		windUnit = "kmh"
	elif saveData.windUnit == "ms":
		windUnit = "ms"
	elif saveData.windUnit == "kn":
		windUnit = "kn"
	
	# Update wind summary
	if openMeteoJSON["daily"]["wind_speed_10m_max"][day]:
		dayWindText[position].text = str(getWindDirection(roundi(openMeteoJSON["daily"]["wind_direction_10m_dominant"][day]))) + " wind\n" + str(roundi(openMeteoJSON["daily"]["wind_speed_10m_max"][day])) + " " + windUnit + "\n" + str(roundi(openMeteoJSON["daily"]["wind_gusts_10m_max"][day])) + " " + windUnit + " gusts"
	
	daySummaryWindRotations[position].SetInitialRotation(wrapf(openMeteoJSON["daily"]["wind_direction_10m_dominant"][day] + 180.0, 0.0, 360.0), daySummaryWindRotations[position].get_parent().get_rotation_degrees() ,get_node_or_null(clock).get_rotation_degrees())
	
	var amp = clampi(roundi(openMeteoJSON["daily"]["wind_speed_10m_max"][day]) * 2, 0, 40)
	if saveData.windUnit == "": #kmh
		amp = clampi(roundi(openMeteoJSON["daily"]["wind_speed_10m_max"][day]) * 2 * 0.62, 0, 40)
	elif saveData.windUnit == "ms":
		amp = clampi(roundi(openMeteoJSON["daily"]["wind_speed_10m_max"][day]) * 2 * 2.24, 0, 40)
	elif saveData.windUnit == "kn":
		amp = clampi(roundi(openMeteoJSON["daily"]["wind_speed_10m_max"][day]) * 2 * 1.15, 0, 40)
	
	if !saveData.windAnim:
		amp = 0;
	
	daySummaryWindTexts[position].text = "[font_size=40]" + "[wave amp=" + str(amp) + " freq=5.0 connected=1]" + str(roundi(openMeteoJSON["daily"]["wind_speed_10m_max"][day])) + "\n" + "[font_size=32]" + str(roundi(openMeteoJSON["daily"]["wind_gusts_10m_max"][day])) + "[/font_size][/wave]"
	
	# Update sunrise / sunset summary
	var sunrise = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunrise"][day]) + ":00", false)
	var sunset = Time.get_datetime_dict_from_datetime_string(str(openMeteoJSON["daily"]["sunset"][day]) + ":00", false)
	daySunText[position].text = "Daylight " +  str("%02d" % sunrise.hour) + ":" + str("%02d" % sunrise.minute) + "\nto " + str("%02d" % sunset.hour) + ":" + str("%02d" % sunset.minute)
	
	# Use sunrise / sunset to update day / night visual on the clock dial
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
	
func getWindDirection(dir):
	if dir >= 337.5 and dir < 22.5:
		return "North"
	elif dir >= 22.5 and dir < 67.5:
		return "Northeast"
	elif dir >= 67.5 and dir < 112.5:
		return "East"
	elif dir >= 112.5 and dir < 157.5:
		return "Southeast"
	elif dir >= 157.5 and dir < 202.5:
		return "South"
	elif dir >= 202.5 and dir < 247.5:
		return "Southwest"
	elif dir >= 247.5 and dir < 292.5:
		return "West"
	elif dir >= 292.5 and dir < 337.5:
		return "Northwest"
	else:
		return ""
	
func getWMOCode(wmo):
	# Modified from OpenMeteo
	match wmo:
		0.0: return "Clear sky"
		1.0: return "Mainly clear"
		2.0: return "Partly cloudy"
		3.0: return "Overcast"
		45.0: return "Fog"
		48.0: return "Depositing rime fog"
		51.0: return "Light drizzle"
		53.0: return "Moderate drizzle"
		55.0: return "Dense drizzle"
		56.0: return "Light freezing drizzle"
		57.0: return "Dense freezing drizzle"
		61.0: return "Slight rain"
		63.0: return "Moderate rain"
		65.0: return "Heavy rain"
		66.0: return "Light freezing rain"
		67.0: return "Heavy freezing rain"
		71.0: return "Slight snowfall"
		73.0: return "Moderate snowfall"
		75.0: return "Heavy snowfall"
		77.0: return "Snow grains"
		80.0: return "Slight rain showers"
		81.0: return "Moderate rain showers"
		82.0: return "Violent rain showers"
		85.0: return "Slight snow showers"
		86.0: return "Heavy snow showers"
		95.0: return "Thunder storm"
		96.0: return "Thunder storm and hail"
		97.0: return "Heavy thunder storm"
		99.0: return "Heavy thunder and hail"
		_: return "Unknown"

func getWMOIcon(wmo):
	match wmo:
		0.0: return daySummaryIcons[0]
		1.0: return daySummaryIcons[1]
		2.0: return daySummaryIcons[2]
		3.0: return daySummaryIcons[3]
		45.0: return daySummaryIcons[4]
		48.0: return daySummaryIcons[5]
		51.0: return daySummaryIcons[6]
		53.0: return daySummaryIcons[7]
		55.0: return daySummaryIcons[8]
		56.0: return daySummaryIcons[9]
		57.0: return daySummaryIcons[10]
		61.0: return daySummaryIcons[11]
		63.0: return daySummaryIcons[12]
		65.0: return daySummaryIcons[13]
		66.0: return daySummaryIcons[14]
		67.0: return daySummaryIcons[15]
		71.0: return daySummaryIcons[16]
		73.0: return daySummaryIcons[17]
		75.0: return daySummaryIcons[18]
		77.0: return daySummaryIcons[19]
		80.0: return daySummaryIcons[20]
		81.0: return daySummaryIcons[21]
		82.0: return daySummaryIcons[22]
		85.0: return daySummaryIcons[23]
		86.0: return daySummaryIcons[24]
		95.0: return daySummaryIcons[25]
		96.0: return daySummaryIcons[26]
		97.0: return daySummaryIcons[27]
		99.0: return daySummaryIcons[28]
		_: return "Unknown"

func updateDailyWMO(wmoText : Label, wmoTexture : TextureRect, day, position):
	#print("updateDailyWMO at " + str(position) + ", " + wmoText.name)
	var wmoArray
	
	if position == 0:
		wmoArray = previousDayHourlyWMO
	elif position == 1:
		wmoArray = currentDayHourlyWMO
	elif position == 2:
		wmoArray = nextDayHourlyWMO
		
	#for w in wmoArray.size():
	#	print(wmoArray[w])
	
	var text = ""
	var texture = 0
	
	# THUNDER / HAIL
	if wmoArray.has(96) or wmoArray.has(99): # 96 = "Thunder storm and hail", 99 = "Heavy thunder and hail"
		#If rest of day mostly sunny
		if wmoArray.count(0) + wmoArray.count(1) > 6: # 0 = "Clear sky", 1 = "Mainly clear"
			if wmoArray.has(99):
				text = "Thunder and heavy hail showers"
				texture = 0 #"WMOIcon_Thunder_HailHeavy_Sunny.png"
			elif wmoArray.has(96):
				text = "Thunder and hail showers"
				texture = 1 #"WMOIcon_Thunder_Hail_Sunny.png"
		#If rest of day mostly cloudy
		elif wmoArray.count(2)+ wmoArray.count(3) > 6: # 2 = "Partly cloudy", 3 = "Overcast"
			if wmoArray.has(99):
				text = "Cloudy with thunder and heavy hail"
				texture = 2 #"WMOIcon_Thunder_HailHeavy_Cloudy.png"
			elif wmoArray.has(96):
				text = "Cloudy with thunder and hail"
				texture = 3 #"WMOIcon_Thunder_Hail_Cloudy.png"
		else:
			if wmoArray.has(99):
				text = "Thunder and heavy hail"
				texture = 4 #"WMOIcon_Thunder_HailHeavy.png"
			elif wmoArray.has(96):
				text = "Thunder and hail"
				texture = 5 #"WMOIcon_Thunder_Hail.png"
	# THUNDER / RAIN
	elif wmoArray.has(95) or wmoArray.has(97): # 95 = "Thunder storm", 97 = "Heavy thunder storm"
		#If rest of day mostly sunny
		if wmoArray.count(0) + wmoArray.count(1) > 6: # 0 = "Clear sky", 1 = "Mainly clear"
			if wmoArray.has(97):
				text = "Thunder and heavy rain showers"
				texture = 6 #"WMOIcon_Thunder_RainHeavy_Sunny.png"
			elif wmoArray.has(95):
				text = "Thunder and rain showers"
				texture = 7 #"WMOIcon_Thunder_Rain_Sunny.png"
		#If rest of day mostly cloudy
		elif wmoArray.count(2)+ wmoArray.count(3) > 6: # 2 = "Partly cloudy", 3 = "Overcast"
			if wmoArray.has(97):
				text = "Cloudy with thunder and heavy rain"
				texture = 8 #"WMOIcon_Thunder_RainHeavy_Cloudy.png"
			elif wmoArray.has(95):
				text = "Cloudy with thunder and rain"
				texture = 9 #"WMOIcon_Thunder_Rain_Cloudy.png"
		else:
			if wmoArray.has(97):
				text = "Thunder and heavy rain"
				texture = 10 #"WMOIcon_Thunder_RainHeavy.png"
			elif wmoArray.has(95):
				text = "Thunder and rain"
				texture = 11 #"WMOIcon_Thunder_Rain.png"
	# SNOW
	elif wmoArray.has(56) or wmoArray.has(57) or wmoArray.has(66) or wmoArray.has(67) or wmoArray.has(71) or wmoArray.has(73) or wmoArray.has(75) or wmoArray.has(77) or wmoArray.has(85) or wmoArray.has(86):
	# 56 = "Light freezing drizzle", 57 = "Dense freezing drizzle", 
	# 66 = "Light freezing rain", 67 = "Heavy freezing rain", 
	# 71 = "Slight snowfall", 73 = "Moderate snowfall", 75 = "Heavy snowfall", 77 = "Snow grains"
	# 85 = "Slight snow showers", 86 = "Heavy snow showers"
		#If rest of day mostly sunny
		if wmoArray.count(0) + wmoArray.count(1) > 6: # 0 = "Clear sky", 1 = "Mainly clear"
			if wmoArray.has(73) or wmoArray.has(75) or wmoArray.has(86):
				text = "Heavy snow showers"
				texture = 12 #"WMOIcon_SnowHeavy_Showers.png"
			elif wmoArray.has(71) or wmoArray.has(77) or wmoArray.has(85):
				text = "Snow showers"
				texture = 13 #"WMOIcon_Snow_Showers.png"
		#If rest of day mostly rainy
		elif wmoArray.count(51) + wmoArray.count(53) + wmoArray.count(55) + wmoArray.count(56) + wmoArray.count(57) + wmoArray.count(61) + wmoArray.count(63) + wmoArray.count(65) + wmoArray.count(66) + wmoArray.count(67) + wmoArray.count(80) + wmoArray.count(81) + wmoArray.count(82) > 6:
			if wmoArray.has(63) or wmoArray.has(65) or wmoArray.has(67) or wmoArray.has(81) or wmoArray.has(82):
				text = "Heavy snow and rain"
				texture = 14 #"WMOIcon_SnowHeavy_Rain.png"
			elif wmoArray.has(51) or wmoArray.has(53) or wmoArray.has(55) or wmoArray.has(56) or wmoArray.has(57) or wmoArray.has(61) or wmoArray.has(66) or wmoArray.has(80):
				text = "Snow and rain"
				texture = 15 #"WMOIcon_Snow_Rain.png"
		else:
			if wmoArray.has(86) or wmoArray.has(75):
				text = "Heavy snow"
				texture = 16 #"WMOIcon_SnowHeavy.png"
			elif wmoArray.has(73):
				text = "Moderate snow"
				texture = 17 #"WMOIcon_SnowModerate.png"
			elif wmoArray.has(71) or wmoArray.has(77) or wmoArray.has(85):
				text = "Snow"
				texture = 18 #"WMOIcon_Snow.png"
			elif wmoArray.has(57) or wmoArray.has(67):
				text = "Heavy snow and rain"
				texture = 14 #"WMOIcon_SnowHeavy_Rain.png"
			elif wmoArray.has(56) or wmoArray.has(66):
				text = "Snow and rain"
				texture = 15 #"WMOIcon_Snow_Rain.png"
	# RAIN
	elif wmoArray.count(51) + wmoArray.count(53) + wmoArray.count(55) + wmoArray.count(61) + wmoArray.count(63) + wmoArray.count(65) + wmoArray.count(80) + wmoArray.count(81) + wmoArray.count(82) > 1:
	# 51 = "Light drizzle", 53 = "Moderate drizzle", 55 = "Dense drizzle", 
	# 61 = "Slight rain", 63 = "Moderate rain", 65 = "Heavy rain", 
	# 80 = "Slight rain showers", 81 = "Moderate rain showers", 82 = "Violent rain showers"
		# If rest of day is mostly sunny
		if wmoArray.count(0) + wmoArray.count(1) > 6: # 0 = "Clear sky", 1 = "Mainly clear"
			if wmoArray.has(55) or wmoArray.has(65) or wmoArray.has(82):
				text = "Heavy rain showers"
				texture = 19 #"WMOIcon_RainHeavy_Showers.png"
			elif wmoArray.has(53) or wmoArray.has(63) or wmoArray.has(81):
				text = "Moderate rain showers"
				texture = 20 #"WMOIcon_RainModerate_Showers.png"
			elif wmoArray.has(51) or wmoArray.has(61) or wmoArray.has(80):
				text = "Slight rain showers"
				texture = 21 #"WMOIcon_RainSlight_Showers.png"
		# Mostly rainy
		else:
			if wmoArray.has(55) or wmoArray.has(65) or wmoArray.has(82):
				text = "Heavy rain"
				texture = 22 #"WMOIcon_RainHeavy.png"
			elif wmoArray.has(53) or wmoArray.has(63) or wmoArray.has(81):
				text = "Moderate rain"
				texture = 23 #"WMOIcon_RainModerate.png"
			elif wmoArray.has(51) or wmoArray.has(61) or wmoArray.has(80):
				text = "Slight rain"
				texture = 24 #"WMOIcon_RainSlight.png"
	# CLOUD
	elif wmoArray.count(2) + wmoArray.count(3) + wmoArray.count(45) + wmoArray.count(48) > 6:
	# 2 = "Partly cloudy", 3 = "Overcast", 45 = "Fog", 48 = "Depositing rime fog"
	# If rest of day is mostly sunny
		if wmoArray.count(0) + wmoArray.count(1) > 8: # 0 = "Clear sky", 1 = "Mainly clear"
			if wmoArray.has(45) or wmoArray.has(48):
				text = "Foggy intervals"
				texture = 25 #"WMOIcon_PartlyCloud.png"
			elif wmoArray.has(2) or wmoArray.has(3):
				text = "Sunny intervals"
				texture = 25 #"WMOIcon_PartlyCloud.png"
		elif wmoArray.has(45) or wmoArray.has(48):
				text = "Fog and cloud"
				texture = 26 #"WMOIcon_Overcast.png"
		elif wmoArray.has(3):
			text = "Overcast"
			texture = 26 #"WMOIcon_Overcast.png"
		else:
			text = "Partly cloudy"
			texture = 26 #"WMOIcon_PartlyCloud.png"
	# SUN + 1 = "Mainly clear"
	else:
		text = "Clear sky"
		texture = 27 #"WMOIcon_ClearSky.png"

	wmoText.text = text #getWMOCode(openMeteoJSON["daily"]["weather_code"][day])
	wmoTexture.texture = daySummaryIcons[texture] #getWMOIcon(openMeteoJSON["daily"]["weather_code"][day])

func clearForecastVisuals():
	weatherWarningIcon.hide()
	get_node_or_null(dateText).text = "Forecasting..."
	if ukLocation:
		weatherWarningText.text = "Checking for weather warnings..."
	else:
		weatherWarningText.text = ""
	
	for position in range(0,3):
		dayDateText[position].text = ""
		dayWMOText[position].text = "" 
		dayTempText[position].text = ""
		dayWindText[position].text = ""
		daySunText[position].text = ""
		daySummaryWeatherCodeIcons[position].texture = null
		daySummaryTempTexts[position].get_parent().material = daySummaryTempTexts[position].get_parent().material.duplicate()
		daySummaryTempTexts[position].get_parent().material.set_shader_parameter('colour', Color.WHITE)
		daySummaryTempColourBorders[position].hide()
		daySummaryTempTexts[position].text = ""
		daySummaryWindRotations[position].SetInitialRotation(90,0,0)
		daySummaryWindTexts[position].text = ""
	
	get_node_or_null(moonPhaseText).text = ""
	get_node_or_null(moonPhaseTexture).texture_normal = null
	get_node_or_null(moonPhaseTexturePrevious).texture_normal = null
	get_node_or_null(moonPhaseTextureNext).texture_normal = null
	
	for h in range(0,24): # Each hour in 24 hours
		tempText[h].text = ""
		tempText[h].get_parent().material = tempText[h].get_parent().material.duplicate()
		tempText[h].get_parent().material.set_shader_parameter('colour', Color.WHITE)
		tempColourBorers[h].hide()
		precText[h].text = ""
		rainImage[h].texture = null
		cloudImage[h].texture = null
		windText[h].text = ""
		windRotation[h].SetInitialRotation(90,0,0)
		weatherText[h].text = ""

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
	# This is a hard-coded calculation that will gradually drift as the date gets further from the 'dateReference' - a recent (at the time of coding) new moon
	#var dateReference = "2026-05-16T21:01:00.00" # Recent known new moon
	#var dateSelected = selectedDateUnix
	
	#var seconds = dateSelected - Time.get_unix_time_from_datetime_string(dateReference)
	#var days = float(seconds) / 60.0 / 60.0 / 24.0
	#var age = fmod(days, 29.53059)
	
	#var daysPrevious = float(seconds - 86400) / 60.0 / 60.0 / 24.0
	#var agePrevious = fmod(daysPrevious, 29.53059)
	
	#var daysNext = float(seconds + 86400) / 60.0 / 60.0 / 24.0
	#var ageNext = fmod(daysNext, 29.53059)
	
	
	if openMeteoJSON == null:
		return
		
	var agePrevious = openMeteoJSON["daily"]["moon_phase"][startDay - 1]
	var age = openMeteoJSON["daily"]["moon_phase"][startDay]
	var ageNext = age
	if startDay < 20:
		ageNext = openMeteoJSON["daily"]["moon_phase"][startDay + 1]
	
	# https://calculatorhub.com/tools/moon-phase-illumination-calculator/
	# New Moon: D = 0 (0% lit). 
	# Waxing Crescent: D = 1.85 to 7.38. 
	# First Quarter: D = approximately 7.38 (50% lit). 
	# Waxing Gibbous: D = 7.38 to 14.77. 
	# Full Moon: D = 14.77 (100% lit). 
	# Waning Gibbous: D = 14.77 to 22.15. 
	# Last Quarter: D = approximately 22.15 (50% lit). 
	# Waning Crescent: D = 22.15 to 29.53.
	if age < 0.05 or age >= 0.95: #if (age >= 0.0 and age < 0.75) or age >= 28.75:
		get_node_or_null(moonPhaseText).text = "New Moon"
	elif age >= 0.05 and age < 0.2: #elif age >= 0.75 and age < 6.65:
		get_node_or_null(moonPhaseText).text = "Waxing Crescent Moon"
	elif age >= 0.2 and age < 0.3: #elif age >= 6.65 and age < 8.15:
		get_node_or_null(moonPhaseText).text = "First Quarter Moon" #7.4
	elif age >= 0.3 and age < 0.45: #elif age >= 8.15 and age < 14.05:
		get_node_or_null(moonPhaseText).text = "Waxing Gibbous Moon"
	elif age >= 0.45 and age < 0.55: #elif age >= 14.05 and age < 15.55:
		get_node_or_null(moonPhaseText).text = "Full Moon" #14.8
	elif age >= 0.55 and age < 0.7: #elif age >= 15.55 and age < 21.45:
		get_node_or_null(moonPhaseText).text = "Waning Gibbous Moon"
	elif age >= 0.7 and age < 0.8: #elif age >= 21.45 and age < 22.95:
		get_node_or_null(moonPhaseText).text = "Last Quarter Moon" #22.2
	elif age >= 0.8: #elif age >= 22.95:
		get_node_or_null(moonPhaseText).text = "Waning Crescent Moon"
		
	var moonIndex: float = floor(age * 29.0) #29.53059
	var moonIndexPrevious: float = floor(agePrevious * 29.0)
	var moonIndexNext: float = floor(ageNext * 29.0)
	get_node_or_null(moonPhaseTexture).texture_normal = moonTextures[moonIndex]
	get_node_or_null(moonPhaseTexturePrevious).texture_normal = moonTextures[moonIndexPrevious]
	get_node_or_null(moonPhaseTextureNext).texture_normal = moonTextures[moonIndexNext]
	
	# Hide moon if beyond forecast date limits
	if startDay > 0:
		get_node_or_null(moonPhaseTexturePrevious).show()
	else:
		get_node_or_null(moonPhaseTexturePrevious).hide()
		
	if startDay < 20:
		get_node_or_null(moonPhaseTextureNext).show()
	else:
		get_node_or_null(moonPhaseTextureNext).hide()

func updateLocation(placeName: String, lat: float, long: float):
	saveData.save_game(placeName, lat, long, saveData.tempUnit, saveData.windUnit, saveData.windAnim, saveData.tempColours, saveData.mapConnect, saveData.hour24, saveData.setToDefaultTime, saveData.showIcons, saveData.favouriteLocations)	
	get_node_or_null(locationText).text = saveData.placeName
	clearForecastVisuals()
	TryWeatherRequest()

func _on_today_button_pressed() -> void:
	today()

func today():
	get_node_or_null(anim).play("ChangeDay")
	todayUnix = Time.get_unix_time_from_system() + (60 * tzLocal) # Recalculates in case we've had the app open overnight!
	startDay = 7
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	clockRotation()
	get_node_or_null(clock).currentRot = clampf(wrap(get_node_or_null(clock).get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
	get_node_or_null(clock).previousRot = get_node_or_null(clock).currentRot
	get_node_or_null(clock).UpdateRotationData()
	get_node_or_null(clock).NowDial()
	populateForecastTable()
	daySummarySetup()
	getLunarPhase()

func _on_previous_day_button_pressed() -> void:
	previousDay(true)

func previousDay(buttonPressed):
	get_node_or_null(anim).play("ChangeDay")
	startDay -= 1
	if startDay < 0:
		startDay = 0
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	get_node_or_null(clock).UpdateRotationData()
	get_node_or_null(clock).NowDial()
	populateForecastTable()
	daySummarySetup()
	getLunarPhase()
	if buttonPressed:
		clockSet8AM() #if savedata is toggled on

func on_next_day_button_pressed() -> void:
	nextDay(true)

func nextDay(buttonPressed):
	get_node_or_null(anim).play("ChangeDay")
	startDay += 1
	if startDay > 20:
		startDay = 20
	selectedDateUnix = todayUnix + (86400 * (startDay - 7))
	get_node_or_null(clock).UpdateRotationData()
	get_node_or_null(clock).NowDial()
	populateForecastTable()
	daySummarySetup()
	getLunarPhase()
	if buttonPressed:
		clockSet8AM() #if savedata is toggled on

func clockSet8AM():
	if saveData.setToDefaultTime:
		get_node_or_null(clock).set_rotation_degrees(90)

func clockRotation():
	# Rotates the clock dial to show the local time
	var tzH = floor(tzOffset / 60)
	var tzM = tzOffset % 60
	var h = Time.get_datetime_dict_from_system().hour + tzH
	var m = Time.get_datetime_dict_from_system().minute + tzM
	get_node_or_null(clock).set_rotation_degrees((-15.0 * h) - (15.0 / 60.0 * m) -90)

func updateClock24():
	if saveData.hour24 == 24:
		for h in range(0,24):
			hour12[h].hide()
			hour24[h].show()
	else:
		for h in range(0,24):
			hour12[h].show()
			hour24[h].hide()

func updateSummaryIcons():
	if saveData.showIcons:
		for x in daySummaryTextNodes.size():
			daySummaryTextNodes[x].hide()
		for x in daySummaryIconNodes.size():
			daySummaryIconNodes[x].show()
	else:
		for x in daySummaryTextNodes.size():
			daySummaryTextNodes[x].show()
		for x in daySummaryIconNodes.size():
			daySummaryIconNodes[x].hide()
	
func updateClockLabels(previous, next):
	var selectedDatePrevious = Time.get_datetime_dict_from_unix_time(todayUnix + (86400 * (previous - 7)))
	var selectedDateNext = Time.get_datetime_dict_from_unix_time(todayUnix + (86400 * (next - 7)))
	
	#E.g. 'Mon' for Monday
	var dateShortPrevious = getWeekdayString(selectedDatePrevious.weekday).erase(3,100) + "\n " + str(selectedDatePrevious.day) + " " + getMonthString(selectedDatePrevious.month).erase(3,100)
	var dateShortNext = getWeekdayString(selectedDateNext.weekday).erase(3,100) + "\n " + str(selectedDateNext.day) + " " + getMonthString(selectedDateNext.month).erase(3,100)
	
	get_node_or_null(clockPreviousDay).text = dateShortPrevious
	get_node_or_null(clockNextDay).text = dateShortNext
	
	# Hide for dates beyond forecast limits
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
	#Colours modified from https://www.bbc.co.uk/weather/features/66293839
	
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

func _on_location_text_pressed() -> void:
	# Reference: https://www.cartograph.eu/v3/using-the-geo-uri-scheme-in-cartograph-maps/
	# Reference: https://forum.godotengine.org/t/android-how-to-open-a-web-browser-at-a-specific-address/137838/8
	#if saveData.mapConnect:
	if OS.get_name() == "Web":
		var url = "https://www.openstreetmap.org/#map=12/" + str(saveData.latitude) + "/" + str(saveData.longitude)
		var evalString = "window.open(\"" + url + "\").focus();"
		JavaScriptBridge.eval(evalString)
	else:
		OS.shell_open("geo:" + str(saveData.latitude) + "," + str(saveData.longitude) + "?z=12")

func _on_credits_button_pressed() -> void:
	creditsPanel.show()

func _on_back_button_pressed() -> void:
	creditsPanel.hide()
	settingsPanel.hide()
	locationPanel.hide()
	weatherWarningPanel.hide()
	weatherWarningDetailPanel.hide()

func _on_settings_button_pressed() -> void:
	settingsPanel.show()
	
func _on_location_button_pressed() -> void:
	locationPanel.show()
	if saveData.savedLocationsContains(saveData.placeName):
		saveLocationButton.disabled = true
		removeLocationButton.disabled = false
		maxFavourites.hide()
	elif saveData.favouriteLocations.size() == 10:
		saveLocationButton.disabled = true
		removeLocationButton.disabled = true
		maxFavourites.show()
	else:
		saveLocationButton.disabled = false
		removeLocationButton.disabled = true
		maxFavourites.hide()

func _on_texture_button_weather_warning_pressed() -> void:
	weatherWarningPanel.show()

func _on_ww_back_button_pressed() -> void:
	weatherWarningPanel.show()
	weatherWarningDetailPanel.hide()

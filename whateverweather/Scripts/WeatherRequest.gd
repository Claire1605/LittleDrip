extends HTTPRequest
@export_node_path("Label") var uiText
@export_node_path("Label") var errorText

func _ready():
	request_completed.connect(_on_request_completed)

	# Perform a GET request. The URL below returns JSON as of writing.
	var error = request("https://api.open-meteo.com/v1/forecast?latitude=56.4691&longitude=-2.9749&hourly=temperature_2m&forecast_days=1")
	if error != OK:
		get_node_or_null(uiText).text = "An error occurred in the HTTP request."
		#push_error("An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		get_node_or_null(uiText).text = "The HTTP request was unsuccesful"
		#push_error("The HTTP request was unsuccesful")
		
	var openMeteoJSON = JSON.parse_string(body.get_string_from_utf8())
	if (openMeteoJSON != null):
		print(openMeteoJSON["hourly"]["temperature_2m"].size())
		var date = getWeekdayString(Time.get_date_dict_from_system().weekday) + " " + str(Time.get_date_dict_from_system(false).day) + " " + getMonthString(Time.get_date_dict_from_system(false).month) + " " + str(Time.get_date_dict_from_system(false).year)
		var temperatureString = "The temperature at midnight on " + date + " is " + str(openMeteoJSON["hourly"]["temperature_2m"][0]) + "°C"
		get_node_or_null(uiText).text = temperatureString
		

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
	if month == 0:
		return "January"
	elif month == 1:
		return "February"
	elif month == 2:
		return "March"
	elif month == 3:
		return "April"
	elif month == 4:
		return "May"
	elif month == 5:
		return "June"
	elif month == 6:
		return "July"
	elif month == 7:
		return "August"
	elif month == 8:
		return "September"
	elif month == 9:
		return "October"
	elif month == 10:
		return "November"
	elif month == 11:
		return "December"


# TO-DO
# You have to wait for a request to finish before sending another one. Making multiple request at once requires you to have one node per request. A common strategy is to create and delete HTTPRequest nodes at runtime as necessary.
# Need more feedback if HTTP request unsuccesful, e.g. prompt to connect to internet

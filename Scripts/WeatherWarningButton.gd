# this needs testing!

extends Button

var weatherRequest : WeatherRequest
var geoJsonRequest : GeoJSONRequest
	
var redWarningIcon = preload("res://Art/WeatherWarningClay03.png")
var amberWarningIcon = preload("res://Art/WeatherWarningClay02.png")
var yellowWarningIcon = preload("res://Art/WeatherWarningClay01.png")
var redWarningButtonTheme = preload("res://Themes/WWRedButton.tres")
var amberWarningButtonTheme = preload("res://Themes/WWAmberButton.tres")
var yellowWarningButtonTheme = preload("res://Themes/WWYellowButton.tres")

var titleText : String
var warningStatus : String
var weatherType : String
var warningLevel : String
var warningHeadline : String
var whatToExpect : String
var warningFurtherDetails : String
var validFromDate : Dictionary
var validToDate : Dictionary
var affectedAreas : Array[String]
var whatShouldIDo : String

func _ready() -> void:
	weatherRequest = get_node_or_null("/root/Control/HTTPRequest_Weather")
	weatherRequest = get_node_or_null("/root/Control/HTTPRequest-GeoJSON")

# pass in e.g. NSWWSgeoJSON["features"][x]
func PopulateData(feature):
	warningStatus = feature["properties"]["warningStatus"]
	if feature["properties"]["weatherType"].size() > 1:
		for w in feature["properties"]["weatherType"].size():
			if w == feature["properties"]["weatherType"].size() - 1:
				weatherType += feature["properties"]["weatherType"][w]
			else:
				weatherType += feature["properties"]["weatherType"][w] + "&"
	else:
		weatherType = feature["properties"]["weatherType"]
	warningLevel = feature["properties"]["warningLevel"]
	warningHeadline = feature["properties"]["warningHeadline"]
	whatToExpect = feature["properties"]["whatToExpect"]
	warningFurtherDetails = feature["properties"]["warningFurtherDetails"]
	validFromDate = Time.get_datetime_dict_from_datetime_string(feature["properties"]["validFromDate"], true)
	validToDate = Time.get_datetime_dict_from_datetime_string(feature["properties"]["validToDate"], true)
	affectedAreas.clear()
	for a in feature["properties"]["affectedAreas"].size():
		affectedAreas.append(a)
	whatShouldIDo = feature["properties"]["whatShouldIDo"]
	
	var fromDate = validFromDate.hour + ":" + validFromDate.minute + " " + weatherRequest.getWeekdayString(validFromDate.weekday).erase(3,100) + " " + validFromDate.day + weatherRequest.getWeekdayString(validFromDate.month).erase(3,100)
	var toDate = validToDate.hour + ":" + validToDate.minute + " " + weatherRequest.getWeekdayString(validToDate.weekday).erase(3,100) + " " + validToDate.day + weatherRequest.getWeekdayString(validToDate.month).erase(3,100)
	titleText = warningLevel + " warning of " + weatherType + "\nbetween " + fromDate + " and " + toDate
	text = titleText
	# E.g. Red warning of thunderstorm & extreme heat between 14:00 Fri 5 Jan and 17:35 Fri 5 Jan

func _on_pressed() -> void:
	ShowWarningDetails()

func ShowWarningDetails():
	if warningLevel == "YELLOW":
		geoJsonRequest.weatherWarningDetailIcon.texture = yellowWarningIcon
	elif warningLevel == "AMBER":
		geoJsonRequest.weatherWarningDetailIcon.texture = amberWarningIcon
	elif warningLevel == "RED":
		geoJsonRequest.weatherWarningDetailIcon.texture = redWarningIcon
	weatherRequest.weatherWarningDetailPanel.show()
	geoJsonRequest.detailIssued.text = warningStatus
	geoJsonRequest.detailHeadline.text = warningHeadline
	for a in affectedAreas.size():
		if a == affectedAreas.size() - 1:
			geoJsonRequest.detailAffectedAreas.text += affectedAreas[a]
		else:
			geoJsonRequest.detailAffectedAreas.text += affectedAreas[a] + "&"
	geoJsonRequest.detailWhatToExpect.text = whatToExpect
	geoJsonRequest.detailFurtherDetails.text = warningFurtherDetails
	geoJsonRequest.detailWhatShouldIDo.text = whatShouldIDo

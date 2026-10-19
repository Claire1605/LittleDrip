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
var whatToExpect : Array
var warningFurtherDetails : String
var affectedAreas : Array[String]
var whatShouldIDo : String

# pass in e.g. NSWWSgeoJSON["features"][x]
func PopulateData(feature):
	var issuedLocalUnix = Time.get_unix_time_from_datetime_string(feature["properties"]["issuedDate"]) + (60 * weatherRequest.tzLocal)
	var issuedDict = Time.get_datetime_dict_from_unix_time(issuedLocalUnix)
	var issuedDate = str("%02d" % issuedDict.hour) + ":" + str("%02d" % issuedDict.minute) + " (" + weatherRequest.openMeteoJSON["timezone_abbreviation"] + ") " + weatherRequest.getWeekdayString(issuedDict.weekday).erase(3,100) + " " + str(issuedDict.day) + " " + weatherRequest.getMonthString(issuedDict.month).erase(3,100)
	
	warningStatus = "Issued " + issuedDate
	
	if feature["properties"]["weatherType"].size() > 1:
		for w in feature["properties"]["weatherType"].size():
			if w == feature["properties"]["weatherType"].size() - 1:
				weatherType += feature["properties"]["weatherType"][w]
			else:
				weatherType += feature["properties"]["weatherType"][w] + "&"
	else:
		weatherType = feature["properties"]["weatherType"][0]
	warningLevel = feature["properties"]["warningLevel"]
	warningHeadline = feature["properties"]["warningHeadline"]
	whatToExpect = feature["properties"]["whatToExpect"]
	warningFurtherDetails = feature["properties"]["warningFurtherDetails"]
	
	var validFromUnix = Time.get_unix_time_from_datetime_string(feature["properties"]["validFromDate"]) + (60 * weatherRequest.tzLocal)
	var validFromDict = Time.get_datetime_dict_from_unix_time(validFromUnix)
	var validToUnix = Time.get_unix_time_from_datetime_string(feature["properties"]["validToDate"]) + (60 * weatherRequest.tzLocal)
	var validToDict = Time.get_datetime_dict_from_unix_time(validToUnix)
	#validFromDate = Time.get_datetime_dict_from_datetime_string(feature["properties"]["validFromDate"]+ (60 * weatherRequest.tzLocal), true)
	#validToDate = Time.get_datetime_dict_from_datetime_string(feature["properties"]["validToDate"]+ (60 * weatherRequest.tzLocal), true)
	
	affectedAreas.clear()
	for a in feature["properties"]["affectedAreas"].size():
		for s in feature["properties"]["affectedAreas"][a]["subRegions"].size():
			affectedAreas.append(feature["properties"]["affectedAreas"][a]["subRegions"][s])
		
	whatShouldIDo = feature["properties"]["whatShouldIDo"]
	
	var validFromShortDate = weatherRequest.getWeekdayString(validFromDict.weekday).erase(3,100)
	var validFromShortMonth = weatherRequest.getMonthString(validFromDict.month).erase(3,100)
	var validToShortDate = weatherRequest.getWeekdayString(validToDict.weekday).erase(3,100)
	var validToShortMonth = weatherRequest.getMonthString(validToDict.month).erase(3,100)
	var fromDate = str("%02d" % validFromDict.hour) + ":" + str("%02d" % validFromDict.minute) + " " + validFromShortDate + " " + str(validFromDict.day) + " " + validFromShortMonth
	var toDate = str("%02d" % validToDict.hour) + ":" + str("%02d" % validToDict.minute) + " " + validToShortDate + " " + str(validToDict.day) + " " + validToShortMonth
	titleText = warningLevel.capitalize() + " warning of " + weatherType.to_lower() + "\nbetween " + fromDate + "\nand " + toDate
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
	geoJsonRequest.detailTitle.text = titleText
	geoJsonRequest.detailHeadline.text = warningHeadline
	
	geoJsonRequest.detailAffectedAreas.text = ""
	geoJsonRequest.detailAffectedAreas.text += "[ul][font_size=50]"
	for a in affectedAreas.size():
		if a == affectedAreas.size() - 1:
			geoJsonRequest.detailAffectedAreas.text += affectedAreas[a]
		else:
			geoJsonRequest.detailAffectedAreas.text += affectedAreas[a] + "\n"
	geoJsonRequest.detailAffectedAreas.text += "[/font_size][/ul]"
	
	geoJsonRequest.detailWhatToExpect.text = ""
	geoJsonRequest.detailWhatToExpect.text += "[ul][font_size=50]"
	for e in whatToExpect.size():
		if e == whatToExpect.size() - 1:
			geoJsonRequest.detailWhatToExpect.text += whatToExpect[e]
		else:
			geoJsonRequest.detailWhatToExpect.text += whatToExpect[e] + "\n"
	geoJsonRequest.detailWhatToExpect.text+= "[/font_size][/ul]"
	geoJsonRequest.detailFurtherDetails.text = warningFurtherDetails
	geoJsonRequest.detailWhatShouldIDo.text = whatShouldIDo

extends Node

var redWarningIcon = preload("res://Art/WeatherWarningClay03.png")
var amberWarningIcon = preload("res://Art/WeatherWarningClay02.png")
var yellowWarningIcon = preload("res://Art/WeatherWarningClay01.png")
var redWarningButtonTheme = preload("res://Themes/WWRedButton.tres")
var amberWarningButtonTheme = preload("res://Themes/WWAmberButton.tres")
var yellowWarningButtonTheme = preload("res://Themes/WWYellowButton.tres")

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
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

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
	validFromDate = Time.get_datetime_dict_from_datetime_string(feature["properties"]["validFromDate"], false)
	validToDate = Time.get_datetime_dict_from_datetime_string(feature["properties"]["validToDate"], false)
	affectedAreas.clear()
	for a in feature["properties"]["affectedAreas"].size():
		affectedAreas.append(a)
	whatShouldIDo = feature["properties"]["whatShouldIDo"]

func _on_pressed() -> void:
	ShowWarningDetails()

func ShowWarningDetails():
		get_node_or_null("/root/Control/HTTPRequest_Weather").weatherWarningDetailPanel.show()

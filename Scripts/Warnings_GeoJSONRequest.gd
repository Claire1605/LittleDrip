# this needs testing!

class_name GeoJSONRequest
extends HTTPRequest

@export var weatherRequest : WeatherRequest
@export_node_path("Node") var saveDataPath
@export var weatherWarningIcon : Node
@export var weatherWarningDetailIcon : TextureRect
@export var noWarnings : Node
@export var warningVBox : Node
@export var wwYellow : Texture
@export var wwAmber: Texture
@export var wwRed : Texture
@export var activeWarningsTitle: Label
var saveData
var id = ""
var redWarningButtonScene
var amberWarningButtonScene
var yellowWarningButtonScene

# Warning detail
@export var detailIssued : Label
@export var detailTitle : Label
@export var detailHeadline : Label
@export var detailAffectedAreas : RichTextLabel
@export var detailWhatToExpect : RichTextLabel
@export var detailFurtherDetails : Label
@export var detailWhatShouldIDo : Label

func _ready() -> void:
	saveData = get_node_or_null(saveDataPath)
	redWarningButtonScene = preload("res://Scenes/button_weather_warning_red.tscn")
	amberWarningButtonScene = preload("res://Scenes/button_weather_warning_amber.tscn")
	yellowWarningButtonScene = preload("res://Scenes/button_weather_warning_yellow.tscn")
	request_completed.connect(_on_request_completed)
	
func startRequest():
	weatherWarningRequest()

func weatherWarningRequest():
	# Retrieves a feature collection of latest warnings in a GeoJSON format
	# Documentation: https://datahub.metoffice.gov.uk/docs/g/category/warnings/type/nswws/api-documentation#get-/objects/issued/-uuid-
	var headers = ["accept: application/geo+json", "apikey: eyJ4NXQjUzI1NiI6Ik5XVTVZakUxTkRjeVl6a3hZbUl4TkdSaFpqSmpOV1l6T1dGaE9XWXpNMk0yTWpRek5USm1OVEE0TXpOaU9EaG1NVFJqWVdNellXUm1ZalUyTTJJeVpBPT0iLCJraWQiOiJnYXRld2F5X2NlcnRpZmljYXRlX2FsaWFzIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ==.eyJzdWIiOiJjbGFpcmUxNjA1QGR1Y2suY29tQGNhcmJvbi5zdXBlciIsImFwcGxpY2F0aW9uIjp7Im93bmVyIjoiY2xhaXJlMTYwNUBkdWNrLmNvbSIsInRpZXJRdW90YVR5cGUiOm51bGwsInRpZXIiOiJVbmxpbWl0ZWQiLCJuYW1lIjoibnN3d3MtMTQ0NGQ5YmQtYzNhMS00ZDE1LTkwNDQtMzUwM2VjMGMzMmZmIiwiaWQiOjY3NTk1LCJ1dWlkIjoiMDk0NmRkNTItNjQxMC00NmUwLWExOGUtYmUxY2Q5YTM5M2I2In0sImlzcyI6Imh0dHBzOlwvXC9hcGktbWFuYWdlci5hcGktbWFuYWdlbWVudC5tZXRvZmZpY2UuY2xvdWQ6NDQzXC9vYXV0aDJcL3Rva2VuIiwidGllckluZm8iOnsiTlNXV1NfZGVmYXVsdCI6eyJ0aWVyUXVvdGFUeXBlIjoicmVxdWVzdENvdW50IiwiZ3JhcGhRTE1heENvbXBsZXhpdHkiOjAsImdyYXBoUUxNYXhEZXB0aCI6MCwic3RvcE9uUXVvdGFSZWFjaCI6dHJ1ZSwic3Bpa2VBcnJlc3RMaW1pdCI6MTAwLCJzcGlrZUFycmVzdFVuaXQiOiJzZWMifX0sImtleXR5cGUiOiJQUk9EVUNUSU9OIiwic3Vic2NyaWJlZEFQSXMiOlt7InN1YnNjcmliZXJUZW5hbnREb21haW4iOiJjYXJib24uc3VwZXIiLCJuYW1lIjoiTlNXV1MiLCJjb250ZXh0IjoiXC9uc3d3c1wvdjEuMSIsInB1Ymxpc2hlciI6IkFhcmR3b2xmX0NJIiwidmVyc2lvbiI6InYxLjEiLCJzdWJzY3JpcHRpb25UaWVyIjoiTlNXV1NfZGVmYXVsdCJ9XSwidG9rZW5fdHlwZSI6ImFwaUtleSIsImlhdCI6MTc5MTk3MTAzNSwianRpIjoiMjFkZTVlMTgtOTk2ZS00NWU0LWIwMWYtM2Y5N2I5OWM0ZjJmIn0=.C7lE5O_7ZU_5WjDML3Z2SDTHq2diFL28nYkOlDCxPU2eiF5HujezscWs95DaZ1a-0FsM4v6p2dQR15NvpdwjMIYy1pYTMG6eueS6b5PCp_YOb-jFG7AC7NnSWMVtuTmITkNt7t_WYJDCAk1khr9fdL34TMRdCWTIpZXh087niBZHVJCI1SFbJL9SOF8rBpfAPyDieIPr4VLRD4hjRtUpsVFXTNa1LxQ4oIn_-ncHo8RCae0XeO_sTH-vvt-IzRv7ExxmQ6Jad5RJo-ndNAfh7qOJdXnLkrHchi8OPX1hJ2PBRstfclvSWDWDXGR0AdBjrQVZz5hgMQjtFf2TxIVMZw=="]

	var error = request("https://data.hub.api.metoffice.gov.uk/nswws/v1.1/objects/issued/" + id, headers)
	if error != OK:
		get_node_or_null(weatherRequest.dateText).text = "GEOJson error 1. Please contact developer"

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		get_node_or_null(weatherRequest.dateText).text = "GEOJson error 2. Please contact developer"
	
	var NSWWSgeoJSON = JSON.parse_string(body.get_string_from_utf8())
	
	activeWarningsTitle.text = "Active Met Office Weather Warnings in\n" + saveData.placeName + "\nClick each warning for further details."
	
	# Are there active weather warnings?
	if NSWWSgeoJSON["features"].size() > 0:
		# Do they apply to the currently selected area?
		var thisArea = false
		for i in NSWWSgeoJSON["features"].size():
			if isPointInPolygon(constructPolygon(NSWWSgeoJSON["features"][i]["geometry"]["coordinates"][0][0])):
				thisArea = true
		
		if thisArea == true:
			weatherWarningIcon.show()
			noWarnings.hide()
			weatherRequest.weatherWarningText.text = "Weather warnings have been issued. Click below for details."
		else:
			weatherWarningIcon.hide()
			noWarnings.show()
			weatherRequest.weatherWarningText.text = "No active weather warnings."
			return
	else:
		weatherWarningIcon.hide()
		noWarnings.show()
		weatherRequest.weatherWarningText.text = "No active weather warnings."
		return
		
	#DEBUG + uncomment returns above
	#weatherWarningIcon.show()
	#noWarnings.show()
	
	var r = false
	var a = false
	var y = false
	
	# Remove all warnings first
	for i in warningVBox.get_child_count():
		warningVBox.get_child(i).queue_free()
	
	# Instantiate warnings
	for i in NSWWSgeoJSON["features"].size():
		if NSWWSgeoJSON["features"][i]["properties"]["warningLevel"] == "RED":
			r = true
			# Instantiate a red warning button with the correct data
			var warningButton = redWarningButtonScene.instantiate()
			warningButton.weatherRequest = weatherRequest
			warningButton.geoJsonRequest = self
			warningButton.PopulateData(NSWWSgeoJSON["features"][i])
			warningVBox.add_child(warningButton)
		if NSWWSgeoJSON["features"][i]["properties"]["warningLevel"] == "AMBER":
			a = true
			# Instantiate an amber warning button with the correct data
			var warningButton = amberWarningButtonScene.instantiate()
			warningButton.weatherRequest = weatherRequest
			warningButton.geoJsonRequest = self
			warningButton.PopulateData(NSWWSgeoJSON["features"][i])
			warningVBox.add_child(warningButton)
			pass
		if NSWWSgeoJSON["features"][i]["properties"]["warningLevel"] == "YELLOW":
			y = true
			# Instantiate a yellow warning button with the correct data
			var warningButton = yellowWarningButtonScene.instantiate()
			warningButton.weatherRequest = weatherRequest
			warningButton.geoJsonRequest = self
			warningButton.PopulateData(NSWWSgeoJSON["features"][i])
			warningVBox.add_child(warningButton)
			pass
	
	# Prioritise the most severe warning for the icon colour
	if y == true:
		weatherWarningIcon.texture_normal = wwYellow
	if a == true:
		weatherWarningIcon.texture_normal = wwAmber
	if r == true:
		weatherWarningIcon.texture_normal = wwRed
	
	# Example
	#for i in NSWWSgeoJSON["features"].size():
	#	var areas = ""
	#	for x in NSWWSgeoJSON["features"][i]["properties"]["affectedAreas"].size():
	#		areas += NSWWSgeoJSON["features"][i]["properties"]["affectedAreas"][x]["regionName"]
	#		if NSWWSgeoJSON["features"][i]["properties"]["affectedAreas"].size() > 1 and x < NSWWSgeoJSON["features"][i]["properties"]["affectedAreas"].size():
	#			areas += ", "
	#	var weatherTypes = ""
	#	for x in NSWWSgeoJSON["features"][i]["properties"]["weatherType"].size():
	#		weatherTypes += NSWWSgeoJSON["features"][i]["properties"]["weatherType"][x]
	#		if NSWWSgeoJSON["features"][i]["properties"]["weatherType"].size() > 1 and x < NSWWSgeoJSON["features"][i]["properties"]["weatherType"].size():
	#			areas += ", "
	#	print("There is a " + NSWWSgeoJSON["features"][i]["properties"]["warningLevel"] + " " + weatherTypes +  " warning in " + areas)
	
	#for i in NSWWSgeoJSON["features"].size():
	#	var polygon : PackedVector2Array
	#	for c in NSWWSgeoJSON["features"][i]["geometry"]["coordinates"][0][0].size():
	#		var coord = Vector2(NSWWSgeoJSON["features"][i]["geometry"]["coordinates"][0][0][c][0], NSWWSgeoJSON["features"][i]["geometry"]["coordinates"][0][0][c][1])
	#		polygon.append(coord)
	#	
	#	print(isPointInPolygon(polygon))


func constructPolygon(coordinates) -> PackedVector2Array:
	var polygon : PackedVector2Array
	for c in coordinates.size():
			var coord = Vector2(coordinates[c][0], coordinates[c][1])
			polygon.append(coord)
	
	return polygon


func isPointInPolygon(polygon) -> bool:
	var inside = false
	var location = Vector2(saveData.longitude, saveData.latitude)
	
	if Geometry2D.is_point_in_polygon(location, polygon):
		inside = true
	
	return inside

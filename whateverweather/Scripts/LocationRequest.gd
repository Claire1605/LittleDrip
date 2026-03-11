extends HTTPRequest
@export_node_path("VBoxContainer") var locationResults
@export_node_path("LineEdit") var locationSearch
@export_node_path("HTTPRequest") var weatherRequest
var locationJSON
var locationButtonScene
var locationChildren: Array[Node]

func _ready() -> void:
	locationButtonScene = preload("res://Scenes/location_button.tscn")
	print(self.get_path())

func search(text: String):
	get_node_or_null(locationResults).show()
	
	request_completed.connect(geocoding)
	
	text = text.replace(' ', '+')

	# Perform a GET request. The URL below returns JSON as of writing.
	var error = request("https://geocoding-api.open-meteo.com/v1/search?name=" + text + "&count=10&language=en&format=json")
	if error != OK:
		#get_node_or_null(dateText).text = "An error occurred in the HTTP request."
		push_error("An error occurred in the HTTP request.")
		
func geocoding(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		#get_node_or_null(dateText).text = "The HTTP request was unsuccesful"
		push_error("The HTTP request was unsuccesful")
	
	locationJSON = JSON.parse_string(body.get_string_from_utf8())

	if locationJSON != null and locationJSON.has("results"):
		
		if !locationChildren.is_empty():
			for node in locationChildren:
				if is_instance_valid(node):
					node.queue_free()
		
		for l in locationJSON["results"]:
			if l.has("name") and l.has("admin1"):
				var locationButton = locationButtonScene.instantiate()
				get_node_or_null(locationResults).add_child(locationButton)
				locationChildren.append(locationButton as Node)
				locationButton.placeName = l["name"]
				locationButton.lat = l["latitude"]
				locationButton.long = l["longitude"]
				locationButton.text = l["name"] + " (" + l["admin1"] + ")"

func updateLocation(placeName: String, lat: float, long: float):
	clearLocationResults()
	get_node_or_null(locationSearch).text = ""
	get_node_or_null(weatherRequest).updateLocation(placeName, lat, long)

func clearLocationResults():
	if !locationChildren.is_empty():
			for node in locationChildren:
				if is_instance_valid(node):
					node.queue_free()
	
	get_node_or_null(locationResults).hide()

func _on_location_search_text_submitted(new_text: String) -> void:
	if new_text.length() > 1:
		search(new_text)
	else:
		clearLocationResults()

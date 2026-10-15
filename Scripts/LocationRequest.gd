extends HTTPRequest
@export_node_path("VBoxContainer") var locationResults
@export_node_path("LineEdit") var locationSearch
@export_node_path("VBoxContainer") var locationFavResults
@export_node_path("HTTPRequest") var weatherRequest
@export_node_path("Node") var saveDataPath
@export var favouritesExitButton : Node
var saveData
var locationJSON
var locationButtonScene
var locationChildren: Array[Node]
var locationFavChildren: Array[Node]

func _ready() -> void:
	saveData = get_node_or_null(saveDataPath)
	locationButtonScene = preload("res://Scenes/location_button.tscn")

func search(text: String):
	get_node_or_null(locationResults).show()
	
	if !request_completed.is_connected(geocoding):
		request_completed.connect(geocoding)
	
	text = text.replace(' ', '+')

	# Perform a GET request. The URL below returns JSON as of writing.
	var error = request("https://geocoding-api.open-meteo.com/v1/search?name=" + text + "&count=10&language=en&format=json")
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		
func geocoding(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
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
				locationButton.placeName = l["name"] + " (" + l["admin1"] + ")"
				#locationButton.adminName = l["admin1"]
				locationButton.lat = l["latitude"]
				locationButton.long = l["longitude"]
				locationButton.text = l["name"] + " (" + l["admin1"] + ")"

func updateLocation(placeName: String, lat: float, long: float):
	clearLocationResults(locationChildren)
	clearLocationResults(locationFavChildren)
	DisplayFavouriteLocations(false)
	favouritesExitButton.hide()
	get_node_or_null(locationSearch).text = ""
	get_node_or_null(weatherRequest).updateLocation(placeName, lat, long)

func clearLocationResults(locChildren):
	if !locChildren.is_empty():
			for node in locChildren:
				if is_instance_valid(node):
					node.queue_free()
	
	get_node_or_null(locationResults).hide()

func _on_location_search_text_submitted(new_text: String) -> void:
	if new_text.length() > 1:
		search(new_text)
	else:
		clearLocationResults(locationChildren)


func _on_location_search_focus_entered() -> void:
	DisplayFavouriteLocations(true)

func exitFavourites() -> void:
	DisplayFavouriteLocations(false)

func _on_location_search_text_changed(new_text: String) -> void:
	DisplayFavouriteLocations(false)
	

func DisplayFavouriteLocations(show):
	if show == true and get_node_or_null(locationFavResults).visible == false:
		get_node_or_null(locationFavResults).show()
		favouritesExitButton.show()
		if saveData.favouriteLocations != null and saveData.favouriteLocations.size() > 0:
			if !locationFavChildren.is_empty():
				for node in locationFavChildren:
					if is_instance_valid(node):
						node.queue_free()
			
			for l in saveData.favouriteLocations.size():
				var locationButton = locationButtonScene.instantiate()
				get_node_or_null(locationFavResults).add_child(locationButton)
				locationFavChildren.append(locationButton as Node)
				locationButton.placeName = saveData.favouriteLocations[l]["placeName"]
				#locationButton.adminName = saveData.favouriteLocations[l]["placeName"]
				locationButton.lat = saveData.favouriteLocations[l]["latitude"]
				locationButton.long = saveData.favouriteLocations[l]["longitude"]
				locationButton.text = saveData.favouriteLocations[l]["placeName"]
	elif show == false and get_node_or_null(locationFavResults).visible == true:
		clearLocationResults(locationFavChildren)
		favouritesExitButton.hide()
		get_node_or_null(locationFavResults).hide()


func _on_button_favourites_save_pressed() -> void:
	saveData.save_fav_location()
	get_node_or_null(weatherRequest)._on_back_button_pressed()


func _on_button_favourites_remove_pressed() -> void:
	saveData.remove_fav_location()
	get_node_or_null(weatherRequest)._on_back_button_pressed()

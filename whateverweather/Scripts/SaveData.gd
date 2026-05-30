extends Node
var placeName: String = "Dundee"
var latitude: float = 56.4691
var longitude: float = -2.9749
var tempUnit: String = ""
var windUnit: String = "mph"

func save_game(pName, lat, long, temp, wind):
	placeName = pName
	latitude = lat
	longitude = long
	tempUnit = temp
	windUnit = wind
	
	print("sdtu: " + tempUnit)
	print("sdwu: " + windUnit)
	
	var save_dict = {
		"placeName" : placeName,
		"latitude" : latitude,
		"longitude" : longitude,
		"tempUnit" : tempUnit,
		"windUnit" : windUnit
	}
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save_dict))

func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data = json.data

		placeName = node_data.placeName
		latitude = node_data.latitude
		longitude = node_data.longitude
		tempUnit = node_data.tempUnit
		windUnit = node_data.windUnit
		
		print("ldtu: " + tempUnit)
		print("ldwu: " + windUnit)

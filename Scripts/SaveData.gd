extends Node
var placeName: String = "Dundee"
var latitude: float = 56.4691
var longitude: float = -2.9749
var tempUnit: String = ""
var windUnit: String = "mph"
var windAnim: bool = true
var tempColours: bool = true
var mapConnect: bool = true
var hour24: int = 24
var setToDefaultTime: bool = true

func save_game(pName, lat, long, temp, wind, anim, tempCol, mapConn, h24, defaultTime):
	placeName = pName
	latitude = lat
	longitude = long
	tempUnit = temp
	windUnit = wind
	windAnim = anim
	tempColours = tempCol
	mapConnect = mapConn
	hour24 = h24
	setToDefaultTime = defaultTime
	
	var save_dict = {
		"placeName" : placeName,
		"latitude" : latitude,
		"longitude" : longitude,
		"tempUnit" : tempUnit,
		"windUnit" : windUnit,
		"windAnim" : windAnim,
		"tempColours" : tempColours,
		"mapConnect" : mapConnect,
		"hour24" : hour24,
		"setToDefaultTime" : setToDefaultTime
	}
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save_dict))

func saveTempUnit(t):
	save_game(placeName, latitude, longitude, t, windUnit, windAnim, tempColours, mapConnect, hour24, setToDefaultTime)

func saveWindUnit(w):
	save_game(placeName, latitude, longitude, tempUnit, w, windAnim, tempColours, mapConnect, hour24, setToDefaultTime)
	
func saveWindAnim(a):
	save_game(placeName, latitude, longitude, tempUnit, windUnit, a, tempColours, mapConnect, hour24, setToDefaultTime)
	
func saveTempColours(c):
	save_game(placeName, latitude, longitude, tempUnit, windUnit, windAnim, c, mapConnect, hour24, setToDefaultTime)
	
func saveMapConnect(m):
	save_game(placeName, latitude, longitude, tempUnit, windUnit, windAnim, tempColours, m, hour24, setToDefaultTime)
	
func saveHour24(h):
	save_game(placeName, latitude, longitude, tempUnit, windUnit, windAnim, tempColours, mapConnect, h, setToDefaultTime)
	
func saveDefaultTime(d):
	save_game(placeName, latitude, longitude, tempUnit, windUnit, windAnim, tempColours, mapConnect, hour24, d)

func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.

	# Load the file line by line and process that dictionary to restore the object it represents.
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
		windAnim = node_data.windAnim
		tempColours = node_data.tempColours
		mapConnect = node_data.mapConnect
		
		#variables in v2, need to check if in dictionary first
		hour24 = node_data.get("hour24", 24)	
		setToDefaultTime = node_data.get("setToDefaultTime", false)

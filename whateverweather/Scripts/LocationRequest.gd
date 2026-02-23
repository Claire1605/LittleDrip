extends HTTPRequest
var locationJSON

func _ready():
	request_completed.connect(geocoding)

	# Perform a GET request. The URL below returns JSON as of writing.
	var error = request("https://geocoding-api.open-meteo.com/v1/search?name=Dundee&count=10&language=en&format=json")
	if error != OK:
		#get_node_or_null(dateText).text = "An error occurred in the HTTP request."
		push_error("An error occurred in the HTTP request.")
		
func geocoding(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		#get_node_or_null(dateText).text = "The HTTP request was unsuccesful"
		push_error("The HTTP request was unsuccesful")
	
	locationJSON = JSON.parse_string(body.get_string_from_utf8())
	if (locationJSON != null):
		for l in locationJSON["results"]:
			print(l["name"] + " (" + l["admin1"] + ")")
	
	#str(locationJSON["results"][x]["latitude"])
	#str(locationJSON["results"][x]["longitude"])

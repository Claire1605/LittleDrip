extends HTTPRequest

@export var jsonRequest: GeoJSONRequest

func _ready() -> void:
	request_completed.connect(_on_request_completed)
	weatherWarningRequest()

func weatherWarningRequest():
	# Retrieve the Atom Feed
	# Documentation: https://datahub.metoffice.gov.uk/docs/g/category/warnings/type/nswws/api-documentation#get-/objects/feed
	var headers = ["accept: application/atom+xml", "apikey: eyJ4NXQjUzI1NiI6Ik5XVTVZakUxTkRjeVl6a3hZbUl4TkdSaFpqSmpOV1l6T1dGaE9XWXpNMk0yTWpRek5USm1OVEE0TXpOaU9EaG1NVFJqWVdNellXUm1ZalUyTTJJeVpBPT0iLCJraWQiOiJnYXRld2F5X2NlcnRpZmljYXRlX2FsaWFzIiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ==.eyJzdWIiOiJjbGFpcmUxNjA1QGR1Y2suY29tQGNhcmJvbi5zdXBlciIsImFwcGxpY2F0aW9uIjp7Im93bmVyIjoiY2xhaXJlMTYwNUBkdWNrLmNvbSIsInRpZXJRdW90YVR5cGUiOm51bGwsInRpZXIiOiJVbmxpbWl0ZWQiLCJuYW1lIjoibnN3d3MtMTQ0NGQ5YmQtYzNhMS00ZDE1LTkwNDQtMzUwM2VjMGMzMmZmIiwiaWQiOjY3NTk1LCJ1dWlkIjoiMDk0NmRkNTItNjQxMC00NmUwLWExOGUtYmUxY2Q5YTM5M2I2In0sImlzcyI6Imh0dHBzOlwvXC9hcGktbWFuYWdlci5hcGktbWFuYWdlbWVudC5tZXRvZmZpY2UuY2xvdWQ6NDQzXC9vYXV0aDJcL3Rva2VuIiwidGllckluZm8iOnsiTlNXV1NfZGVmYXVsdCI6eyJ0aWVyUXVvdGFUeXBlIjoicmVxdWVzdENvdW50IiwiZ3JhcGhRTE1heENvbXBsZXhpdHkiOjAsImdyYXBoUUxNYXhEZXB0aCI6MCwic3RvcE9uUXVvdGFSZWFjaCI6dHJ1ZSwic3Bpa2VBcnJlc3RMaW1pdCI6MTAwLCJzcGlrZUFycmVzdFVuaXQiOiJzZWMifX0sImtleXR5cGUiOiJQUk9EVUNUSU9OIiwic3Vic2NyaWJlZEFQSXMiOlt7InN1YnNjcmliZXJUZW5hbnREb21haW4iOiJjYXJib24uc3VwZXIiLCJuYW1lIjoiTlNXV1MiLCJjb250ZXh0IjoiXC9uc3d3c1wvdjEuMSIsInB1Ymxpc2hlciI6IkFhcmR3b2xmX0NJIiwidmVyc2lvbiI6InYxLjEiLCJzdWJzY3JpcHRpb25UaWVyIjoiTlNXV1NfZGVmYXVsdCJ9XSwidG9rZW5fdHlwZSI6ImFwaUtleSIsImlhdCI6MTc5MTk3MTAzNSwianRpIjoiMjFkZTVlMTgtOTk2ZS00NWU0LWIwMWYtM2Y5N2I5OWM0ZjJmIn0=.C7lE5O_7ZU_5WjDML3Z2SDTHq2diFL28nYkOlDCxPU2eiF5HujezscWs95DaZ1a-0FsM4v6p2dQR15NvpdwjMIYy1pYTMG6eueS6b5PCp_YOb-jFG7AC7NnSWMVtuTmITkNt7t_WYJDCAk1khr9fdL34TMRdCWTIpZXh087niBZHVJCI1SFbJL9SOF8rBpfAPyDieIPr4VLRD4hjRtUpsVFXTNa1LxQ4oIn_-ncHo8RCae0XeO_sTH-vvt-IzRv7ExxmQ6Jad5RJo-ndNAfh7qOJdXnLkrHchi8OPX1hJ2PBRstfclvSWDWDXGR0AdBjrQVZz5hgMQjtFf2TxIVMZw=="]

	var error = request("https://data.hub.api.metoffice.gov.uk/nswws/v1.1/objects/feed", headers)
	if error != OK:
		print("atom feed request error")

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("atom feed request unsuccesful")
	#else:
		#print("atom feedg request succesful")
		
	var xml = body.get_string_from_utf8()
	var from = xml.find("<id>") + 13
	var to = xml.find("</id>") - from
	var id = xml.substr(from, to)
	jsonRequest.id = id
	jsonRequest.startRequest()

	#var parser = XMLParser.new()
	#parser.open_buffer(body)
	#print(body.get_string_from_utf8())
	#while parser.read() != ERR_FILE_EOF:
		#print each attribute here
		#if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			#var node_name = parser.get_node_name()
			#print(str(parser.get_node_name()))
			#print(str(parser.get_node_data()))
			#print(str(parser.get_node_type()))
			#var attributes_dict = {}
			#for idx in range(parser.get_attribute_count()):
			#	attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			#print("The ", node_name, " element has the following attributes: ", attributes_dict)

extends Node
var placeName: String
var adminName: String
var lat: float
var long: float

func _on_pressed() -> void:
	get_parent().hide()
	get_node_or_null("/root/Control/HTTPRequest_Location").updateLocation(placeName,adminName, lat, long)

extends Node

@export var weatherRequest: NodePath
@export var ToggleFamily: Array[NodePath] #use getnodeornull
@export var tempColours: bool

func _ready() -> void:
	if get_node_or_null(weatherRequest).saveData.tempColours == tempColours:
		SelectSetting(get_node_or_null(get_path()))

func _on_pressed() -> void:
	if get_node_or_null(get_path()).button_pressed:
		for t in range(0, ToggleFamily.size()):
			if get_node_or_null(get_path()).name == get_node_or_null(ToggleFamily[t]).name:
				SelectSetting(get_node_or_null(get_path()))
				get_node_or_null(weatherRequest).TryWeatherRequest()
			else:
				DeselectSetting(get_node_or_null(ToggleFamily[t]))
	

func SelectSetting(node):
	get_node_or_null(weatherRequest).saveData.saveTempColours(tempColours)
	node.disabled = true
	
func DeselectSetting(node):
	node.disabled = false
	node.button_pressed = false

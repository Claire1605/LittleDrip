extends Node

@export var weatherRequest: NodePath
@export var ToggleFamily: Array[NodePath] #use getnodeornull
@export var h24: int

func _ready() -> void:
	if get_node_or_null(weatherRequest).saveData.hour24 == h24:
		SelectSetting(get_node_or_null(get_path()))

func _on_pressed() -> void:
	if get_node_or_null(get_path()).button_pressed:
		for t in range(0, ToggleFamily.size()):
			if get_node_or_null(get_path()).name == get_node_or_null(ToggleFamily[t]).name:
				SelectSetting(get_node_or_null(get_path()))
				get_node_or_null(weatherRequest).updateClock24()
			else:
				DeselectSetting(get_node_or_null(ToggleFamily[t]))

func SelectSetting(node):
	get_node_or_null(weatherRequest).saveData.saveHour24(h24)
	node.disabled = true
	
func DeselectSetting(node):
	node.disabled = false
	node.button_pressed = false

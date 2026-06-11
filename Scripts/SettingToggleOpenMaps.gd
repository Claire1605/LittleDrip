extends Node

@export var weatherRequest: NodePath
@export var ToggleFamily: Array[NodePath] #use getnodeornull
@export var mapConnect: bool

func _ready() -> void:
	if get_node_or_null(weatherRequest).saveData.mapConnect == mapConnect:
		SelectSetting(get_node_or_null(get_path()))

func _on_pressed() -> void:
	if get_node_or_null(get_path()).button_pressed:
		for t in range(0, ToggleFamily.size()):
			if get_node_or_null(get_path()).name == get_node_or_null(ToggleFamily[t]).name:
				SelectSetting(get_node_or_null(get_path()))
			else:
				DeselectSetting(get_node_or_null(ToggleFamily[t]))

func SelectSetting(node):
	get_node_or_null(weatherRequest).saveData.saveMapConnect(mapConnect)
	node.disabled = true
	
func DeselectSetting(node):
	node.disabled = false
	node.button_pressed = false

extends Control
var initialRotation

func SetInitialRotation(rot):
	initialRotation = rot
	set_rotation_degrees(initialRotation)

func UpdateRotation(rot):
	set_rotation_degrees(initialRotation - rot)

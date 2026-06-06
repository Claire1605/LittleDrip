extends Control
var windDirection
var windParentRotation
var clockRotation

func SetInitialRotation(wind, windRot, clockRot):
	windDirection = wind
	windParentRotation = windRot
	clockRotation = wrapf(clockRot, 0.0, 360.0)
	set_rotation_degrees(wrapf((windDirection - clockRotation - windParentRotation - 90), 0.0, 360.0))

func UpdateRotation(clockRot):
	clockRotation = wrapf(clockRot, 0.0, 360.0)
	set_rotation_degrees(wrapf((windDirection - clockRotation - windParentRotation - 90), 0.0, 360.0))

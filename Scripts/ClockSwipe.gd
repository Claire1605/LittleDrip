extends TextureButton

@export_node_path("HTTPRequest") var weatherRequestPath
@export_node_path("TextureRect") var dialNow
@export var dialTextures: Array[Texture] = []
var weatherRequest: WeatherRequest
var mouseDown: bool = false
var mouseDownFirstFrame: bool = true
var rotationInitial: float = 0.0
var distance = Vector2(0,0)
var mouseCurrentPosition = Vector2(0,0)
var mouseLastFramePosition = Vector2(0,0)
var mouseInitialPosition = Vector2(0,0)
var requestReady: bool = false
var currentRot: float
var previousRot: float
var canRotate: bool = true
var currentSegment = 0;
var previousSegment = 0;
var clockHourDates: Array[int]
var previousStartDay

func _ready():
	weatherRequest = get_node_or_null(weatherRequestPath)
	
	# clockHourDates determines which day each hour should show data for
	for x in 24:
		clockHourDates.append(weatherRequest.startDay)

func _process(delta: float) -> void:
	# Debug
	'if weatherRequest.get_node_or_null(weatherRequest.debug).visible:
		weatherRequest.get_node_or_null(weatherRequest.debug).text = ""
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "Current Segment: " + str(currentSegment)
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nPrevious Segment: " + str(previousSegment)
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nStart Day: " + str(weatherRequest.startDay)
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nPrevious Start Day: " + str(previousStartDay)
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nActual Rotation: " + str(clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0))
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nCurrentRotation: " + str(currentRot)
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nPreviousRotation: " + str(previousRot)
		for x in clockHourDates.size():
			weatherRequest.get_node_or_null(weatherRequest.debug).text += ("\n" + str(x) + " : " + str(clockHourDates[x]))'
		
	if requestReady: # If the HTTP request has completed succesfully
		if mouseDown:  # Left mouse button / finger held down
			if mouseDownFirstFrame:
				InitialRotationSetup() # Sets default rotation and mouse position
			ApplyRotation() # Checks how far we have swiped and rotates clock accordingly
		
		NowDial() # Updates rotation and visibilty of dial showing 'now' hour
		UpdateRotationData() # Updates clock labels and hourly data
		CheckDayChange()

func InitialRotationSetup():
	rotationInitial = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
	mouseInitialPosition = get_viewport().get_mouse_position()
	mouseDownFirstFrame = false
	
func ApplyRotation():
	mouseCurrentPosition = get_viewport().get_mouse_position()	
	currentRot = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
	distance = mouseCurrentPosition - mouseInitialPosition

	var canRotate = true
	
	# Rotation at past extreme: If we try to rotate further back it should clamp rotation. Does this with a buffer of a few degrees
	if weatherRequest.startDay == 0 and currentRot <= 254 and currentRot > 180:
		if wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0) > 254 or wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0) < 90:
			set_rotation_degrees(253)
			canRotate = false
	
	# Rotation at future extreme: If we try to rotate further forward it should clamp rotation. Does this with a buffer of a few degrees
	if weatherRequest.startDay == 20 and currentRot < 350 and currentRot >= 286:
		if wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0) < 286:
			set_rotation_degrees(287)
			canRotate = false
	
	if canRotate: # Rotation in non-extreme situations
		set_rotation_degrees(wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0))
		
		for x in range(24):
			weatherRequest.windRotation[x].UpdateRotation(get_rotation_degrees()) # Pass in current clock rotation to align the wind direction
	
	mouseLastFramePosition = mouseCurrentPosition

func NowDial():
	# Get system time and offset it to local time of location searched
	var tzH = floor(weatherRequest.tzOffset / 60) # tzH = timezoneHour
	var tzM = weatherRequest.tzOffset - (tzH * 60) # tzM = timezoneMinute
	var h = wrap(Time.get_time_dict_from_system().hour + tzH, 0, 24)
	var m = Time.get_time_dict_from_system().minute + tzM
	if m > 60:
		h += 1
		m -=60
	if m < 0:
		h -= 1
		m +=60
	if m >= 30:
		h = wrap(h + 1, 0, 24)
	
	# Show or hide the 'now' dial (if we're looking at today's data) and set it to the correct rotation
	if clockHourDates[h] == 7:
		get_node_or_null(dialNow).texture = dialTextures[0]
		get_node_or_null(dialNow).set_rotation_degrees(90 + (h * 15))
	else:
		get_node_or_null(dialNow).texture = dialTextures[1] # this used to be .hide() but it made the dial spin round when tapped???

func UpdateRotationData():
	var r = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
	
	# UPDATE CURRENT SEGMENT
	if r >= 270: # 270 is midnight, 00:00
		currentSegment = 24 - (floorf(r / 15.0) - 17) # 15 = 360 degrees / 24 hours
	else:
		currentSegment = 0 - (floorf(r / 15.0) - 17)
	
	# UPDATE CLOCK DATE LABELS
	if currentSegment == 12:
		if previousSegment == 11:
			weatherRequest.updateClockLabels(weatherRequest.startDay, weatherRequest.startDay + 1)
		elif previousSegment == 13:
			weatherRequest.updateClockLabels(weatherRequest.startDay - 1, weatherRequest.startDay)
	elif currentSegment >= 12:
		weatherRequest.updateClockLabels(weatherRequest.startDay, weatherRequest.startDay + 1)
	elif previousSegment < 12:
		weatherRequest.updateClockLabels(weatherRequest.startDay - 1, weatherRequest.startDay)
	
	# UPDATE HOURLY DATES
	if currentSegment != previousSegment or weatherRequest.startDay != previousStartDay:
		if currentSegment >= 12:
			for s in range(currentSegment - 12, 24):
				clockHourDates[s] = weatherRequest.startDay
			for s in range(0, currentSegment - 12):
				clockHourDates[s] = weatherRequest.startDay + 1

		if currentSegment < 12:
			for s in range(0, 12 + currentSegment):
				clockHourDates[s] = weatherRequest.startDay
			for s in range(12 + currentSegment, 24):
				clockHourDates[s] = weatherRequest.startDay - 1
	
	previousSegment = currentSegment
	previousStartDay = weatherRequest.startDay

func CheckDayChange():
	#If swipe across midnight
	currentRot = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
	if previousRot > 270 and previousRot < 360 and currentRot > 180 and currentRot <= 270:
		weatherRequest.nextDay()
	elif previousRot > 180 and previousRot < 270 and currentRot >= 270 and currentRot < 360:
		#print("check day change - previous: PR: " + str(previousRot) + ", CR: " + str(currentRot))
		weatherRequest.previousDay()
	
	previousRot = currentRot
			
func resetSwipe():
	distance = 0
	mouseCurrentPosition = mouseInitialPosition

func _on_button_down() -> void:
	if requestReady:
		mouseDown = true
		mouseDownFirstFrame = true

func _on_button_up() -> void:
	if requestReady:
		mouseDown = false
		ApplyRotation()
		resetSwipe()

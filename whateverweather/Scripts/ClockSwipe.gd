extends TextureButton
@export_node_path("HTTPRequest") var weatherRequestPath
var weatherRequest
var mouseDown: bool = false
var hasClicked: bool = false
var mouseDownFirstFrame: bool = true
var rotationInitial: float = 0.0
var distance = Vector2(0,0)
var mouseCurrentPosition = Vector2(0,0)
var mouseLastFramePosition = Vector2(0,0)
var mouseInitialPosition = Vector2(0,0)
var deceleration: float = 270.0
var holdTime: float = 0.2
var requestReady: bool = false
var currentRot: float
var previousRot: float
var canRotate: bool = true
var movingClockwise = 0
var currentSegment = 0;
var previousSegment = 0;
var clockHourDates: Array[int]
var velocity = 0.0
var rotationOnMouseDown = 0.0
var timeOnMouseDown
var startDay
var previousStartDay

func _ready():
	weatherRequest = get_node_or_null(weatherRequestPath)
	
	startDay = weatherRequest.startDay
	
	for x in 24:
		clockHourDates.append(startDay)

func resetSwipe():
	holdTime = 0.0
	velocity = 0.0
	rotationInitial = get_rotation_degrees()
	
	mouseInitialPosition = get_viewport().get_mouse_position()
	mouseDownFirstFrame = false

func updateRotationData():
	if mouseCurrentPosition.x - mouseLastFramePosition.x > 0:
		movingClockwise = 1
	elif mouseCurrentPosition.x - mouseLastFramePosition.x < 0:
		movingClockwise = -1
	else:
		movingClockwise = 0
	
	var r = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
	
	startDay = weatherRequest.startDay
	
	# UPDATE CURRENT SEGMENT
	if r >= 270:
		currentSegment = 24 - (floorf(r / 15.0) - 17)
	else:
		currentSegment = 0 - (floorf(r / 15.0) - 17)
	
	# UPDATE CLOCK DATE LABELS
	if currentSegment == 12:
		if previousSegment == 11:
			weatherRequest.updateClockLabels(startDay, startDay + 1)
		elif previousSegment == 13:
			weatherRequest.updateClockLabels(startDay - 1, startDay)
	elif currentSegment >= 12:
		weatherRequest.updateClockLabels(startDay, startDay + 1)
	elif previousSegment < 12:
		weatherRequest.updateClockLabels(startDay - 1, startDay)
	
	# UPDATE HOURLY DATES
	if currentSegment != previousSegment or startDay != previousStartDay:
		if currentSegment >= 12:
			for s in range(currentSegment - 12, 24):
				clockHourDates[s] = weatherRequest.startDay
			for s in range(0, currentSegment - 12):
				clockHourDates[s] = weatherRequest.startDay + 1

		if currentSegment < 12:
			for s in range(currentSegment, 12 + currentSegment):
				clockHourDates[s] = weatherRequest.startDay
			for s in range(12 + currentSegment, 24):
				clockHourDates[s] = weatherRequest.startDay - 1
	
	previousSegment = currentSegment
	previousStartDay = startDay

func _process(delta: float) -> void:
	if weatherRequest.get_node_or_null(weatherRequest.debug).visible:
		weatherRequest.get_node_or_null(weatherRequest.debug).text = ""
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "Current Segment: " + str(currentSegment)
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nStart Day: " + str(weatherRequest.startDay)
		weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nRotation: " + str(clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0))
		#weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nPrevious Label: " + str(weatherRequest.get_node_or_null(weatherRequest.clockPreviousDay).text)
		#weatherRequest.get_node_or_null(weatherRequest.debug).text += "\nNext Label: " + str(weatherRequest.get_node_or_null(weatherRequest.clockNextDay).text)
		#for x in clockHourDates.size():
		#	weatherRequest.get_node_or_null(weatherRequest.debug).text += ("\n" + str(x) + " : " + str(clockHourDates[x]))
		
	if requestReady:
		updateRotationData()
		if mouseDown:  # Left mouse button.
			if mouseDownFirstFrame:
				resetSwipe()
				
			mouseCurrentPosition = get_viewport().get_mouse_position()	
			currentRot = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
			distance = mouseCurrentPosition - mouseInitialPosition
			
			if abs(mouseCurrentPosition.x - mouseLastFramePosition.x) < 50.0:
				holdTime += get_process_delta_time()
			else:
				holdTime = 0.0
			
			var canRotate = true
			
			if startDay == 0 and currentRot <= 269 and currentRot > 180:
				if wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0) > 269:
					set_rotation_degrees(268)
					canRotate = false
					velocity = 0
			
			if startDay == 20 and currentRot < 350 and currentRot >= 286:
				if wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0) < 286:
					set_rotation_degrees(287)
					canRotate = false
					velocity = 0
			
			if canRotate:
				set_rotation_degrees(wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0))
			
			mouseLastFramePosition = mouseCurrentPosition
		
		if !mouseDown and abs(velocity) > 0 and holdTime < 0.1:
			if velocity > 0:
				velocity -= deceleration * delta
				if velocity < 0:
					velocity = 0
			elif velocity < 0:
				velocity += deceleration * delta
				if velocity > 0:
					velocity = 0
			
			set_rotation_degrees(wrap(get_rotation_degrees() + (velocity * delta), 0.0, 360.0))

		if previousRot > 270 and previousRot < 360 and currentRot > 180 and currentRot < 270:
			weatherRequest.nextDay()
		elif previousRot > 180 and previousRot < 270 and currentRot > 270 and currentRot < 360:
			weatherRequest.previousDay()
		
		previousRot = currentRot

func _on_button_down() -> void:
	if requestReady:
		mouseDown = true
		mouseDownFirstFrame = true
		hasClicked = true
		rotationOnMouseDown = wrapf(rotation, -PI, PI)
		timeOnMouseDown = Time.get_unix_time_from_system()

func _on_button_up() -> void:
	if requestReady:
		mouseDown = false
		
		if hasClicked:
			var a = angle_difference(rotationOnMouseDown, wrapf(rotation, -PI, PI)) # degrees in radians from -PI to +PI
			var t = Time.get_unix_time_from_system() - timeOnMouseDown # time in seconds
			velocity = clampf(rad_to_deg(a) / t, -135.0, 135.0) 
			#print(velocity)
			hasClicked = false

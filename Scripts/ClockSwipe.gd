extends TextureButton
@export_node_path("HTTPRequest") var weatherRequestPath
var weatherRequest: WeatherRequest
var mouseDown: bool = false
var mouseDownFirstFrame: bool = true
var rotationInitial: float = 0.0
var distance = Vector2(0,0)
var mouseCurrentPosition = Vector2(0,0)
var mouseLastFramePosition = Vector2(0,0)
var mouseInitialPosition = Vector2(0,0)
var deceleration: float = 270.0
var requestReady: bool = false
var currentRot: float
var previousRot: float
var canRotate: bool = true
var movingClockwise = 0
var currentSegment = 0;
var previousSegment = 0;
var clockHourDates: Array[int]
var startDay
var previousStartDay
@export_node_path("TextureRect") var dialNow

func _ready():
	weatherRequest = get_node_or_null(weatherRequestPath)
	
	startDay = weatherRequest.startDay
	
	for x in 24:
		clockHourDates.append(startDay)

func resetSwipe():
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
				
			ApplyRotation()

		CheckDayChange()
		
		previousRot = currentRot
		
		if startDay == 7:
			get_node_or_null(dialNow).show()
			get_node_or_null(dialNow).set_rotation_degrees(90 + (roundi(Time.get_time_dict_from_system().hour) * 15))
		else:
			get_node_or_null(dialNow).hide()

func ApplyRotation():
	mouseCurrentPosition = get_viewport().get_mouse_position()	
	currentRot = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
	distance = mouseCurrentPosition - mouseInitialPosition

	var canRotate = true
	
	#Rotation at past extreme
	if startDay == 0 and currentRot <= 269 and currentRot > 180:
		if wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0) > 269:
			set_rotation_degrees(268)
			canRotate = false
	
	#Rotation at future extreme
	if startDay == 20 and currentRot < 350 and currentRot >= 286:
		if wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0) < 286:
			set_rotation_degrees(287)
			canRotate = false
			#velocity = 0
	
	if canRotate:
		set_rotation_degrees(wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0))
		for x in range(24):
			weatherRequest.windRotation[x].UpdateRotation(get_rotation_degrees())
	
	mouseLastFramePosition = mouseCurrentPosition

func CheckDayChange():
	#If swipe across midnight
		if previousRot > 270 and previousRot < 360 and currentRot > 180 and currentRot <= 270:
			weatherRequest.nextDay()
		elif previousRot > 180 and previousRot < 270 and currentRot >= 270 and currentRot < 360:
			weatherRequest.previousDay()
	
func _on_button_down() -> void:
	if requestReady:
		mouseDown = true
		mouseDownFirstFrame = true

func _on_button_up() -> void:
	if requestReady:
		mouseDown = false

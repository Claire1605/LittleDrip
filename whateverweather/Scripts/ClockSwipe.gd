extends TextureButton
@export_node_path("HTTPRequest") var weatherRequest
@export_node_path("Label") var clockPreviousDay
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

func _ready():
	'var startDay = get_node_or_null(weatherRequest).startDay
	
	for x in 24:
		clockHourDates.append(startDay)
	
	var h = Time.get_datetime_dict_from_system().hour
	
	if h < 12: # before 12 oclock
		for x in range(h):
			clockHourDates[x] = startDay
			print(str(x) + " " + str(clockHourDates[x]))
		for x in range(12):
			clockHourDates[h + x] = startDay
			print(str(h + x) + " " + str(clockHourDates[h + x]))
		for x in range(12 - h):
			clockHourDates[23 - x] = startDay - 1
			print(str(23 - x) + " " + str(clockHourDates[23 - x]))
	elif h >= 12: # after 12 oclock
		for x in range(h - 12):
			clockHourDates[x] = startDay + 1
			print(str(x) + " " + str(clockHourDates[x]))
		for x in range(12):
			clockHourDates[h - 12 + x] = startDay
			print(str(h - 12 + x) + " " + str(clockHourDates[h - 12 + x]))
		for x in range(23 - h):
			clockHourDates[23 - x] = startDay
			print(str(23 - x) + " " + str(clockHourDates[23 - x]))'

func resetSwipe():
	holdTime = 0.0
	velocity = 0.0
	rotationInitial = get_rotation_degrees()
	
	mouseInitialPosition = get_viewport().get_mouse_position()
	mouseDownFirstFrame = false

func checkRotation():
	if mouseCurrentPosition.x - mouseLastFramePosition.x > 0:
		movingClockwise = 1
	elif mouseCurrentPosition.x - mouseLastFramePosition.x < 0:
		movingClockwise = -1
	else:
		movingClockwise = 0
	
	var r = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
	
	if r > 255 and r <= 270:
		currentSegment = 0
	elif r > 240 and r <= 255:
		currentSegment = 1
	elif r > 225 and r <= 240:
		currentSegment = 2
	elif r > 210 and r <= 225:
		currentSegment = 3
	elif r > 195 and r <= 210:
		currentSegment = 4
	elif r > 180 and r <= 195:
		currentSegment = 5
	elif r > 165 and r <= 180:
		currentSegment = 6
	elif r > 150 and r <= 165:
		currentSegment = 7
	elif r > 135 and r <= 150:
		currentSegment = 8
	elif r > 120 and r <= 135:
		currentSegment = 9
	elif r > 105 and r <= 120:
		currentSegment = 10
	elif r > 90 and r <= 105:
		currentSegment = 11
	elif r > 75 and r <= 90:
		currentSegment = 12
	elif r > 60 and r <= 75:
		currentSegment = 13
	elif r > 45 and r <= 60:
		currentSegment = 14
	elif r > 30 and r <= 45:
		currentSegment = 15
	elif r > 15 and r <= 30:
		currentSegment = 16
	elif r > 0 and r <= 15:
		currentSegment = 17
	elif r > 345 and r <= 360:
		currentSegment = 18
	elif r > 330 and r <= 345:
		currentSegment = 19
	elif r > 315 and r <= 330:
		currentSegment = 20
	elif r > 300 and r <= 315:
		currentSegment = 21
	elif r > 285 and r <= 300:
		currentSegment = 22
	elif r > 270 and r <= 285:
		currentSegment = 23
		
	if currentSegment != previousSegment:
		if movingClockwise > 0: #back in time
			if currentSegment > previousSegment: #looped around
				for s in range(currentSegment):
					updateClockDate(currentSegment - s, 1)
				for s in range(23 - previousSegment):
					updateClockDate(23 - s, 1)
			else:
				for s in range(previousSegment - currentSegment):
					updateClockDate(previousSegment - s, 1)
		elif movingClockwise < 0: #forward in time
			if currentSegment > previousSegment:
				for s in range(currentSegment - previousSegment):
					updateClockDate(previousSegment + s, -1)
			else: # looped around
				for s in range(23 - previousSegment + 1):
					updateClockDate(previousSegment + s, -1)
				for s in range(currentSegment):
					updateClockDate(s, -1)
	
	previousSegment = currentSegment

func updateClockDate(segment, clockwise):
	var s = wrap(segment + 12, 0, 24)
	
	if clockwise > 0:
		if segment >= 12 and clockHourDates[s] != get_node_or_null(weatherRequest).startDay:
			clockHourDates[s] = get_node_or_null(weatherRequest).startDay
		elif segment < 12 and clockHourDates[s] != get_node_or_null(weatherRequest).startDay:
			clockHourDates[s] = get_node_or_null(weatherRequest).startDay - 1
	elif clockwise < 0:
		if segment >= 12 and clockHourDates[s] != get_node_or_null(weatherRequest).startDay:
			clockHourDates[s] = get_node_or_null(weatherRequest).startDay + 1
		elif segment < 12 and clockHourDates[s] != get_node_or_null(weatherRequest).startDay:
			clockHourDates[s] = get_node_or_null(weatherRequest).startDay
	
	get_node_or_null(weatherRequest).populateForecastTable()

func _process(delta: float) -> void:
	if requestReady:	
		if mouseDown:  # Left mouse button.
			if mouseDownFirstFrame:
				resetSwipe()
				
			mouseCurrentPosition = get_viewport().get_mouse_position()	
			currentRot = clampf(wrap(get_rotation_degrees(), 0.0, 360.0), 0.0, 360.0)
			distance = mouseCurrentPosition - mouseInitialPosition
			#checkRotation()
			
			if abs(mouseCurrentPosition.x - mouseLastFramePosition.x) < 50.0:
				holdTime += get_process_delta_time()
			else:
				holdTime = 0.0
			
			'if get_node_or_null(weatherRequest).clockDay == 0 and !get_node_or_null(clockPreviousDay).visible and wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0) > 270.0:
				#set_rotation_degrees(271.0)
				#get_node_or_null(weatherRequest).clockDay = 0
				#resetSwipe()
				print("nope")
				#set_rotation_degrees(wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0))
			elif get_node_or_null(weatherRequest).clockDay > 20:
				print(currentRot)
			else:
				set_rotation_degrees(wrap(rotationInitial + (distance.x * 0.15), 0.0, 360.0))
				print(currentRot)
				print(get_node_or_null(weatherRequest).clockDay)'
			
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
			get_node_or_null(weatherRequest).nextDay()
		elif previousRot > 180 and previousRot < 270 and currentRot > 270 and currentRot < 360:
			get_node_or_null(weatherRequest).previousDay()
			
		#update date text
		if previousRot > 90 and previousRot < 180 and currentRot > 0 and currentRot < 90:
			get_node_or_null(weatherRequest).increaseClockDates()
			get_node_or_null(weatherRequest).updateClockLabels()
		elif previousRot > 0 and previousRot < 90 and currentRot > 90 and currentRot < 180:
			get_node_or_null(weatherRequest).decreaseClockDates()
			get_node_or_null(weatherRequest).updateClockLabels()
		
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
			print(velocity)
			hasClicked = false

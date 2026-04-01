extends TextureButton
@export_node_path("HTTPRequest") var weatherRequest
@export_node_path("Label") var clockPreviousDay
var mouseDown: bool = false
var hasClicked: bool = false
var mouseDownFirstFrame: bool = true
var rotationInitial: float = 0.0
var rotationOnRelease: float = 0.0
var distance = Vector2(0,0)
var mouseCurrentPosition = Vector2(0,0)
var mouseLastFramePosition = Vector2(0,0)
var mouseInitialPosition = Vector2(0,0)
var swipePower: float = 0.0
var deceleration: float = 0.0
var decelerationTime: float = 1.0
var speedMultiplier: float = 0.2
var holdTime: float = 0.2
var t: float = 0.0
var requestReady: bool = false
var currentRot: float
var previousRot: float
var canRotate: bool = true

func resetSwipe():
	swipePower = 0.0
	deceleration = 0.0
	t = 0.0
	holdTime = 0.0
	rotationInitial = get_rotation_degrees()
	
	mouseInitialPosition = get_viewport().get_mouse_position()
	mouseDownFirstFrame = false

func _process(delta: float) -> void:
	if requestReady:
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
		
		if !mouseDown and abs(swipePower) > 0 and holdTime < 0.1:
			deceleration = clampf(deceleration + (get_process_delta_time() * decelerationTime), 0.0, 1.0)

			var t = 1.0 - pow(1.0 - deceleration, 3.0) * speedMultiplier #https://easings.net/#easeOutCubic
			var rot = lerp(rotationOnRelease, rotationOnRelease + swipePower, t)
			set_rotation_degrees(wrap(rot, 0.0, 270.0))

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

func _on_button_up() -> void:
	if requestReady:
		mouseDown = false
		
		if hasClicked:
			rotationOnRelease = get_rotation_degrees()
			swipePower = clampf(distance.x, -540.0, 540.0)
			decelerationTime = abs(swipePower) / 750.0
			hasClicked = false

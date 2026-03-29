extends TextureButton
var mouseDown: bool = false
var hasClicked: bool = false
var mouseDownFirstFrame: bool = true
var rotationFirstFrame
var rotationOnButtonUp
var dif
var mousePosition = Vector2(0,0)
var mousePositionLastFrame = Vector2(0,0)
var mouseDownPosition = Vector2(0,0)
var mouseSwipeDistance: float = 0
var speed: float = 0
var deceleration: float = 0.0
var decelerationTime: float = 1.0
var speedMultiplier: float = 0.2
var holdTime: float = 0.2

func _process(delta: float) -> void:
	if mouseDown:  # Left mouse button.
		speed = 0.0
		deceleration = 0.0
		mouseSwipeDistance = 0.0
		
		mousePosition = get_viewport().get_mouse_position()
		
		if abs(mousePosition.x - mousePositionLastFrame.x) < 50.0:
			holdTime += get_process_delta_time()
			#mouseDownPosition = get_viewport().get_mouse_position()
		else:
			holdTime = 0
		
		if mouseDownFirstFrame:
			rotationFirstFrame = get_node_or_null(get_path()).get_rotation_degrees()
			mouseDownPosition = get_viewport().get_mouse_position()
			mouseDownFirstFrame = false
	
		if !mouseDownFirstFrame:
			dif = mousePosition - mouseDownPosition
		
		get_node_or_null(get_path()).set_rotation_degrees(rotationFirstFrame + (dif.x * 0.15))
	
	if !mouseDown:
		if hasClicked:
			#SWIPE
			mouseSwipeDistance = get_viewport().get_mouse_position().x - mouseDownPosition.x
			if mouseSwipeDistance > 540:
				mouseSwipeDistance = 540
			speed = mouseSwipeDistance
			decelerationTime = abs(speed) / 750.0
			rotationOnButtonUp = get_node_or_null(get_path()).get_rotation_degrees()
			hasClicked = false
			
		if abs(speed) > 0 and holdTime < 0.1:
			deceleration += get_process_delta_time() * decelerationTime
			if deceleration > 1.0:
				deceleration = 1.0
			
			var t = 1 - pow(1 - deceleration, 3) #https://easings.net/#easeOutCubic
			var rot = lerp(rotationOnButtonUp, rotationOnButtonUp + mouseSwipeDistance, t) * speedMultiplier
			get_node_or_null(get_path()).set_rotation_degrees(rot)
	
	mousePositionLastFrame = mousePosition


func _on_button_down() -> void:
	mouseDownFirstFrame = true
	mouseDown = true
	hasClicked = true

func _on_button_up() -> void:
	mouseDown = false
	

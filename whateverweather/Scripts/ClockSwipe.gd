extends TextureButton
var mouseDown: bool = false
var hasClicked: bool = false
var mouseDownFirstFrame: bool = true
var rotationFirstFrame
var dif
var mousePosition = Vector2(0,0)
var mouseDownPosition = Vector2(0,0)
var mouseSwipeDistance = Vector2(0,0)
var speed = Vector2(0,0)
var deceleration: float = 0.0
var decelerationTime: float = 1.0
var speedMultiplier: float = 0.15

func _process(delta: float) -> void:
	if mouseDown:  # Left mouse button.
		speed = 0.0
		deceleration = 0.0
		mouseSwipeDistance = Vector2(0,0)
		
		mousePosition = get_viewport().get_mouse_position()
		
		if mouseDownFirstFrame:
			rotationFirstFrame = get_node_or_null(get_path()).rotation
			mouseDownPosition = get_viewport().get_mouse_position()
			mouseDownFirstFrame = false
	
		if !mouseDownFirstFrame:
			dif = mousePosition - mouseDownPosition
		
		get_node_or_null(get_path()).rotation = rotationFirstFrame + (dif.x * 0.002)
	
	if !mouseDown:
		mouseDownFirstFrame = true
		
		#SWIPE
		mouseSwipeDistance = get_viewport().get_mouse_position() - mouseDownPosition
		speed = mouseSwipeDistance
		decelerationTime = abs(speed.length()) / 750.0
		
		deceleration += get_process_delta_time() / decelerationTime
		if deceleration > 1.0:
			deceleration = 1.0
		speed = lerp(mouseSwipeDistance, Vector2(0,0), deceleration) * speedMultiplier
		get_node_or_null(get_path()).rotation -= speed.x
		
		print(mouseSwipeDistance)


func _on_button_down() -> void:
	mouseDown = true


func _on_button_up() -> void:
	mouseDown = false

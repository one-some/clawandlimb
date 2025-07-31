extends CharacterBody3D

@onready var navigation_agent = $NavigationAgent3D
@onready var reeval_timer = $NavReEvalTimer

@export var target: Node3D
@export var movement_speed: float = 4.0
@export var gravity: float = 14.0

func _ready() -> void:
	navigation_agent.target_position = target.global_position
	navigation_agent.velocity_computed.connect(_on_velocity_computed)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	self.velocity.x = safe_velocity.x
	self.velocity.z = safe_velocity.z
	self.move_and_slide()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if navigation_agent.is_navigation_finished():
		return

	var next_path_pos = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	navigation_agent.velocity = direction * movement_speed


func _on_nav_re_eval_timer_timeout() -> void:
	navigation_agent.target_position = target.global_position

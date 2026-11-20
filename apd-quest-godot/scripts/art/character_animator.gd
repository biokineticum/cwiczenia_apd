extends Node
class_name CharacterAnimator
## Drives Grab3D rigged clips (walk / run) + a gentle procedural idle.
## Attach under a character Visual root that contains AnimationPlayer + Skeleton3D.

enum State { IDLE, WALK, RUN }

@export var walk_speed_threshold: float = 0.35
@export var run_speed_threshold: float = 3.8
@export var blend_fade: float = 0.18
@export var idle_breath_amp: float = 0.028
@export var idle_sway_amp: float = 0.022

var _anim: AnimationPlayer
var _skeleton: Skeleton3D
var _state: State = State.IDLE
var _phase: float = 0.0
var _bone_spine: int = -1
var _bone_spine01: int = -1
var _bone_head: int = -1
var _bone_larm: int = -1
var _bone_rarm: int = -1
var _clip_walk: StringName = &""
var _clip_run: StringName = &""
var _ready_ok: bool = false


func _ready() -> void:
	# Parent is the character Visual after reparent from StylizedCharacterBuilder.
	call_deferred("setup", get_parent())


func setup(from_root: Node) -> void:
	if from_root == null or not is_instance_valid(from_root):
		from_root = get_parent()
	if from_root == null:
		return
	_anim = _find_animation_player(from_root)
	_skeleton = _find_skeleton(from_root)
	_resolve_clips()
	_cache_bones()
	if _anim:
		for clip in _anim.get_animation_list():
			var a: Animation = _anim.get_animation(clip)
			if a:
				a.loop_mode = Animation.LOOP_LINEAR
		_anim.active = true
	_ready_ok = _anim != null or _skeleton != null
	_phase = randf() * TAU
	play_idle(true)
	if _ready_ok:
		print(
			"[CharacterAnimator] clips walk=%s run=%s skeleton=%s"
			% [_clip_walk, _clip_run, _skeleton != null]
		)


func set_locomotion_speed(horizontal_speed: float) -> void:
	if not _ready_ok:
		return
	if horizontal_speed >= run_speed_threshold and _clip_run != &"":
		_set_state(State.RUN)
	elif horizontal_speed >= walk_speed_threshold and _clip_walk != &"":
		_set_state(State.WALK)
	else:
		_set_state(State.IDLE)


func play_idle(force: bool = false) -> void:
	_set_state(State.IDLE, force)


func play_walk(force: bool = false) -> void:
	_set_state(State.WALK, force)


func _process(delta: float) -> void:
	if not _ready_ok:
		return
	if _state != State.IDLE:
		return
	if _skeleton == null:
		return
	_phase += delta
	_apply_procedural_idle()


func _set_state(next: State, force: bool = false) -> void:
	if not force and next == _state:
		return
	_state = next
	match next:
		State.IDLE:
			if _anim and _anim.is_playing():
				_anim.stop()
			if _skeleton:
				_skeleton.reset_bone_poses()
			_apply_procedural_idle()
		State.WALK:
			_clear_procedural()
			_play_clip(_clip_walk)
		State.RUN:
			_clear_procedural()
			_play_clip(_clip_run if _clip_run != &"" else _clip_walk)


func _play_clip(clip: StringName) -> void:
	if _anim == null or clip == &"":
		return
	if _anim.current_animation == String(clip) and _anim.is_playing():
		return
	_anim.play(clip, blend_fade)


func _apply_procedural_idle() -> void:
	if _skeleton == null:
		return
	var breath := sin(_phase * 1.55) * idle_breath_amp
	var sway := sin(_phase * 0.85) * idle_sway_amp
	var arm := sin(_phase * 1.1) * 0.04
	_set_bone_euler(_bone_spine, Vector3(breath * 0.6, sway, 0.0))
	_set_bone_euler(_bone_spine01, Vector3(breath, sway * 0.5, 0.0))
	_set_bone_euler(_bone_head, Vector3(breath * 0.35, -sway * 0.7, 0.0))
	_set_bone_euler(_bone_larm, Vector3(0.05 + arm * 0.3, 0.0, 0.08 + arm))
	_set_bone_euler(_bone_rarm, Vector3(0.05 - arm * 0.3, 0.0, -0.08 - arm))


func _clear_procedural() -> void:
	if _skeleton:
		_skeleton.reset_bone_poses()


func _set_bone_euler(bone_idx: int, euler: Vector3) -> void:
	if bone_idx < 0 or _skeleton == null:
		return
	var q := Quaternion.from_euler(euler)
	_skeleton.set_bone_pose_rotation(bone_idx, q)


func _cache_bones() -> void:
	if _skeleton == null:
		return
	_bone_spine = _find_bone(["Spine", "spine", "Spine01"])
	_bone_spine01 = _find_bone(["Spine01", "Spine1", "spine.001"])
	_bone_head = _find_bone(["Head", "head"])
	_bone_larm = _find_bone(["LeftArm", "LeftUpperArm", "upper_arm.L"])
	_bone_rarm = _find_bone(["RightArm", "RightUpperArm", "upper_arm.R"])


func _find_bone(names: Array) -> int:
	for n in names:
		var idx := _skeleton.find_bone(String(n))
		if idx >= 0:
			return idx
	return -1


func _resolve_clips() -> void:
	_clip_walk = &""
	_clip_run = &""
	if _anim == null:
		return
	var names := _anim.get_animation_list()
	for n in names:
		var low := String(n).to_lower()
		if _clip_walk == &"" and ("walk" in low):
			_clip_walk = StringName(n)
		if _clip_run == &"" and ("run" in low):
			_clip_run = StringName(n)
	# Quaternius-style Female_Walk / Female_Idle fallbacks
	if _clip_walk == &"":
		for n in names:
			var low := String(n).to_lower()
			if "idle" in low:
				continue
			if "locomotion" in low or "move" in low:
				_clip_walk = StringName(n)
				break


func _find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var f := _find_animation_player(c)
		if f:
			return f
	return null


func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var f := _find_skeleton(c)
		if f:
			return f
	return null

extends Node3D
## Echo 3D — layout wg konsultacji odbioru fizyki:
## 1 rząd propów + 1 linia slotów 1–4; minima spacing; wolniejszy chód w answer.
## Pomarańczowe kółko „od nowa” (walk-in) czyści układ bez restartu questa.

signal arrangement_complete(word_ids: PackedStringArray)
signal arrangement_changed(word_ids: PackedStringArray)
signal board_reset

const MeshFactory = preload("res://scripts/art/mesh_factory.gd")
const EchoPropScript = preload("res://scripts/listening/echo_prop.gd")
const EchoSlotScript = preload("res://scripts/listening/echo_slot.gd")
const WalkZone = preload("res://scripts/world/walk_confirm_zone.gd")

## Minima z konsultacji (środek–środek, metry świata).
const PICKUP_SPACING := 2.8
const SLOT_SPACING := 2.5
const ROW_GAP := 3.0 # pickup ↔ slot
const SLOT_Z := -1.6
const PROP_Z := SLOT_Z + ROW_GAP # +3.0 m
const ANSWER_SPEED_MUL := 0.6 # ×0.55–0.7 eksploracji
const PICK_COOLDOWN_MS := 500
const RESET_REARM_SEC := 0.85

var _slots: Array = []
var _props: Array = []
var _carry: Area3D = null
var _player: Node3D = null
var _active: bool = false
var _speech: Node = null
var _pick_ready_ms: int = 0
var _saved_player_speed: float = -1.0
var _saved_player_accel: float = -1.0
var _overlap_pulse_ms: int = 0
var _reset_zone: Area3D = null
var _reset_busy: bool = false


func setup(
	sequence_ids: PackedStringArray,
	sequence_icons: PackedStringArray,
	origin: Vector3,
	speech: Node = null
) -> void:
	_speech = speech
	_clear_children()
	_slots.clear()
	_props.clear()
	_carry = null
	_reset_zone = null
	_reset_busy = false
	_active = true
	_pick_ready_ms = 0
	position = origin
	_player = _find_player()
	_apply_answer_speed(true)
	var n := sequence_ids.size()
	var line_w := maxf(PICKUP_SPACING, SLOT_SPACING) * float(maxi(n - 1, 1))
	var width := line_w + 4.0
	var depth := ROW_GAP + 4.0
	MeshFactory.add_mesh(
		self,
		MeshFactory.box(Vector3(width, 0.06, depth)),
		MeshFactory.mat(Color(0.78, 0.62, 0.4), 0.92),
		Vector3(0, 0.02, (PROP_Z + SLOT_Z) * 0.5)
	)
	# EchoSlots — jedna linia 1→4
	var slots_root := Node3D.new()
	slots_root.name = "EchoSlots"
	add_child(slots_root)
	var slot_start := -0.5 * SLOT_SPACING * float(n - 1)
	for i in n:
		var slot: Area3D = EchoSlotScript.new()
		slots_root.add_child(slot)
		slot.setup(i, Vector3(slot_start + float(i) * SLOT_SPACING, 0.0, SLOT_Z))
		slot.place_requested.connect(_on_slot_place)
		_slots.append(slot)
	# EchoPickups — jeden rząd, X przetasowane względem sekwencji
	var pickups_root := Node3D.new()
	pickups_root.name = "EchoPickups"
	add_child(pickups_root)
	var prop_xs: Array = []
	var prop_start := -0.5 * PICKUP_SPACING * float(n - 1)
	for i in n:
		prop_xs.append(prop_start + float(i) * PICKUP_SPACING)
	prop_xs.shuffle()
	for i in n:
		var prop: Area3D = EchoPropScript.new()
		pickups_root.add_child(prop)
		var pos := Vector3(float(prop_xs[i]), 0.0, PROP_Z)
		prop.setup(str(sequence_ids[i]), str(sequence_icons[i]), pos)
		prop.picked.connect(_on_prop_picked)
		_props.append(prop)
	_spawn_reset_zone(line_w)
	_assert_no_area_overlap()
	_refresh_highlights()
	_set_props_pickable(true)
	print(
		"[EchoBoard] pickups Δ=%.1fm @z=%.1f | slots Δ=%.1fm @z=%.1f | row_gap=%.1fm | speed×%.2f | reset pad"
		% [PICKUP_SPACING, PROP_Z, SLOT_SPACING, SLOT_Z, ROW_GAP, ANSWER_SPEED_MUL]
	)


func teardown() -> void:
	_active = false
	_carry = null
	_reset_busy = false
	if _reset_zone and is_instance_valid(_reset_zone):
		_reset_zone.set_armed(false)
	_reset_zone = null
	_apply_answer_speed(false)
	_drop_carry_visual()
	queue_free()


func get_placed_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for s in _slots:
		out.append(str(s.filled_word_id))
	return out


func is_complete() -> bool:
	for s in _slots:
		if s.is_empty():
			return false
	return true


func has_attempt_progress() -> bool:
	if _carry != null:
		return true
	for s in _slots:
		if not s.is_empty():
			return true
	return false


func force_arrange(sequence_ids: PackedStringArray) -> void:
	if not _active:
		return
	_drop_carry_visual()
	_carry = null
	for i in mini(sequence_ids.size(), _slots.size()):
		var want := str(sequence_ids[i])
		var prop: Area3D = null
		for p in _props:
			if str(p.word_id) == want and not p.placed:
				prop = p
				break
		if prop == null:
			continue
		_slots[i].place_prop(prop)
	arrangement_changed.emit(get_placed_ids())
	if is_complete():
		arrangement_complete.emit(get_placed_ids())


func reset_board() -> void:
	_drop_carry_visual()
	_carry = null
	_pick_ready_ms = Time.get_ticks_msec() + PICK_COOLDOWN_MS
	for s in _slots:
		for c in s.get_children():
			if c is Area3D and c.has_method("reset_home"):
				s.remove_child(c)
				var pickups: Node = get_node_or_null("EchoPickups")
				if pickups:
					pickups.add_child(c)
				else:
					add_child(c)
				c.placed = false
				c.carried = false
				c.set_deferred("monitoring", true)
				c.visible = true
				c.scale = Vector3.ONE
				c.position = c._home
		if s.has_method("clear_fill"):
			s.clear_fill()
		else:
			s.filled_word_id = ""
			s.set_highlight(false)
	for p in _props:
		var prop: Area3D = p as Area3D
		if prop == null:
			continue
		var want_parent: Node = get_node_or_null("EchoPickups")
		if want_parent == null:
			want_parent = self
		if prop.get_parent() != want_parent:
			var par: Node = prop.get_parent()
			if par:
				par.remove_child(prop)
			want_parent.add_child(prop)
		prop.placed = false
		prop.carried = false
		prop.set_deferred("monitoring", true)
		prop.visible = true
		prop.scale = Vector3.ONE
		prop.position = prop._home
	_refresh_highlights()
	_set_props_pickable(true)
	arrangement_changed.emit(PackedStringArray())
	board_reset.emit()


func _spawn_reset_zone(line_w: float) -> void:
	# Bok planszy — daleko od slotów/propów, żeby nie czyścić przypadkiem.
	var zone: Area3D = WalkZone.new()
	zone.name = "EchoResetPad"
	add_child(zone)
	var side_x := 0.5 * line_w + 2.2
	var mid_z := (PROP_Z + SLOT_Z) * 0.5
	zone.setup("undo", "undo", Vector3(side_x, 0.0, mid_z), Color(0.92, 0.62, 0.28))
	zone.walked_in.connect(_on_reset_zone)
	_reset_zone = zone


func _on_reset_zone(_zone: Area3D) -> void:
	call_deferred("_reset_from_walk_deferred")


func _reset_from_walk_deferred() -> void:
	if not _active or _reset_busy:
		_rearm_reset_zone_later()
		return
	if not has_attempt_progress():
		if _speech:
			_speech.play_text("Tu możesz zacząć od nowa, jak pomylisz kolejność.")
		_rearm_reset_zone_later()
		return
	_reset_busy = true
	reset_board()
	if _speech:
		_speech.play_text("Od nowa. Weź obrazki znowu.")
	_rearm_reset_zone_later()


func _rearm_reset_zone_later() -> void:
	# One-shot WalkZone — po zejściu / krótkiej przerwie znów aktywne.
	var tree := get_tree()
	if tree == null:
		_reset_busy = false
		return
	await tree.create_timer(RESET_REARM_SEC).timeout
	if not _active or not is_instance_valid(self):
		return
	_reset_busy = false
	if _reset_zone and is_instance_valid(_reset_zone):
		# Jeśli dziecko dalej stoi na padzie — czekaj na wyjście (set_armed czyści dwell).
		_reset_zone.set_armed(true)


func _on_prop_picked(prop: Area3D) -> void:
	# body_entered → nie mutuj Area/CollisionObject w tym samym callbacku.
	call_deferred("_pick_prop_deferred", prop)


func _pick_prop_deferred(prop: Area3D) -> void:
	if not _active or not is_instance_valid(prop) or prop.placed or prop.carried:
		return
	if Time.get_ticks_msec() < _pick_ready_ms:
		return
	if _carry != null:
		if _speech:
			_speech.play_text("Najpierw włóż to do kółka z cyfrą.")
		return
	# Ambiguous: dwa Area naraz → nie bierz żadnego (konsultacja §6).
	var near_count := _count_props_overlapping_player()
	if near_count >= 2:
		_pulse_ambiguous()
		return
	_carry = prop
	prop.carried = true
	prop.set_deferred("monitoring", false)
	_set_props_pickable(false)
	_attach_to_player(prop)
	_pick_ready_ms = Time.get_ticks_msec() + PICK_COOLDOWN_MS
	_refresh_highlights()
	if _speech:
		_speech.play_text("Dobrze. Idź do kółka numer %d." % _next_digit())


func _on_slot_place(slot: Area3D) -> void:
	# place_requested leci z _physics_process — reparent deferred.
	call_deferred("_place_on_slot_deferred", slot)


func _place_on_slot_deferred(slot: Area3D) -> void:
	if not _active or not is_instance_valid(slot) or _carry == null:
		return
	if not slot.is_empty():
		return
	var expected := _next_slot_index()
	if slot.slot_index != expected:
		# Soft: bez place, bez resetu sekwencji od ocierania.
		if _speech and Time.get_ticks_msec() > _overlap_pulse_ms:
			_overlap_pulse_ms = Time.get_ticks_msec() + 1200
			_speech.play_text("To kółko numer %d. Idź do numeru %d." % [slot.digit, expected + 1])
		return
	var prop := _carry
	_carry = null
	_detach_from_player(prop)
	slot.place_prop(prop)
	arrangement_changed.emit(get_placed_ids())
	_refresh_highlights()
	_pick_ready_ms = Time.get_ticks_msec() + PICK_COOLDOWN_MS
	if is_complete():
		_set_props_pickable(false)
		if _reset_zone and is_instance_valid(_reset_zone):
			_reset_zone.set_armed(false)
		if _speech:
			_speech.play_text("Brawo, wszystkie na miejscu.")
		arrangement_complete.emit(get_placed_ids())
	else:
		_set_props_pickable(true)
		if _speech:
			_speech.play_text("Teraz następny obrazek.")


func _count_props_overlapping_player() -> int:
	if _player == null:
		return 0
	var count := 0
	var ppos := _player.global_position
	for p in _props:
		var prop: Area3D = p as Area3D
		if prop == null or prop.placed or prop.carried or not prop.monitoring:
			continue
		var d := Vector2(prop.global_position.x - ppos.x, prop.global_position.z - ppos.z).length()
		# PICK_RADIUS 0.35 + capsule ~0.35
		if d <= 0.7:
			count += 1
	return count


func _pulse_ambiguous() -> void:
	if Time.get_ticks_msec() < _overlap_pulse_ms:
		return
	_overlap_pulse_ms = Time.get_ticks_msec() + 900
	# Soft feedback — bez auto-wyboru (konsultacja §6).
	if _speech:
		_speech.play_text("Wybierz jeden obrazek.")


func _set_props_pickable(enabled: bool) -> void:
	for p in _props:
		var prop: Area3D = p as Area3D
		if prop == null or prop.placed or prop.carried:
			continue
		prop.set_deferred("monitoring", enabled)


func _next_slot_index() -> int:
	for i in _slots.size():
		if _slots[i].is_empty():
			return i
	return _slots.size()


func _next_digit() -> int:
	return _next_slot_index() + 1


func _refresh_highlights() -> void:
	var next_i := _next_slot_index()
	for i in _slots.size():
		var is_next: bool = (i == next_i and _slots[i].is_empty())
		_slots[i].set_highlight(is_next)
		# Tylko aktywne kółko + gdy niesie prop.
		_slots[i].set_deferred("monitoring", is_next and _carry != null)


func _apply_answer_speed(enable: bool) -> void:
	if _player == null:
		_player = _find_player()
	if _player == null:
		return
	if enable:
		if _saved_player_speed < 0.0:
			_saved_player_speed = float(_player.get("speed"))
			_saved_player_accel = float(_player.get("acceleration"))
		_player.set("speed", _saved_player_speed * ANSWER_SPEED_MUL)
		_player.set("acceleration", maxf(8.0, _saved_player_accel * 0.7))
	else:
		if _saved_player_speed >= 0.0:
			_player.set("speed", _saved_player_speed)
			_player.set("acceleration", _saved_player_accel)
		_saved_player_speed = -1.0
		_saved_player_accel = -1.0


func _assert_no_area_overlap() -> void:
	# Debug: żadne dwa Area Echo nie powinny się przecinać w XZ.
	var centers: Array = []
	var radii: Array = []
	for p in _props:
		centers.append((p as Node3D).position)
		radii.append(0.35)
	for s in _slots:
		centers.append((s as Node3D).position)
		radii.append(0.38)
	for i in centers.size():
		for j in range(i + 1, centers.size()):
			var a: Vector3 = centers[i]
			var b: Vector3 = centers[j]
			var d := Vector2(a.x - b.x, a.z - b.z).length()
			var need: float = float(radii[i]) + float(radii[j])
			if d < need:
				push_warning("[EchoBoard] Area overlap XZ d=%.2f need≥%.2f (i=%d j=%d)" % [d, need, i, j])


func _attach_to_player(prop: Area3D) -> void:
	if _player == null:
		_player = _find_player()
	if _player == null:
		return
	if not is_instance_valid(prop):
		return
	var par: Node = prop.get_parent()
	if par:
		par.remove_child(prop)
	_player.add_child(prop)
	prop.position = Vector3(0.0, 1.05, 0.45)
	prop.scale = Vector3(0.75, 0.75, 0.75)


func _detach_from_player(prop: Area3D) -> void:
	if not is_instance_valid(prop):
		return
	var par: Node = prop.get_parent()
	if par:
		par.remove_child(prop)


func _drop_carry_visual() -> void:
	if _carry == null:
		return
	var prop := _carry
	_carry = null
	_detach_from_player(prop)
	var pickups: Node = get_node_or_null("EchoPickups")
	if pickups:
		pickups.add_child(prop)
	else:
		add_child(prop)
	prop.carried = false
	prop.set_deferred("monitoring", true)
	prop.position = prop._home
	prop.scale = Vector3.ONE


func _find_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var nodes := tree.get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0] as Node3D


func _clear_children() -> void:
	for c in get_children():
		c.queue_free()


func _exit_tree() -> void:
	_apply_answer_speed(false)

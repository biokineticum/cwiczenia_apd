extends Node3D
## Plansza Echo 3D: dziewczynka chodzi, podnosi symbole (wejście w obiekt)
## i wkłada je do kółek z cyframi 1–4 w kolejności. Bez klikania siatki UI.

signal arrangement_complete(word_ids: PackedStringArray)
signal arrangement_changed(word_ids: PackedStringArray)

const MeshFactory = preload("res://scripts/art/mesh_factory.gd")
const EchoPropScript = preload("res://scripts/listening/echo_prop.gd")
const EchoSlotScript = preload("res://scripts/listening/echo_slot.gd")

var _slots: Array = [] # EchoSlot
var _props: Array = [] # EchoProp
var _carry: Area3D = null
var _player: Node3D = null
var _active: bool = false
var _speech: Node = null


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
	_active = true
	position = origin
	_player = _find_player()
	# Platforma
	MeshFactory.add_mesh(
		self,
		MeshFactory.box(Vector3(7.2, 0.08, 4.2)),
		MeshFactory.mat(Color(0.78, 0.62, 0.4), 0.92),
		Vector3(0, 0.02, 0.3)
	)
	# Sloty 1–4 w rzędzie (cyfry znane dziecku)
	var n := sequence_ids.size()
	var start_x := -1.5 * float(n - 1) / 2.0
	for i in n:
		var slot: Area3D = EchoSlotScript.new()
		add_child(slot)
		slot.setup(i, Vector3(start_x + float(i) * 1.5, 0.0, -0.6))
		slot.place_requested.connect(_on_slot_place)
		_slots.append(slot)
	# Symbole rozrzucone przed slotami — wejdź w nie, by podnieść
	var positions: Array[Vector3] = [
		Vector3(-2.4, 0, 1.4),
		Vector3(-0.8, 0, 1.7),
		Vector3(0.8, 0, 1.5),
		Vector3(2.4, 0, 1.6),
		Vector3(-1.6, 0, 2.4),
		Vector3(1.6, 0, 2.3),
	]
	positions.shuffle()
	for i in sequence_ids.size():
		var prop: Area3D = EchoPropScript.new()
		add_child(prop)
		var pos: Vector3 = positions[i % positions.size()]
		prop.setup(str(sequence_ids[i]), str(sequence_icons[i]), pos)
		prop.picked.connect(_on_prop_picked)
		_props.append(prop)
	_refresh_highlights()
	print("[EchoBoard] gotowa — %d slotów, chodź i układaj" % n)


func teardown() -> void:
	_active = false
	_carry = null
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


## Playtest / smoke: automatycznie ułóż sekwencję bez chodzenia.
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
	for s in _slots:
		s.filled_word_id = ""
		s.set_highlight(false)
		for c in s.get_children():
			if c is Area3D and c.has_method("reset_home"):
				s.remove_child(c)
				add_child(c)
				c.placed = false
				c.carried = false
				c.monitoring = true
				c.visible = true
				c.scale = Vector3.ONE
				c.position = c._home
	for p in _props:
		var prop: Area3D = p as Area3D
		if prop == null:
			continue
		if prop.get_parent() != self:
			var par: Node = prop.get_parent()
			if par:
				par.remove_child(prop)
			add_child(prop)
		prop.placed = false
		prop.carried = false
		prop.monitoring = true
		prop.visible = true
		prop.scale = Vector3.ONE
		prop.position = prop._home
	_refresh_highlights()


func _on_prop_picked(prop: Area3D) -> void:
	if not _active or prop.placed:
		return
	if _carry != null:
		# Już niesie — najpierw włóż do kółka.
		if _speech:
			_speech.play_text("Najpierw włóż to do kółka z cyfrą.")
		return
	_carry = prop
	prop.carried = true
	prop.monitoring = false
	_attach_to_player(prop)
	if _speech:
		_speech.play_text("Dobrze. Teraz do kółka numer %d." % _next_digit())


func _on_slot_place(slot: Area3D) -> void:
	if not _active or _carry == null:
		return
	if not slot.is_empty():
		return
	# Wypełniaj po kolei 1 → 2 → 3 → 4
	var expected := _next_slot_index()
	if slot.slot_index != expected:
		if _speech:
			_speech.play_text("To kółko numer %d. Idź do numeru %d." % [slot.digit, expected + 1])
		return
	var prop := _carry
	_carry = null
	_detach_from_player(prop)
	slot.place_prop(prop)
	arrangement_changed.emit(get_placed_ids())
	_refresh_highlights()
	if is_complete():
		if _speech:
			_speech.play_text("Brawo, wszystkie na miejscu.")
		arrangement_complete.emit(get_placed_ids())
	elif _speech:
		_speech.play_text("Teraz następny.")


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
		_slots[i].set_highlight(i == next_i and _slots[i].is_empty())


func _attach_to_player(prop: Area3D) -> void:
	if _player == null:
		_player = _find_player()
	if _player == null:
		return
	var par: Node = prop.get_parent()
	if par:
		par.remove_child(prop)
	_player.add_child(prop)
	prop.position = Vector3(0.0, 1.05, 0.45)
	prop.scale = Vector3(0.75, 0.75, 0.75)


func _detach_from_player(prop: Area3D) -> void:
	var par: Node = prop.get_parent()
	if par:
		par.remove_child(prop)


func _drop_carry_visual() -> void:
	if _carry == null:
		return
	var prop := _carry
	_detach_from_player(prop)
	add_child(prop)
	prop.carried = false
	prop.monitoring = true
	prop.position = prop._home
	prop.scale = Vector3.ONE
	_carry = null


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

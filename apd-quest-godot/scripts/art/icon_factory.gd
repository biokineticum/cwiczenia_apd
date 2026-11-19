extends RefCounted
class_name IconFactory
## Ikony z PNG (assets/textures/icons/<id>.png) albo proceduralny fallback.
## Zawsze zwraca Texture2D o rozmiarze CANONICAL_SIZE (nie surowy 1024 PNG).
## Sprite3D: używaj sprite_pixel_size() — wysokość świata ≈ SPRITE_WORLD_HEIGHT.

const ICONS_DIR := "res://assets/textures/icons/"
## Wspólny rozmiar runtime (PNG #13 są 1024×1024; proceduralne rysowane 128→upscale).
const CANONICAL_SIZE := 256
## Docelowa wysokość Sprite3D w metrach (konsultacja fizyki §5: mesh ~0,8–1,2 m).
const SPRITE_WORLD_HEIGHT := 1.15

static var _cache: Dictionary = {}


static func get_icon(icon_id: String) -> Texture2D:
	if _cache.has(icon_id):
		return _cache[icon_id]
	var tex := _load_png_icon(icon_id)
	if tex == null:
		tex = _draw_icon(icon_id)
	_cache[icon_id] = tex
	return tex


## pixel_size dla Sprite3D tak, by CANONICAL_SIZE * pixel_size = SPRITE_WORLD_HEIGHT.
static func sprite_pixel_size() -> float:
	return SPRITE_WORLD_HEIGHT / float(CANONICAL_SIZE)


static func _load_png_icon(icon_id: String) -> Texture2D:
	if icon_id.is_empty() or icon_id.contains("..") or icon_id.contains("/") or icon_id.contains("\\"):
		return null
	var path := ICONS_DIR + icon_id + ".png"
	var img: Image = null
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			img = (res as Texture2D).get_image()
	# Bez .import / get_image() niedostępny — wczytaj surowy PNG.
	if img == null and FileAccess.file_exists(path):
		img = Image.new()
		var err := img.load(path)
		if err != OK:
			return null
	if img == null:
		return null
	return _texture_from_canonical_image(img)


static func _texture_from_canonical_image(img: Image) -> ImageTexture:
	if img.get_width() != CANONICAL_SIZE or img.get_height() != CANONICAL_SIZE:
		img.resize(CANONICAL_SIZE, CANONICAL_SIZE, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


static func _draw_icon(icon_id: String) -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Tło kafelka
	_fill_round_rect(img, 8, 8, size - 16, size - 16, Color(0.98, 0.95, 0.88, 1))
	match icon_id:
		"dog":
			_ellipse(img, 64, 78, 36, 28, Color(0.72, 0.5, 0.28))
			_ellipse(img, 64, 48, 28, 24, Color(0.72, 0.5, 0.28))
			_ellipse(img, 40, 30, 12, 18, Color(0.55, 0.35, 0.18))
			_ellipse(img, 88, 30, 12, 18, Color(0.55, 0.35, 0.18))
			_circle(img, 54, 48, 4, Color(0.1, 0.1, 0.1))
			_circle(img, 74, 48, 4, Color(0.1, 0.1, 0.1))
			_circle(img, 64, 56, 5, Color(0.2, 0.15, 0.1))
		"cat":
			_ellipse(img, 64, 72, 32, 26, Color(0.85, 0.7, 0.35))
			_ellipse(img, 64, 48, 26, 22, Color(0.85, 0.7, 0.35))
			_tri(img, Vector2(42, 42), Vector2(48, 18), Vector2(58, 40), Color(0.85, 0.7, 0.35))
			_tri(img, Vector2(70, 40), Vector2(80, 18), Vector2(86, 42), Color(0.85, 0.7, 0.35))
			_circle(img, 54, 48, 4, Color(0.2, 0.55, 0.2))
			_circle(img, 74, 48, 4, Color(0.2, 0.55, 0.2))
		"house":
			_rect(img, 36, 58, 56, 42, Color(0.9, 0.75, 0.55))
			_tri(img, Vector2(30, 60), Vector2(64, 28), Vector2(98, 60), Color(0.8, 0.35, 0.35))
			_rect(img, 56, 72, 16, 28, Color(0.5, 0.3, 0.18))
			_rect(img, 42, 68, 14, 14, Color(0.55, 0.8, 1.0))
		"ball":
			_circle(img, 64, 64, 34, Color(0.95, 0.45, 0.25))
			_circle(img, 64, 64, 34, Color(0.95, 0.45, 0.25))
			_ellipse(img, 64, 64, 34, 10, Color(1, 1, 1, 0.85))
			_ellipse(img, 64, 64, 10, 34, Color(1, 1, 1, 0.85))
		"apple":
			_circle(img, 64, 70, 30, Color(0.85, 0.2, 0.22))
			_rect(img, 60, 32, 8, 18, Color(0.4, 0.25, 0.12))
			_ellipse(img, 78, 40, 14, 8, Color(0.35, 0.7, 0.3))
		"bread":
			_ellipse(img, 64, 70, 40, 22, Color(0.9, 0.72, 0.4))
			_ellipse(img, 64, 58, 36, 16, Color(0.95, 0.82, 0.55))
		"milk":
			_rect(img, 48, 40, 32, 56, Color(0.95, 0.95, 1.0))
			_rect(img, 52, 32, 24, 12, Color(0.4, 0.65, 0.95))
			_rect(img, 54, 55, 20, 28, Color(1, 1, 1))
		"bird":
			_ellipse(img, 64, 64, 28, 18, Color(0.35, 0.65, 0.95))
			_circle(img, 88, 58, 12, Color(0.35, 0.65, 0.95))
			_circle(img, 92, 56, 3, Color(0.1, 0.1, 0.1))
			_tri(img, Vector2(100, 58), Vector2(114, 54), Vector2(100, 64), Color(0.95, 0.7, 0.2))
			_ellipse(img, 50, 70, 22, 8, Color(0.25, 0.5, 0.85))
		"flower":
			for i in 5:
				var a := float(i) * TAU / 5.0
				_circle(img, int(64 + cos(a) * 22), int(64 + sin(a) * 22), 14, Color(1.0, 0.45, 0.7))
			_circle(img, 64, 64, 12, Color(1.0, 0.9, 0.25))
		"sun":
			_circle(img, 64, 64, 24, Color(1.0, 0.85, 0.25))
			for i in 8:
				var a := float(i) * TAU / 8.0
				_rect_rotish(img, 64 + int(cos(a) * 38), 64 + int(sin(a) * 38), Color(1.0, 0.75, 0.2))
		"rain":
			_ellipse(img, 64, 48, 36, 20, Color(0.55, 0.65, 0.85))
			for i in 5:
				_rect(img, 40 + i * 12, 70, 4, 22, Color(0.4, 0.6, 0.95))
		"tree":
			_rect(img, 58, 70, 12, 30, Color(0.45, 0.28, 0.15))
			_circle(img, 64, 55, 28, Color(0.3, 0.65, 0.3))
			_circle(img, 48, 60, 16, Color(0.35, 0.7, 0.32))
			_circle(img, 80, 58, 16, Color(0.28, 0.6, 0.28))
		"book":
			_rect(img, 40, 36, 48, 56, Color(0.35, 0.5, 0.85))
			_rect(img, 44, 40, 40, 48, Color(0.95, 0.95, 0.9))
			_rect(img, 62, 40, 4, 48, Color(0.3, 0.4, 0.7))
		"door":
			_rect(img, 40, 28, 48, 76, Color(0.55, 0.35, 0.2))
			_circle(img, 72, 68, 5, Color(0.9, 0.75, 0.3))
		"water":
			_ellipse(img, 64, 70, 40, 22, Color(0.35, 0.65, 0.95))
			_ellipse(img, 64, 58, 30, 12, Color(0.55, 0.8, 1.0))
		"car":
			_rect(img, 30, 60, 68, 28, Color(0.9, 0.35, 0.3))
			_rect(img, 42, 42, 40, 22, Color(0.7, 0.85, 1.0))
			_circle(img, 44, 90, 10, Color(0.15, 0.15, 0.15))
			_circle(img, 84, 90, 10, Color(0.15, 0.15, 0.15))
		"sleep":
			_ellipse(img, 64, 78, 40, 18, Color(0.7, 0.55, 0.85))
			_ellipse(img, 64, 58, 28, 22, Color(0.95, 0.85, 0.7))
			_circle(img, 56, 56, 3, Color(0.2, 0.2, 0.2))
			_circle(img, 72, 56, 3, Color(0.2, 0.2, 0.2))
		"park":
			_rect(img, 20, 80, 88, 20, Color(0.4, 0.7, 0.35))
			_circle(img, 40, 55, 22, Color(0.3, 0.6, 0.28))
			_rect(img, 36, 70, 8, 20, Color(0.45, 0.3, 0.15))
			_circle(img, 90, 70, 14, Color(0.95, 0.45, 0.25))
		"ear":
			_ellipse(img, 64, 64, 28, 38, Color(0.95, 0.8, 0.7))
			_ellipse(img, 64, 64, 14, 22, Color(0.9, 0.65, 0.6))
			_circle(img, 64, 70, 8, Color(0.85, 0.55, 0.5))
		"parent":
			_circle(img, 64, 40, 16, Color(0.95, 0.8, 0.7))
			_ellipse(img, 64, 78, 28, 26, Color(0.4, 0.55, 0.75))
		"undo":
			_ellipse(img, 64, 64, 28, 28, Color(0.85, 0.75, 0.55))
			_tri(img, Vector2(40, 64), Vector2(58, 48), Vector2(58, 80), Color(0.45, 0.3, 0.15))
		"play":
			_circle(img, 64, 64, 40, Color(0.35, 0.75, 0.45))
			_tri(img, Vector2(52, 40), Vector2(92, 64), Vector2(52, 88), Color(1, 1, 1))
		"close":
			_circle(img, 64, 64, 40, Color(0.85, 0.45, 0.4))
			for i in 40:
				var t := float(i) / 40.0
				_circle(img, int(lerp(40.0, 88.0, t)), int(lerp(40.0, 88.0, t)), 5, Color(1, 1, 1))
				_circle(img, int(lerp(88.0, 40.0, t)), int(lerp(40.0, 88.0, t)), 5, Color(1, 1, 1))
		"check":
			_circle(img, 64, 64, 40, Color(0.35, 0.7, 0.5))
			for i in 18:
				var t := float(i) / 18.0
				_circle(img, int(lerp(38.0, 56.0, t)), int(lerp(66.0, 88.0, t)), 5, Color(1, 1, 1))
			for i in 28:
				var t := float(i) / 28.0
				_circle(img, int(lerp(56.0, 92.0, t)), int(lerp(88.0, 40.0, t)), 5, Color(1, 1, 1))
		"talk":
			_ellipse(img, 64, 58, 36, 28, Color(0.95, 0.9, 0.75))
			_tri(img, Vector2(48, 78), Vector2(64, 100), Vector2(72, 78), Color(0.95, 0.9, 0.75))
			_circle(img, 50, 56, 5, Color(0.4, 0.35, 0.3))
			_circle(img, 64, 56, 5, Color(0.4, 0.35, 0.3))
			_circle(img, 78, 56, 5, Color(0.4, 0.35, 0.3))
		_:
			_circle(img, 64, 64, 30, Color(0.7, 0.7, 0.75))
			_circle(img, 64, 64, 12, Color(0.45, 0.45, 0.5))
	# Procedural 128 → kanoniczny rozmiar (spójny z PNG).
	return _texture_from_canonical_image(img)


static func _fill_round_rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var dx := mini(xx - x, x + w - 1 - xx)
			var dy := mini(yy - y, y + h - 1 - yy)
			if dx + dy >= 4 or (dx >= 2 and dy >= 2):
				if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
					img.set_pixel(xx, yy, col)


static func _circle(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	for yy in range(cy - r, cy + r + 1):
		for xx in range(cx - r, cx + r + 1):
			if (xx - cx) * (xx - cx) + (yy - cy) * (yy - cy) <= r * r:
				if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
					img.set_pixel(xx, yy, col)


static func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for yy in range(cy - ry, cy + ry + 1):
		for xx in range(cx - rx, cx + rx + 1):
			var nx := float(xx - cx) / float(maxi(rx, 1))
			var ny := float(yy - cy) / float(maxi(ry, 1))
			if nx * nx + ny * ny <= 1.0:
				if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
					img.set_pixel(xx, yy, col)


static func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
				img.set_pixel(xx, yy, col)


static func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	var min_x := int(floor(minf(a.x, minf(b.x, c.x))))
	var max_x := int(ceil(maxf(a.x, maxf(b.x, c.x))))
	var min_y := int(floor(minf(a.y, minf(b.y, c.y))))
	var max_y := int(ceil(maxf(a.y, maxf(b.y, c.y))))
	for yy in range(min_y, max_y + 1):
		for xx in range(min_x, max_x + 1):
			if _point_in_tri(Vector2(xx, yy), a, b, c):
				if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
					img.set_pixel(xx, yy, col)


static func _point_in_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 := c - a
	var v1 := b - a
	var v2 := p - a
	var dot00 := v0.dot(v0)
	var dot01 := v0.dot(v1)
	var dot02 := v0.dot(v2)
	var dot11 := v1.dot(v1)
	var dot12 := v1.dot(v2)
	var inv := 1.0 / (dot00 * dot11 - dot01 * dot01)
	var u := (dot11 * dot02 - dot01 * dot12) * inv
	var v := (dot00 * dot12 - dot01 * dot02) * inv
	return u >= 0.0 and v >= 0.0 and (u + v) < 1.0


static func _rect_rotish(img: Image, cx: int, cy: int, col: Color) -> void:
	_rect(img, cx - 3, cy - 8, 6, 16, col)

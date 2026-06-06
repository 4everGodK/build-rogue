extends RefCounted
class_name ArtifactVisuals

static func make_projectile_visual(data: ArtifactData) -> Node2D:
	var root := Node2D.new()
	match data.id:
		"flying_sword":
			root.add_child(_sword_polygon(Color.WHITE, Color(0.72, 0.9, 1.0), maxf(26.0, data.length), maxf(5.0, data.width)))
		"blood_slash":
			root.add_child(_slash_line(Color(0.95, 0.02, 0.08, 0.88), maxf(42.0, data.length), maxf(7.0, data.width * 0.28)))
		"fire_orb":
			root.add_child(_filled_circle(maxf(10.0, data.width * 0.55), Color(1.0, 0.22, 0.04, 0.95)))
			root.add_child(_filled_circle(maxf(6.0, data.width * 0.32), Color(1.0, 0.72, 0.16, 0.95)))
		"guqin":
			root.add_child(_note_visual(Color(0.62, 1.0, 0.82, 0.95)))
		"copper_coin":
			root.add_child(_coin_visual())
		"magic_ring":
			root.add_child(_ring_visual(Color(0.25, 0.75, 1.0, 0.9), maxf(14.0, data.width * 0.55)))
		"poison_needle":
			root.add_child(_needle_visual(Color(0.35, 1.0, 0.18, 1.0), maxf(24.0, data.length)))
		_:
			if data.attack_shape == "circle":
				root.add_child(_filled_circle(maxf(7.0, data.width * 0.45), data.visual_color))
			else:
				root.add_child(_sword_polygon(data.visual_color, data.visual_color.lightened(0.35), maxf(20.0, data.length), maxf(5.0, data.width)))
	return root

static func make_projectile_trail(data: ArtifactData) -> Line2D:
	var trail := Line2D.new()
	trail.width = 4.0
	trail.default_color = _trail_color(data)
	var length := 30.0
	match data.id:
		"flying_sword":
			length = 42.0
		"blood_slash":
			length = 58.0
		"fire_orb":
			length = 46.0
		"poison_needle":
			length = 34.0
	trail.points = PackedVector2Array([Vector2(-length, 0), Vector2.ZERO])
	return trail

static func projectile_spin_speed(data: ArtifactData) -> float:
	return 5.5 if data.id == "magic_ring" or data.id == "copper_coin" else 0.0

static func projectile_hit_kind(data: ArtifactData) -> String:
	match data.id:
		"flying_sword":
			return "sword"
		"fire_orb":
			return "fire"
		"guqin":
			return "sound"
		"copper_coin":
			return "coin"
		"blood_slash":
			return "blood"
		"poison_needle":
			return "poison"
		_:
			return "flash"

static func make_melee_visual(data: ArtifactData) -> Node2D:
	var root := Node2D.new()
	match data.id:
		"long_spear":
			root.add_child(_thrust_line(Color(0.72, 1.0, 0.86, 0.72), data.length, maxf(4.0, data.width * 0.35)))
			root.add_child(_afterimage_line(Color(0.72, 1.0, 0.86, 0.28), data.length * 0.78, maxf(2.0, data.width * 0.2), Vector2(-18, 0)))
		"dagger":
			root.add_child(_thrust_line(Color(0.42, 1.0, 0.35, 0.75), data.length, maxf(3.0, data.width * 0.5)))
			root.add_child(_afterimage_line(Color(0.42, 1.0, 0.35, 0.28), data.length * 0.65, 2.0, Vector2(-10, -5)))
			root.add_child(_afterimage_line(Color(0.42, 1.0, 0.35, 0.18), data.length * 0.5, 2.0, Vector2(-18, 5)))
		"fist":
			root.add_child(_impact_wave(Color(1.0, 0.48, 0.14, 0.55), data.length * 0.55))
		"palm":
			root.add_child(_fan_visual(Color(0.42, 0.85, 1.0, 0.42), maxf(72.0, data.length), deg_to_rad(70.0) * data.melee_arc_multiplier))
		"kick":
			root.add_child(_spiral_visual(Color(0.66, 0.86, 1.0, 0.52), data.radius))
		"blood_sword":
			root.add_child(_fan_visual(Color(0.95, 0.02, 0.08, 0.58), maxf(90.0, data.length), deg_to_rad(52.0)))
			root.add_child(_slash_line(Color(1.0, 0.08, 0.12, 0.45), data.length * 0.9, maxf(6.0, data.width * 0.18)))
		_:
			root.add_child(_fan_visual(data.visual_color, maxf(data.length, data.radius), deg_to_rad(48.0)))
	return root

static func melee_hit_kind(data: ArtifactData) -> String:
	match data.id:
		"blood_sword":
			return "blood"
		"dagger":
			return "poison"
		"long_spear", "one_handed_sword":
			return "sword"
		"fist", "palm", "kick":
			return "flash"
		_:
			return "flash"

static func make_orbiter_visual(data: ArtifactData) -> Node2D:
	var root := Node2D.new()
	root.add_child(_sword_polygon(Color(0.96, 0.92, 0.72, 1.0), Color(0.82, 0.72, 0.36, 1.0), 28.0, 5.0))
	var glow := _ring_visual(Color(0.95, 0.82, 0.38, 0.25), 12.0)
	glow.scale = Vector2(0.65, 0.65)
	root.add_child(glow)
	return root

static func make_formation_visual(data: ArtifactData) -> Node2D:
	var root := Node2D.new()
	var color := _formation_color(data)
	var ring := _ring_visual(color, data.radius)
	root.add_child(ring)
	var inner := _ring_visual(Color(color.r, color.g, color.b, color.a * 0.45), data.radius * 0.68)
	root.add_child(inner)
	match data.id:
		"slow_formation":
			_add_runes(root, color, data.radius, "cross")
		"attack_speed_formation":
			_add_runes(root, color, data.radius, "wind")
		"healing_formation":
			_add_runes(root, color, data.radius, "water")
		"damage_formation":
			_add_runes(root, color, data.radius, "fire")
		"flame_robe":
			root.add_child(_ring_visual(Color(1.0, 0.18, 0.04, 0.18), data.radius * 0.75))
		"golden_shield":
			root.add_child(_ring_visual(Color(1.0, 0.82, 0.22, 0.22), data.radius * 0.85))
		_:
			_add_runes(root, color, data.radius, "cross")
	return root

static func make_eye_visual() -> Node2D:
	var root := Node2D.new()
	var eye := Line2D.new()
	eye.width = 4.0
	eye.default_color = Color(0.95, 0.85, 1.0, 0.9)
	eye.closed = true
	eye.points = PackedVector2Array([Vector2(-22, 0), Vector2(-10, -10), Vector2(10, -10), Vector2(22, 0), Vector2(10, 10), Vector2(-10, 10)])
	root.add_child(eye)
	root.add_child(_filled_circle(7.0, Color(1.0, 0.04, 0.08, 0.95)))
	return root

static func _trail_color(data: ArtifactData) -> Color:
	match data.id:
		"flying_sword":
			return Color(1.0, 1.0, 1.0, 0.42)
		"blood_slash":
			return Color(0.95, 0.0, 0.08, 0.45)
		"fire_orb":
			return Color(1.0, 0.42, 0.05, 0.48)
		"poison_needle":
			return Color(0.35, 1.0, 0.18, 0.38)
		"guqin":
			return Color(0.62, 1.0, 0.82, 0.32)
		"copper_coin":
			return Color(1.0, 0.78, 0.18, 0.28)
		_:
			return Color(data.visual_color.r, data.visual_color.g, data.visual_color.b, 0.35)

static func _formation_color(data: ArtifactData) -> Color:
	match data.id:
		"slow_formation":
			return Color(0.28, 0.95, 0.38, 0.42)
		"attack_speed_formation":
			return Color(0.25, 1.0, 0.86, 0.4)
		"healing_formation":
			return Color(0.2, 0.64, 1.0, 0.38)
		"damage_formation":
			return Color(1.0, 0.18, 0.05, 0.42)
		"flame_robe":
			return Color(1.0, 0.16, 0.04, 0.22)
		"golden_shield":
			return Color(1.0, 0.82, 0.22, 0.34)
		_:
			return data.visual_color

static func _sword_polygon(fill: Color, edge: Color, length: float, width: float) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(length * 0.52, 0), Vector2(-length * 0.35, -width), Vector2(-length * 0.18, 0), Vector2(-length * 0.35, width)])
	poly.color = fill
	var outline := Line2D.new()
	outline.width = 2.0
	outline.default_color = edge
	outline.closed = true
	outline.points = poly.polygon
	poly.add_child(outline)
	return poly

static func _needle_visual(color: Color, length: float) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(length * 0.55, 0), Vector2(-length * 0.45, -3), Vector2(-length * 0.2, 0), Vector2(-length * 0.45, 3)])
	poly.color = color
	return poly

static func _coin_visual() -> Node2D:
	var root := Node2D.new()
	var outer := _filled_circle(12.0, Color(1.0, 0.72, 0.14, 0.95))
	root.add_child(outer)
	var hole := _filled_circle(4.5, Color(0.08, 0.06, 0.03, 0.95))
	root.add_child(hole)
	var ring := _ring_visual(Color(1.0, 0.9, 0.35, 0.9), 12.0)
	root.add_child(ring)
	return root

static func _note_visual(color: Color) -> Node2D:
	var root := Node2D.new()
	root.add_child(_filled_circle(6.0, color))
	var stem := Line2D.new()
	stem.width = 3.0
	stem.default_color = color
	stem.points = PackedVector2Array([Vector2(4, -3), Vector2(4, -22), Vector2(15, -16)])
	root.add_child(stem)
	return root

static func _ring_visual(color: Color, radius: float) -> Line2D:
	var line := Line2D.new()
	line.width = maxf(2.0, radius * 0.04)
	line.default_color = color
	line.closed = true
	line.points = _circle_points(radius, 56)
	return line

static func _filled_circle(radius: float, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = _circle_points(radius, 24)
	poly.color = color
	return poly

static func _thrust_line(color: Color, length: float, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([Vector2(8, 0), Vector2(length, 0)])
	return line

static func _afterimage_line(color: Color, length: float, width: float, offset: Vector2) -> Line2D:
	var line := _thrust_line(color, length, width)
	line.position = offset
	return line

static func _slash_line(color: Color, length: float, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([Vector2(-length * 0.35, 18), Vector2(0, 0), Vector2(length * 0.45, -16)])
	return line

static func _fan_visual(color: Color, length: float, arc: float) -> Polygon2D:
	var poly := Polygon2D.new()
	var points := PackedVector2Array([Vector2.ZERO])
	for index in 16:
		var t := -arc * 0.5 + arc * float(index) / 15.0
		points.append(Vector2(cos(t), sin(t)) * length)
	poly.polygon = points
	poly.color = color
	return poly

static func _impact_wave(color: Color, length: float) -> Node2D:
	var root := Node2D.new()
	root.add_child(_filled_circle(16.0, color))
	var ring := _ring_visual(Color(color.r, color.g, color.b, color.a * 0.7), maxf(20.0, length))
	ring.position.x = length * 0.7
	root.add_child(ring)
	return root

static func _spiral_visual(color: Color, radius: float) -> Line2D:
	var line := Line2D.new()
	line.width = 6.0
	line.default_color = color
	var points := PackedVector2Array()
	for index in 30:
		var t := TAU * 1.25 * float(index) / 29.0
		var r := radius * (0.25 + 0.75 * float(index) / 29.0)
		points.append(Vector2(cos(t), sin(t)) * r)
	line.points = points
	return line

static func _add_runes(root: Node2D, color: Color, radius: float, kind: String) -> void:
	for index in 6:
		var angle := TAU * float(index) / 6.0
		var pos := Vector2(cos(angle), sin(angle)) * radius * 0.72
		var rune := Line2D.new()
		rune.width = 3.0
		rune.default_color = color
		rune.position = pos
		rune.rotation = angle
		match kind:
			"wind":
				rune.points = PackedVector2Array([Vector2(-10, 5), Vector2(0, -6), Vector2(12, 0), Vector2(0, 7)])
			"water":
				rune.points = PackedVector2Array([Vector2(-12, 0), Vector2(-4, -5), Vector2(4, 5), Vector2(12, 0)])
			"fire":
				rune.points = PackedVector2Array([Vector2(-6, 8), Vector2(0, -10), Vector2(6, 8), Vector2(0, 2)])
			_:
				rune.points = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(0, 0), Vector2(0, -10), Vector2(0, 10)])
		root.add_child(rune)

static func _circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

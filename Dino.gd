extends Node2D

# ══════════════════════════════════════════════
#  DINO PROPERTIES
# ══════════════════════════════════════════════
var x := 80.0
var y := 310.0   # feet Y
var w := 46.0
var h := 50.0
var vy := 0.0
var on_ground := true
var jumps := 0
var max_jumps := 2
var ducking := false
var dead := false
var inv_frames := 0
var gy := 310.0  # set by Main

# Duck dimensions
const DUCK_W := 64.0
const DUCK_H := 30.0

# Texture
var tex : Texture2D = null

func _ready():
	var img_path = "res://assets/dino.png"
	if ResourceLoader.exists(img_path):
		tex = load(img_path)

func reset(ground_y: float):
	gy = ground_y
	y = gy
	vy = 0.0
	on_ground = true
	jumps = 0
	dead = false
	ducking = false
	inv_frames = 0

func do_jump():
	if jumps < max_jumps:
		vy = -12.5
		on_ground = false
		jumps += 1
		get_parent().play_jump_sound()

func update_physics(ground_y: float, _spd: float):
	gy = ground_y
	if inv_frames > 0:
		inv_frames -= 1
	if not on_ground or vy < 0:
		vy += 0.68
	y += vy
	if y >= gy:
		y = gy
		vy = 0.0
		on_ground = true
		jumps = 0
	else:
		on_ground = false

func get_rect() -> Dictionary:
	if ducking:
		return {"x": x, "y": gy - DUCK_H, "w": DUCK_W, "h": DUCK_H}
	return {"x": x, "y": y - h, "w": w, "h": h}

func draw_self(tick: int):
	# Blink when invincible
	if inv_frames > 0 and tick % 6 < 3:
		return

	var dw := DUCK_W if ducking else w
	var dh := DUCK_H if ducking else h
	var dy := gy - dh if ducking else y - dh

	# Draw dino PNG if loaded
	if tex != null:
		var tilt := 0.0
		if not dead:
			if on_ground and not ducking:
				tilt = 0.06
			elif not on_ground:
				tilt = -0.12 if vy < 0 else 0.06
		else:
			tilt = 0.18

		var cx = x + dw / 2.0
		var cy = dy + dh / 2.0

		var xf = Transform2D()
		xf = xf.translated(Vector2(cx, cy))
		xf = xf.rotated(tilt)
		if on_ground and not ducking:
			var sq = Vector2(1.0 + sin(tick * 0.45) * 0.03, 1.0 - sin(tick * 0.45) * 0.02)
			xf = xf.scaled(sq)
		elif not on_ground and vy < 0:
			xf = xf.scaled(Vector2(0.94, 1.08))

		get_parent().draw_set_transform_matrix(xf)
		var src = Rect2(0, 0, tex.get_width(), tex.get_height())
		var dst = Rect2(-dw/2.0, -dh/2.0, dw, dh)
		get_parent().draw_texture_rect_region(tex, dst, src)
		get_parent().draw_set_transform_matrix(Transform2D())
	else:
		# Fallback: draw simple rectangle dino
		var col = Color("ff3355") if dead else Color("4a90d9")
		get_parent().draw_rect(Rect2(x, dy, dw, dh), col)
		# Eye
		get_parent().draw_rect(Rect2(x + dw - 12, dy + 8, 6, 6), Color.WHITE)
		get_parent().draw_rect(Rect2(x + dw - 10, dy + 10, 3, 3), Color("1a1a2e"))

	# Double jump glow
	if not on_ground and jumps == 2:
		get_parent().draw_rect(Rect2(x-3, dy-3, dw+6, dh+6), Color("ffd700", 0.0), false, 2.5)

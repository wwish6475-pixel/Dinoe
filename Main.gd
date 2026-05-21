extends Node2D

var jump_sfx := AudioStreamPlayer.new()
var hit_sfx := AudioStreamPlayer.new()
var score_sfx := AudioStreamPlayer.new()


# ══════════════════════════════════════════════
#  CONSTANTS
# ══════════════════════════════════════════════
const W := 900
const H := 400
const GY := 310  # Ground Y (feet position)

# ══════════════════════════════════════════════
#  GAME STATE
# ══════════════════════════════════════════════
enum State { IDLE, PLAYING, DEAD }
var state := State.IDLE
var score := 0
var best := 0
var lives := 3
var spd := 5.0
var game_tick := 0
var next_obs := 80

# ══════════════════════════════════════════════
#  ENVIRONMENT SYSTEM
# ══════════════════════════════════════════════
var env_index := 0
var env_tick := 0
var env_transition := 0.0
const ENV_DURATION := 1800

var ENVS := [
	{
		"name": "NIGHT",
		"sky": [Color("0a0020"), Color("1a0a3e"), Color("2a1555"), Color("3a1a6e"), Color("4a2a7a")],
		"ground_top": Color("2a6a2a"), "ground_hl": Color("3a8a3a"), "ground_dark": Color("1a4a1a"),
		"dirt": Color("6a4830"), "dirt_dark": Color("4a3020"),
		"cloud_col": Color("2a1a5e"), "cloud_hl": Color("4a3a7e"),
		"stars": true, "moon": true, "sun": false, "sun_evening": false,
		"landmark": "mountains"
	},
	{
		"name": "DAY",
		"sky": [Color("4ab8f0"), Color("6ac8f8"), Color("90d8ff"), Color("b8e8ff"), Color("d8f0ff")],
		"ground_top": Color("5ad85a"), "ground_hl": Color("7af07a"), "ground_dark": Color("3ab83a"),
		"dirt": Color("c8945a"), "dirt_dark": Color("a87040"),
		"cloud_col": Color("e0e8f0"), "cloud_hl": Color("ffffff"),
		"stars": false, "moon": false, "sun": true, "sun_evening": false,
		"landmark": "pyramids"
	},
	{
		"name": "EVENING",
		"sky": [Color("8b1a4a"), Color("c0402a"), Color("e07030"), Color("f0a040"), Color("f8c860")],
		"ground_top": Color("4a8a3a"), "ground_hl": Color("6aaa5a"), "ground_dark": Color("2a6a2a"),
		"dirt": Color("a87050"), "dirt_dark": Color("885030"),
		"cloud_col": Color("c06040"), "cloud_hl": Color("f09060"),
		"stars": false, "moon": false, "sun": true, "sun_evening": true,
		"landmark": "tajmahal"
	}
]

var landmark_offset := 0.0
var ground_offset := 0.0

# ══════════════════════════════════════════════
#  CLOUDS
# ══════════════════════════════════════════════
var clouds := [
	{"x": 150.0, "y": 50.0, "w": 80.0, "spd": 0.4},
	{"x": 420.0, "y": 35.0, "w": 60.0, "spd": 0.3},
	{"x": 700.0, "y": 55.0, "w": 70.0, "spd": 0.35}
]

# ══════════════════════════════════════════════
#  OBSTACLES & COINS & PARTICLES
# ══════════════════════════════════════════════
var obstacles := []
var coins := []
var particles := []

# ══════════════════════════════════════════════
#  DINO reference
# ══════════════════════════════════════════════
var dino_node : Node2D

# ══════════════════════════════════════════════
#  HUD references
# ══════════════════════════════════════════════
var score_label : Label
var best_label : Label
var lives_label : Label
var env_label : Label
var msg_label : Label

# ══════════════════════════════════════════════
#  READY
# ══════════════════════════════════════════════
func _ready():

	# Sound setup
	add_child(jump_sfx)
	add_child(hit_sfx)
	add_child(score_sfx)
	jump_sfx.stream = load("res://assets/jump.wav")
	hit_sfx.stream = load("res://assets/hit.wav")
	score_sfx.stream = load("res://assets/score.wav")

	dino_node = $Dino
	score_label = $CanvasLayer/HUD/ScoreLabel
	best_label  = $CanvasLayer/HUD/BestLabel
	lives_label = $CanvasLayer/HUD/LivesLabel
	env_label   = $CanvasLayer/HUD/EnvLabel
	msg_label   = $CanvasLayer/HUD/MessageLabel
	dino_node.gy = GY
	queue_redraw()

	# ── AdMob: show banner on game launch ──
	if Engine.has_singleton("AdMob"):
		AdMobManager.show_banner()
	# ── AdMob: show App Open Ad on first launch ──
	if Engine.has_singleton("AdMob"):
		AdMobManager.show_open_app_ad()

# ══════════════════════════════════════════════
#  INPUT
# ══════════════════════════════════════════════
func _input(event):
	if event is InputEventKey or event is InputEventScreenTouch:
		var pressed = false
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_SPACE or event.keycode == KEY_UP:
				pressed = true
			if event.keycode == KEY_DOWN:
				if state == State.PLAYING:
					dino_node.ducking = event.pressed
		elif event is InputEventScreenTouch and event.pressed:
			pressed = true

		if pressed:
			handle_jump()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_DOWN:
			if state == State.PLAYING:
				dino_node.ducking = event.pressed

# ══════════════════════════════════════════════
#  HANDLE JUMP / RESTART
# ══════════════════════════════════════════════
func handle_jump():
	if state == State.IDLE or state == State.DEAD:
		restart_game()
		return
	if state == State.PLAYING:
		dino_node.do_jump()

func restart_game():
	state = State.PLAYING
	score = 0; lives = 3; spd = 5.0; game_tick = 0; next_obs = 80
	obstacles.clear(); coins.clear(); particles.clear()
	env_index = 0; env_tick = 0; env_transition = 0.0; landmark_offset = 0.0
	dino_node.reset(GY)
	update_hud()
	msg_label.visible = false
	queue_redraw()

# ══════════════════════════════════════════════
#  PROCESS
# ══════════════════════════════════════════════
func _process(delta):
	if state != State.PLAYING:
		game_tick += 1
		queue_redraw()
		return

	game_tick += 1
	score += 1
	spd = min(5.0 + score * 0.004, 13.0)

	# Dino physics
	dino_node.update_physics(GY, spd)

	# Obstacles
	for o in obstacles:
		o["x"] -= spd
	obstacles = obstacles.filter(func(o): return o["x"] > -150)

	next_obs -= 1
	if next_obs <= 0:
		spawn_obstacle()
		var min_gap: float = max(40.0, 80.0 - score * 0.03)
		var max_gap: float = max(80.0, 150.0 - score * 0.05)
		next_obs = int(min_gap + randf() * (max_gap - min_gap))

	# Coins
	for c in coins:
		c["x"] -= spd * 0.8
	coins = coins.filter(func(c): return c["x"] > -30)
	if randf() < 0.004:
		coins.append({"x": W + 20.0, "y": GY - 35 - randf() * 55, "spin": 0.0, "phase": randf() * PI * 2, "bob": 0.0})

	# Collision
	var dr = dino_node.get_rect()
	if dino_node.inv_frames == 0:
		for i in range(obstacles.size() - 1, -1, -1):
			var o = obstacles[i]
			if rects_overlap(dr, o):
				burst(dr["x"] + dr["w"] * 0.5, dr["y"] + dr["h"] * 0.5,
					[Color("ff3355"), Color("ff8866"), Color("ffaa00"), Color.WHITE], 14, 6)
				obstacles.remove_at(i)
				lives -= 1
				hit_sfx.play()
				update_lives_ui()
				if lives <= 0:
					state = State.DEAD
					dino_node.dead = true
					dino_node.vy = -5
					msg_label.text = "GAME OVER\nSCORE: %05d\n\nTAP / SPACE TO RESTART" % score
					msg_label.visible = true
					# ── AdMob: App Open Ad on Game Over ──
					if Engine.has_singleton("AdMob"):
						await get_tree().create_timer(0.5).timeout
						AdMobManager.show_open_app_ad()
				else:
					dino_node.inv_frames = 100
				break

	# Coin collect
	for i in range(coins.size() - 1, -1, -1):
		var cn = coins[i]
		var cr = {"x": cn["x"] - 11, "y": cn["y"] - 11, "w": 22.0, "h": 22.0}
		if rects_overlap(dr, cr):
			burst(cn["x"], cn["y"], [Color("ffd700"), Color("ffee88"), Color("fffaaa")], 8, 3)
			score += 100
			score_sfx.play()
			coins.remove_at(i)

	# Particles
	for p in particles:
		p["x"] += p["vx"]; p["y"] += p["vy"]
		p["vy"] += 0.3; p["life"] -= 0.055
	particles = particles.filter(func(p): return p["life"] > 0)

	# Clouds
	for cl in clouds:
		cl["x"] -= spd * cl["spd"] * 0.12
		if cl["x"] + cl["w"] < 0:
			cl["x"] = W + 30

	# Landmark + ground scroll
	landmark_offset += spd * 0.5
	ground_offset = fmod(ground_offset + spd, W + 20)

	# Environment transition
	env_tick += 1
	if env_tick >= ENV_DURATION:
		if env_transition == 0.0:
			env_transition = 0.01
		env_transition += 0.008
		if env_transition >= 1.0:
			env_index = (env_index + 1) % ENVS.size()
			env_transition = 0.0
			env_tick = 0

	update_hud()
	queue_redraw()

# ══════════════════════════════════════════════
#  SPAWN OBSTACLE
# ══════════════════════════════════════════════
func spawn_obstacle():
	var r := randf()
	if r < 0.5:
		var variants = [{"w":20,"h":44},{"w":16,"h":58},{"w":24,"h":38}]
		var v = variants[randi() % variants.size()]
		obstacles.append({"type":"cactus","x":float(W+10),"y":float(GY-v["h"]),"w":float(v["w"]),"h":float(v["h"]),"color":Color("3aaa3a"),"dark":Color("2a7a2a")})
	elif r < 0.75:
		obstacles.append({"type":"cactus","x":float(W+10),"y":float(GY-44),"w":20.0,"h":44.0,"color":Color("3aaa3a"),"dark":Color("2a7a2a")})
		obstacles.append({"type":"cactus","x":float(W+38),"y":float(GY-54),"w":18.0,"h":54.0,"color":Color("2a9a2a"),"dark":Color("1a6a1a")})
	elif r < 0.88:
		var fy_opts = [GY-28, GY-60, GY-90]
		var fy = float(fy_opts[randi() % 3])
		obstacles.append({"type":"ptero","x":float(W+10),"y":fy,"w":50.0,"h":28.0,"wf":0.0})
	else:
		obstacles.append({"type":"cactus","x":float(W+10),"y":float(GY-40),"w":18.0,"h":40.0,"color":Color("3aaa3a"),"dark":Color("2a7a2a")})
		obstacles.append({"type":"cactus","x":float(W+34),"y":float(GY-56),"w":20.0,"h":56.0,"color":Color("4aba4a"),"dark":Color("3a8a3a")})
		obstacles.append({"type":"cactus","x":float(W+58),"y":float(GY-38),"w":16.0,"h":38.0,"color":Color("2a9a2a"),"dark":Color("1a6a1a")})

# ══════════════════════════════════════════════
#  COLLISION
# ══════════════════════════════════════════════
func rects_overlap(a: Dictionary, b: Dictionary) -> bool:
	var m := 6.0
	return (a["x"]+m < b["x"]+b["w"]-m and
			a["x"]+a["w"]-m > b["x"]+m and
			a["y"]+m < b["y"]+b["h"]-m and
			a["y"]+a["h"]-m > b["y"]+m)

# ══════════════════════════════════════════════
#  PARTICLES
# ══════════════════════════════════════════════
func burst(x:float, y:float, cols:Array, n:int, pwr:float):
	for i in range(n):
		var a = randf() * PI * 2
		var s = pwr * 0.5 + randf() * pwr
		particles.append({
			"x": x, "y": y,
			"vx": cos(a)*s, "vy": sin(a)*s - 2,
			"col": cols[randi() % cols.size()],
			"life": 1.0, "sz": int(3 + randf() * 5)
		})

# ══════════════════════════════════════════════
#  HUD UPDATE
# ══════════════════════════════════════════════
func update_hud():
	score_label.text = "SCORE: %05d" % score
	if score > best:
		best = score
	best_label.text  = "BEST: %05d" % best
	env_label.text   = ENVS[env_index]["name"]

func update_lives_ui():
	lives_label.text = "❤ ".repeat(max(lives, 0)).strip_edges()

# ══════════════════════════════════════════════
#  LERP COLOR
# ══════════════════════════════════════════════
func lerp_col(c1: Color, c2: Color, t: float) -> Color:
	return c1.lerp(c2, t)

func get_env_col(key: String) -> Color:
	var e = ENVS[env_index]
	var ne = ENVS[(env_index + 1) % ENVS.size()]
	var t = env_transition
	if t <= 0.0:
		return e[key]
	return lerp_col(e[key], ne[key], t)

# ══════════════════════════════════════════════
#  DRAW
# ══════════════════════════════════════════════
func _draw():
	draw_bg()
	draw_ground()
	draw_coins_gfx()
	for o in obstacles:
		if o["type"] == "cactus":
			draw_cactus(o)
		else:
			draw_ptero(o)
	draw_dino_gfx()
	draw_particles_gfx()

	if state == State.IDLE:
		draw_rect(Rect2(0,0,W,H), Color(0.06,0.02,0.11,0.65))
		draw_string(ThemeDB.fallback_font, Vector2(W/2-120, H/2-20),
			"🦕  DINO RUSH", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffd700"))
		if game_tick % 80 < 50:
			draw_string(ThemeDB.fallback_font, Vector2(W/2-150, H/2+20),
				"PRESS SPACE / TAP TO START", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

# ── BACKGROUND ──
func draw_bg():
	var env = ENVS[env_index]
	var next_env = ENVS[(env_index+1) % ENVS.size()]
	var t = env_transition
	var sky1 = env["sky"] as Array
	var sky2 = next_env["sky"] as Array
	var bh = float(GY) / sky1.size()
	for i in range(sky1.size()):
		var col = lerp_col(sky1[i], sky2[i], t) if t > 0 else sky1[i]
		draw_rect(Rect2(0, i*bh, W, bh+1), col)

	# Stars
	if env["stars"] or (t > 0 and next_env["stars"]):
		var sa = (1.0-t) if env["stars"] else t
		var star_positions = [[55,8],[130,14],[200,5],[310,19],[440,9],[560,4],[660,17],[770,11],[850,20],[30,25],[180,30],[350,12],[500,28],[620,8],[780,22]]
		for sp in star_positions:
			var sc = Color(1,0.9,0.4, sa)
			if game_tick % 120 < 60:
				draw_rect(Rect2(sp[0], sp[1], 2, 2), sc)
			else:
				draw_rect(Rect2(sp[0]+1, sp[1]+1, 1, 1), sc)

	# Moon
	if env["moon"] or (t > 0 and next_env["moon"]):
		var ma = max(0.0, 1.0 - t*2) if env["moon"] else min(1.0, t*2-1.0)
		if ma > 0:
			draw_circle(Vector2(800,40), 22, Color(1,0.99,0.88,ma))
			draw_circle(Vector2(793,38), 4, Color(0.91,0.88,0.63,ma))
			draw_circle(Vector2(808,48), 3, Color(0.91,0.88,0.63,ma))

	# Sun
	if env["sun"] or (t > 0 and next_env["sun"]):
		var sa2 := 0.0
		if env["sun"]: sa2 = min(1.0, (1.0-t)*2)
		if t > 0 and next_env["sun"]: sa2 = max(sa2, min(1.0, t*2))
		if sa2 > 0:
			var sy = 55.0 if env["sun_evening"] else 35.0
			var sc2 = Color("ff8020") if env["sun_evening"] else Color("ffe840")
			var sg = Color("ff4000") if env["sun_evening"] else Color("ffd000")
			draw_circle(Vector2(820, sy), 28, Color(sg.r, sg.g, sg.b, sa2))
			draw_circle(Vector2(820, sy), 22, Color(sc2.r, sc2.g, sc2.b, sa2))

	# Landmark crossfade
	if t > 0:
		draw_landmark(env["landmark"], 1.0 - t)
		draw_landmark(next_env["landmark"], t)
	else:
		draw_landmark(env["landmark"], 1.0)

	# Clouds
	var ccol = lerp_col(env["cloud_col"], next_env["cloud_col"], t) if t > 0 else env["cloud_col"]
	var chl  = lerp_col(env["cloud_hl"],  next_env["cloud_hl"],  t) if t > 0 else env["cloud_hl"]
	for cl in clouds:
		draw_cloud(cl["x"], cl["y"], cl["w"], ccol, chl)

# ── LANDMARKS ──
func draw_landmark(ltype: String, alpha: float):
	match ltype:
		"mountains": draw_mountains(alpha)
		"pyramids":  draw_pyramids(alpha)
		"tajmahal":  draw_tajmahal(alpha)

func draw_mountains(alpha: float):
	# Far mountains
	var pts1 = PackedVector2Array([
		Vector2(0,GY), Vector2(0,200), Vector2(80,140), Vector2(160,180),
		Vector2(240,110), Vector2(350,160), Vector2(450,100), Vector2(560,150),
		Vector2(650,90), Vector2(750,140), Vector2(850,80), Vector2(900,130), Vector2(900,GY)
	])
	draw_colored_polygon(pts1, Color(0.10,0.03,0.25,alpha))

	# Near mountains scrolling
	var ox = fmod(landmark_offset * 0.3, 900)
	var raw = [[0,GY],[0,190],[60,160],[130,200],[200,145],[280,185],[370,130],
			   [440,170],[520,120],[600,160],[680,105],[760,150],[840,125],[900,160],[900,GY]]
	var pts2 = PackedVector2Array()
	for p in raw:
		pts2.append(Vector2(fmod(p[0] - ox + 1800, 900), p[1]))
	draw_colored_polygon(pts2, Color(0.15,0.05,0.33,alpha))

func draw_pyramids(alpha: float):
	# Sand dunes
	var dune = PackedVector2Array([
		Vector2(0,GY), Vector2(0,210), Vector2(150,185), Vector2(300,215),
		Vector2(450,198), Vector2(600,182), Vector2(750,210), Vector2(900,195), Vector2(900,GY)
	])
	draw_colored_polygon(dune, Color(0.91,0.78,0.44,alpha))

	var ox = fmod(landmark_offset * 0.15, 600)
	var pyrs = [{"x":100,"h":120,"w":180},{"x":380,"h":90,"w":140},{"x":600,"h":140,"w":200},{"x":820,"h":100,"w":150}]
	for p in pyrs:
		var px = fmod(p["x"] - ox + 1200, 900) - 100
		# Body
		var body = PackedVector2Array([
			Vector2(px, GY), Vector2(px+p["w"], GY), Vector2(px+p["w"]/2.0, GY-p["h"])
		])
		draw_colored_polygon(body, Color(0.78,0.63,0.19,alpha))
		# Highlight
		var hl = PackedVector2Array([
			Vector2(px+p["w"]/2.0, GY-p["h"]),
			Vector2(px+p["w"]*0.55, GY-p["h"]+10),
			Vector2(px+p["w"]*0.65, GY), Vector2(px+p["w"]/2.0, GY)
		])
		draw_colored_polygon(hl, Color(0.88,0.75,0.31,alpha))
		# Entrance
		draw_rect(Rect2(px+p["w"]/2.0-10, GY-30, 20, 30), Color(0.38,0.25,0.06,alpha))

func draw_tajmahal(alpha: float):
	var ox = fmod(landmark_offset * 0.08, 900)
	for offset in [0, 900]:
		var bx = 350.0 - ox + offset
		var by = float(GY)
		# Platform
		draw_rect(Rect2(bx-120, by-20, 240, 20), Color(0.83,0.75,0.66,alpha))
		draw_rect(Rect2(bx-100, by-30, 200, 12), Color(0.78,0.70,0.60,alpha))
		draw_rect(Rect2(bx-80,  by-38,  160, 10), Color(0.75,0.67,0.57,alpha))
		# Main body
		draw_rect(Rect2(bx-60, by-98, 120, 60), Color(0.91,0.86,0.78,alpha))
		# Arches (dark)
		draw_rect(Rect2(bx-15, by-53, 30, 15), Color(0.54,0.42,0.31,alpha))
		draw_rect(Rect2(bx-45, by-50, 20, 12), Color(0.54,0.42,0.31,alpha))
		draw_rect(Rect2(bx+25, by-50, 20, 12), Color(0.54,0.42,0.31,alpha))
		# Minarets
		for tx in [-90, 90]:
			draw_rect(Rect2(bx+tx-8, by-108, 16, 70), Color(0.88,0.83,0.75,alpha))
			# Minaret top
			var mt = PackedVector2Array([
				Vector2(bx+tx, by-122), Vector2(bx+tx-8, by-108), Vector2(bx+tx+8, by-108)
			])
			draw_colored_polygon(mt, Color(0.75,0.70,0.63,alpha))
			draw_rect(Rect2(bx+tx-9, by-108+21, 18, 3), Color(0.72,0.66,0.59,alpha))
			draw_rect(Rect2(bx+tx-9, by-108+42, 18, 3), Color(0.72,0.66,0.59,alpha))
		# Main dome
		var dome = PackedVector2Array()
		for a in range(0, 181, 10):
			var rad = deg_to_rad(a)
			dome.append(Vector2(bx + cos(rad)*35, by-98 - sin(rad)*50))
		dome.append(Vector2(bx-35, by-98))
		draw_colored_polygon(dome, Color(0.87,0.82,0.74,alpha))
		# Dome spire
		var sp = PackedVector2Array([
			Vector2(bx, by-148), Vector2(bx-4, by-98), Vector2(bx+4, by-98)
		])
		draw_colored_polygon(sp, Color(0.78,0.72,0.60,alpha))
		# Side domes
		for dx in [-45, 45]:
			var sd = PackedVector2Array()
			for a2 in range(0, 181, 15):
				var rad2 = deg_to_rad(a2)
				sd.append(Vector2(bx+dx + cos(rad2)*16, by-98 - sin(rad2)*22))
			sd.append(Vector2(bx+dx-16, by-98))
			draw_colored_polygon(sd, Color(0.85,0.80,0.72,alpha))
		# Pool
		draw_rect(Rect2(bx-50, by-20, 100, 20), Color(0.39,0.59,0.78,alpha*0.4))

# ── GROUND ──
func draw_ground():
	var g_top  = get_env_col("ground_top")
	var g_hl   = get_env_col("ground_hl")
	var g_dark = get_env_col("ground_dark")
	var g_dirt = get_env_col("dirt")
	var g_dd   = get_env_col("dirt_dark")

	draw_rect(Rect2(0, GY, W, 13), g_top)
	for x in range(0, W, 12):
		draw_rect(Rect2(x, GY-2, 4, 5), g_hl)
	draw_rect(Rect2(0, GY+13, W, 5), g_dark)
	draw_rect(Rect2(0, GY+18, W, H-(GY+18)), g_dirt)
	for x in range(0, W, 40):
		draw_rect(Rect2(x+8,  GY+24, 20, 7), g_dd)
		draw_rect(Rect2(x+30, GY+35, 9,  5), g_dd)
	# Pebbles
	for i in range(15):
		var gx = fmod(i*65.0 + ground_offset, W+20) - 10
		draw_rect(Rect2(gx, GY+10, 3, 2), Color(0.78,0.66,0.47))
		draw_rect(Rect2(gx+30, GY+7, 2, 2), Color(0.78,0.66,0.47))

# ── CLOUD ──
func draw_cloud(cx: float, cy: float, cw: float, bg_col: Color, hl_col: Color):
	var s = cw / 70.0
	draw_ellipse_filled(Vector2(cx+cw/2, cy+14*s), cw*0.48, 9*s, bg_col)
	var bumps = [[0.08,0.85],[0.22,0.55],[0.42,0.28],[0.62,0.5],[0.82,0.8]]
	for b in bumps:
		var r = (0.28 - abs(b[0]-0.45)*0.4) * cw
		draw_ellipse_filled(Vector2(cx+b[0]*cw, cy+b[1]*18*s), r, r*0.72, hl_col)

func draw_ellipse_filled(center: Vector2, rx: float, ry: float, col: Color):
	var pts = PackedVector2Array()
	for i in range(24):
		var a = i * PI * 2 / 24
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, col)

# ── CACTUS ──
func draw_cactus(o: Dictionary):
	var x = o["x"]; var y = o["y"]; var w = o["w"]; var h = o["h"]
	var col = o["color"]; var dark = o["dark"]
	draw_rect(Rect2(x+4, GY, w-2, 6), Color(0,0,0,0.18))
	draw_rect(Rect2(x, y, w, h), dark)
	draw_rect(Rect2(x+2, y+2, w-4, h-4), col)
	draw_rect(Rect2(x+3, y+4, 4, h-8), Color(0.42,0.87,0.42))
	# Arms
	var ay = y + h*0.32
	draw_rect(Rect2(x-11, ay+4, 13, 7), dark)
	draw_rect(Rect2(x-11, ay-8, 8, 14), dark)
	draw_rect(Rect2(x+w-2, ay+10, 13, 7), dark)
	draw_rect(Rect2(x+w+3, ay+4, 8, 12), dark)

# ── PTERODACTYL ──
func draw_ptero(o: Dictionary):
	o["wf"] += 0.14
	var wing_up = sin(o["wf"]) > 0
	var x = o["x"]; var y = o["y"]
	draw_rect(Rect2(x+12, y+9, 26, 13), Color("7a4a9a"))
	draw_rect(Rect2(x+14, y+7, 22, 13), Color("aa70cc"))
	draw_rect(Rect2(x+34, y+4, 16, 12), Color("9a60b8"))
	draw_rect(Rect2(x+48, y+7, 12, 4),  Color("f0b030"))
	draw_rect(Rect2(x+38, y+5, 6, 6),   Color("1a1a2e"))
	draw_rect(Rect2(x+39, y+6, 2, 2),   Color.WHITE)
	# Wings
	if wing_up:
		var lw = PackedVector2Array([Vector2(x+14,y+10),Vector2(x+2,y-14),Vector2(x-2,y-10),Vector2(x+10,y+12)])
		var rw = PackedVector2Array([Vector2(x+34,y+10),Vector2(x+50,y-14),Vector2(x+54,y-10),Vector2(x+38,y+12)])
		draw_colored_polygon(lw, Color("9a60b8"))
		draw_colored_polygon(rw, Color("9a60b8"))
	else:
		var lw = PackedVector2Array([Vector2(x+14,y+14),Vector2(x+2,y+32),Vector2(x-2,y+28),Vector2(x+10,y+12)])
		var rw = PackedVector2Array([Vector2(x+34,y+14),Vector2(x+50,y+32),Vector2(x+54,y+28),Vector2(x+38,y+12)])
		draw_colored_polygon(lw, Color("9a60b8"))
		draw_colored_polygon(rw, Color("9a60b8"))

# ── COINS ──
func draw_coins_gfx():
	for cn in coins:
		cn["spin"] += 0.1
		cn["bob"] = sin(game_tick * 0.06 + cn["phase"]) * 5
		var cx = cn["x"]; var cy = cn["y"] + cn["bob"]
		var sx = abs(cos(cn["spin"])) * 11
		draw_rect(Rect2(cx-11, cy-11, 22, 22), Color("b8860b"))
		draw_rect(Rect2(cx-sx, cy-10, sx*2, 20), Color("ffd700"))
		if sx > 5:
			draw_rect(Rect2(cx-1, cy-7, 3, 14), Color("b8860b"))
			draw_rect(Rect2(cx-6, cy-1, 12, 3), Color("b8860b"))

# ── DINO DRAW ──
func draw_dino_gfx():
	dino_node.draw_self(game_tick)

# ── PARTICLES ──
func draw_particles_gfx():
	for p in particles:
		var col = p["col"] as Color
		draw_rect(Rect2(p["x"], p["y"], p["sz"], p["sz"]), Color(col.r, col.g, col.b, p["life"]))


func play_jump_sound():
	jump_sfx.play()

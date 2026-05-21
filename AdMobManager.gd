extends Node

# ══════════════════════════════════════════════
#  ADMOB MANAGER - Dino Rush
#  App ID:      ca-app-pub-2417109156263886~2434312983
#  Banner ID:   ca-app-pub-2417109156263886/1048694682
#  Open App ID: ca-app-pub-2417109156263886/7761827135
# ══════════════════════════════════════════════

const APP_ID        := "ca-app-pub-2417109156263886~2434312983"
const BANNER_ID     := "ca-app-pub-2417109156263886/1048694682"
const OPEN_APP_ID   := "ca-app-pub-2417109156263886/7761827135"

# Use test IDs during development — set to false before release
const USE_TEST_ADS  := true

const TEST_BANNER_ID    := "ca-app-pub-3940256099942544/6300978111"
const TEST_OPEN_APP_ID  := "ca-app-pub-3940256099942544/9257395921"

var admob : Object = null
var banner_loaded  := false
var open_app_loaded := false

func _ready():
	_init_admob()

func _init_admob() -> void:
	# Check if the GodotAdMob plugin is available (Android only)
	if Engine.has_singleton("AdMob"):
		admob = Engine.get_singleton("AdMob")
		print("[AdMob] Plugin found — initializing...")
		_connect_signals()
		_load_open_app_ad()
		_load_banner()
	else:
		print("[AdMob] Plugin NOT found. Running without ads (Editor/iOS/unsupported).")

func _connect_signals() -> void:
	if admob == null:
		return
	# Banner signals
	if admob.has_signal("banner_loaded"):
		admob.connect("banner_loaded",      _on_banner_loaded)
	if admob.has_signal("banner_failed_to_load"):
		admob.connect("banner_failed_to_load", _on_banner_failed)
	# Open App signals
	if admob.has_signal("app_open_ad_loaded"):
		admob.connect("app_open_ad_loaded",     _on_open_app_loaded)
	if admob.has_signal("app_open_ad_failed_to_load"):
		admob.connect("app_open_ad_failed_to_load", _on_open_app_failed)
	if admob.has_signal("app_open_ad_dismissed_full_screen_content"):
		admob.connect("app_open_ad_dismissed_full_screen_content", _on_open_app_dismissed)

# ══════════════════════════════════════════════
#  BANNER AD
# ══════════════════════════════════════════════
func _load_banner() -> void:
	if admob == null:
		return
	var id = TEST_BANNER_ID if USE_TEST_ADS else BANNER_ID
	# Position: BOTTOM = 0, TOP = 1
	admob.loadBanner(id, true, 0)  # (unit_id, is_on_top=false → bottom, position)

func show_banner() -> void:
	if admob == null:
		return
	if banner_loaded:
		admob.showBanner()
	else:
		_load_banner()   # retry if not loaded yet

func hide_banner() -> void:
	if admob != null:
		admob.hideBanner()

func _on_banner_loaded() -> void:
	print("[AdMob] Banner loaded ✓")
	banner_loaded = true
	admob.showBanner()

func _on_banner_failed(error_code) -> void:
	print("[AdMob] Banner failed to load. Error: ", error_code)
	banner_loaded = false

# ══════════════════════════════════════════════
#  APP OPEN AD
# ══════════════════════════════════════════════
func _load_open_app_ad() -> void:
	if admob == null:
		return
	var id = TEST_OPEN_APP_ID if USE_TEST_ADS else OPEN_APP_ID
	admob.loadAppOpenAd(id)

func show_open_app_ad() -> void:
	if admob == null:
		return
	if open_app_loaded:
		admob.showAppOpenAd()
	else:
		print("[AdMob] Open App ad not ready yet.")
		_load_open_app_ad()   # pre-load for next time

func _on_open_app_loaded() -> void:
	print("[AdMob] App Open Ad loaded ✓")
	open_app_loaded = true

func _on_open_app_failed(error_code) -> void:
	print("[AdMob] App Open Ad failed to load. Error: ", error_code)
	open_app_loaded = false

func _on_open_app_dismissed() -> void:
	print("[AdMob] App Open Ad dismissed.")
	open_app_loaded = false
	_load_open_app_ad()   # pre-load next one immediately

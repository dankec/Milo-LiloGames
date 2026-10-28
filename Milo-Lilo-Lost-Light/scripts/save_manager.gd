extends RefCounted
## Atomic saves with a backup. Additive fields remain backward compatible with v1.

const SAVE_PATH := "user://milo_lilo_save.json"

static func fresh() -> Dictionary:
	return {"schema": 1, "unlocked": 0, "completed": [], "coins": 0,
		"crystals": [], "maps": [], "abilities": [], "treasure": [],
		"collected": [], "checkpoints": {}, "language": "hr", "music": true, "sfx": true}

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary or parsed.get("schema", 0) != 1:
		return {}
	return parsed

static func load_save() -> Dictionary:
	var defaults := fresh()
	var parsed := _read(SAVE_PATH)
	if parsed.is_empty():
		parsed = _read(SAVE_PATH + ".bak")
	for key in defaults.keys():
		if parsed.has(key) and typeof(parsed[key]) == typeof(defaults[key]):
			defaults[key] = parsed[key]
	defaults["unlocked"] = clampi(int(defaults["unlocked"]), 0, 4)
	defaults["coins"] = maxi(0, int(defaults["coins"]))
	return defaults

static func save(data: Dictionary) -> bool:
	var temporary := SAVE_PATH + ".tmp"
	var f := FileAccess.open(temporary, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.flush()
	f.close()
	var path := ProjectSettings.globalize_path(SAVE_PATH)
	var tmp := ProjectSettings.globalize_path(temporary)
	# Never replace a valid backup with corrupt content.
	if FileAccess.file_exists(SAVE_PATH) and not _read(SAVE_PATH).is_empty():
		DirAccess.copy_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path) == OK

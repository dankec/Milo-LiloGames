extends SceneTree
## Run with: godot --headless --editor --script res://ci/configure_android.gd

func _initialize() -> void:
	var settings := EditorInterface.get_editor_settings()
	var android_home := OS.get_environment("ANDROID_HOME")
	var java_home := OS.get_environment("JAVA_HOME")
	if android_home != "":
		settings.set_setting("export/android/android_sdk_path", android_home)
	if java_home != "":
		settings.set_setting("export/android/java_sdk_path", java_home)
	settings.save()
	quit()

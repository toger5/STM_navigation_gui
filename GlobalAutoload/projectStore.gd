extends Node

var patternFilePath = null
var projectName = null
func _ready():
	Signals.new_project_pressed.connect(new_project)

func new_project():
	projectName = "New Project"
	Signals.project_changed.emit()

func save_project_to_file(customPath = ""):
	var path = "user://last_project_save.dat"
	var project = {
		"patternFile": patternFilePath,
		"markers": MarkerStore.markers,
		"projectName": projectName
	}
	if customPath != "":
		path = customPath
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(project)
	file.close()
	print("saved project: ", project)
	Signals.show_notification.emit("Project stored to file")


func load_project_from_file(customPath = ""):
	var path = "user://last_project_save.dat"
	if customPath != "":
		path = customPath
	var file = FileAccess.open(path, FileAccess.READ)
	var project = file.get_var()
	MarkerStore.markers = project.markers
	self.patternFilePath = project.patternFile
	self.projectName = project.projectName
	file.close()
	Signals.project_changed.emit()
	Signals.marker_changed.emit()
	Signals.show_notification.emit("Project loaded from file")

func set_project_name(name):
	self.projectName = name
	Signals.project_changed.emit()

func set_pattern_file(path):
	self.patternFilePath = path
	Signals.project_changed.emit()
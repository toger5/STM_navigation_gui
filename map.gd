extends Control

var nav_generator
var NavGenerator = preload("res://navGenerator.gd")

@export var highColor = Color(255,255,255) 
@export var lowColor =  Color(100,100,100) 
@export var highlightColor = Color(200,100,0)
@export var highlightId = 1
@export var hightlightMarker = false

var mapMarkerDict = {}
var highlights = []
var arrows = []
var hash_of_file = ""
#var Arrow = preload("res://Arrow.tscn")
var FlakeMarkerPacked = preload("res://MarkerMenu/FlakeMarker.tscn")
var texture

func _ready():
	print(MarkerStore.markers)
	Signals.export_image_pressed.connect(save_navigation_cache)
	Signals.remove_navpatches_pressed.connect(remove_highlights)
	Signals.rebuild_pattern_pressed.connect(func(): update_pattern(true))
	Signals.highlight_navpatches_pressed.connect(highlight_index)
	Signals.marker_changed.connect(on_marker_changed)
	Signals.project_changed.connect(update_pattern)
	Signals.marker_changed.connect(draw_selected_target_arrow)
	Signals.marker_changed.connect(drawBox)
#	Signals.add_marker_by_index.connect(add_marker_by_index)
# Dont just update the pattern if no project is set
# TODO open last project on startup
#	update_pattern()


func create_texture_with_pattern(obj, navGenCallbackName, forcePatternRebuild):
	nav_generator.load_patternFile()
	var totalSize = nav_generator.get_totalSize()
	var totalSizeX = totalSize[0]
	var totalSizeY = totalSize[1]
	var imageT: Image = Image.create(totalSizeX, totalSizeY , false, Image.FORMAT_RGBA8)
#	imageT.fill(Color(0,0,0,0))
	var xOffset = 0
	var yOffset = 0
	nav_generator.createNavigation(imageT, highColor, highlightColor, -1, false, Vector2(totalSizeX, totalSizeY), obj, navGenCallbackName, forcePatternRebuild)

func navGenCallback(image, done):
	texture = ImageTexture.create_from_image(image)
	$mapTex.texture = texture
	if done:
		save_navigation_cache()

func update_pattern(forcePatternRebuild = false):
	if not nav_generator:
		nav_generator = NavGenerator.new()
		add_child(nav_generator)
	if(self.is_inside_tree()):
		create_texture_with_pattern(self, "navGenCallback", forcePatternRebuild)

func zoom(factor):
	$mapTex.scale = $mapTex.scale * factor
func muToPixelSize(mu):
	return mu * 1000 / nav_generator.pixelSize
func on_marker_changed():
	for m in mapMarkerDict:
		remove_child(mapMarkerDict[m])
	mapMarkerDict.clear()
	for m in MarkerStore.markers.values():
		var markerNode = MarkerStore.createNodeForMarker(m, true)
		mapMarkerDict[m.id] = markerNode
		add_child(markerNode)
		markerNode.visible = m.visible
		markerNode.size = muToPixelSize(m.size)
		markerNode.position = m.pos - markerNode.size/2

func highlight_index(posIndex, marker):
	var positions = nav_generator.getPositionsForIndex(posIndex, marker).duplicate()
	for pos in positions:
		if pos == Vector2(-10, -10):
			continue
		#var im_texture = ImageTexture.new()
		var im_texture = ImageTexture.create_from_image(nav_generator.getSingleNavpatchTexture(posIndex, marker, nav_generator.NAVPATCHSIZE)) #,Texture2D.FLAG_MIPMAPS
		var texNode = TextureRect.new()
		texNode.texture = im_texture
		texNode.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texNode.position = pos - Vector2(0,im_texture.get_size().y) + Vector2(-2, 2)
		highlights.append(texNode)
		add_child(texNode)

func remove_highlights():
	for h in highlights:
		remove_child(h)

func add_arrow(from_pos: Vector2, to_pos: Vector2, type: int, color: Color):
	var arrow = FlakeMarkerPacked.instantiate();
	arrow.color = color
	arrow.type = type
	arrow.from_pos = from_pos
	arrow.to_pos = to_pos
	arrows.append(arrow)
	add_child(arrow)
	return arrow

func save_navigation_cache(customPath = null):
	var img = $mapTex.texture.get_image()
	var pathImage = "user://navigation_"+str(nav_generator.hash_of_file)+".png"
	var pathPosCache = "user://navigation_positionCache_"+str(nav_generator.hash_of_file)+".json"
	GdsExporter.currentNavigationImagePath = pathImage
	if customPath:
		img.save_png(customPath)
	else:
		img.save_png(pathImage)
		var file = FileAccess.open(pathPosCache, FileAccess.WRITE)
		file.store_var(nav_generator.positionCache)
	Signals.show_notification.emit("Navigation pattern stored on disk.")
	var l = $Line2D
	var ms = MarkerStore.get_selected_marker()
	var mt = MarkerStore.get_target_marker()
	if(ms and mt):
		l.visible = true
		l.points = [ms.pos, mt.pos]


func draw_selected_target_arrow():
	var l = $Line2D
	var ms = MarkerStore.get_selected_marker()
	var mt = MarkerStore.get_target_marker()
	if(ms  and mt ):
		l.visible = true
		l.points = [ms.pos, mt.pos]
	else:
		l.visible = false
func drawBox():
#	pos = nav_generator.get_position_for_index(nav_generator.hieghtightid)
	$Panel.position = Vector2(100,100)
	$Panel.size = Vector2(100,1000)

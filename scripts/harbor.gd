extends Node3D
## An original Harbor Jelly miniature. All geometry is generated procedurally.
## No proprietary model downloads, textures, API keys or network needed.

const JELLY_SHADER: Shader = preload("res://shaders/jelly.gdshader")
const WATER_W = 24.0
const WATER_D = 17.5
const SEA_LEVEL = 0.19
const COLORS = [
    Color("b9483e"), Color("dc9b3b"), Color("d9c464"),
    Color("397a69"), Color("427e9d"), Color("555b92"), Color("ad6688")
]

var world: Node3D
var camera: Camera3D
var water_material: ShaderMaterial
var angle := -0.69
var distance := 29.0
var elapsed := 0.0
var impulse_slot := 0
var last_splash := -1.0
var wobble_strength := 0.95
var floaters: Array[Node3D] = []
var touches := {}
var touch_water := {}
var mouse_water_drag := false
var splash_impulses: Array[Vector4] = [
    Vector4(100.0, 100.0, -100.0, 0.0),
    Vector4(100.0, 100.0, -100.0, 0.0),
    Vector4(100.0, 100.0, -100.0, 0.0),
    Vector4(100.0, 100.0, -100.0, 0.0)
]
var sailing := true
var ship_speed := 0.62
var ship_origin := Vector3(-4.4, 0.48, 2.45)
var freighter: Node3D
var hud_info: Label
var free_cam_zoom := 0.0
var horn_count := 0

func _ready() -> void:
    _create_world()
    _make_hud()
    _update_camera()

func _process(delta: float) -> void:
    elapsed += delta
    water_material.set_shader_parameter("clock", elapsed)
    # All floating boats sample the same wave function used by the water shader.
    # Surface height, pitch and roll therefore respond to actual finger ripples.
    for item in floaters:
        if is_instance_valid(item):
            _rock_boat(item, 0.8, 0.75, float(item.get_meta("base_y", SEA_LEVEL)), delta)
    if sailing and is_instance_valid(freighter):
        freighter.position.x = ship_origin.x + 0.82 * sin(elapsed * 0.37 * ship_speed)
        freighter.position.z = ship_origin.z + 0.32 * sin(elapsed * 0.2 * ship_speed)
        freighter.rotation.y = -0.08 * sin(elapsed * 0.30 * ship_speed)
    if is_instance_valid(freighter):
        _rock_boat(freighter, 4.1, 1.35, ship_origin.y, delta)
    if hud_info != null:
        hud_info.text = "JELLY  %.0f%%   |   %s" % [wobble_strength * 100.0, "SAILING" if sailing else "PAUSED"]


func _water_height_at(point: Vector2) -> float:
    var h := 0.062 * sin(point.x * 0.85 + elapsed * 1.05) * cos(point.y * 0.72 - elapsed * 0.68)
    h += 0.030 * sin((point.x + point.y) * 1.7 - elapsed * 1.25)
    for hit in splash_impulses:
        var age: float = elapsed - hit.z
        if age >= 0.0 and age <= 6.5:
            var r: float = point.distance_to(Vector2(hit.x, hit.y))
            var front: float = r - age * 3.3
            h += hit.w * cos(front * 4.2) * exp(-abs(front) * 0.83) * exp(-age * 0.36)
    return wobble_strength * h


func _rock_boat(item: Node3D, span_x: float, span_z: float, base_y: float, delta: float) -> void:
    var point := Vector2(item.position.x, item.position.z)
    var half_x: float = span_x * 0.5
    var half_z: float = span_z * 0.5
    var center_height := _water_height_at(point)
    var slope_x: float = (_water_height_at(point + Vector2(half_x, 0.0)) - _water_height_at(point - Vector2(half_x, 0.0))) / span_x
    var slope_z: float = (_water_height_at(point + Vector2(0.0, half_z)) - _water_height_at(point - Vector2(0.0, half_z))) / span_z
    var blend: float = clampf(delta * 8.0, 0.0, 1.0)
    item.position.y = lerpf(item.position.y, base_y + center_height * 0.92, blend)
    item.rotation.x = lerp_angle(item.rotation.x, -atan(slope_z), blend)
    item.rotation.z = lerp_angle(item.rotation.z, atan(slope_x), blend)


func _create_world() -> void:
    world = Node3D.new()
    world.name = "MiniatureHarbor"
    add_child(world)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color("dbe4df")
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("ffffff")
    environment.environment.ambient_light_energy = 0.42
    environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55.0, -29.0, 0.0)
    sun.light_energy = 0.93
    sun.light_color = Color("ffedce")
    sun.shadow_enabled = true
    add_child(sun)
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 46.0
    camera.near = 0.1
    camera.far = 140.0
    add_child(camera)
    _build_jelly()
    _build_quays()
    _build_town()
    _build_containers()
    _build_cranes()
    _build_breakwater()
    _build_freighter()
    _build_boats()
    _build_decorations()

func _build_jelly() -> void:
    _box(world, Vector3(0, -0.9, 0), Vector3(WATER_W + 0.3, 0.12, WATER_D + 0.3), Color("d4cbbd"))
    var jelly := _box(world, Vector3(0, -0.31, 0), Vector3(WATER_W, 1.10, WATER_D), Color(0.02, 0.43, 0.50, 0.72), 0.13, 0.12)
    jelly.name = "TranslucentJellyBlock"
    _box(world, Vector3(0, -0.76, 0), Vector3(WATER_W - 0.1, 0.13, WATER_D - 0.1), Color("185265"), 0.6)
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(WATER_W - 0.04, WATER_D - 0.04)
    mesh.subdivide_width = 120
    mesh.subdivide_depth = 88
    var surface := MeshInstance3D.new()
    surface.name = "InteractiveJellySurface"
    surface.mesh = mesh
    surface.position.y = SEA_LEVEL
    water_material = ShaderMaterial.new()
    water_material.shader = JELLY_SHADER
    surface.material_override = water_material
    world.add_child(surface)
    water_material.set_shader_parameter("wobble", wobble_strength)
    # A thin light-colored base makes the sea look like a physical tabletop diorama.
    _box(world, Vector3(0, -0.98, 0), Vector3(25.25, 0.19, 18.75), Color("d3d1c4"))

func _build_quays() -> void:
    # Rear shoreline (pastel old town) and harbour cargo apron.
    _box(world, Vector3(0.8, 0.52, -8.25), Vector3(21.4, 0.82, 4.2), Color("a7aa9e"))
    _box(world, Vector3(0.8, 0.98, -7.16), Vector3(21.4, 0.13, 1.37), Color("d1c0a6"))
    _box(world, Vector3(10.55, 0.57, -1.15), Vector3(2.40, 0.76, 14.65), Color("858f8a"))
    _box(world, Vector3(10.42, 0.98, -1.15), Vector3(1.85, 0.10, 14.65), Color("bbb3a3"))
    # Stone cap line and narrow warehouse pier along the back.
    for i in range(45):
        _box(world, Vector3(-10.2 + float(i) * 0.49, 1.05, -6.45), Vector3(0.08, 0.31, 0.25), Color("898d88"))
    for i in range(26):
        var xx := -9.6 + float(i) * 0.75
        _box(world, Vector3(xx, 0.44, -5.96), Vector3(0.45, 0.13, 0.12), Color("ece4d9"))
    # Little wooden jetty, sticking out into the water.
    for i in range(8):
        _box(world, Vector3(7.0, 0.52, -4.1 + i * 0.47), Vector3(1.8, 0.13, 0.37), Color("a57858"))
    for x in [6.2, 7.8]:
        for z in [-3.9, -2.3, -0.8]:
            _cylinder(world, Vector3(x, 0.14, z), 0.11, 1.27, Color("806e5c"))

func _build_town() -> void:
    # Dense toy town: individually shaped houses rather than a blank backdrop.
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261112
    for i in range(33):
        var col := i % 17
        var row := int(i / 17)
        var x := -10.35 + col * 1.25 + rng.randf_range(-0.19, 0.19)
        var z := -8.53 - row * 0.85
        var height := rng.randf_range(0.85, 2.12)
        var width := rng.randf_range(0.62, 0.96)
        var color: Color = COLORS[i % COLORS.size()]
        _house(Vector3(x, 1.02, z), Vector3(width, height, 0.77), color, i % 4)
    # Tiny roadside trees and individual poles give real depth to the scene.
    for i in range(16):
        var tx := -9.7 + i * 1.28
        _cylinder(world, Vector3(tx, 1.24, -6.85), 0.07, 0.45, Color("947a58"))
        _sphere(world, Vector3(tx, 1.62, -6.85), Vector3(0.28, 0.29, 0.28), Color("77ad82"))

func _house(position: Vector3, size: Vector3, color: Color, style: int) -> void:
    var p := Node3D.new()
    p.position = position
    world.add_child(p)
    _box(p, Vector3(0, size.y / 2.0, 0), size, color)
    _box(p, Vector3(0, size.y + 0.08, 0), Vector3(size.x * 1.15, 0.17, size.z * 1.2), Color("d68a72") if style % 2 == 0 else Color("b1b7bb"))
    var w := Color("efe6cb")
    _box(p, Vector3(-size.x * 0.24, size.y * 0.55, size.z * 0.506), Vector3(0.13, 0.22, 0.026), w)
    _box(p, Vector3(size.x * 0.24, size.y * 0.55, size.z * 0.506), Vector3(0.13, 0.22, 0.026), w)
    _box(p, Vector3(0, 0.21, size.z * 0.514), Vector3(0.16, 0.37, 0.027), Color("8b857c"))

func _build_containers() -> void:
    # Stacked shipping containers laid out across the dock (not in the water).
    var rng := RandomNumberGenerator.new()
    rng.seed = 888
    for layer in range(2):
        for x in range(15):
            for z in range(2):
                if layer == 1 and (x + z) % 4 == 0:
                    continue
                var px := -10.0 + x * 0.84
                var py := 1.18 + layer * 0.48
                var pz := -7.8 + z * 0.72
                var c: Color = COLORS[rng.randi_range(0, COLORS.size() - 1)]
                _box(world, Vector3(px, py, pz), Vector3(0.76, 0.44, 0.58), c, 0.78)
                for k in range(3):
                    _box(world, Vector3(px - 0.21 + k * 0.21, py, pz + 0.296), Vector3(0.028, 0.36, 0.025), c.darkened(0.2))
    # Road leading toward ship terminal.
    for i in range(16):
        _box(world, Vector3(10.5, 1.046, -6.4 + i * 0.81), Vector3(0.075, 0.01, 0.39), Color("eee6d7"))

func _build_cranes() -> void:
    for c in range(3):
        var px := -6.7 + c * 4.05
        var pz := -6.42
        var tint: Color = [Color("e78d59"), Color("6c8aa8"), Color("d66b60")][c]
        var crane := Node3D.new()
        crane.position = Vector3(px, 1.04, pz)
        world.add_child(crane)
        for dx in [-0.5, 0.5]:
            _rod(crane, Vector3(dx, 0, -0.35), Vector3(dx * 0.35, 4.0, -0.35), 0.10, tint)
            _rod(crane, Vector3(dx, 0, 0.35), Vector3(dx * 0.35, 4.0, 0.35), 0.10, tint)
        _rod(crane, Vector3(-0.35, 4.0, -0.42), Vector3(0.35, 4.0, 0.42), 0.13, tint)
        _rod(crane, Vector3(0, 4.13, -3.2), Vector3(0, 4.13, 2.45), 0.18, tint)
        _rod(crane, Vector3(0, 4.2, 0.35), Vector3(0, 5.35, 0.1), 0.09, tint)
        _rod(crane, Vector3(0, 5.35, 0.1), Vector3(0, 4.2, -3.12), 0.045, tint)
        _rod(crane, Vector3(0, 3.98, -2.25), Vector3(0, 1.94, -2.25), 0.032, Color("797a79"))
        _box(crane, Vector3(0, 1.86, -2.25), Vector3(0.72, 0.12, 0.55), Color("dfb75f"))
        _box(crane, Vector3(0, 4.25, 0.7), Vector3(0.62, 0.43, 0.75), Color("f0dbbc"))

func _build_breakwater() -> void:
    # Curved wall of rounded stones separating the outer harbour.
    for i in range(30):
        var t := float(i) / 29.0
        var z := 2.5 + t * 5.55
        var x := 4.6 + 2.6 * sin(t * PI * 0.65)
        _sphere(world, Vector3(x, SEA_LEVEL + 0.08, z), Vector3(0.46, 0.38, 0.47), Color("b6b6a8") if i % 3 else Color("c7c3b6"))
        if i % 2 == 0:
            _sphere(world, Vector3(x + 0.34, SEA_LEVEL - 0.02, z + 0.17), Vector3(0.3, 0.24, 0.3), Color("a0afa8"))
    _cylinder(world, Vector3(7.1, 0.64, 6.7), 0.25, 1.9, Color("f9f3e6"))
    for i in range(3):
        _cylinder(world, Vector3(7.1, 0.45 + i * 0.55, 6.7), 0.259, 0.20, Color("d46655"))
    _cylinder(world, Vector3(7.1, 1.64, 6.7), 0.35, 0.13, Color("d86f60"))
    _sphere(world, Vector3(7.1, 1.83, 6.7), Vector3(0.26, 0.17, 0.26), Color("e7b05c"), true)

func _build_freighter() -> void:
    freighter = Node3D.new()
    freighter.name = "CargoShip"
    freighter.position = ship_origin
    world.add_child(freighter)
    _box(freighter, Vector3(0, 0, 0), Vector3(5.1, 0.58, 1.65), Color("395766"), 0.2, 0.48)
    _box(freighter, Vector3(0, 0.31, 0), Vector3(4.66, 0.1, 1.45), Color("e8e2d4"))
    _box(freighter, Vector3(-1.89, 0.91, 0), Vector3(0.95, 1.0, 1.15), Color("e5e6e3"))
    _box(freighter, Vector3(-1.92, 1.46, 0), Vector3(1.08, 0.1, 1.27), Color("e8a268"))
    _box(freighter, Vector3(-1.88, 1.12, 0.6), Vector3(0.76, 0.22, 0.04), Color("6a9ba3"))
    for row in range(2):
        for col in range(7):
            var clr: Color = COLORS[(col + row * 3) % COLORS.size()]
            _box(freighter, Vector3(-0.82 + col * 0.55, 0.62 + row * 0.40, -0.34 if col % 2 == 0 else 0.34), Vector3(0.49, 0.35, 0.61), clr)
    _rod(freighter, Vector3(-2.0, 1.43, 0.0), Vector3(-2.0, 2.05, 0.0), 0.04, Color("797b77"))
    _sphere(freighter, Vector3(-2.0, 2.09, 0), Vector3(0.10, 0.10, 0.10), Color("ca694b"))

func _build_boats() -> void:
    for i in range(8):
        var boat := Node3D.new()
        boat.name = "Sailboat_%d" % i
        boat.position = Vector3(-9.6 + float(i % 4) * 3.52, SEA_LEVEL + 0.20, -2.6 + float(int(i / 4)) * 4.3)
        world.add_child(boat)
        _box(boat, Vector3.ZERO, Vector3(0.62, 0.16, 1.15), Color("f1e0c2"))
        _rod(boat, Vector3(0, 0.06, 0), Vector3(0, 1.23, 0), 0.025, Color("a08165"))
        _sail(boat, Color("fff9e8"))
        boat.set_meta("base_y", boat.position.y)
        floaters.append(boat)
    for i in range(3):
        var tug := Node3D.new()
        tug.position = Vector3(-7.3 + i * 4.05, SEA_LEVEL + 0.22, 6.15)
        world.add_child(tug)
        _box(tug, Vector3.ZERO, Vector3(1.04, 0.24, 0.54), Color("c66b41"))
        _box(tug, Vector3(0, 0.28, 0), Vector3(0.39, 0.34, 0.42), Color("f2e3c5"))
        tug.set_meta("base_y", tug.position.y)
        floaters.append(tug)

func _sail(parent: Node3D, color: Color) -> void:
    var mesh := ArrayMesh.new()
    var vertices := PackedVector3Array([
        Vector3(0.0, 0.20, 0), Vector3(0.0, 1.13, 0), Vector3(0.45, 0.26, 0),
        Vector3(0.0, 0.20, 0), Vector3(0.45, 0.26, 0), Vector3(0.0, 1.13, 0)
    ])
    var arr := []
    arr.resize(Mesh.ARRAY_MAX)
    arr[Mesh.ARRAY_VERTEX] = vertices
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    var sail_mat := _mat(color, 0.8, 0.0, true)
    sail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    instance.material_override = sail_mat
    parent.add_child(instance)

func _build_decorations() -> void:
    # Sparse foam flecks; all part of miniature physical tabletop scene.
    var rng := RandomNumberGenerator.new()
    rng.seed = 1405
    for i in range(52):
        var x := rng.randf_range(-10.3, 8.8)
        var z := rng.randf_range(-5.5, 7.7)
        if x > 3.8 and z > 2.2:
            continue
        var r := rng.randf_range(0.025, 0.077)
        _sphere(world, Vector3(x, SEA_LEVEL + 0.036, z), Vector3(r * 2.0, 0.012, r), Color(0.83, 1.0, 0.96, 0.48))
    # Small barrels and bollards on pier.
    for i in range(10):
        _cylinder(world, Vector3(10.42, 1.19, -6.9 + i * 1.3), 0.09, 0.31, Color("526a6d"))
    for i in range(6):
        var x := -9.5 + i * 3.35
        _sphere(world, Vector3(x, 0.82, -5.3), Vector3(0.23, 0.09, 0.23), Color("efdfc5"))

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 2
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    var top := VBoxContainer.new()
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top.position = Vector2(34, 22)
    root.add_child(top)
    var heading := Label.new()
    heading.text = "Harbor\nJelly."
    heading.add_theme_color_override("font_color", Color("413c3b"))
    heading.add_theme_font_size_override("font_size", 40)
    top.add_child(heading)
    var subtitle := Label.new()
    subtitle.text = "A tiny interactive jelly sea"
    subtitle.add_theme_font_size_override("font_size", 16)
    subtitle.add_theme_color_override("font_color", Color("6b7777"))
    top.add_child(subtitle)
    var panel := PanelContainer.new()
    panel.anchor_left = 1.0
    panel.anchor_right = 1.0
    panel.offset_left = -277.0
    panel.offset_right = -23.0
    panel.offset_top = 22.0
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.98, 0.965, 0.94, 0.91)
    panel_style.border_color = Color(0.73, 0.73, 0.70, 0.8)
    panel_style.set_border_width_all(1)
    panel_style.set_corner_radius_all(13)
    panel_style.content_margin_left = 14
    panel_style.content_margin_right = 14
    panel_style.content_margin_top = 11
    panel_style.content_margin_bottom = 11
    panel.add_theme_stylebox_override("panel", panel_style)
    root.add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 6)
    panel.add_child(content)
    var title := Label.new()
    title.text = "THE HARBOR  /  LIVE"
    title.add_theme_font_size_override("font_size", 17)
    title.add_theme_color_override("font_color", Color("4b514d"))
    content.add_child(title)
    var choose := HBoxContainer.new()
    content.add_child(choose)
    _button(choose, "HORN", _horn)
    _button(choose, "SAIL / STOP", _toggle_sail)
    _button(choose, "RESET", _reset)
    content.add_child(HSeparator.new())
    _panel_label(content, "JELLY   /   FIRMNESS & WAVES")
    var slider := HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 2.0
    slider.step = 0.05
    slider.value = wobble_strength
    slider.custom_minimum_size = Vector2(0, 24)
    slider.value_changed.connect(_change_wobble)
    content.add_child(slider)
    _panel_label(content, "Drag sea: ripple / drag sky: rotate")
    _panel_label(content, "Pinch: zoom  /  tap: splash")
    content.add_child(HSeparator.new())
    hud_info = Label.new()
    hud_info.add_theme_font_size_override("font_size", 13)
    hud_info.add_theme_color_override("font_color", Color("59665f"))
    content.add_child(hud_info)
    var tip := Label.new()
    tip.text = "Press the water. Watch the boats bob."
    tip.position = Vector2(35, 655)
    tip.add_theme_font_size_override("font_size", 16)
    tip.add_theme_color_override("font_color", Color("575f5c"))
    root.add_child(tip)

func _panel_label(parent: Node, line: String) -> void:
    var label := Label.new()
    label.text = line
    label.add_theme_font_size_override("font_size", 13)
    label.add_theme_color_override("font_color", Color("747a75"))
    parent.add_child(label)

func _button(parent: Node, title: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = title
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 12)
    button.pressed.connect(callback)
    parent.add_child(button)

func _change_wobble(value: float) -> void:
    wobble_strength = value
    water_material.set_shader_parameter("wobble", value)

func _horn() -> void:
    horn_count += 1
    _splash(Vector2(-4.4, 2.45), 0.9)
    # Visual horn pulse without external audio; an original recording can be added later.
    if is_instance_valid(freighter):
        var puff := _sphere(world, freighter.position + Vector3(-1.9, 2.2, 0.0), Vector3(0.16, 0.16, 0.16), Color("f6f1e3"))
        var tween := create_tween()
        tween.tween_property(puff, "scale", Vector3(5.0, 5.0, 5.0), 0.65)
        tween.tween_callback(puff.queue_free)

func _toggle_sail() -> void:
    sailing = not sailing

func _reset() -> void:
    angle = -0.69
    distance = 29.0
    sailing = true
    _update_camera()
    for i in range(splash_impulses.size()):
        splash_impulses[i] = Vector4(100.0, 100.0, -100.0, 0.0)
        water_material.set_shader_parameter(["hit_a", "hit_b", "hit_c", "hit_d"][i], splash_impulses[i])

func _splash(point: Vector2, force: float = 0.58) -> void:
    var slot: int = impulse_slot % splash_impulses.size()
    var key: String = ["hit_a", "hit_b", "hit_c", "hit_d"][slot]
    impulse_slot += 1
    splash_impulses[slot] = Vector4(point.x, point.y, elapsed, force)
    water_material.set_shader_parameter(key, splash_impulses[slot])
    last_splash = elapsed

func _water_hit(screen_pos: Vector2) -> Variant:
    var origin := camera.project_ray_origin(screen_pos)
    var direction := camera.project_ray_normal(screen_pos)
    if abs(direction.y) < 0.0001:
        return null
    var time_to_plane := (SEA_LEVEL - origin.y) / direction.y
    if time_to_plane < 0.0:
        return null
    var p := origin + time_to_plane * direction
    if abs(p.x) > WATER_W * 0.49 or abs(p.z) > WATER_D * 0.49:
        return null
    return Vector2(p.x, p.z)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var e := event as InputEventScreenTouch
        if e.pressed:
            touches[e.index] = e.position
            var hit = _water_hit(e.position)
            touch_water[e.index] = hit != null
            if hit != null:
                _splash(hit, 0.74)
        else:
            touches.erase(e.index)
            touch_water.erase(e.index)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        touches[drag.index] = drag.position
        if touches.size() >= 2:
            var ids := touches.keys()
            var a: Vector2 = touches[ids[0]]
            var b: Vector2 = touches[ids[1]]
            var old_distance := (a - b).length()
            var old_a := a - drag.relative if ids[0] == drag.index else a
            var old_b := b - drag.relative if ids[1] == drag.index else b
            distance = clampf(distance - (old_distance - (old_a - old_b).length()) * 0.023, 19.5, 46.0)
            _update_camera()
        elif bool(touch_water.get(drag.index, false)):
            var hit = _water_hit(drag.position)
            if hit != null and elapsed - last_splash > 0.07:
                var force := clampf(drag.relative.length() * 0.023, 0.18, 0.85)
                _splash(hit, force)
        else:
            angle -= drag.relative.x * 0.0045
            _update_camera()
    elif event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed:
                var hit = _water_hit(mouse.position)
                mouse_water_drag = hit != null
                if hit != null:
                    _splash(hit, 0.74)
            else:
                mouse_water_drag = false
        elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
            distance = clampf(distance - 1.5, 19.5, 46.0)
            _update_camera()
        elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            distance = clampf(distance + 1.5, 19.5, 46.0)
            _update_camera()
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        var motion := event as InputEventMouseMotion
        if mouse_water_drag:
            var hit = _water_hit(motion.position)
            if hit != null and elapsed - last_splash > 0.07:
                _splash(hit, clampf(motion.relative.length() * 0.023, 0.18, 0.85))
        else:
            angle -= motion.relative.x * 0.0045
            _update_camera()


func _update_camera() -> void:
    var target := Vector3(0.0, 0.2, -0.8)
    var radius := distance
    camera.position = target + Vector3(sin(angle) * radius, radius * 0.69, cos(angle) * radius)
    camera.look_at(target, Vector3.UP)

func _mat(color: Color, rough: float = 0.72, metal: float = 0.03, double_sided: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    m.metallic = metal
    if color.a < 0.99:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    if double_sided:
        m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rough: float = 0.68, metal: float = 0.0) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var item := MeshInstance3D.new()
    item.mesh = mesh
    item.position = pos
    item.material_override = _mat(color, rough, metal)
    parent.add_child(item)
    return item

func _sphere(parent: Node3D, pos: Vector3, size: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radial_segments = 10
    mesh.rings = 6
    var item := MeshInstance3D.new()
    item.mesh = mesh
    item.position = pos
    item.scale = size
    var m := _mat(color)
    if emissive:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 0.4
    item.material_override = m
    parent.add_child(item)
    return item

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 10
    var item := MeshInstance3D.new()
    item.mesh = mesh
    item.position = pos
    item.material_override = _mat(color)
    parent.add_child(item)
    return item

func _rod(parent: Node3D, start: Vector3, finish: Vector3, width: float, color: Color) -> void:
    var mid := (start + finish) * 0.5
    var direction := finish - start
    var rod := _box(parent, mid, Vector3(width, direction.length(), width), color, 0.45, 0.1)
    rod.quaternion = Quaternion(Vector3.UP, direction.normalized())

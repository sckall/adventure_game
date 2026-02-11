extends Node

# UI 工具类 - 提供常用的 UI 创建辅助函数
# 用于简化代码，减少重复

# ============ 常用常量 ============

# 字体大小
const FONT_SIZE_TITLE_XL = 64    # 超大标题
const FONT_SIZE_TITLE_L = 52     # 大标题
const FONT_SIZE_TITLE_M = 44     # 中标题
const FONT_SIZE_TITLE_S = 36     # 小标题
const FONT_SIZE_BODY_L = 32      # 大正文
const FONT_SIZE_BODY_M = 26      # 中正文
const FONT_SIZE_BODY_S = 22      # 小正文
const FONT_SIZE_BODY_XS = 18     # 超小正文
const FONT_SIZE_CAPTION = 14     # 说明文字

# 颜色
const COLOR_GOLD = Color(1, 0.95, 0.7)
const COLOR_GOLD_DIM = Color(1, 0.85, 0.4)
const COLOR_SILVER = Color(0.85, 0.9, 1)
const COLOR_BRONZE = Color(1, 0.9, 0.5)
const COLOR_TEXT_PRIMARY = Color(1, 0.95, 0.85)
const COLOR_TEXT_SECONDARY = Color(0.7, 0.75, 0.85)
const COLOR_TEXT_DIM = Color(0.6, 0.65, 0.75)

# 按钮尺寸
const BTN_SIZE_L = Vector2(450, 75)
const BTN_SIZE_M = Vector2(300, 70)
const BTN_SIZE_S = Vector2(200, 60)

# ============ 颜色辅助函数 ============

# 加深颜色
static func darken_color(color: Color, factor: float) -> Color:
	return Color(
		color.r * (1.0 - factor),
		color.g * (1.0 - factor),
		color.b * (1.0 - factor),
		1.0
	)

# 提亮颜色
static func lighten_color(color: Color, factor: float) -> Color:
	return Color(
		min(color.r + factor, 1.0),
		min(color.g + factor, 1.0),
		min(color.b + factor, 1.0),
		color.a
	)

# 调整颜色透明度
static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

# ============ 样式创建函数 ============

# 创建面板样式
static func create_panel_style(bg_color: Color, border_color: Color, border_width: int = 4, corner_radius: int = 16) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	return style

# 创建带阴影的面板样式
static func create_panel_style_with_shadow(bg_color: Color, border_color: Color, border_width: int = 4, corner_radius: int = 16, shadow_size: int = 20) -> StyleBoxFlat:
	var style = create_panel_style(bg_color, border_color, border_width, corner_radius)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_offset = Vector2(0, 6)
	style.shadow_size = shadow_size
	return style

# 创建卡片样式
static func create_card_style(card_color: Color, bg_color: Color = Color(0.15, 0.2, 0.28, 0.9)) -> StyleBoxFlat:
	return create_panel_style(bg_color, card_color, 4, 16)

# ============ 控件创建辅助函数 ============

# 创建居中标签
static func create_centered_label(text: String, font_size: int, color: Color = COLOR_TEXT_PRIMARY) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

# 创建按钮
static func create_button(text: String, size: Vector2 = BTN_SIZE_M, font_size: int = FONT_SIZE_BODY_L) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	btn.add_theme_font_size_override("font_size", font_size)
	return btn

# 创建半透明遮罩
static func create_overlay(color: Color = Color(0, 0, 0, 0.85), click_to_close: bool = true, close_callback: Callable = Callable()) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = color
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if click_to_close and not close_callback.is_null():
		overlay.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				e.accept_event()
				close_callback.call()
		)

	return overlay

# ============ 布局辅助函数 ============

# 创建居中面板容器
static func create_centered_panel(size: Vector2, style: StyleBoxFlat) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -size.x / 2
	panel.offset_top = -size.y / 2
	panel.offset_right = size.x / 2
	panel.offset_bottom = size.y / 2
	panel.custom_minimum_size = size
	panel.add_theme_stylebox_override("panel", style)
	return panel

# 创建 VBoxContainer
static func create_vbox(separation: int = 16) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", separation)
	return vbox

# 创建 HBoxContainer
static func create_hbox(separation: int = 12) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", separation)
	return hbox

# 创建 GridContainer
static func create_grid(columns: int, h_separation: int = 16, v_separation: int = 16) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", h_separation)
	grid.add_theme_constant_override("v_separation", v_separation)
	return grid

# ============ CanvasLayer 辅助函数 ============

# 创建 CanvasLayer
static func create_canvas_layer(layer: int = 100) -> CanvasLayer:
	var canvas = CanvasLayer.new()
	canvas.layer = layer
	return canvas

# 创建带遮罩的弹出层
static func create_popup_layer(layer_num: int = 100, overlay_color: Color = Color(0, 0, 0, 0.85)) -> CanvasLayer:
	var canvas = create_canvas_layer(layer_num)
	var overlay = create_overlay(overlay_color)
	canvas.add_child(overlay)
	return canvas

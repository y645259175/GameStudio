# =============================================================================
# ui_theme.gd · 水墨风 UI 皮肤工具（class_name UITheme）
# 提供宣纸卡片 StyleBox + 给 AcceptDialog / Panel 套统一水墨皮肤，
# 消除 Godot 默认深灰弹窗与水墨风格的割裂。
# =============================================================================
class_name UITheme
extends RefCounted

const PAPER := Color("#F5EFE0")
const PAPER_LIGHT := Color("#FBF7EC")
const INK := Color("#1A1814")
const VERMILION := Color("#A93226")
const SHANQING := Color("#4A6670")
const BRONZE := Color("#8C6D3F")


## 宣纸卡片样式（米色底 + 古铜描边 + 圆角）
static func paper_panel(alpha: float = 0.95) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PAPER_LIGHT.r, PAPER_LIGHT.g, PAPER_LIGHT.b, alpha)
	sb.border_color = Color(BRONZE.r, BRONZE.g, BRONZE.b, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 8
	return sb


## 给 AcceptDialog 套水墨皮肤
static func skin_dialog(dlg: AcceptDialog) -> void:
	# 弹窗主面板
	dlg.add_theme_stylebox_override("panel", paper_panel(0.98))
	# 标题字色
	dlg.add_theme_color_override("title_color", VERMILION)
	dlg.add_theme_font_size_override("title_font_size", 20)
	# OK 按钮也套（通过内部 button 主题在 add_child 后处理，简化：靠全局）


## 给 Button 套水墨风（米底墨字朱砂描边）
static func skin_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(PAPER.r, PAPER.g, PAPER.b, 0.9)
	normal.border_color = Color(BRONZE.r, BRONZE.g, BRONZE.b, 0.7)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate()
	hover.bg_color = Color(1, 0.96, 0.88, 1.0)
	hover.border_color = VERMILION
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", VERMILION)

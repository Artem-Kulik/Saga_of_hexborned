extends Control

const _SIGIL_TEXTURES: Dictionary = {
	"fire":  "res://Основа/visual/sigils/sigil_fire.png",
	"water": "res://Основа/visual/sigils/sigil_water.png",
	"earth": "res://Основа/visual/sigils/sigil_earth.png",
	"air":   "res://Основа/visual/sigils/sigil_air.png",
}

@onready var ward_name: Label             = $Ward_name
@onready var ward_background: TextureRect = $Ward_background
@onready var sigil_frame: TextureRect     = $Content/SkillList/Skill_P/Frame_pas

@onready var icon_q: TextureRect     = $Content/SkillList/Skill_Q/Icon_q
@onready var name_q: Label           = $Content/SkillList/Skill_Q/Name_q
@onready var cooldown_q: Label       = $Content/SkillList/Skill_Q/Cooldown_q
@onready var desc_q: RichTextLabel   = $Content/SkillList/Skill_Q/Description_q

@onready var icon_w: TextureRect     = $Content/SkillList/Skill_W/Icon_w
@onready var name_w: Label           = $Content/SkillList/Skill_W/Name_w
@onready var cooldown_w: Label       = $Content/SkillList/Skill_W/Cooldown_w
@onready var desc_w: RichTextLabel   = $Content/SkillList/Skill_W/Description_w

@onready var icon_e: TextureRect     = $Content/SkillList/Skill_E/Icon_e
@onready var name_e: Label           = $Content/SkillList/Skill_E/Name_e
@onready var cooldown_e: Label       = $Content/SkillList/Skill_E/Cooldown_e
@onready var desc_e: RichTextLabel   = $Content/SkillList/Skill_E/Description_e

@onready var icon_p: TextureRect     = $Content/SkillList/Skill_P/Icon_pas
@onready var name_p: Label           = $Content/SkillList/Skill_P/Name_pas
@onready var desc_p: RichTextLabel   = $Content/SkillList/Skill_P/Description_pas


func _ready() -> void:
	visible = true


func show_panel() -> void:
	visible = true


func populate(ward_id: String) -> void:
	var data := WardDatabase.get_data(ward_id)
	if data.is_empty():
		return

	ward_name.text = data.get("name", "")

	var portrait_path: String = data.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		ward_background.texture = load(portrait_path)

	var element: String = data.get("element", "")
	var sigil_path: String = _SIGIL_TEXTURES.get(element, "")
	if sigil_frame and sigil_path != "" and ResourceLoader.exists(sigil_path):
		sigil_frame.texture = load(sigil_path)

	var skills: Dictionary = data.get("skills", {})
	_fill(icon_q, name_q, cooldown_q, desc_q, skills.get("Q", {}), portrait_path)
	_fill(icon_w, name_w, cooldown_w, desc_w, skills.get("W", {}), portrait_path)
	_fill(icon_e, name_e, cooldown_e, desc_e, skills.get("E", {}), portrait_path)
	_fill_passive(icon_p, name_p, desc_p, skills.get("P", {}), portrait_path)


func _fill(
	icon: TextureRect,
	name_label: Label,
	cd_label: Label,
	desc_label: RichTextLabel,
	skill: Dictionary,
	fallback: String
) -> void:
	if skill.is_empty():
		return

	name_label.text = skill.get("name", "")
	cd_label.text = ""  # не використовуємо — ховаємо щоб не налазило

	var cd: int = skill.get("cd", 0)
	var cd_line: String = "КД: " + str(cd) + " ходи\n" if cd > 0 else ""
	desc_label.text = cd_line + skill.get("desc_full", skill.get("desc", ""))

	var icon_path: String = skill.get("icon", "")
	if icon_path == "":
		icon_path = fallback
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)


func _fill_passive(
	icon: TextureRect,
	name_label: Label,
	desc_label: RichTextLabel,
	skill: Dictionary,
	fallback: String
) -> void:
	if skill.is_empty():
		return

	name_label.text = skill.get("name", "")
	desc_label.text = skill.get("desc_full", skill.get("desc", ""))

	var icon_path: String = skill.get("icon", "")
	if icon_path == "":
		icon_path = fallback
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)

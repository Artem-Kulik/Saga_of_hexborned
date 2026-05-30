extends Node

var WARDS: Dictionary = {
	"mais_oichi": {
		"name": "Майстер Оічі",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/МайстерОічі/Майстер Оічі Скіли.png",
		"short_desc_file": "res://Основа/char/Вогонь/МайстерОічі/skills_short.txt",
		"skills": {
			"P": { "name": "Раж",            "icon": "res://Основа/char/Вогонь/МайстерОічі/P.png", "desc": "" },
			"Q": { "name": "Випад",          "icon": "res://Основа/char/Вогонь/МайстерОічі/Q.png", "desc": "" },
			"W": { "name": "Жар",            "icon": "res://Основа/char/Вогонь/МайстерОічі/W.png", "desc": "" },
			"E": { "name": "Чесний бій",     "icon": "res://Основа/char/Вогонь/МайстерОічі/E.png", "desc": "" },
		}
	},
	"zhnets": {
		"name": "Жнець",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Жнець/Жнець.png",
		"short_desc_file": "res://Основа/char/Вогонь/Жнець/skills_short.txt",
		"skills": {
			"P": { "name": "Присутність",        "icon": "", "desc": "" },
			"Q": { "name": "Прокляття жнеця",    "icon": "", "desc": "" },
			"W": { "name": "Маска горгони",       "icon": "", "desc": "" },
			"E": { "name": "Жнива",               "icon": "", "desc": "" },
		}
	},
	"otsii": {
		"name": "Оцій",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Оцій/Оцій.png",
		"short_desc_file": "res://Основа/char/Вогонь/Оцій/skills_short.txt",
		"skills": {
			"P": { "name": "Пасивна",                  "icon": "", "desc": "" },
			"Q": { "name": "Вигорання",                "icon": "", "desc": "" },
			"W": { "name": "Коло пекельного вогню",    "icon": "", "desc": "" },
			"E": { "name": "Рик",                      "icon": "", "desc": "" },
		}
	},
	"siomyi": {
		"name": "Сьомий слуга",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Сьомийслуга/Сьомий слуга.png",
		"short_desc_file": "res://Основа/char/Вогонь/Сьомийслуга/skills_short.txt",
		"skills": {
			"P": { "name": "З пилу жару",      "icon": "", "desc": "" },
			"Q": { "name": "Покарання",        "icon": "", "desc": "" },
			"W": { "name": "Бар'єр",           "icon": "", "desc": "" },
			"E": { "name": "Вогонь сьомого",   "icon": "", "desc": "" },
		}
	},
	"liah": {
		"name": "Лія",
		"element": "water",
		"portrait": "res://Основа/char/Вода/Лія/Liah.png",
		"short_desc_file": "res://Основа/char/Вода/Лія/skills_short.txt",
		"skills": {
			"P": { "name": "Спокій",                     "icon": "res://Основа/char/Вода/Лія/liah_p.png", "desc": "" },
			"Q": { "name": "Течія",                      "icon": "res://Основа/char/Вода/Лія/liah_q.png", "desc": "" },
			"W": { "name": "Кола на воді",               "icon": "res://Основа/char/Вода/Лія/liah_w.png", "desc": "" },
			"E": { "name": "Загороджуючий водопад",      "icon": "res://Основа/char/Вода/Лія/liah_e.png", "desc": "" },
		}
	},
	"riker": {
		"name": "Рікер",
		"element": "water",
		"portrait": "res://Основа/char/Вода/Рікер/Рікер.png",
		"short_desc_file": "res://Основа/char/Вода/Рікер/skills_short.txt",
		"skills": {
			"P": { "name": "На волосині",       "icon": "", "desc": "" },
			"Q": { "name": "Роздирання",        "icon": "", "desc": "" },
			"W": { "name": "Стиль Доломедес",  "icon": "", "desc": "" },
			"E": { "name": "Кігті",             "icon": "", "desc": "" },
		}
	},
	"adoneia": {
		"name": "Адонея",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Адонея/Адонея.png",
		"short_desc_file": "res://Основа/char/Земля/Адонея/skills_short.txt",
		"skills": {
			"P": { "name": "Пасивна",                  "icon": "", "desc": "" },
			"Q": { "name": "Пролом",                   "icon": "", "desc": "" },
			"W": { "name": "Майстер кулачного бою",    "icon": "", "desc": "" },
			"E": { "name": "Голем",                    "icon": "", "desc": "" },
		}
	},
	"grump": {
		"name": "Грумп",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Грумп/Грумп.png",
		"short_desc_file": "res://Основа/char/Земля/Грумп/skills_short.txt",
		"skills": {
			"P": { "name": "Наростання породи",  "icon": "", "desc": "" },
			"Q": { "name": "Клятва Варда",        "icon": "", "desc": "" },
			"W": { "name": "Борозда",             "icon": "", "desc": "" },
			"E": { "name": "Вибух породи",        "icon": "", "desc": "" },
		}
	},
	"kromius": {
		"name": "Кроміус",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Кроміус/Кроміус.png",
		"short_desc_file": "res://Основа/char/Земля/Кроміус/skills_short.txt",
		"skills": {
			"P": { "name": "Пасивна",           "icon": "", "desc": "" },
			"Q": { "name": "Роздирання",        "icon": "", "desc": "" },
			"W": { "name": "Відступ",           "icon": "", "desc": "" },
			"E": { "name": "Інстинкт вожака",   "icon": "", "desc": "" },
		}
	},
	"parasyt": {
		"name": "Паразит",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Паразит/Земля Паразит.png",
		"short_desc_file": "res://Основа/char/Земля/Паразит/skills_short.txt",
		"skills": {
			"P": { "name": "Паразитування",  "icon": "", "desc": "" },
			"Q": { "name": "Укол",           "icon": "", "desc": "" },
			"W": { "name": "Асиміляція",     "icon": "", "desc": "" },
			"E": { "name": "Плач чаші",      "icon": "", "desc": "" },
		}
	},
	"fizita": {
		"name": "Фізіта",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Фізіта/Фізіта.png",
		"short_desc_file": "res://Основа/char/Земля/Фізіта/skills_short.txt",
		"skills": {
			"P": { "name": "Тяжіння",    "icon": "", "desc": "" },
			"Q": { "name": "Шквал",      "icon": "", "desc": "" },
			"W": { "name": "Стіна",      "icon": "", "desc": "" },
			"E": { "name": "Смятіння",   "icon": "", "desc": "" },
		}
	},
	"shusima": {
		"name": "Шусіма",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Шусіма/Шусіма.png",
		"short_desc_file": "res://Основа/char/Земля/Шусіма/skills_short.txt",
		"skills": {
			"P": { "name": "Розсипання",  "icon": "", "desc": "" },
			"Q": { "name": "Висушення",   "icon": "", "desc": "" },
			"W": { "name": "Зибучі піски","icon": "", "desc": "" },
			"E": { "name": "Розпад",      "icon": "", "desc": "" },
		}
	},
	"iskoris": {
		"name": "Іскоріс",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Іскоріс/Iskoris.png",
		"short_desc_file": "res://Основа/char/Повітря/Іскоріс/skills_short.txt",
		"skills": {
			"P": { "name": "Тисяча порізів",  "icon": "", "desc": "" },
			"Q": { "name": "Укус",            "icon": "", "desc": "" },
			"W": { "name": "Пісня мерця",     "icon": "", "desc": "" },
			"E": { "name": "Ріжучий смерч",   "icon": "", "desc": "" },
		}
	},
	"etesena": {
		"name": "Етесена",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Етесена/Etesena.png",
		"short_desc_file": "res://Основа/char/Повітря/Етесена/skills_short.txt",
		"skills": {
			"P": { "name": "Пасивна",        "icon": "", "desc": "" },
			"Q": { "name": "Укол",           "icon": "", "desc": "" },
			"W": { "name": "Танець",         "icon": "", "desc": "" },
			"E": { "name": "Північні вітри", "icon": "", "desc": "" },
		}
	},
	"shopey": {
		"name": "Шопей",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Шопей/Shopey.png",
		"short_desc_file": "res://Основа/char/Повітря/Шопей/skills_short.txt",
		"skills": {
			"P": { "name": "Відсічена гідра",    "icon": "res://Основа/char/Повітря/Шопей/shopey_p.png", "desc": "" },
			"Q": { "name": "Поривистий випад",   "icon": "res://Основа/char/Повітря/Шопей/shopey_q.png", "desc": "" },
			"W": { "name": "Ріжуча гідра",       "icon": "res://Основа/char/Повітря/Шопей/shopey_w.png", "desc": "" },
			"E": { "name": "Наскок",             "icon": "res://Основа/char/Повітря/Шопей/shopey_e.png", "desc": "" },
		}
	},
}


func _ready() -> void:
	_load_short_descs()


func _load_short_descs() -> void:
	for id in WARDS:
		var path: String = WARDS[id].get("short_desc_file", "")
		if path.is_empty() or not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		while not file.eof_reached():
			var line := file.get_line().strip_edges()
			if line.length() < 3:
				continue
			var sep := line.find(":")
			if sep < 0:
				continue
			var key := line.substr(0, sep).strip_edges().to_upper()
			var val := line.substr(sep + 1).strip_edges()
			if key in WARDS[id]["skills"]:
				WARDS[id]["skills"][key]["desc"] = val
		file.close()


func get_data(id: String) -> Dictionary:
	return WARDS.get(id, {})


func get_by_element(element: String) -> Array:
	var result: Array = []
	for id in WARDS:
		if WARDS[id]["element"] == element:
			result.append(id)
	return result


func get_all_ids() -> Array:
	return WARDS.keys()

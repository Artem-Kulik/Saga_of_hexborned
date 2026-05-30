extends Node

var WARDS: Dictionary = {
	"mais_oichi": {
		"name": "Майстер Оічі",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/МайстерОічі/Майстер Оічі Скіли.png",
		"short_desc_file": "res://Основа/char/Вогонь/МайстерОічі/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Вогонь/МайстерОічі/skills_full.txt",
		"skills": {
			"P": { "name": "Раж",         "cd": 0, "icon": "res://Основа/char/Вогонь/МайстерОічі/P.png", "desc": "", "desc_full": "" },
			"Q": { "name": "Випад",       "cd": 0, "icon": "res://Основа/char/Вогонь/МайстерОічі/Q.png", "desc": "", "desc_full": "" },
			"W": { "name": "Жар",         "cd": 2, "icon": "res://Основа/char/Вогонь/МайстерОічі/W.png", "desc": "", "desc_full": "" },
			"E": { "name": "Чесний бій",  "cd": 5, "icon": "res://Основа/char/Вогонь/МайстерОічі/E.png", "desc": "", "desc_full": "" },
		}
	},
	"zhnets": {
		"name": "Жнець",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Жнець/Жнець.png",
		"short_desc_file": "res://Основа/char/Вогонь/Жнець/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Вогонь/Жнець/skills_full.txt",
		"skills": {
			"P": { "name": "Присутність",     "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Прокляття жнеця", "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Маска горгони",   "cd": 4, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Жнива",           "cd": 3, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"otsii": {
		"name": "Оцій",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Оцій/Оцій.png",
		"short_desc_file": "res://Основа/char/Вогонь/Оцій/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Вогонь/Оцій/skills_full.txt",
		"skills": {
			"P": { "name": "Пасивна",               "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Вигорання",             "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Коло пекельного вогню", "cd": 4, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Рик",                   "cd": 4, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"siomyi": {
		"name": "Сьомий слуга",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Сьомийслуга/Сьомий слуга.png",
		"short_desc_file": "res://Основа/char/Вогонь/Сьомийслуга/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Вогонь/Сьомийслуга/skills_full.txt",
		"skills": {
			"P": { "name": "З пилу жару",    "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Покарання",      "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Бар'єр",         "cd": 3, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Вогонь сьомого", "cd": 7, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"liah": {
		"name": "Лія",
		"element": "water",
		"portrait": "res://Основа/char/Вода/Лія/Liah.png",
		"short_desc_file": "res://Основа/char/Вода/Лія/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Вода/Лія/skills_full.txt",
		"skills": {
			"P": { "name": "Спокій",                "cd": 0, "icon": "res://Основа/char/Вода/Лія/liah_p.png", "desc": "", "desc_full": "" },
			"Q": { "name": "Течія",                 "cd": 0, "icon": "res://Основа/char/Вода/Лія/liah_q.png", "desc": "", "desc_full": "" },
			"W": { "name": "Кола на воді",          "cd": 2, "icon": "res://Основа/char/Вода/Лія/liah_w.png", "desc": "", "desc_full": "" },
			"E": { "name": "Загороджуючий водопад", "cd": 3, "icon": "res://Основа/char/Вода/Лія/liah_e.png", "desc": "", "desc_full": "" },
		}
	},
	"riker": {
		"name": "Рікер",
		"element": "water",
		"portrait": "res://Основа/char/Вода/Рікер/Рікер.png",
		"short_desc_file": "res://Основа/char/Вода/Рікер/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Вода/Рікер/skills_full.txt",
		"skills": {
			"P": { "name": "На волосині",    "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Роздирання",     "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Стиль Доломедес","cd": 2, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Кігті",          "cd": 0, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"adoneia": {
		"name": "Адонея",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Адонея/Адонея.png",
		"short_desc_file": "res://Основа/char/Земля/Адонея/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Земля/Адонея/skills_full.txt",
		"skills": {
			"P": { "name": "Пасивна",               "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Пролом",                "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Майстер кулачного бою", "cd": 4, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Голем",                 "cd": 8, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"grump": {
		"name": "Грумп",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Грумп/Грумп.png",
		"short_desc_file": "res://Основа/char/Земля/Грумп/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Земля/Грумп/skills_full.txt",
		"skills": {
			"P": { "name": "Наростання породи", "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Клятва Варда",       "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Борозда",            "cd": 3, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Вибух породи",       "cd": 2, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"kromius": {
		"name": "Кроміус",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Кроміус/Кроміус.png",
		"short_desc_file": "res://Основа/char/Земля/Кроміус/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Земля/Кроміус/skills_full.txt",
		"skills": {
			"P": { "name": "Пасивна",         "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Роздирання",      "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Відступ",         "cd": 3, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Інстинкт вожака", "cd": 2, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"parasyt": {
		"name": "Паразит",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Паразит/Земля Паразит.png",
		"short_desc_file": "res://Основа/char/Земля/Паразит/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Земля/Паразит/skills_full.txt",
		"skills": {
			"P": { "name": "Паразитування", "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Укол",          "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Асиміляція",    "cd": 2, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Плач чаші",     "cd": 2, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"fizita": {
		"name": "Фізіта",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Фізіта/Фізіта.png",
		"short_desc_file": "res://Основа/char/Земля/Фізіта/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Земля/Фізіта/skills_full.txt",
		"skills": {
			"P": { "name": "Тяжіння",  "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Шквал",    "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Стіна",    "cd": 1, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Смятіння", "cd": 0, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"shusima": {
		"name": "Шусіма",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Шусіма/Шусіма.png",
		"short_desc_file": "res://Основа/char/Земля/Шусіма/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Земля/Шусіма/skills_full.txt",
		"skills": {
			"P": { "name": "Розсипання",   "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Висушення",    "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Зибучі піски", "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Розпад",       "cd": 3, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"iskoris": {
		"name": "Іскоріс",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Іскоріс/Iskoris.png",
		"short_desc_file": "res://Основа/char/Повітря/Іскоріс/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Повітря/Іскоріс/skills_full.txt",
		"skills": {
			"P": { "name": "Тисяча порізів", "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Укус",           "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Пісня мерця",    "cd": 4, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Ріжучий смерч",  "cd": 4, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"etesena": {
		"name": "Етесена",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Етесена/Etesena.png",
		"short_desc_file": "res://Основа/char/Повітря/Етесена/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Повітря/Етесена/skills_full.txt",
		"skills": {
			"P": { "name": "Пасивна",        "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "name": "Укол",           "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "name": "Танець",         "cd": 3, "icon": "", "desc": "", "desc_full": "" },
			"E": { "name": "Північні вітри", "cd": 5, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"shopey": {
		"name": "Шопей",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Шопей/Shopey.png",
		"short_desc_file": "res://Основа/char/Повітря/Шопей/skills_short.txt",
		"full_desc_file":  "res://Основа/char/Повітря/Шопей/skills_full.txt",
		"skills": {
			"P": { "name": "Відсічена гідра",  "cd": 0, "icon": "res://Основа/char/Повітря/Шопей/shopey_p.png", "desc": "", "desc_full": "" },
			"Q": { "name": "Поривистий випад", "cd": 0, "icon": "res://Основа/char/Повітря/Шопей/shopey_q.png", "desc": "", "desc_full": "" },
			"W": { "name": "Ріжуча гідра",    "cd": 3, "icon": "res://Основа/char/Повітря/Шопей/shopey_w.png", "desc": "", "desc_full": "" },
			"E": { "name": "Наскок",          "cd": 3, "icon": "res://Основа/char/Повітря/Шопей/shopey_e.png", "desc": "", "desc_full": "" },
		}
	},
}


func _ready() -> void:
	_load_descs("short_desc_file", "desc")
	_load_descs("full_desc_file",  "desc_full")


func _load_descs(file_key: String, target_field: String) -> void:
	for id in WARDS:
		var path: String = WARDS[id].get(file_key, "")
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
				WARDS[id]["skills"][key][target_field] = val
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

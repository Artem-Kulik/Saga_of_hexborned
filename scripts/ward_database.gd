extends Node

var WARDS: Dictionary = {
	"mais_oichi": {
		"name": "Майстер Оічі",
		"element": "fire",
		"portrait": "res://Основа/char/fire/MasterOichi/Oichi.png",
		"short_desc_file": "res://Основа/char/fire/MasterOichi/skills_short.txt",
		"full_desc_file":  "res://Основа/char/fire/MasterOichi/skills_full.txt",
		"skills": {
			"P": { "id": "mais_oichi_p", "damage_type": "passive", "name": "Раж",        "cd": 0, "icon": "res://Основа/char/fire/MasterOichi/P.png", "desc": "", "desc_full": "" },
			"Q": { "id": "mais_oichi_q", "damage_type": "phys",    "name": "Випад",      "cd": 0, "icon": "res://Основа/char/fire/MasterOichi/Q.png", "desc": "", "desc_full": "" },
			"W": { "id": "mais_oichi_w", "damage_type": "fire",    "name": "Жар",        "cd": 2, "icon": "res://Основа/char/fire/MasterOichi/W.png", "desc": "", "desc_full": "" },
			"E": { "id": "mais_oichi_e", "damage_type": "phys",    "name": "Чесний бій", "cd": 5, "icon": "res://Основа/char/fire/MasterOichi/E.png", "desc": "", "desc_full": "" },
		}
	},
	"zhnets": {
		"name": "Жнець",
		"element": "fire",
		"portrait": "res://Основа/char/fire/Znec/Znec.png",
		"short_desc_file": "res://Основа/char/fire/Znec/skills_short.txt",
		"full_desc_file":  "res://Основа/char/fire/Znec/skills_full.txt",
		"skills": {
			"P": { "id": "zhnets_p", "damage_type": "passive", "name": "Присутність",     "cd": 0, "icon": "res://Основа/char/fire/Znec/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "zhnets_q", "damage_type": "fire",    "name": "Прокляття жнеця", "cd": 0, "icon": "res://Основа/char/fire/Znec/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "zhnets_w", "damage_type": "fire",    "name": "Маска горгони",   "cd": 4, "icon": "res://Основа/char/fire/Znec/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "zhnets_e", "damage_type": "fire",    "name": "Жнива",           "cd": 3, "icon": "res://Основа/char/fire/Znec/e.png", "desc": "", "desc_full": "" },
		}
	},
	"otsii": {
		"name": "Оцій",
		"element": "fire",
		"portrait": "res://Основа/char/fire/Ocii/Ocii.png",
		"short_desc_file": "res://Основа/char/fire/Ocii/skills_short.txt",
		"full_desc_file":  "res://Основа/char/fire/Ocii/skills_full.txt",
		"skills": {
			"P": { "id": "otsii_p", "damage_type": "passive", "name": "Пасивна",               "cd": 0, "icon": "res://Основа/char/fire/Ocii/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "otsii_q", "damage_type": "fire",    "name": "Вигорання",             "cd": 0, "icon": "res://Основа/char/fire/Ocii/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "otsii_w", "damage_type": "fire",    "name": "Коло пекельного вогню", "cd": 4, "icon": "res://Основа/char/fire/Ocii/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "otsii_e", "damage_type": "phys",    "name": "Рик",                   "cd": 4, "icon": "res://Основа/char/fire/Ocii/e.png", "desc": "", "desc_full": "" },
		}
	},
	"siomyi": {
		"name": "Сьомий слуга",
		"element": "fire",
		"portrait": "res://Основа/char/fire/Prayer/Prayer.png",
		"short_desc_file": "res://Основа/char/fire/Prayer/skills_short.txt",
		"full_desc_file":  "res://Основа/char/fire/Prayer/skills_full.txt",
		"skills": {
			"P": { "id": "siomyi_p", "damage_type": "passive", "name": "З пилу жару",    "cd": 0, "icon": "res://Основа/char/fire/Prayer/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "siomyi_q", "damage_type": "phys",    "name": "Покарання",      "cd": 0, "icon": "res://Основа/char/fire/Prayer/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "siomyi_w", "damage_type": "passive", "name": "Бар'єр",         "cd": 3, "icon": "res://Основа/char/fire/Prayer/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "siomyi_e", "damage_type": "fire",    "name": "Вогонь сьомого", "cd": 7, "icon": "res://Основа/char/fire/Prayer/e.png", "desc": "", "desc_full": "" },
		}
	},
	"liah": {
		"name": "Лія",
		"element": "water",
		"portrait": "res://Основа/char/water/Liah/Liah.png",
		"short_desc_file": "res://Основа/char/water/Liah/skills_short.txt",
		"full_desc_file":  "res://Основа/char/water/Liah/skills_full.txt",
		"skills": {
			"P": { "id": "liah_p", "damage_type": "passive", "name": "Спокій",                "cd": 0, "icon": "res://Основа/char/water/Liah/liah_p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "liah_q", "damage_type": "phys",    "name": "Течія",                 "cd": 0, "icon": "res://Основа/char/water/Liah/liah_q.png", "desc": "", "desc_full": "" },
			"W": { "id": "liah_w", "damage_type": "water",   "name": "Кола на воді",          "cd": 2, "icon": "res://Основа/char/water/Liah/liah_w.png", "desc": "", "desc_full": "" },
			"E": { "id": "liah_e", "damage_type": "water",   "name": "Загороджуючий водопад", "cd": 3, "icon": "res://Основа/char/water/Liah/liah_e.png", "desc": "", "desc_full": "" },
		}
	},
	"riker": {
		"name": "Рікер",
		"element": "water",
		"portrait": "res://Основа/char/water/Ricker/Ricker.png",
		"short_desc_file": "res://Основа/char/water/Ricker/skills_short.txt",
		"full_desc_file":  "res://Основа/char/water/Ricker/skills_full.txt",
		"skills": {
			"P": { "id": "riker_p", "damage_type": "passive", "name": "На волосині",     "cd": 0, "icon": "res://Основа/char/water/Ricker/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "riker_q", "damage_type": "phys",    "name": "Роздирання",      "cd": 0, "icon": "res://Основа/char/water/Ricker/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "riker_w", "damage_type": "phys",    "name": "Стиль Доломедес", "cd": 2, "icon": "res://Основа/char/water/Ricker/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "riker_e", "damage_type": "phys",    "name": "Кігті",           "cd": 0, "icon": "res://Основа/char/water/Ricker/e.png", "desc": "", "desc_full": "" },
		}
	},
	"adoneia": {
		"name": "Адонея",
		"element": "earth",
		"portrait": "res://Основа/char/earth/Adoneya/Adoneya.png",
		"short_desc_file": "res://Основа/char/earth/Adoneya/skills_short.txt",
		"full_desc_file":  "res://Основа/char/earth/Adoneya/skills_full.txt",
		"skills": {
			"P": { "id": "adoneia_p", "damage_type": "passive", "name": "Пасивна",               "cd": 0, "icon": "res://Основа/char/earth/Adoneya/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "adoneia_q", "damage_type": "phys",    "name": "Пролом",                "cd": 0, "icon": "res://Основа/char/earth/Adoneya/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "adoneia_w", "damage_type": "phys",    "name": "Майстер кулачного бою", "cd": 4, "icon": "res://Основа/char/earth/Adoneya/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "adoneia_e", "damage_type": "earth",   "name": "Голем",                 "cd": 8, "icon": "res://Основа/char/earth/Adoneya/e.png", "desc": "", "desc_full": "" },
		}
	},
	"adoneia_golem": {
		"name": "Адонея (Голем)",
		"hidden": true,
		"element": "earth",
		"portrait": "res://Основа/char/earth/Adoneya/form_golem.png",
		"skills": {
			"P": { "id": "adoneia_p",      "damage_type": "passive", "name": "Пасивна",                "cd": 0, "icon": "res://Основа/char/earth/Adoneya/p.png",      "desc": "Контратакує при слабкості.", "desc_full": "Контратакує при слабкості." },
			"Q": { "id": "adoneia_golem_q","damage_type": "phys",    "name": "Пролом (Голем)",         "cd": 0, "icon": "res://Основа/char/earth/Adoneya/golem_q.png", "desc": "60(фіз) по всіх ворогах одразу.", "desc_full": "60(фіз) по всіх ворогах одразу." },
			"W": { "id": "adoneia_golem_w","damage_type": "phys",    "name": "Гром кулаків (Голем)",   "cd": 2, "icon": "res://Основа/char/earth/Adoneya/golem_w.png", "desc": "3 удари по 35(фіз) по рандомних цілях. Кожен ударений ворог отримує Провокацію.", "desc_full": "3 удари по 35(фіз) по рандомних цілях. Кожен ударений ворог отримує Провокацію." },
			"E": { "id": "adoneia_e",      "damage_type": "earth",   "name": "Голем",                 "cd": 8, "icon": "res://Основа/char/earth/Adoneya/e.png",      "desc": "Форма Голема активна.", "desc_full": "Форма Голема активна." },
		}
	},
	"grump": {
		"name": "Грумп",
		"element": "earth",
		"portrait": "res://Основа/char/earth/Groomp/Groomp.png",
		"short_desc_file": "res://Основа/char/earth/Groomp/skills_short.txt",
		"full_desc_file":  "res://Основа/char/earth/Groomp/skills_full.txt",
		"skills": {
			"P": { "id": "grump_p", "damage_type": "passive", "name": "Наростання породи", "cd": 0, "icon": "res://Основа/char/earth/Groomp/P.png", "desc": "", "desc_full": "" },
			"Q": { "id": "grump_q", "damage_type": "earth",   "name": "Клятва Варда",      "cd": 0, "icon": "res://Основа/char/earth/Groomp/Q.png", "desc": "", "desc_full": "" },
			"W": { "id": "grump_w", "damage_type": "earth",   "name": "Борозда",           "cd": 3, "icon": "res://Основа/char/earth/Groomp/W.png", "desc": "", "desc_full": "" },
			"E": { "id": "grump_e", "damage_type": "earth",   "name": "Вибух породи",      "cd": 2, "icon": "res://Основа/char/earth/Groomp/E.png", "desc": "", "desc_full": "" },
		}
	},
	"kromius": {
		"name": "Кроміус",
		"hidden": true,
		"element": "earth",
		"portrait": "res://Основа/char/earth/Chromius/Chromius.png",
		"short_desc_file": "res://Основа/char/earth/Chromius/skills_short.txt",
		"full_desc_file":  "res://Основа/char/earth/Chromius/skills_full.txt",
		"skills": {
			"P": { "id": "kromius_p", "damage_type": "passive", "name": "Пасивна",         "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"Q": { "id": "kromius_q", "damage_type": "phys",    "name": "Роздирання",      "cd": 0, "icon": "", "desc": "", "desc_full": "" },
			"W": { "id": "kromius_w", "damage_type": "passive", "name": "Відступ",         "cd": 3, "icon": "", "desc": "", "desc_full": "" },
			"E": { "id": "kromius_e", "damage_type": "phys",    "name": "Інстинкт вожака", "cd": 2, "icon": "", "desc": "", "desc_full": "" },
		}
	},
	"parasyt": {
		"name": "Паразит",
		"hp": 350,
		"element": "earth",
		"portrait": "res://Основа/char/earth/Parazyte/Parazyte.png",
		"short_desc_file": "res://Основа/char/earth/Parazyte/skills_short.txt",
		"full_desc_file":  "res://Основа/char/earth/Parazyte/skills_full.txt",
		"skills": {
			"P": { "id": "parasyt_p", "damage_type": "passive", "name": "Паразитування", "cd": 0, "icon": "res://Основа/char/earth/Parazyte/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "parasyt_q", "damage_type": "phys",    "name": "Укол",          "cd": 0, "icon": "res://Основа/char/earth/Parazyte/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "parasyt_w", "damage_type": "earth",   "name": "Асиміляція",    "cd": 2, "icon": "res://Основа/char/earth/Parazyte/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "parasyt_e", "damage_type": "earth",   "name": "Плач чаші",     "cd": 2, "icon": "res://Основа/char/earth/Parazyte/e.png", "desc": "", "desc_full": "" },
		}
	},
	"fizita": {
		"name": "Фізіта",
		"element": "earth",
		"portrait": "res://Основа/char/earth/Phisita/Phisita.png",
		"short_desc_file": "res://Основа/char/earth/Phisita/skills_short.txt",
		"full_desc_file":  "res://Основа/char/earth/Phisita/skills_full.txt",
		"skills": {
			"P": { "id": "fizita_p", "damage_type": "passive", "name": "Тяжіння",  "cd": 0, "icon": "res://Основа/char/earth/Phisita/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "fizita_q", "damage_type": "earth",   "name": "Шквал",    "cd": 0, "icon": "res://Основа/char/earth/Phisita/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "fizita_w", "damage_type": "earth",   "name": "Стіна",    "cd": 1, "icon": "res://Основа/char/earth/Phisita/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "fizita_e", "damage_type": "earth",   "name": "Сметіння", "cd": 0, "icon": "res://Основа/char/earth/Phisita/e.png", "desc": "Завдає 70 фіз. та накладає Сметіння (12%×N промаху) на ціль. N = стаки Тяжіння.", "desc_full": "Завдає 70 фіз. шкоди. Знімає всі стаки Тяжіння: якщо було N стаків — накладає на ціль Сметіння з шансом промаху 12%×N. Вард зі Сметінням при наступному скілі може промахнутися — скіл перенаправиться на іншого варда (не на атакера і не на початкову ціль)." },
		}
	},
	"shusima": {
		"name": "Шусіма",
		"hp": 350,
		"element": "earth",
		"portrait": "res://Основа/char/earth/ShuSima/ShuSima.png",
		"short_desc_file": "res://Основа/char/earth/ShuSima/skills_short.txt",
		"full_desc_file":  "res://Основа/char/earth/ShuSima/skills_full.txt",
		"skills": {
			"P": { "id": "shusima_p", "damage_type": "passive", "name": "Розсипання",   "cd": 0, "icon": "res://Основа/char/earth/ShuSima/p.png", "desc": "На початку ходу — 90 фіз шкоди собі.", "desc_full": "На початку кожного свого ходу Шусіма отримує 90 фіз. шкоди." },
			"Q": { "id": "shusima_q", "damage_type": "phys",    "name": "Висушення",    "cd": 0, "icon": "res://Основа/char/earth/ShuSima/q.png", "desc": "40 фіз ворогу. +реген 20 HP/хід на 2 ходи собі.", "desc_full": "Атакує ворога — 40 фіз. шкоди. Себе отримує регенерацію: 20 HP на початку кожного з 2 наступних ходів." },
			"W": { "id": "shusima_w", "damage_type": "phys",    "name": "Зибучі піски", "cd": 0, "icon": "res://Основа/char/earth/ShuSima/w.png", "desc": "150 фіз всім вардам. Союзники (та Шусіма) отримують реген 70 HP/хід на 2 ходи.", "desc_full": "Атакує всіх вардів на полі (і союзників, і ворогів, і себе) — 150 фіз. шкоди кожному. Виживші союзники отримують регенерацію 70 HP/хід на 2 ходи." },
			"E": { "id": "shusima_e", "damage_type": "phys",    "name": "Розпад",       "cd": 3, "icon": "res://Основа/char/earth/ShuSima/e.png", "desc": "Рандомному ворогу — фіз шкоди рівну поточному HP Шусіми.", "desc_full": "Завдає випадковому живому ворогу фіз. шкоди, рівну поточному HP Шусіми. Перезарядка — 3 ходи." },
		}
	},
	"iskoris": {
		"name": "Іскоріс",
		"element": "air",
		"portrait": "res://Основа/char/air/Hiskoris/Hiskoris.png",
		"short_desc_file": "res://Основа/char/air/Hiskoris/skills_short.txt",
		"full_desc_file":  "res://Основа/char/air/Hiskoris/skills_full.txt",
		"skills": {
			"P": { "id": "iskoris_p", "damage_type": "passive", "name": "Тисяча порізів", "cd": 0, "icon": "res://Основа/char/air/Hiskoris/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "iskoris_q", "damage_type": "phys",    "name": "Укус",           "cd": 0, "icon": "res://Основа/char/air/Hiskoris/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "iskoris_w", "damage_type": "air",     "name": "Пісня мерця",    "cd": 4, "icon": "res://Основа/char/air/Hiskoris/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "iskoris_e", "damage_type": "air",     "name": "Ріжучий смерч",  "cd": 4, "icon": "res://Основа/char/air/Hiskoris/e.png", "desc": "", "desc_full": "" },
		}
	},
	"etesena": {
		"name": "Етесена",
		"element": "air",
		"portrait": "res://Основа/char/air/Etesena/Etesena.png",
		"short_desc_file": "res://Основа/char/air/Etesena/skills_short.txt",
		"full_desc_file":  "res://Основа/char/air/Etesena/skills_full.txt",
		"skills": {
			"P": { "id": "etesena_p", "damage_type": "passive", "name": "Пасивна",        "cd": 0, "icon": "res://Основа/char/air/Etesena/p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "etesena_q", "damage_type": "phys",    "name": "Укол",           "cd": 0, "icon": "res://Основа/char/air/Etesena/q.png", "desc": "", "desc_full": "" },
			"W": { "id": "etesena_w", "damage_type": "air",     "name": "Танець",         "cd": 3, "icon": "res://Основа/char/air/Etesena/w.png", "desc": "", "desc_full": "" },
			"E": { "id": "etesena_e", "damage_type": "air",     "name": "Північні вітри", "cd": 5, "icon": "res://Основа/char/air/Etesena/e.png", "desc": "", "desc_full": "" },
		}
	},
	"shopey": {
		"name": "Шопей",
		"element": "air",
		"portrait": "res://Основа/char/air/Shopey/Shopey.png",
		"short_desc_file": "res://Основа/char/air/Shopey/skills_short.txt",
		"full_desc_file":  "res://Основа/char/air/Shopey/skills_full.txt",
		"skills": {
			"P": { "id": "shopey_p", "damage_type": "passive", "name": "Відсічена гідра",  "cd": 0, "icon": "res://Основа/char/air/Shopey/shopey_p.png", "desc": "", "desc_full": "" },
			"Q": { "id": "shopey_q", "damage_type": "phys",    "name": "Поривистий випад", "cd": 0, "icon": "res://Основа/char/air/Shopey/shopey_q.png", "desc": "", "desc_full": "" },
			"W": { "id": "shopey_w", "damage_type": "air",     "name": "Ріжуча гідра",    "cd": 3, "icon": "res://Основа/char/air/Shopey/shopey_w.png", "desc": "", "desc_full": "" },
			"E": { "id": "shopey_e", "damage_type": "phys",    "name": "Наскок",          "cd": 3, "icon": "res://Основа/char/air/Shopey/shopey_e.png", "desc": "", "desc_full": "" },
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
		if WARDS[id]["element"] == element and not WARDS[id].get("hidden", false):
			result.append(id)
	return result


func get_all_ids() -> Array:
	var result: Array = []
	for id in WARDS:
		if not WARDS[id].get("hidden", false):
			result.append(id)
	return result

extends Node

const WARDS: Dictionary = {
	"mais_oichi": {
		"name": "Майстер Оічі",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/МайстерОічі/Майстер Оічі Скіли.png"
	},
	"zhnets": {
		"name": "Жнець",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Жнець/Жнець.png"
	},
	"otsii": {
		"name": "Оцій",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Оцій/Оцій.png"
	},
	"siomyi": {
		"name": "Сьомий слуга",
		"element": "fire",
		"portrait": "res://Основа/char/Вогонь/Сьомийслуга/Сьомий слуга.png"
	},
	"liah": {
		"name": "Лія",
		"element": "water",
		"portrait": "res://Основа/char/Вода/Лія/Liah.png"
	},
	"riker": {
		"name": "Рікер",
		"element": "water",
		"portrait": "res://Основа/char/Вода/Рікер/Рікер.png"
	},
	"adoneia": {
		"name": "Адонея",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Адонея/Адонея.png"
	},
	"grump": {
		"name": "Грумп",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Грумп/Грумп.png"
	},
	"kromius": {
		"name": "Кроміус",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Кроміус/Кроміус.png"
	},
	"parasyt": {
		"name": "Паразит",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Паразит/Земля Паразит.png"
	},
	"fizita": {
		"name": "Фізіта",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Фізіта/Фізіта.png"
	},
	"shusima": {
		"name": "Шусіма",
		"element": "earth",
		"portrait": "res://Основа/char/Земля/Шусіма/Шусіма.png"
	},
	"iskoris": {
		"name": "Іскоріс",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Іскоріс/Iskoris.png"
	},
	"etesena": {
		"name": "Етесена",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Етесена/Etesena.png"
	},
	"shopey": {
		"name": "Шопей",
		"element": "air",
		"portrait": "res://Основа/char/Повітря/Шопей/Shopey.png"
	},
}


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

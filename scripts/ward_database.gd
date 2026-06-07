extends Node

var WARDS: Dictionary = {
	"mais_oichi": {
		"name": "Майстер Оічі",
		"element": "fire",
		"portrait": "res://Основа/char/fire/MasterOichi/Oichi.png",
		"short_desc_file": "res://Основа/char/fire/MasterOichi/skills_short.txt",
		"full_desc_file":  "res://Основа/char/fire/MasterOichi/skills_full.txt",
		"skills": {
			"P": { "id": "mais_oichi_p", "damage_type": "passive", "name": "Раж",        "cd": 0, "icon": "res://Основа/char/fire/MasterOichi/P.png", "desc": "Накопичує Раж після кожного удару.", "desc_full": "" },
			"Q": { "id": "mais_oichi_q", "damage_type": "phys",    "name": "Випад",      "cd": 0, "icon": "res://Основа/char/fire/MasterOichi/Q.png", "desc": "Атакує ворога, витрачаючи весь накопичений Раж.", "desc_full": "" },
			"W": { "id": "mais_oichi_w", "damage_type": "fire",    "name": "Жар",        "cd": 2, "icon": "res://Основа/char/fire/MasterOichi/W.png", "desc": "Броня і вогняний щит — контратакує горінням.", "desc_full": "" },
			"E": { "id": "mais_oichi_e", "damage_type": "phys",    "name": "Чесний бій", "cd": 5, "icon": "res://Основа/char/fire/MasterOichi/E.png", "desc": "Масивна броня і провокація ворога.", "desc_full": "" },
		}
	},
	"zhnets": {
		"name": "Жнець",
		"element": "fire",
		"portrait": "res://Основа/char/fire/Znec/Znec.png",
		"short_desc_file": "res://Основа/char/fire/Znec/skills_short.txt",
		"full_desc_file":  "res://Основа/char/fire/Znec/skills_full.txt",
		"skills": {
			"P": { "id": "zhnets_p", "damage_type": "passive", "name": "Присутність",     "cd": 0, "icon": "res://Основа/char/fire/Znec/p.png", "desc": "Ворог нижче 50% HP — підпалює рандомних ворогів.", "desc_full": "" },
			"Q": { "id": "zhnets_q", "damage_type": "fire",    "name": "Прокляття жнеця", "cd": 0, "icon": "res://Основа/char/fire/Znec/q.png", "desc": "Вогнем усіх ворогів + підпалює кожного.", "desc_full": "" },
			"W": { "id": "zhnets_w", "damage_type": "fire",    "name": "Маска горгони",   "cd": 4, "icon": "res://Основа/char/fire/Znec/w.png", "desc": "Сильне горіння на одну ціль.", "desc_full": "" },
			"E": { "id": "zhnets_e", "damage_type": "fire",    "name": "Жнива",           "cd": 3, "icon": "res://Основа/char/fire/Znec/e.png", "desc": "Позначає ціль — наступного ходу спалює її горіння.", "desc_full": "" },
		}
	},
	"otsii": {
		"name": "Оцій",
		"element": "fire",
		"portrait": "res://Основа/char/fire/Ocii/Ocii.png",
		"short_desc_file": "res://Основа/char/fire/Ocii/skills_short.txt",
		"full_desc_file":  "res://Основа/char/fire/Ocii/skills_full.txt",
		"skills": {
			"P": { "id": "otsii_p", "damage_type": "passive", "name": "Пасивна",               "cd": 0, "icon": "res://Основа/char/fire/Ocii/p.png", "desc": "Смерть союзника скорочує КД. Власна — захищає союзника.", "desc_full": "" },
			"Q": { "id": "otsii_q", "damage_type": "fire",    "name": "Вигорання",             "cd": 0, "icon": "res://Основа/char/fire/Ocii/q.png", "desc": "Підпалює рандомного ворога.", "desc_full": "" },
			"W": { "id": "otsii_w", "damage_type": "fire",    "name": "Коло пекельного вогню", "cd": 4, "icon": "res://Основа/char/fire/Ocii/w.png", "desc": "Захищає союзника — атакуючий отримує горіння.", "desc_full": "" },
			"E": { "id": "otsii_e", "damage_type": "phys",    "name": "Рик",                   "cd": 4, "icon": "res://Основа/char/fire/Ocii/e.png", "desc": "Оцій і союзник б'ють ціль разом.", "desc_full": "" },
		}
	},
	"siomyi": {
		"name": "Сьомий слуга",
		"element": "fire",
		"portrait": "res://Основа/char/fire/Prayer/Prayer.png",
		"short_desc_file": "res://Основа/char/fire/Prayer/skills_short.txt",
		"full_desc_file":  "res://Основа/char/fire/Prayer/skills_full.txt",
		"skills": {
			"P": { "id": "siomyi_p", "damage_type": "passive", "name": "З пилу жару",    "cd": 0, "icon": "res://Основа/char/fire/Prayer/p.png", "desc": "На початку ходу підпалює рандомного варда.", "desc_full": "" },
			"Q": { "id": "siomyi_q", "damage_type": "phys",    "name": "Покарання",      "cd": 0, "icon": "res://Основа/char/fire/Prayer/q.png", "desc": "Подовжує горіння ворогу або гасить союзнику.", "desc_full": "" },
			"W": { "id": "siomyi_w", "damage_type": "passive", "name": "Бар'єр",         "cd": 3, "icon": "res://Основа/char/fire/Prayer/w.png", "desc": "Бар'єр союзнику — атакуючий отримує горіння.", "desc_full": "" },
			"E": { "id": "siomyi_e", "damage_type": "fire",    "name": "Вогонь сьомого", "cd": 7, "icon": "res://Основа/char/fire/Prayer/e.png", "desc": "Потребує горіння — спалює стаки і мітить ціль назавжди.", "desc_full": "" },
		}
	},
	"ashayah": {
		"name": "Ошая",
		"element": "air",
		"portrait": "res://Основа/char/air/Ashayah/Ashaya.png",
		"short_desc_file": "res://Основа/char/air/Ashayah/skills_short.txt",
		"full_desc_file":  "res://Основа/char/air/Ashayah/skills_full.txt",
		"skills": {
			"P": { "id": "ashayah_p", "damage_type": "passive", "name": "Крилатий трофей",    "cd": 0, "icon": "res://Основа/char/air/Ashayah/p.png", "desc": "Перший W у бою — краде позитивні статуси у всіх ворогів.", "desc_full": "При першому використанні Східного вітру Ошая також краде перший позитивний статус кожного ворога (або загиблого від удару). Статус копіюється з повною тривалістю і всіма параметрами. Клятва рицаря дощу — особливий випадок: Ошая стає носієм, хілить водяних союзників, але отримує броню замість HP." },
			"Q": { "id": "ashayah_q", "damage_type": "phys",    "name": "Пікирування",         "cd": 0, "icon": "res://Основа/char/air/Ashayah/q.png", "desc": "Б'є обрану ціль і рандомну іншу.", "desc_full": "Пікірує на вибраного ворога — 60 фіз. шкоди. Потім б'є 1 випадкового іншого живого ворога — ще 60 фіз. Якщо інших ворогів немає — лише 1 удар." },
			"W": { "id": "ashayah_w", "damage_type": "air",     "name": "Східний вітер",       "cd": 5, "icon": "res://Основа/char/air/Ashayah/w.png", "desc": "Атакує всіх ворогів і знімає позитивні статуси.", "desc_full": "Б'є всіх ворогів — 30 повітря кожному. Знімає по 1 позитивному статусу з кожного (незалежно від виживання). При першому використанні пасивка дозволяє вкрасти ці статуси собі. Перезарядка: 5 ходів." },
			"E": { "id": "ashayah_e", "damage_type": "air",     "name": "Громовий спис",       "cd": 3, "icon": "res://Основа/char/air/Ashayah/e.png", "desc": "Громовий удар + оглушення. Повторний — б'є всіх.", "desc_full": "Перше використання: 150 повітря обраній цілі та 50 повітря всім іншим ворогам. Ошая отримує оглушення на 2 ходи. Всі наступні використання: 50 повітря всім ворогам без оглушення. Перезарядка: 3 ходи." },
		}
	},
	"velodiy": {
		"name": "Велодій",
		"element": "water",
		"portrait": "res://Основа/char/water/Velodiy/Vilodiy.png",
		"short_desc_file": "res://Основа/char/water/Velodiy/skills_short.txt",
		"full_desc_file":  "res://Основа/char/water/Velodiy/skills_full.txt",
		"skills": {
			"P": { "id": "velodiy_p", "damage_type": "passive", "name": "Захисний рефлекс",           "cd": 2, "icon": "res://Основа/char/water/Velodiy/p.png", "desc": "Шанс відмінити будь-який скіл ворога.", "desc_full": "Щоразу коли ворог використовує скіл — є 35% шанс повністю відмінити його (ворог витрачає хід, ефект не відбувається). Після спрацювання пасивка іде на КД 2 ходи." },
			"Q": { "id": "velodiy_q", "damage_type": "phys",    "name": "Вода камінь точить",         "cd": 0, "icon": "res://Основа/char/water/Velodiy/q.png", "desc": "Атакує ціль і сусідню з нею.", "desc_full": "Завдає 90 фіз. шкоди вибраному ворогу. Також завдає 45 фіз. шкоди сусідній цілі (крайній б'є центр, центральний б'є рандомного крайнього)." },
			"W": { "id": "velodiy_w", "damage_type": "passive", "name": "Фаланга",                    "cd": 5, "icon": "res://Основа/char/water/Velodiy/w.png", "desc": "Контратака. Підвищує власну вхідну шкоду.", "desc_full": "Приймає захисне положення. Накладає на себе контратаку на 2 ходи (при отриманні удару — використовує Q скіл проти атакуючого) та Фалангу на 2 ходи (весь вхідний урон збільшено на 50%). Перезарядка: 5 ходів." },
			"E": { "id": "velodiy_e", "damage_type": "passive", "name": "Клятва рицаря дощу Арная",   "cd": 9, "icon": "res://Основа/char/water/Velodiy/e.png", "desc": "Водяні союзники регенерують HP. Велодій копить броню щохід.", "desc_full": "Викликає дощ на 4 раунди. На початку ходу носія: всі живі водяні союзники +75 HP, Велодій +75 броні. Якщо Велодій гине — клятва передається рандомному водяному союзнику (без бонусу броні). Перезарядка: 9 ходів." },
		}
	},
	"liah": {
		"name": "Лія",
		"element": "water",
		"portrait": "res://Основа/char/water/Liah/Liah.png",
		"short_desc_file": "res://Основа/char/water/Liah/skills_short.txt",
		"full_desc_file":  "res://Основа/char/water/Liah/skills_full.txt",
		"skills": {
			"P": { "id": "liah_p", "damage_type": "passive", "name": "Спокій",                "cd": 0, "icon": "res://Основа/char/water/Liah/liah_p.png", "desc": "Після вбивства — всі союзники відновлюють HP.", "desc_full": "" },
			"Q": { "id": "liah_q", "damage_type": "phys",    "name": "Течія",                 "cd": 0, "icon": "res://Основа/char/water/Liah/liah_q.png", "desc": "Атакує ворога. Повний HP — б'є вдруге.", "desc_full": "" },
			"W": { "id": "liah_w", "damage_type": "water",   "name": "Кола на воді",          "cd": 2, "icon": "res://Основа/char/water/Liah/liah_w.png", "desc": "Атакує всіх ворогів. При вбивстві — повторює.", "desc_full": "" },
			"E": { "id": "liah_e", "damage_type": "water",   "name": "Загороджуючий водопад", "cd": 3, "icon": "res://Основа/char/water/Liah/liah_e.png", "desc": "Стає невразливою до власного наступного ходу.", "desc_full": "" },
		}
	},
	"asteyah": {
		"name": "Астея",
		"element": "water",
		"portrait": "res://Основа/char/water/Asteyah/Asteyah.png",
		"short_desc_file": "res://Основа/char/water/Asteyah/skills_short.txt",
		"full_desc_file":  "res://Основа/char/water/Asteyah/skills_full.txt",
		"skills": {
			"P": { "id": "asteyah_p", "damage_type": "passive", "name": "Пам'ять",         "cd": 0, "icon": "res://Основа/char/water/Asteyah/p.png", "desc": "Автоматично копіює останній скіл ворога в слот E.", "desc_full": "" },
			"Q": { "id": "asteyah_q", "damage_type": "water",   "name": "Кенсел",          "cd": 0, "icon": "res://Основа/char/water/Asteyah/q.png", "desc": "Атакує ворога і затримує один із його скілів.",              "desc_full": "" },
			"W": { "id": "asteyah_w", "damage_type": "passive", "name": "Таємні знання",   "cd": 6, "icon": "res://Основа/char/water/Asteyah/w.png", "desc": "Отримує регенерацію і ходить ще раз.",              "desc_full": "" },
			"E": { "id": "asteyah_e", "damage_type": "passive", "name": "Пам'ять (E)",     "cd": 0, "icon": "res://Основа/char/water/Asteyah/e.png", "desc": "Використовує скопійований скіл ворога.",             "desc_full": "" },
		}
	},
	"riker": {
		"name": "Рікер",
		"element": "water",
		"portrait": "res://Основа/char/water/Ricker/Ricker.png",
		"short_desc_file": "res://Основа/char/water/Ricker/skills_short.txt",
		"full_desc_file":  "res://Основа/char/water/Ricker/skills_full.txt",
		"skills": {
			"P": { "id": "riker_p", "damage_type": "passive", "name": "На волосині",     "cd": 0, "icon": "res://Основа/char/water/Ricker/p.png", "desc": "Перехоплює смертельний удар — авто-E перед смертю.", "desc_full": "" },
			"Q": { "id": "riker_q", "damage_type": "phys",    "name": "Роздирання",      "cd": 0, "icon": "res://Основа/char/water/Ricker/q.png", "desc": "Б'є ціль двічі.", "desc_full": "" },
			"W": { "id": "riker_w", "damage_type": "phys",    "name": "Стиль Доломедес", "cd": 2, "icon": "res://Основа/char/water/Ricker/w.png", "desc": "Після Q — потрійний. Після E — б'є всіх ворогів.", "desc_full": "" },
			"E": { "id": "riker_e", "damage_type": "phys",    "name": "Кігті",           "cd": 0, "icon": "res://Основа/char/water/Ricker/e.png", "desc": "Б'є ціль і сусідню з нею.", "desc_full": "" },
		}
	},
	"adoneia": {
		"name": "Адонея",
		"element": "earth",
		"portrait": "res://Основа/char/earth/Adoneya/Adoneya.png",
		"short_desc_file": "res://Основа/char/earth/Adoneya/skills_short.txt",
		"full_desc_file":  "res://Основа/char/earth/Adoneya/skills_full.txt",
		"skills": {
			"P": { "id": "adoneia_p", "damage_type": "passive", "name": "Пасивна",               "cd": 0, "icon": "res://Основа/char/earth/Adoneya/p.png", "desc": "При падінні нижче 50% HP — Контратака.", "desc_full": "" },
			"Q": { "id": "adoneia_q", "damage_type": "phys",    "name": "Пролом",                "cd": 0, "icon": "res://Основа/char/earth/Adoneya/q.png", "desc": "Б'є ціль двічі. Голем — атакує всіх.", "desc_full": "" },
			"W": { "id": "adoneia_w", "damage_type": "phys",    "name": "Майстер кулачного бою", "cd": 4, "icon": "res://Основа/char/earth/Adoneya/w.png", "desc": "Атакує і провокує ворога. Голем — потрійний удар.", "desc_full": "" },
			"E": { "id": "adoneia_e", "damage_type": "earth",   "name": "Голем",                 "cd": 8, "icon": "res://Основа/char/earth/Adoneya/e.png", "desc": "Форма Голема: більше HP, посилені Q та W.", "desc_full": "" },
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
			"P": { "id": "grump_p", "damage_type": "passive", "name": "Наростання породи", "cd": 0, "icon": "res://Основа/char/earth/Groomp/P.png", "desc": "Після кожного скілу +25 броні.", "desc_full": "" },
			"Q": { "id": "grump_q", "damage_type": "earth",   "name": "Клятва Варда",      "cd": 0, "icon": "res://Основа/char/earth/Groomp/Q.png", "desc": "Атакує всіх ворогів.", "desc_full": "" },
			"W": { "id": "grump_w", "damage_type": "earth",   "name": "Борозда",           "cd": 3, "icon": "res://Основа/char/earth/Groomp/W.png", "desc": "Атакує і оглушує одного ворога.", "desc_full": "" },
			"E": { "id": "grump_e", "damage_type": "earth",   "name": "Вибух породи",      "cd": 2, "icon": "res://Основа/char/earth/Groomp/E.png", "desc": "Вивільняє всю броню — шкода всім ворогам.", "desc_full": "" },
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
			"P": { "id": "parasyt_p", "damage_type": "passive", "name": "Паразитування", "cd": 0, "icon": "res://Основа/char/earth/Parazyte/p.png", "desc": "Відновлює HP після кожної смерті ворога.", "desc_full": "" },
			"Q": { "id": "parasyt_q", "damage_type": "phys",    "name": "Укол",          "cd": 0, "icon": "res://Основа/char/earth/Parazyte/q.png", "desc": "Атакує одного ворога.", "desc_full": "" },
			"W": { "id": "parasyt_w", "damage_type": "earth",   "name": "Асиміляція",    "cd": 2, "icon": "res://Основа/char/earth/Parazyte/w.png", "desc": "Жертвує HP — ворог б'є свого союзника наступного ходу.", "desc_full": "" },
			"E": { "id": "parasyt_e", "damage_type": "earth",   "name": "Плач чаші",     "cd": 2, "icon": "res://Основа/char/earth/Parazyte/e.png", "desc": "Жертвує HP і отримує тривалу регенерацію.", "desc_full": "" },
		}
	},
	"fizita": {
		"name": "Фізіта",
		"element": "earth",
		"portrait": "res://Основа/char/earth/Phisita/Phisita.png",
		"short_desc_file": "res://Основа/char/earth/Phisita/skills_short.txt",
		"full_desc_file":  "res://Основа/char/earth/Phisita/skills_full.txt",
		"skills": {
			"P": { "id": "fizita_p", "damage_type": "passive", "name": "Тяжіння",  "cd": 0, "icon": "res://Основа/char/earth/Phisita/p.png", "desc": "Накопичує стаки Тяжіння щохід — посилює всі скіли.", "desc_full": "" },
			"Q": { "id": "fizita_q", "damage_type": "earth",   "name": "Шквал",    "cd": 0, "icon": "res://Основа/char/earth/Phisita/q.png", "desc": "Витрачає всі стаки — потужний удар по цілі.", "desc_full": "" },
			"W": { "id": "fizita_w", "damage_type": "earth",   "name": "Стіна",    "cd": 1, "icon": "res://Основа/char/earth/Phisita/w.png", "desc": "Кам'яна стіна союзнику — поглинає удари.", "desc_full": "" },
			"E": { "id": "fizita_e", "damage_type": "earth",   "name": "Сметіння", "cd": 0, "icon": "res://Основа/char/earth/Phisita/e.png", "desc": "Атакує ціль — шанс промаху наступного її скілу.", "desc_full": "Завдає 70 фіз. шкоди. Знімає всі стаки Тяжіння: якщо було N стаків — накладає на ціль Сметіння з шансом промаху 12%×N. Вард зі Сметінням при наступному скілі може промахнутися — скіл перенаправиться на іншого варда (не на атакера і не на початкову ціль)." },
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
			"P": { "id": "shusima_p", "damage_type": "passive", "name": "Розсипання",   "cd": 0, "icon": "res://Основа/char/earth/ShuSima/p.png", "desc": "Щоходу отримує пошкодження.", "desc_full": "На початку кожного свого ходу Шусіма отримує 90 фіз. шкоди." },
			"Q": { "id": "shusima_q", "damage_type": "phys",    "name": "Висушення",    "cd": 0, "icon": "res://Основа/char/earth/ShuSima/q.png", "desc": "Атакує ворога і відновлює власне здоров'я.", "desc_full": "Атакує ворога — 40 фіз. шкоди. Себе отримує регенерацію: 20 HP на початку кожного з 2 наступних ходів." },
			"W": { "id": "shusima_w", "damage_type": "phys",    "name": "Зибучі піски", "cd": 0, "icon": "res://Основа/char/earth/ShuSima/w.png", "desc": "Атакує всіх вардів + регенерація союзникам.", "desc_full": "Атакує всіх вардів на полі (і союзників, і ворогів, і себе) — 150 фіз. шкоди кожному. Виживші союзники отримують регенерацію 70 HP/хід на 2 ходи." },
			"E": { "id": "shusima_e", "damage_type": "phys",    "name": "Розпад",       "cd": 3, "icon": "res://Основа/char/earth/ShuSima/e.png", "desc": "Б'є рандомного ворога на силу власного HP.", "desc_full": "Завдає випадковому живому ворогу фіз. шкоди, рівну поточному HP Шусіми. Перезарядка — 3 ходи." },
		}
	},
	"iskoris": {
		"name": "Іскоріс",
		"element": "air",
		"portrait": "res://Основа/char/air/Hiskoris/Hiskoris.png",
		"short_desc_file": "res://Основа/char/air/Hiskoris/skills_short.txt",
		"full_desc_file":  "res://Основа/char/air/Hiskoris/skills_full.txt",
		"skills": {
			"P": { "id": "iskoris_p", "damage_type": "passive", "name": "Тисяча порізів", "cd": 0, "icon": "res://Основа/char/air/Hiskoris/p.png", "desc": "Кожен удар + пасивна шкода + Порізи на ціль.", "desc_full": "" },
			"Q": { "id": "iskoris_q", "damage_type": "phys",    "name": "Укус",           "cd": 0, "icon": "res://Основа/char/air/Hiskoris/q.png", "desc": "Атакує ціль. Сила росте зі стаками Порізів.", "desc_full": "" },
			"W": { "id": "iskoris_w", "damage_type": "air",     "name": "Пісня мерця",    "cd": 4, "icon": "res://Основа/char/air/Hiskoris/w.png", "desc": "Б'є ціль двічі.", "desc_full": "" },
			"E": { "id": "iskoris_e", "damage_type": "air",     "name": "Ріжучий смерч",  "cd": 4, "icon": "res://Основа/char/air/Hiskoris/e.png", "desc": "Атакує всіх ворогів.", "desc_full": "" },
		}
	},
	"etesena": {
		"name": "Етесена",
		"element": "air",
		"portrait": "res://Основа/char/air/Etesena/Etesena.png",
		"short_desc_file": "res://Основа/char/air/Etesena/skills_short.txt",
		"full_desc_file":  "res://Основа/char/air/Etesena/skills_full.txt",
		"skills": {
			"P": { "id": "etesena_p", "damage_type": "passive", "name": "Пасивна",        "cd": 0, "icon": "res://Основа/char/air/Etesena/p.png", "desc": "Удар по оглушеному — може пробити до сусідньої цілі.", "desc_full": "" },
			"Q": { "id": "etesena_q", "damage_type": "phys",    "name": "Укол",           "cd": 0, "icon": "res://Основа/char/air/Etesena/q.png", "desc": "Три голки в рандомні цілі.", "desc_full": "" },
			"W": { "id": "etesena_w", "damage_type": "air",     "name": "Танець",         "cd": 3, "icon": "res://Основа/char/air/Etesena/w.png", "desc": "Б'є трьох різних вардів з різними ефектами.", "desc_full": "" },
			"E": { "id": "etesena_e", "damage_type": "air",     "name": "Північні вітри", "cd": 5, "icon": "res://Основа/char/air/Etesena/e.png", "desc": "Серія ударів. Якщо ціль оглушена — подовжує оглушення.", "desc_full": "" },
		}
	},
	"shopey": {
		"name": "Шопей",
		"element": "air",
		"portrait": "res://Основа/char/air/Shopey/Shopey.png",
		"short_desc_file": "res://Основа/char/air/Shopey/skills_short.txt",
		"full_desc_file":  "res://Основа/char/air/Shopey/skills_full.txt",
		"skills": {
			"P": { "id": "shopey_p", "damage_type": "passive", "name": "Відсічена гідра",  "cd": 0, "icon": "res://Основа/char/air/Shopey/shopey_p.png", "desc": "Шанс після удару — вдарити сусідню ціль (Гідра).", "desc_full": "" },
			"Q": { "id": "shopey_q", "damage_type": "phys",    "name": "Поривистий випад", "cd": 0, "icon": "res://Основа/char/air/Shopey/shopey_q.png", "desc": "Атакує ціль із шансом Гідри.", "desc_full": "" },
			"W": { "id": "shopey_w", "damage_type": "air",     "name": "Ріжуча гідра",    "cd": 3, "icon": "res://Основа/char/air/Shopey/shopey_w.png", "desc": "Атакує ціль з гарантованою Гідрою по сусідній.", "desc_full": "" },
			"E": { "id": "shopey_e", "damage_type": "phys",    "name": "Наскок",          "cd": 3, "icon": "res://Основа/char/air/Shopey/shopey_e.png", "desc": "Слабкий удар, але гарантує Гідру для наступного скілу.", "desc_full": "" },
		}
	},

	# ===== СТИХІЯ СЯЙВО — сюжетні боти, гравець НЕ обирає =====
	# Щоб додати нового Варда Сяйва, скопіюй шаблон нижче і заповни:
	#
	# "ward_id": {
	#     "name": "Назва",
	#     "element": "light",          # ОБОВ'ЯЗКОВО "light"
	#     "enemy_only": true,          # ОБОВ'ЯЗКОВО — не показується у виборі
	#     "hp": 300,                   # якщо відрізняється від 200
	#     "portrait": "res://...",
	#     "short_desc_file": "res://...",
	#     "full_desc_file": "res://...",
	#     "skills": {
	#         "P": { "id": "ward_p", "damage_type": "passive", "name": "...", "cd": 0, "icon": "res://...", "desc": "", "desc_full": "" },
	#         "Q": { "id": "ward_q", "damage_type": "light",   "name": "...", "cd": 0, "icon": "res://...", "desc": "", "desc_full": "" },
	#         "W": { "id": "ward_w", "damage_type": "light",   "name": "...", "cd": 2, "icon": "res://...", "desc": "", "desc_full": "" },
	#         "E": { "id": "ward_e", "damage_type": "light",   "name": "...", "cd": 3, "icon": "res://...", "desc": "", "desc_full": "" },
	#     }
	# },
	#
	# Модифікатори вже в ELEMENT_MULTIPLIERS (battle_resolver.gd):
	#   — Сяйво (light) по вогню/воді/повітрю/землі → ×2.0
	#   — Вогонь/вода/повітря по Сяйву → ×2.0
	#   — Фіз по Сяйву → ×1.0 (немає модифікатора, бо phys виключений)
	#   — Сяйво по Сяйву → ×4.0

	# ─── Стадія 1 ───────────────────────────────────────────────────────────────
	"infected_1_a": {
		"name": "Заражений І",
		"element": "light",
		"portrait": "res://Основа/char/NPC/infected radiance/stage_1/infected_1_stage.png",
		"skills": {
			"P": { "id": "infected_1_p", "damage_type": "passive", "name": "Зараза",     "cd": 0, "icon": "res://Основа/char/NPC/infected radiance/stage_1/p.png", "desc": "Початок ходу: +50 HP × кількість сяйво-вардів на своїй стороні.", "desc_full": "" },
			"Q": { "id": "infected_1_q", "damage_type": "light",   "name": "Удар сяйва", "cd": 0, "icon": "res://Основа/char/NPC/infected radiance/stage_1/q.png", "desc": "70 сяйво шкоди. Вбиває → +2 КД рандомного скіла (не Q) рандомного ворога.", "desc_full": "" },
			"W": { "id": "infected_1_w", "damage_type": "light",   "name": "Чума",       "cd": 6, "icon": "res://Основа/char/NPC/infected radiance/stage_1/w.png", "desc": "Заражає ворога: 15 сяйво шкоди щохід, 3 ходи. КД 6.", "desc_full": "" },
			"E": { "id": "infected_1_e", "damage_type": "light",   "name": "Спалах",     "cd": 6, "icon": "res://Основа/char/NPC/infected radiance/stage_1/e.png", "desc": "100 сяйво всім ворогам. Витрачає 50% поточного HP. КД 6.", "desc_full": "" },
		}
	},
	"infected_1_b": {
		"name": "Заражений І",
		"element": "light",
		"portrait": "res://Основа/char/NPC/infected radiance/stage_1/infected_2.png",
		"skills": {
			"P": { "id": "infected_1_p", "damage_type": "passive", "name": "Зараза",     "cd": 0, "icon": "res://Основа/char/NPC/infected radiance/stage_1/p.png", "desc": "Початок ходу: +50 HP × кількість сяйво-вардів на своїй стороні.", "desc_full": "" },
			"Q": { "id": "infected_1_q", "damage_type": "light",   "name": "Удар сяйва", "cd": 0, "icon": "res://Основа/char/NPC/infected radiance/stage_1/q.png", "desc": "70 сяйво шкоди. Вбиває → +2 КД рандомного скіла (не Q) рандомного ворога.", "desc_full": "" },
			"W": { "id": "infected_1_w", "damage_type": "light",   "name": "Чума",       "cd": 6, "icon": "res://Основа/char/NPC/infected radiance/stage_1/w.png", "desc": "Заражає ворога: 15 сяйво шкоди щохід, 3 ходи. КД 6.", "desc_full": "" },
			"E": { "id": "infected_1_e", "damage_type": "light",   "name": "Спалах",     "cd": 6, "icon": "res://Основа/char/NPC/infected radiance/stage_1/e.png", "desc": "100 сяйво всім ворогам. Витрачає 50% поточного HP. КД 6.", "desc_full": "" },
		}
	},
	"infected_1_c": {
		"name": "Заражений І",
		"element": "light",
		"portrait": "res://Основа/char/NPC/infected radiance/stage_1/infected_3.png",
		"skills": {
			"P": { "id": "infected_1_p", "damage_type": "passive", "name": "Зараза",     "cd": 0, "icon": "res://Основа/char/NPC/infected radiance/stage_1/p.png", "desc": "Початок ходу: +50 HP × кількість сяйво-вардів на своїй стороні.", "desc_full": "" },
			"Q": { "id": "infected_1_q", "damage_type": "light",   "name": "Удар сяйва", "cd": 0, "icon": "res://Основа/char/NPC/infected radiance/stage_1/q.png", "desc": "70 сяйво шкоди. Вбиває → +2 КД рандомного скіла (не Q) рандомного ворога.", "desc_full": "" },
			"W": { "id": "infected_1_w", "damage_type": "light",   "name": "Чума",       "cd": 6, "icon": "res://Основа/char/NPC/infected radiance/stage_1/w.png", "desc": "Заражає ворога: 15 сяйво шкоди щохід, 3 ходи. КД 6.", "desc_full": "" },
			"E": { "id": "infected_1_e", "damage_type": "light",   "name": "Спалах",     "cd": 6, "icon": "res://Основа/char/NPC/infected radiance/stage_1/e.png", "desc": "100 сяйво всім ворогам. Витрачає 50% поточного HP. КД 6.", "desc_full": "" },
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
		if WARDS[id]["element"] == element and not _is_player_hidden(id):
			result.append(id)
	return result


func get_all_ids() -> Array:
	var result: Array = []
	for id in WARDS:
		if not _is_player_hidden(id):
			result.append(id)
	return result


# Варди з "enemy_only": true — сюжетні боти, гравець не може обрати.
# Варди з "hidden": true   — тимчасово приховані, повернуться пізніше.
func _is_player_hidden(id: String) -> bool:
	return WARDS[id].get("hidden", false) or WARDS[id].get("enemy_only", false)


# Повертає всіх вардів стихії "light" для сюжетних битв.
# Використовувати у battle_scene для наповнення enemy_wards ботами-суперниками.
func get_light_wards() -> Array:
	var result: Array = []
	for id in WARDS:
		if WARDS[id].get("element", "") == "light":
			result.append(id)
	return result

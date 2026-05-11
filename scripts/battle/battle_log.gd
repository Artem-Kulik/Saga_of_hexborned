extends Node

var entries: Array[String] = []


func add_entry(text: String) -> void:
	entries.append(text)
	print(text)


func add_empty_line() -> void:
	entries.append("")
	print("")


func clear_log() -> void:
	entries.clear()


func get_entries() -> Array[String]:
	return entries

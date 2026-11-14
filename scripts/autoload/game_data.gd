# Part of Go/No-Go — written with AI assistance (Space Apps 2026).
# GameData (autoload): loads every table in res://data/*.json once at startup.
# Contract: README §8.1. Owner: Member A.
#
# NOTE for Web export: JSON files are not Godot resources, so the export preset
# must include them: Export → Resources → "Filters to export non-resource files" = data/*.json
extends Node

const TABLES: Array[String] = [
	"launch_vehicles", "buses", "power", "instruments",
	"comms", "missions", "events", "lookalikes",
]

var _tables: Dictionary = {}   # table_name -> Array[Dictionary]
var _index: Dictionary = {}    # table_name -> {id: Dictionary}


func _ready() -> void:
	for t in TABLES:
		_load_table(t)


func _load_table(table_name: String) -> void:
	var path := "res://data/%s.json" % table_name
	var rows: Array = []
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) == TYPE_ARRAY:
			rows = parsed
		else:
			push_error("GameData: %s is not a JSON array (check for a typo/comma)." % path)
	elif table_name != "events":   # events.json is created by Member B later
		push_warning("GameData: missing %s" % path)
	_tables[table_name] = rows
	var idx := {}
	for row in rows:
		if typeof(row) == TYPE_DICTIONARY and row.has("id"):
			idx[str(row["id"])] = row
	_index[table_name] = idx


## All rows of a table, e.g. get_table("instruments").
func get_table(table_name: String) -> Array:
	return _tables.get(table_name, [])


## One row by id, or {} if not found.
func get_item(table_name: String, id: String) -> Dictionary:
	return _index.get(table_name, {}).get(id, {})


func get_mission(mission_id: String) -> Dictionary:
	return get_item("missions", mission_id)


## Missions sorted by campaign order (helper, not part of the fixed contract).
func get_missions_in_order() -> Array:
	var list := get_table("missions").duplicate()
	list.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	return list


## Rows of a table filtered by their "kind" field (helper), e.g. get_by_kind("power", "solar").
func get_by_kind(table_name: String, kind: String) -> Array:
	return get_table(table_name).filter(func(r): return r.get("kind", "") == kind)

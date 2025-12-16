extends Node

var tilemaps: Array[TileMapLayer] = []

const footstep_sounds := {
	"floor": [
		preload("res://concrete1.wav"),
		preload("res://concrete2.wav"),
		preload("res://concrete3.wav"),
		preload("res://concrete4.wav")
	]
}

extends Node

class card_cell:
	var name:String = "00"
	var filled:bool = false

class player_data:
	var has_won:bool = false
	var card:Array = [
		card_cell.new()
	]

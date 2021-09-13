extends ItemList
class_name Bingo_Card
# PROPERTIES ===================================================================
var item_list
var bingo_card:Array
var current_basket:Array
var grid_size:int
var bingo_card_data = {
	"cells":[]
}
var current_ball setget set_current_ball

# CORE =========================================================================

func _ready():
	# generate_bingo_card(current_basket)
	connect("item_selected", self, "item_selected")
	pass

# METHODS ======================================================================



func set_current_ball(ball):
	current_ball = ball
	pass

func item_selected(index:int):
	print(array_index_to_grid(index, grid_size))
	if self.get_item_text(index) == current_ball:
		set_item_disabled(index, true)
		set_item_selectable(index, false)
		bingo_card_data["cells"][index].filled = true
		evaluate_card(index)
	pass

master func build_card(bingo_card_data:Array, grid_width:int = 0):
	print("SERVER GAVE US DATA SO WE CAN BUILD A CARD")
	grid_size = grid_width

	max_columns = grid_width
	for cell in bingo_card_data:
		self.add_item(cell["name"])
		if cell["filled"] == true:
			var i = bingo_card_data.find(cell)
			set_item_disabled(i, true)
			set_item_selectable(i, false)
	pass
# evaluate bingo card based on the position of a given cell
# basically does the cell we just filled in complete a row or column (also generically checks for diagnal matches)
func evaluate_card(index:int)->void:
	# if any of these match grid_size, then we got a bingo!
	var row_count:int = 0
	var column_count:int = 0
	var right_to_left_count:int = 0
	var left_to_right_count:int = 0
	
	# tests if we have bingo via row
	# gives us the number closest to our current index thats divisible by our grid size
	# we do this so we can find the first element of the row of a given index

	var target_index = index - (index % grid_size)
	if target_index % grid_size == 0:
		# this is most likely  the left most element in a row
		for n in grid_size:
			if bingo_card_data["cells"][target_index + n].filled == true:
				row_count += 1
			pass
	
	if row_count == grid_size:
		print("%s IN A ROW! THATS BINGO!" % [grid_size])
		#return
	# check if we have bingo va column
	# convert our index to a vector2, then iterate from zero to grid_size(minus 1) 
	# we can use our converrted current index x pos, then iterate the y to get all the cells in a column
	# then we just evaluate, easy!

	var current_index_pos:Vector2 = array_index_to_grid(index, grid_size)
	for m in grid_size:
		var target_pos:Vector2 = Vector2(current_index_pos.x, m)
		var target_pos_to_index:int = grid_to_array_index(target_pos, grid_size)

		if bingo_card_data["cells"][target_pos_to_index].filled == true:
			column_count += 1
		pass
	
	if column_count == grid_size:
		print("%s IN A COLUMN! THATS BINGO!" % [grid_size])
		#return
	# check if we have bingo diagnally 
	# theres only ever going to be 2 ways to get diagnal 
	# so we either gotta start from the top left (0,0) or top right (grid_size, 0)
	# checks diagnal from right to left
	for o in grid_size:
		var p:Vector2 = Vector2(o,o)
		var i:int = grid_to_array_index(p, grid_size)
		if bingo_card_data["cells"][i].filled == true:
			right_to_left_count += 1
		pass
	
	if right_to_left_count == grid_size:
		print("%s THERE! FROM THE RIGHT, DIAGNALLY! BINGO!!" % [right_to_left_count])
		#return
	
	 # checks diagnal from left to right
	for q in grid_size:
		var pv:Vector2 = Vector2((grid_size - 1) - q, q)
		var iv:int = grid_to_array_index(pv, grid_size)
		if bingo_card_data["cells"][iv].filled == true:
			left_to_right_count += 1
		pass
	pass
	
	if left_to_right_count == grid_size:
		print("%s THERE! FROM THE LEFT, DIAGNALLY! BINGO!!" % [left_to_right_count])
		#return
	
	pass

func generate_bingo_card(bingo_basket:Array)->void:
	if bingo_basket.size() == 0:
		return

	var b_array:Array = []
	var i_array:Array = []
	var n_array:Array = []
	var g_array:Array = []
	var o_array:Array = []
	
	# filter and sort out out the balls into different arrays based on letter
	for ball in bingo_basket:
		# do a search within basket_instance for an element that starts with B
		if "B" in ball:
			b_array.append(ball)
		if "I" in ball:
			i_array.append(ball)
		if "N" in ball:
			n_array.append(ball)
		if "G" in ball:
			g_array.append(ball)
		if "O" in ball:
			o_array.append(ball)
		pass
	
	# pick one of these "B" elements at random
	# remove said element from basket_instance
	# add element to bingo_card array
	# iterate 25 times because we have 25 times on the card
	# 
	for n in grid_size:
		if !b_array.empty():
			bingo_card.append(b_array[randi() % b_array.size()])
			b_array.remove(b_array.find(bingo_card.back()))
		
		if !i_array.empty():
			bingo_card.append(i_array[randi() % i_array.size()])
			i_array.remove(i_array.find(bingo_card.back()))
		
		if !n_array.empty():
			bingo_card.append(n_array[randi() % n_array.size()])
			n_array.remove(n_array.find(bingo_card.back()))
		
		if !g_array.empty():
			bingo_card.append(g_array[randi() % g_array.size()])
			g_array.remove(g_array.find(bingo_card.back()))
		
		if !o_array.empty():
			bingo_card.append(o_array[randi() % o_array.size()])
			o_array.remove(o_array.find(bingo_card.back()))
		pass
	
	# ok we have our bingo card array now.
	# next thing to do is populate our ItemList with our bingo_card array
	
	for cell in bingo_card:
		bingo_card_data["cells"].append({"name": cell, "filled": false})
		self.add_item(cell)
		pass
	
	# grid_size = sqrt(bingo_card.size())
	pass

# converts the index of an array to its x,y equivalent
# grid_width is the width of the grid, i.e. a 5 x 5 grid would have a width of 5
func array_index_to_grid(index:int, grid_width:int)->Vector2:
	var x_column = index % grid_width
	var y_row = floor(index / grid_width)
	return Vector2(x_column, y_row)
	pass


func grid_to_array_index(pos:Vector2, grid_width:int)->int:
	return int((pos.y * grid_width) + pos.x)
	pass

extends Node2D

export(PackedScene) var bingo_card_scene

onready var current_number_display:Label = $HUD/Label
onready var pick_ball_button:Button = $HUD/Button
onready var evaluate_button:Button = $HUD/Button2
onready var start_game_button:Button = $HUD/Button3
var bingo_basket:Array = []
var called_balls:Array = []

var current_number:String
var grid_size:int = 3

var players:Array = []
var ready_players:Array = []
var players_ready_to_start:Array = []
# PLAYER DATA STRUCT
var all_player_data = {
	"1": {"has_won":false,"card":[]}
}


const START_GAME_TIMER_MAX:float = 10.0
var start_game_timer:float = START_GAME_TIMER_MAX
var last_time_sent:float = 0.0

enum SERVER_GAME_STATE_ENUM {DEFAULT_STATE, SERVER_STARTED, GAME_START_COUNTDOWN, GAME_IN_PROCESS, GAME_OVER}
var SERVER_GAME_STATE = SERVER_GAME_STATE_ENUM.DEFAULT_STATE
# PLAYER DATA STRUCT END
signal picked_ball_event

# to start...first to connnect becomes host, yet cannot be a "player" in the sense that they will not be given a bingo card
# their job will only be to evaluate cards n stuff. Hopefully this will work headless...

# NETWORK RELATED PROPERTIES
# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 12

var peer = null

var SERVER_IP = "basic-bingo.local"

func _ready():
	# allows us to get "true" random numbers by using a time based seed.
	# only needs to be ran once in the entire application
	randomize()
	
	peer = NetworkedMultiplayerENet.new()
	# Running on the headless server platform
	if OS.has_feature("Server"):
		print("STARTING SERVER %s ON PORT %s" % [SERVER_IP, DEFAULT_PORT])

		peer.create_server(DEFAULT_PORT, MAX_PEERS)
		get_tree().set_network_peer(peer)
# warning-ignore:return_value_discarded
		get_tree().connect("network_peer_connected", self,"_network_peer_connected")
# warning-ignore:return_value_discarded
		get_tree().connect("network_peer_disconnected", self, "_network_peer_disconnected")
		print("SERVER ID: %s" % get_tree().get_network_unique_id())
		fill_basket(grid_size)
		
	else:
		print("CONNECTING TO SERVER %s ON PORT %s" % [SERVER_IP, DEFAULT_PORT])
		peer.create_client(SERVER_IP, DEFAULT_PORT)
		get_tree().network_peer = peer
# warning-ignore:return_value_discarded
		get_tree().connect("connection_failed", self, "_connection_failed")
# warning-ignore:return_value_discarded
		get_tree().connect("connected_to_server", self, "_connected_to_server")


	# UI button event setup
	if pick_ball_button:
		# connect the buttons pressed event to our pick_ball method
# warning-ignore:return_value_discarded
		pick_ball_button.connect("pressed", self, "pick_ball")
	if evaluate_button:
# warning-ignore:return_value_discarded
		evaluate_button.connect("pressed", self, "evaluate_bingo_cards")
	if start_game_button:
		start_game_button.connect("pressed", self, "_player_ready_to_start_button")

	pass

func _process(delta):
	if is_network_master():
		if SERVER_GAME_STATE == SERVER_GAME_STATE_ENUM.GAME_START_COUNTDOWN:
			start_game_timer -= delta
			
			if(last_time_sent != ceil(start_game_timer)):
				print("SERVER COUNTDOWN: %s" % ceil(start_game_timer))
				last_time_sent = ceil(start_game_timer)
				rpc("rpc_update_start_timer", last_time_sent)
			if start_game_timer <= 0:
				SERVER_GAME_STATE = SERVER_GAME_STATE_ENUM.GAME_IN_PROCESS
	pass
# SIGNAL EVENT FUNCS ===============================================================
func _network_peer_connected(id:int):
	print("A USER WITH ID: %s CONNECTED" % [id])
	# a new user has joined, the server must now give this player a bingo card
	if get_tree().is_network_server():
		players.append(id)
	pass

func _network_peer_disconnected(id:int):
	print("A USER WITH ID: %s DISCONNECTED" % [id])
	players.erase(id)
	ready_players.erase(id)
	pass

func _connection_failed():
	print("CONNECTION TO SERVER FAILED FOR SOME REASON")
	pass

func _connected_to_server():
	print("CONNECTION SUCCESS!")
	
	# create player
	if bingo_card_scene:
		var x = bingo_card_scene.instance()
		$HUD.add_child(x)
	print("WE ARE READY, LETS TELL THE SERVER")
	rpc_id(1, "player_is_ready") # tell the server we're ready for whatevers next
	pass

func _player_ready_to_start_button():
	rpc_id(1, "rpc_player_ready_to_start")
	start_game_button.disabled = true
	pass

# RPC FUNCTIONS ================================================================
puppet func rpc_update_start_timer(time:float):
	start_game_timer = time
	print("CLIENT COUNTDOWN: %s" % start_game_timer)
	pass

remote func rpc_player_ready_to_start():
	var id = get_tree().get_rpc_sender_id()
	print("PLAYER: %s IS READY TO START THE GAME" % id)
	if ready_players.has(id):
		players_ready_to_start.append(id)
	
	if players_ready_to_start.size() == players.size():
		print("ALL THE PLAYERS ARE READY TO START THE GAME.")
		SERVER_GAME_STATE = SERVER_GAME_STATE_ENUM.GAME_START_COUNTDOWN
	pass

# populate all the numbers/letter
master func fill_basket(number_of_balls:int)->void:
	# clear out left over "balls" from our basket first
	bingo_basket.clear()
	called_balls.clear()

	# populate the letter array
	# 0 to x
	for n in number_of_balls:
		n = n as String
		if number_of_balls >= 1: 
			bingo_basket.append("B" + n)
		if number_of_balls >= 2: 
			bingo_basket.append("I" + n)
		if number_of_balls >= 3: 
			bingo_basket.append("N" + n)
		if number_of_balls >= 4: 
			bingo_basket.append("G" + n)
		if number_of_balls >= 5: 
			bingo_basket.append("O" + n)
		pass

	pass

# pick a letter then pick a number, 
# remove said leternumber combo from the overall pool
# return the number we got
master func pick_ball()->void:
	
	if bingo_basket.size() <= 0:
		print("No balls left")
		return
	# start mixing up our balls in the basket, turn the crank!
	bingo_basket.shuffle()
	
	# pick a ball and remove it from the basket!
	var picked_ball = bingo_basket.pop_front()
	current_number = picked_ball
	called_balls.append(picked_ball)
	
	current_number_display.text = current_number
	emit_signal("picked_ball_event", current_number)
	pass

# basically a wrapper for the build_card func on our bingo card
remote func build_card(player_data:Array):
	print("BUILD_CARD")
	var built_card:bool
	if get_node_or_null("HUD/bingo_card"):
		print("FIND BINGO CARD AND TELL IT TO BUILD_CARD")
		built_card = get_node("HUD/bingo_card").build_card(player_data, grid_size)
	else:
		print("COULD NOT FIND NODE")
	if built_card == true:
		start_game_button.disabled = false
	pass

remote func player_is_ready():
	var id = get_tree().get_rpc_sender_id()
	print("PLAYER: %s IS READY" % id)
	
	ready_players.append(id)
	generate_bingo_card(id)


# player may request for their card to be evaluated
remote func evaluate_bingo_cards(id)->void:
	pass
# NON NETWORK METHODS (METHODS NOT LIKELY TO BE CALLED OVER RPC==========================
func generate_bingo_card(new_player_id:int)->void:
	if bingo_basket.size() == 0:
		return

	var bingo_card:Array = []
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
	all_player_data[new_player_id] = {"has_won":false,"card":[]}

	for cell in bingo_card:
		all_player_data[new_player_id]["card"].append({"name": cell, "filled":false})

		pass

	
	# we now have an ongoing record of the players card data, 
	# we will use this version to verify whether or not they have a completed row
	# now it's time to give the player their data so they can build out a UI based on it
	print("SEND RPC CALL TO ID: %s" % [new_player_id])
	
	rpc_id(new_player_id, "build_card",all_player_data[new_player_id].card)
	pass


	

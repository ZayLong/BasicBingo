extends Node2D


export(PackedScene) var bingo_card

onready var current_number_display:Label = $HUD/Label
onready var pick_ball_button:Button = $HUD/Button
onready var evaluate_button:Button = $HUD/Button2

var bingo_basket:Array = []
var called_balls:Array = []
var bingo_cards:Array = []
var current_number:String

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

var SERVER_IP = IP.get_local_addresses().front()

func _ready():
	# allows us to get "true" random numbers by using a time based seed.
	# only needs to be ran once in the entire application
	randomize()
	#fill_basket(3)
	
	peer = NetworkedMultiplayerENet.new()
	# Running on the headless server platform
	if OS.has_feature("Server"):
		print("STARTING SERVER %s ON PORT %s" % [SERVER_IP, DEFAULT_PORT])
		peer.create_server(DEFAULT_PORT, MAX_PEERS)
		get_tree().set_network_peer(peer)
		get_tree().connect("network_peer_connected", self,"_network_peer_connected")
		get_tree().connect("network_peer_disconnected", self, "_network_peer_disconnected")
		
	else:
		print("CONNECTING TO SERVER %s ON PORT %s" % [SERVER_IP, DEFAULT_PORT])
		peer.create_client(SERVER_IP, DEFAULT_PORT)
		get_tree().network_peer = peer
		get_tree().connect("connection_failed", self, "_connection_failed")
		get_tree().connect("connected_to_server", self, "_connected_to_server")





	
	# create player
	if bingo_card && false:
		var x = bingo_card.instance()
		x._init(bingo_basket, 3)
		# connect our picked_ball event to our newly created bingo cards set_current_ball setter method
		# this way whenever we pick a ball, we will emit a signal telling all our subscribers what we picked
		self.connect("picked_ball_event", x, "set_current_ball")
		add_child(x)
		bingo_cards.append(x)
	
	# UI button event setup
	if pick_ball_button:
		# connect the buttons pressed event to our pick_ball method
		pick_ball_button.connect("pressed", self, "pick_ball")
	if evaluate_button:
		evaluate_button.connect("pressed", self, "evaluate_bingo_cards")

	pass

func _network_peer_connected(id:int):
	print("A USER WITH ID: %s CONNECTED" % [id])
	pass

func _network_peer_disconnected(id:int):
	print("A USER WITH ID: %s DISCONNECTED" % [id])
	pass

func _connection_failed():
	print("CONNECTION TO SERVER FAILED FOR SOME REASON")
	pass

func _connected_to_server():
	print("CONNECTION SUCCESS!")
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

# player may request for their card to be evaluated
remote func evaluate_bingo_cards()->void:
	for card in bingo_cards:
		
		pass
	pass

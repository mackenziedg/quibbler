class_name GameMultiplayerManager
extends Control

const STARTING_HAND_SIZE: int = 5

@onready var _multiplayer_id := multiplayer.get_unique_id()
@onready var _player_names_container: HBoxContainer = %PlayerNames
@onready var _game: Game = %Game

var username := "username"
var color := Color.WHITE

var _player_info: Array[Dictionary] = []
var _ready_count := 0


@rpc("authority", "call_remote", "reliable")
func send_player_info(host_id: int) -> void:
    update_host_player_info.rpc_id(host_id, _player_info[0])


@rpc("any_peer", "call_remote", "reliable")
func update_host_player_info(info: Dictionary) -> void:
    _player_info.push_back(info)
    update_client_player_info.rpc(_player_info)


@rpc("authority", "call_local", "reliable")
func update_client_player_info(info: Array) -> void:
    _player_info = info
    _update_player_name_labels()


@rpc("authority", "call_local", "reliable")
func update_client_game_state(state: Dictionary) -> void:
    _game.game_state = state


@rpc("authority", "call_local", "reliable")
func start_game() -> void:
    for _i in range(_player_info.size()):
        _game.game_state["round_scores"].push_back(0)
        _game.game_state["total_scores"].push_back(0)

    for _i in range(STARTING_HAND_SIZE):
        var letter := CardData.draw_card()
        _game.add_card(letter)
    _game.start_game()
    %StartButton.queue_free()


@rpc("authority", "call_local", "reliable")
func assign_card(letter: String) -> void:
    _game.add_card(letter)


@rpc("any_peer", "call_local", "reliable")
func draw_card(id: int) -> void:
    if not is_multiplayer_authority():
        return
    var letter := CardData.draw_card()
    assign_card.rpc_id(id, letter)


@rpc("any_peer", "call_local", "reliable")
func end_turn(id: int) -> void:
    if not is_multiplayer_authority():
        return
    var ready_player_ix := _get_player_index(id)
    _player_info[ready_player_ix]["ready_round_end"] = true
    update_client_player_info.rpc(_player_info)
    for p in _player_info:
        if not p["ready_round_end"]:
            return
    print("Round over!")


@rpc("authority", "call_local", "reliable")
func end_round(winners: Array[int]) -> void:
    var round_over_screen: RoundOverScreen = preload("res://Game/Game/RoundOverScreen.tscn").instantiate()
    round_over_screen.winners = winners
    add_child(round_over_screen)
    round_over_screen.ready_round_end.connect(_on_player_ready_round_end)


@rpc("any_peer", "call_local", "reliable")
func ready_player() -> void:
    if not is_multiplayer_authority():
        return
    _ready_count += 1
    if _ready_count == _player_info.size():
        _ready_count = 0
        _game.game_state["round_id"] += 1
        for i in range(_game.game_state["round_scores"].size()):
            _game.game_state["round_scores"][i] = 0
        update_client_game_state.rpc(_game.game_state)


func _get_player_index(id: int) -> int:
    var i := 0
    while i < _player_info.size():
        if _player_info[i]["id"] == id:
            return i
        i += 1
    return -1


func _update_player_name_labels() -> void:
    for child in _player_names_container.get_children():
        child.queue_free()

    for info in _player_info:
        _player_names_container.add_child(_create_player_name_label(info))


func _create_player_name_label(info: Dictionary) -> Label:
    var label := Label.new()
    label.label_settings = LabelSettings.new()
    label.text = ("✓ " if info["ready_round_end"] else "") + info["username"]
    label.label_settings.font_color = info["color"]
    return label


func _ready() -> void:
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    %PlayerIdentifier.text = "Player %d - %s" % [_multiplayer_id, username]
    _player_info.push_back({"id": _multiplayer_id, "username": username, "color": color, "ready_round_end": false})
    %StartButton.visible = is_multiplayer_authority()
    %StartButton.disabled = not is_multiplayer_authority()
    if is_multiplayer_authority():
        _game.game_state = {"round_id": 0, "round_scores": [], "total_scores": []}


func _on_player_connected(id: int) -> void:
    if not is_multiplayer_authority():
        return
    print("[%d]: Player %d connected" % [_multiplayer_id, id])
    send_player_info.rpc_id(id, _multiplayer_id)
    update_client_game_state.rpc(_game.game_state)


func _on_player_disconnected(id: int) -> void:
    print("[%d]: Player %d disconnected" % [_multiplayer_id, id])


func _on_start_button_pressed() -> void:
    start_game.rpc()


func _on_player_ready_round_end() -> void:
    ready_player.rpc()


func _end_round() -> void:
    print("Ending round")


#    end_round.rpc(argmax)


func _on_game_draw_card() -> void:
    draw_card.rpc(_multiplayer_id)


func _on_game_end_turn() -> void:
    end_turn.rpc(_multiplayer_id)

class_name GameMultiplayerManager
extends Control

const STARTING_HAND_SIZE: int = 7

@onready var _multiplayer_id := multiplayer.get_unique_id()
@onready var _player_names_container: VBoxContainer = %PlayerNames
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
    for i in range(_game.game_state["ready_round_end"].size()):
        if _game.game_state["ready_round_end"][i]:
            _player_names_container.get_child(i).text = "✓ " + _player_info[i]["username"]


@rpc("authority", "call_local", "reliable")
func start_game() -> void:
    for _i in range(_player_info.size()):
        _game.game_state["round_scores"].push_back(0)
        _game.game_state["total_scores"].push_back(0)
        _game.game_state["ready_round_end"].push_back(false)

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
    _game.game_state["ready_round_end"][ready_player_ix] = true
    update_client_game_state.rpc(_game.game_state)
    for p in _game.game_state["ready_round_end"]:
        if not p:
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


func _get_player_info(id: int) -> Dictionary:
    for v in _player_info:
        if v["id"] == id:
            return v
    return {}


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
    for v in _player_info:
        _player_names_container.add_child(_create_player_name_label(v["username"], v["color"]))


func _create_player_name_label(n: String, c: Color) -> Label:
    var label := Label.new()
    label.label_settings = LabelSettings.new()
    label.text = n
    label.label_settings.font_color = c
    return label


func _ready() -> void:
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    %PlayerIdentifier.text = "Player %d - %s" % [_multiplayer_id, username]
    _player_info.push_back({"id": _multiplayer_id, "username": username, "color": color})
    %StartButton.visible = is_multiplayer_authority()
    %StartButton.disabled = not is_multiplayer_authority()
    if is_multiplayer_authority():
        _game.game_state = {"round_id": 0, "round_scores": [], "total_scores": [], "ready_round_end": []}


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
    var rolls: Array = _game.game_state["round_scores"]
    var max_roll: int = rolls.max()
    var argmax: Array[int] = []
    for i in range(rolls.size()):
        if rolls[i] == max_roll:
            argmax.push_back(i)
    for i in argmax:
        _game.game_state["total_scores"][i] += 1
    end_round.rpc(argmax)


func _on_game_draw_card() -> void:
    draw_card.rpc(_multiplayer_id)


func _on_game_end_turn() -> void:
    end_turn.rpc(_multiplayer_id)

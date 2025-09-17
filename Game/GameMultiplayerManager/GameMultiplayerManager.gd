class_name GameMultiplayerManager
extends Control

const STARTING_HAND_SIZE: int = 5

@onready var _multiplayer_id := multiplayer.get_unique_id()
@onready var _player_names_container: HBoxContainer = %PlayerNames
@onready var _rounds_won_container: HBoxContainer = %RoundsWonContainer
@onready var _round_over_screen: RoundOverScreen = %RoundOverScreen
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
func start_game() -> void:
    for s in range(_player_info.size()):
        var score_label := Label.new()
        _rounds_won_container.add_child(score_label)
        score_label.text = "0"
    for _i in range(STARTING_HAND_SIZE):
        var letter := CardData.draw_card()
        _game.add_card(letter)
    _game.start_game()
    %WaitToStartContainer.queue_free()


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
func end_turn(id: int, total_score: int) -> void:
    if not is_multiplayer_authority():
        return
    var ready_player_ix := _get_player_index(id)
    _player_info[ready_player_ix]["ready_round_end"] = true
    _player_info[ready_player_ix]["total_score"] = total_score
    update_client_player_info.rpc(_player_info)
    for p in _player_info:
        if not p["ready_round_end"]:
            return
    end_round.rpc()
    print("Round over!")


@rpc("authority", "call_local", "reliable")
func end_round() -> void:
    var winner_ix := -1
    var winning_score := -INF
    for i in range(_player_info.size()):
        if _player_info[i]["total_score"] > winning_score:
            winner_ix = i
            winning_score = _player_info[i]["total_score"]
    _player_info[winner_ix]["rounds_won"] += 1
    for i in range(_player_info.size()):
        _rounds_won_container.get_child(i).text = str(_player_info[i]["rounds_won"])
    %RoundOverScreen.visible = true
    var round_over_text := ["%s won!" % [_player_info[winner_ix]["username"]]]
    for p in _player_info:
        round_over_text.push_back("%s: %d" % [p["username"], p["total_score"]])
    %RoundOverScreen.setup("\n".join(round_over_text))
    for ix in range(_player_info.size()):
        _player_info[ix]["ready_round_end"] = false
    _ready_count = 0


@rpc("authority", "call_local", "reliable")
func next_round() -> void:
    await get_tree().create_timer(1.0).timeout
    _round_over_screen.visible = false
    _game.clear_board()
    for _i in range(STARTING_HAND_SIZE):
        var letter := CardData.draw_card()
        _game.add_card(letter)


@rpc("any_peer", "call_local", "reliable")
func ready_player(id: int) -> void:
    if not is_multiplayer_authority():
        return
    var ready_player_ix := _get_player_index(id)
    _round_over_screen.set_ready.rpc(ready_player_ix)
    _ready_count += 1
    if _ready_count == _player_info.size():
        _ready_count = 0
        for i in range(_player_info.size()):
            _player_info[i]["round_id"] += 1
        update_client_player_info.rpc(_player_info)
        next_round.rpc()


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
    _player_info.push_back({
        "id": _multiplayer_id,
        "username": username,
        "color": color,
        "ready_round_end": false,
        "total_score": 0,
        "rounds_won": 0,
        "round_id": 0,
    })
    if is_multiplayer_authority():
        %WaitingLabel.text = "Press Start when everyone has joined."
        %StartButton.visible = true
        %StartButton.disabled = false


func _on_player_connected(id: int) -> void:
    if not is_multiplayer_authority():
        return
    print("[%d]: Player %d connected" % [_multiplayer_id, id])
    send_player_info.rpc_id(id, _multiplayer_id)


func _on_player_disconnected(id: int) -> void:
    print("[%d]: Player %d disconnected" % [_multiplayer_id, id])


func _on_start_button_pressed() -> void:
    start_game.rpc()


func _on_game_draw_card() -> void:
    draw_card.rpc(_multiplayer_id)


func _on_game_end_turn(total_score: int) -> void:
    end_turn.rpc(_multiplayer_id, total_score)


func _on_round_over_screen_ready_round_end() -> void:
    ready_player.rpc(_multiplayer_id)

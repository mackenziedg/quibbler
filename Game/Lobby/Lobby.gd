class_name Lobby
extends Control

const MAX_CLIENTS: int = 8

@onready var _ip_addr_edit: LineEdit = %IPAddressEdit
@onready var _username_edit: LineEdit = %UsernameEdit


func _ready() -> void:
    if OS.is_debug_build() and OS.has_feature("autostart"):
        var args := OS.get_cmdline_args()
        var is_hosting := args[2] == "--host"
        start_game(is_hosting)


func start_game(is_hosting: bool) -> void:
    var ip := _ip_addr_edit.text.split(":")[0]
    var port := int(_ip_addr_edit.text.split(":")[1])
    var peer := ENetMultiplayerPeer.new()
    if is_hosting:
        peer.create_server(port, MAX_CLIENTS)
    else:
        peer.create_client(ip, port)
    multiplayer.multiplayer_peer = peer

    var gmm: GameMultiplayerManager = preload("res://Game/GameMultiplayerManager/GameMultiplayerManager.tscn").instantiate()
    if OS.is_debug_build() and OS.has_feature("autostart"):
        gmm.username = OS.get_cmdline_args()[3]
        gmm.color = Color(OS.get_cmdline_args()[4])
    else:
        gmm.username = _username_edit.text
    get_parent().switch_scene_to(gmm)


func _on_host_button_pressed() -> void:
    start_game(true)


func _on_client_button_pressed() -> void:
    start_game(false)

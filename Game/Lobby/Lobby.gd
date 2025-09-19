class_name Lobby
extends Control

const MAX_CLIENTS: int = 8
const PORT: int = 55556
const CONFIG_FILE: String = "user://quibbler_userinfo.txt"

@onready var _ip_addr_edit: LineEdit = %IPAddressEdit
@onready var _username_edit: LineEdit = %UsernameEdit
@onready var _color_picker: ColorPickerButton = %ColorPicker
@onready var _host_button: Button = %HostButton
@onready var _client_button: Button = %ClientButton


func _ready() -> void:
    if OS.is_debug_build() and OS.has_feature("autostart"):
        var args := OS.get_cmdline_args()
        var is_hosting := args[2] == "--host"
        start_game(is_hosting)
    else:
        var user_file := FileAccess.open(CONFIG_FILE, FileAccess.READ)
        if user_file.get_length() > 0:
            _username_edit.text = user_file.get_line()
            _color_picker.color = user_file.get_line()
            _on_text_changed("")


func start_game(is_hosting: bool) -> void:
    var username := _username_edit.text
    var color := _color_picker.color
    # Save user info to user storage for next time
    var user_file := FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
    user_file.store_string("%s\n" % _username_edit.text)
    user_file.store_string("%s\n" % color.to_html())


    if OS.is_debug_build() and OS.has_feature("autostart"):
        username = OS.get_cmdline_args()[3]
        color = Color(OS.get_cmdline_args()[4])

    var ip := _ip_addr_edit.text
    var peer := ENetMultiplayerPeer.new()
    if is_hosting:
        peer.create_server(PORT, MAX_CLIENTS)
    else:
        if peer.create_client(ip, PORT):
            %FailedToConnectPopup.visible = true
            return
    multiplayer.multiplayer_peer = peer

    var gmm: GameMultiplayerManager = preload("res://Game/GameMultiplayerManager/GameMultiplayerManager.tscn").instantiate()
    gmm.username = username
    gmm.color = color
    get_parent().switch_scene_to(gmm)


func _on_host_button_pressed() -> void:
    start_game(true)


func _on_client_button_pressed() -> void:
    start_game(false)


func _on_text_changed(_text: String) -> void:
    _host_button.disabled = _username_edit.text.length() == 0
    _client_button.disabled = _username_edit.text.length() == 0 or _ip_addr_edit.text.length() == 0


func _on_ok_button_pressed() -> void:
    %FailedToConnectPopup.visible = false

class_name WaitToStartContainer
extends PanelContainer


signal start_game


func _ready() -> void:
    if is_multiplayer_authority():
        %WaitingLabel.text = "Press Start when everyone has joined."
        %StartButton.visible = true
        %StartButton.disabled = false

func _on_start_button_pressed() -> void:
    start_game.emit()

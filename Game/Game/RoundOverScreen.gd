class_name RoundOverScreen
extends Control

signal ready_round_end

var winner: String = ""


func _ready() -> void:
    %WinnerLabel.text = "%s won!" % winner


func allow_continue() -> void:
    %ContinueButton.disabled = false


func _on_timer_timeout() -> void:
    allow_continue()


func _on_continue_button_pressed() -> void:
    ready_round_end.emit()
    queue_free()

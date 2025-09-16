class_name RoundOverScreen
extends Control

signal ready_round_end

var winners: Array[int] = []


func _ready() -> void:
    var is_plural := winners.size() > 1
    var win_string: String = "Player"
    if is_plural:
        win_string += "s"
    var win_labels := " and ".join(winners.map(func (v): return str(v)))

    %WinnerLabel.text = "%s %s won!" % [win_string, win_labels]


func allow_continue() -> void:
    %ContinueButton.disabled = false


func _on_timer_timeout() -> void:
    allow_continue()


func _on_continue_button_pressed() -> void:
    ready_round_end.emit()
    queue_free()

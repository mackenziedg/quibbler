class_name RoundOverScreen
extends PanelContainer

signal ready_round_end


func setup(t: String) -> void:
    %WinnerLabel.text = t
    $Timer.start()


@rpc("authority", "call_local", "reliable")
func set_ready(ix: int) -> void:
    var lines: PackedStringArray = %WinnerLabel.text.split("\n")
    lines[ix + 1] = "✓ " + lines[ix + 1]
    %WinnerLabel.text = "\n".join(lines)


func allow_continue() -> void:
    %ContinueButton.disabled = false


func _on_timer_timeout() -> void:
    allow_continue()


func _on_continue_button_pressed() -> void:
    %ContinueButton.disabled = true
    ready_round_end.emit()

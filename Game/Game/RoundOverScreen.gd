class_name RoundOverScreen
extends PanelContainer

signal ready_round_end


func setup(infos: Array[Dictionary]) -> void:
    var winner_name := ""
    var winner_score := -INF
    for info in infos:
        if info["last_round_score"] > winner_score:
            winner_name = info["username"]
    %WinnerLabel.text = "%s won the round!" % winner_name
    for info in infos:
        var username_label := Label.new()
        username_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        username_label.label_settings = preload("res://Game/GameMultiplayerManager/interround_label_settings.tres")
        username_label.text = info["username"]
        %PlayerScores.add_child(username_label)
        
        var score_label := Label.new()
        score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        score_label.label_settings = preload("res://Game/GameMultiplayerManager/interround_label_settings.tres")
        score_label.text = str(info["last_round_score"])
        %PlayerScores.add_child(score_label)
    $Timer.start()


@rpc("authority", "call_local", "reliable")
func set_ready(ix: int) -> void:
    var name_node = %PlayerScores.get_child(ix * 2)
    name_node.text = "✓ " + name_node.text


func allow_continue() -> void:
    %ContinueButton.disabled = false


func _on_timer_timeout() -> void:
    allow_continue()


func _on_continue_button_pressed() -> void:
    %ContinueButton.disabled = true
    ready_round_end.emit()

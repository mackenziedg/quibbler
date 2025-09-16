class_name Game
extends Control

signal draw_card
signal end_turn

@onready var _draw_button: Button = %DrawButton
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _round_scores_container: Label = %PlayerLetters
@onready var _total_scores_container: HBoxContainer = %PlayerTotalScores

var _cards: Array[String] = []

var game_state: Dictionary = {}:
    set(s):
        game_state = s
        _sync_game_state()


func start_game() -> void:
    visible = true
    for s in game_state["total_scores"]:
        var score_label := Label.new()
        _total_scores_container.add_child(score_label)
        score_label.text = str(s)


func add_card(letter: String) -> void:
    _cards.push_back(letter)
    %PlayerLetters.text = " ".join(_cards)


func _sync_game_state() -> void:
    for i in range(_round_scores_container.get_child_count()):
        _round_scores_container.get_child(i).text = str(game_state["round_scores"][i])
        _total_scores_container.get_child(i).text = str(game_state["total_scores"][i])


func _on_draw_button_pressed() -> void:
    draw_card.emit()


func _on_end_turn_button_pressed() -> void:
    _draw_button.disabled = true
    end_turn.emit()

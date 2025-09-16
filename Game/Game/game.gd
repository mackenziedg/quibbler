class_name Game
extends Control

signal draw_card
signal end_turn(total_score: int)

@onready var _draw_button: Button = %DrawButton
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _hand_container: HFlowContainer = %HandContainer
@onready var _word_container: HFlowContainer = %WordContainer
@onready var _submit_word_button: Button = %SubmitWordButton

var _drawn := 0
var words: Array[String] = []


func start_game() -> void:
    visible = true


func add_card(letter: String) -> void:
    var card: Card = preload("res://Game/Game/UI/Card/card.tscn").instantiate()
    _hand_container.add_child(card)
    card.letter = letter


func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("drag_card"):
        var card: Card = _get_selected_card()
        if card:
            var parent_container: HFlowContainer = card.get_parent()
            parent_container.remove_child(card)
            if parent_container == _hand_container:
                _word_container.add_child(card)
            else:
                _hand_container.add_child(card)
            _update_word_status()


func _total_score() -> int:
    var word_score: int = 0
    var letter_penalty: int = 0
    var draw_penalty: int = 0
    for word in words:
        word_score += CardData.score_word(word)
    for card: Card in _hand_container.get_children():
        letter_penalty += CardData.points(card.letter)
    draw_penalty = _drawn

    return word_score - letter_penalty - draw_penalty


func _get_word() -> String:
    var word: String = ""
    for card: Card in _word_container.get_children():
        word += card.letter
    return word


func _update_word_status() -> void:
    var word := _get_word()
    _submit_word_button.disabled = not CardData.valid_words.has(word)


func _get_selected_card() -> Card:
    var mouse_global_pos := get_global_mouse_position()
    for c: Card in _hand_container.get_children():
        if c.get_global_rect().has_point(mouse_global_pos):
            return c
    for c: Card in _word_container.get_children():
        if c.get_global_rect().has_point(mouse_global_pos):
            return c
    return null


func _on_draw_button_pressed() -> void:
    draw_card.emit()
    _drawn += 1


func _on_end_turn_button_pressed() -> void:
    _draw_button.disabled = true
    _end_turn_button.disabled = true
    end_turn.emit(_total_score())


func _on_submit_word_button_pressed() -> void:
    words.push_back(_get_word())
    for c in _word_container.get_children():
        c.queue_free()

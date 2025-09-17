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
var _remaining_tiles: Array[String] = []
var words: Array[String] = []


func start_game() -> void:
    visible = true
    _update_round_score_labels()


func add_card(letter: String) -> void:
    var card: Card = preload("res://Game/Game/UI/Card/card.tscn").instantiate()
    _hand_container.add_child(card)
    card.letter = letter
    _remaining_tiles.push_back(letter)


func clear_board() -> void:
    words.clear()
    _remaining_tiles.clear()
    _drawn = 0
    for c in _word_container.get_children():
        c.queue_free()
    for c in _hand_container.get_children():
        c.queue_free()
    _draw_button.disabled = false
    _end_turn_button.disabled = false
    _update_round_score_labels()


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


func _word_score() -> int:
    var word_score := 0
    for word in words:
        word_score += CardData.score_word(word)
    return word_score


func _letter_penalty() -> int:
    var letter_penalty := 0
    for letter in _remaining_tiles:
        letter_penalty += CardData.points(letter)
    return letter_penalty


func _draw_penalty() -> int:
    return _drawn


func _total_score() -> int:
    var word_score := _word_score()
    var letter_penalty := _letter_penalty()
    var draw_penalty := _draw_penalty()
    return word_score - letter_penalty - draw_penalty


func _update_round_score_labels() -> void:
    %WordScoreLabel.text = str(_word_score())
    %LeftoverPenaltyLabel.text = str(_letter_penalty())
    %DrawPenaltyLabel.text = str(_draw_penalty())
    %TotalScoreLabel.text = str(_total_score())


func _get_word() -> String:
    var word: String = ""
    for card: Card in _word_container.get_children():
        word += card.letter
    return word


func _update_word_status() -> void:
    var word := _get_word()
    _submit_word_button.disabled = not CardData.valid_words.has(word)
    _update_round_score_labels()


func _get_selected_card() -> Card:
    var mouse_global_pos := get_global_mouse_position()
    for c: Card in _hand_container.get_children():
        if c.get_global_rect().has_point(mouse_global_pos):
            return c
    for c: Card in _word_container.get_children():
        if c.get_global_rect().has_point(mouse_global_pos):
            return c
    return null


func _sort_letters(by: String) -> void:
    if _hand_container.get_child_count() < 2:
        return
    var sort_fn := func (card): return card.letter
    if by == "shuffle":
        sort_fn = func (_card): return randi_range(0, _hand_container.get_child_count())
    elif by == "points":
        sort_fn = func (card): return CardData.points(card.letter)
    # Insertion sort! DSA finally used in the wild
    var sorted_ix := 1
    for i in range(1, _hand_container.get_child_count()):
        for j in range(0, sorted_ix):
            if sort_fn.call(_hand_container.get_child(i)) <= sort_fn.call(_hand_container.get_child(j)):
                _hand_container.move_child(_hand_container.get_child(i), j)
        sorted_ix += 1


func _on_draw_button_pressed() -> void:
    draw_card.emit()
    _drawn += 2
    _update_round_score_labels()


func _on_end_turn_button_pressed() -> void:
    _draw_button.disabled = true
    _end_turn_button.disabled = true
    end_turn.emit(_total_score())


func _on_submit_word_button_pressed() -> void:
    words.push_back(_get_word())
    for letter in _get_word():
        _remaining_tiles.erase(letter)
    _submit_word_button.disabled = true
    for c in _word_container.get_children():
        c.queue_free()
    _update_round_score_labels()


func _on_shuffle_sort_button_pressed() -> void:
    _sort_letters("shuffle")


func _on_az_sort_button_pressed() -> void:
    _sort_letters("default")


func _on_points_sort_button_pressed() -> void:
    _sort_letters("points")

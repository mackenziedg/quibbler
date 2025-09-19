class_name Card
extends MarginContainer

@export var letter: String = "A":
    set(l):
        _letter_label.text = l
        _score_label.text = str(CardData.points(l))
        letter = l

@onready var _letter_label := %LetterLabel
@onready var _score_label := %ScoreLabel
@onready var _anim := $AnimationPlayer


func _ready() -> void:
    _anim.play("on_create")
    

func submit_word() -> void:
    _anim.play("on_submit_word")


func destroy_leftover() -> void:
    _anim.play("on_destroy_leftover")    


func highlight(b: bool) -> void:
    if b:
        _anim.play("mouseover")
    else:
        _anim.play_backwards("mouseover")


func _on_card_panel_mouse_entered() -> void:
    highlight(true)


func _on_card_panel_mouse_exited() -> void:
    highlight(false)

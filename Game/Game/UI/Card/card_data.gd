extends Node

const _CARDS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

const _CARD_COUNTS := [
50, # A
18, # B
41, # C
35, # D
50, # E
12, # F
24, # G
27, # H
50, # I
1, # J
9, # K
50, # L
29, # M
50, # N
50, # O
30, # P
1, # Q
50, # R
50, # S
50, # T
36, # U
9, # V
8, # W
2, # X
19, # Y
4, # Z
]

const _CARD_POINTS := [
1, # A
9, # B
4, # C
5, # D
1, # E
10, # F
7, # G
7, # H
1, # I
12, # J
11, # K
1, # L
6, # M
1, # N
1, # O
6, # P
12, # Q
1, # R
1, # S
1, # T
5, # U
11, # V
11, # W
12, # X
8, # Y
12, # Z
]

@onready var valid_words: PackedStringArray = FileAccess.get_file_as_string("res://Game/Game/assets/data/dictionary_en.txt").split("\n")


func score_word(word: String) -> int:
    var score := 0
    for l in word:
        score += CardData.points(l)
    return score


func draw_card() -> String:
    # TODO: Change this to allow either drawing from an existing deck (this will need to inherit Node) or infinite draw.
    var deck := get_new_deck()
    deck.shuffle()
    return deck[0]


func get_new_deck() -> Array[String]:
    var deck: Array[String] = []
    for i in range(len(_CARDS)):
        for _j in range(_CARD_COUNTS[i]):
            deck.push_back(_CARDS[i])
    return deck


func points(letter: String) -> int:
    assert(letter in _CARDS)
    return _CARD_POINTS[_CARDS.find(letter)]

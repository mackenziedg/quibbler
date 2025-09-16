class_name SceneSwitcher
extends Control

func switch_scene_to(scene: Node) -> void:
    var current_scene := get_child(0)
    call_deferred("add_child", scene)
    current_scene.call_deferred("queue_free")
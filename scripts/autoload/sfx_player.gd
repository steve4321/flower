extends Node
## 音效播放器占位（静默）
## TODO: 接入音频文件后替换为真实实现
## 触发点已埋在各 EventBus 信号处，接入后取消对应 pass 即可

func _ready() -> void:
	pass


func play_water() -> void:
	# EventBus.plant_watered 触发（阶段推进时播放开花音）
	pass


func play_flower() -> void:
	# EventBus.stage_advanced 触发（FLOWERING时播放）
	pass


func play_breed() -> void:
	# EventBus.breeding_started 触发
	pass


func play_rare() -> void:
	# EventBus.rare_flower_found 触发
	pass


func play_discover() -> void:
	# EventBus.flower_discovered 触发
	pass

extends Control

@onready var preview = $VBoxContainer/SkinPreview
@onready var menu_button: MenuButton = $VBoxContainer/MenuButton

const CharacterTextures = {
	"Naruto": preload("res://tex/freakingnatuto.png"),
	"Sasuke": preload("res://tex/sasuke.png"),
	"Obito": preload("res://tex/obito.png"),
	"Haku": preload("res://tex/haku.png"),
}

func _ready() -> void:
	for key in CharacterTextures.keys():
		var texture: Texture2D = CharacterTextures[key]
		
		var image: Image = texture.get_image()
		var image_size = image.get_size()
		var image_ratio = float(image_size.x) / float(image_size.y)
		
		image.decompress()
		print(int(64 * image_ratio))
		image.resize(int(64 * image_ratio), 64, Image.INTERPOLATE_NEAREST)
		
		var resized = ImageTexture.create_from_image(image)
		menu_button.get_popup().add_icon_item(resized, "    " + key)
	
	menu_button.get_popup().id_pressed.connect(func(id):
		var texture = CharacterTextures.values()[id]
		preview.texture = texture
		Signals.change_player_skin.emit(texture)
	)

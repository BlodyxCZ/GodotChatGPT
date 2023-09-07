extends Control


enum modes {
	text,
	image,
	none
}

var cur_mode = modes.text

var HEADERS = PackedStringArray([
	"content-type: application/json",
	"X-RapidAPI-Key: 44c3daf062mshc4b1be85e3d9fd6p1b3b70jsn4c8016148f48",
	"X-RapidAPI-Host: openai80.p.rapidapi.com"
	])

@onready var http_request = $HTTPRequest

var username : String = "user"
var ai_name : String = "assistant"


func _ready() -> void:
	
	cur_mode = modes.none
	http_request.request("https://via.placeholder.com/512")


func _on_http_request_request_completed(result, response_code, headers, body) -> void:
	
	match cur_mode:
		modes.text:
			var json = JSON.new()
			json.parse(body.get_string_from_utf8())
			var response = json.get_data()
			print(response)
			if response["choices"][0]["message"]["content"]:
				response = response["choices"][0]["message"]["content"]
				_add_to_chat(ai_name, response)
		modes.image:
			var json = JSON.new()
			json.parse(body.get_string_from_utf8())
			var response = json.get_data()
			if response["data"][0]["url"]:
				response = response["data"][0]["url"]
				_create_image(response)
		modes.none:
			if result != HTTPRequest.RESULT_SUCCESS:
				push_error("Image couldn't be downloaded. Try a different image.")
			$TextureRect.show()
			var image = Image.new()
			var error = image.load_png_from_buffer(body)
			if error != OK:
				push_error("Couldn't load the image.")
			var texture = ImageTexture.create_from_image(image)
			$TextureRect.texture = texture


func _chat(message: String, mode: modes) -> void:
	
	match mode:
		modes.text:
			cur_mode = modes.text
			var body = {
				"model": "gpt-3.5-turbo",
				"messages": [{
					"role": "user",
					"content": message
				}]}
			var payload = JSON.new().stringify(body)
			var error = http_request.request("https://openai80.p.rapidapi.com/chat/completions", HEADERS, HTTPClient.METHOD_POST, payload)
			if error != OK:
				push_error("Invalid request.")
		modes.image:
			cur_mode = modes.image
			var body = {
				"prompt": message,
				"n": 1,
				"size": "512x512"
			}
			var payload = JSON.new().stringify(body)
			var error = http_request.request("https://openai80.p.rapidapi.com/images/generations", HEADERS, HTTPClient.METHOD_POST, payload)
			if error != OK:
				push_error("Invalid request.")
	_add_to_chat(username, message)


func _create_image(url: String) -> void:
	
	cur_mode = modes.none
	http_request.request(url)


func _add_to_chat(who: String, what: String) -> void:
	
	var chat = who + ": " + "\n" + what + "\n" + "\n"
	
	$Chat.text += chat


func _on_send_pressed():
	
	if $HBoxContainer/LineEdit.text != "":
		_chat($HBoxContainer/LineEdit.text, modes.text)
		$HBoxContainer/LineEdit.set_text("")


func _on_clr_pressed():
	
	$HBoxContainer/LineEdit.set_text("")


func _on_img_pressed():
	
	if $HBoxContainer/LineEdit.text != "":
		_chat($HBoxContainer/LineEdit.text, modes.image)
		$HBoxContainer/LineEdit.set_text("")


func _on_x_pressed():
	
	$TextureRect.hide()


func _on_lock_pressed():
	
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, !DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS))

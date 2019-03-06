#include <GuiRichEdit.au3>
#include <Misc.au3>
#include "TCP.au3"

; ===============================================================
; make color
Global $cBackground = 0x2C2C25
Global $cText = 0xDBF6FF
Global $c_Blue = 0xD4B84D, $c_Green = 0x12C47B, $c_Red = 0x4408D5, $c_Yellow = 0x37C9B4
Global $c_Gray = 0x9BBEAD, $c_Orange = 0x42A7F4, $c_White = 0xFFFFFF

; GUI
Global $GUI, $Edit, $Input

; ===============================================================

Gui_Create()

; Open server
$ip = @IPAddress1
$port = 1000
Global $Server = Server($ip, $port)

Message("-------------------->", $c_Gray)

While 1
	Switch GUIGetMsg()
		Case -3
			Exit
	EndSwitch

	; $Server.accept() return info (can be an array) of informations the client sent
	$Accept = $Server.accept()

	; $Server.recv() return an array of indexs of all the clients that sent msg
	$Recv = $Server.recv()

	; $Server.getDisconnect() return an array of info of clients that just disconnected
	$Disconnect = $Server.getDisconnect()

	; Check them out, these are important funcs
	CheckMessage($Recv)
	CheckJoin($Accept)
	CheckDisconnect($Disconnect)
	CheckEnter()
WEnd

Func CheckJoin($Accept)

	; accept = info = [ip, name]
	If UBound($Accept) >= 2 Then

		$Data = $Accept[1] & " joined > "
		Message($Data, $c_Gray)

		$Server.send($Data)
	EndIf
EndFunc

Func CheckEnter()

	$Read = GUICtrlRead($Input)

	; whenever hit enter
	If _IsPressed("0D") And $Read <> "" Then

		$Data = "SERVER > " & $Read

		; print it out and send it to all clients
		Message($Data, $c_Blue)
		$Server.send($Data)

		GUICtrlSetData($Input, "")
	EndIf

EndFunc

Func CheckMessage($Recv)

	; recv = [ indexs of recv ]
	If IsArray($Recv) Then

		$Clients = $Server.clients ; Clients = []

		; loop through all client that sent msg
		For $i = 0 To UBound($Recv) - 1

			$index = $Recv[$i] ; recv[$i] is the index of the client that sent msg

			; $Client.info, $Client.msg
			$info = $Clients[ $index ].info ; [ip, name]
			$msg = $Clients[ $index ].msg ; can be an array

			If UBound($info) < 2 Then ContinueLoop ; just for sure

			; print it out, and send it to all clients
			$Data = $info[1] & " > " & $msg

			Message($Data, $c_Blue)
			$Server.send($Data)

		Next
	EndIf

EndFunc

Func CheckDisconnect($Disconnect)

	If IsArray($Disconnect) Then

		For $i = 0 To UBound($Disconnect) - 1

			$info = $Disconnect[$i] ; [ip, name]

			If UBound($info) < 2 Then ContinueLoop ; just for sure

			$Data = $info[1] & " just left >"
			Message($Data, $c_Gray)
			$Server.send($Data)
		Next
	EndIf

EndFunc

; ========== SHITTY CODE, DONT MIND IT
Func Message($msg, $color = False, $color_txt = $c_White)

	$sel = StringLen( _GUICtrlRichEdit_GetText($Edit) )
	$len = StringLen($msg)

	_GUICtrlRichEdit_SetCharColor($Edit, $cText)
	_GUICtrlRichEdit_AppendText($Edit, $msg & @CRLF)

	_Edit_SetFont($sel, $sel + $len, 10.5, "CONSOLAS")
	_Edit_SetPosColor($sel, $sel + $len, $cText)

	If $color Then
		$cmdPos = StringInStr($msg, ">")

		_Edit_SetPosColor($sel, $sel + $cmdPos, $color)
		_Edit_SetPosColor($sel + $cmdPos, $sel + $len, $color_txt)
		_Edit_SetFont($sel, $sel + $cmdPos, 10.5, "CONSOLAS BOLD")
	EndIf

	GUICtrlSetState ($Input, 256)
EndFunc

Func _Edit_SetFont($i, $i2, $size, $font)

	_GUICtrlRichEdit_SetSel($Edit, $i, $i2, True)
	_GUICtrlRichEdit_SetFont($Edit, $size, $font)
	_GUICtrlRichEdit_Deselect($Edit)

EndFunc

Func _Edit_SetPosColor($i, $i2, $color)

	_GUICtrlRichEdit_SetSel($Edit, $i, $i2, True)
	_GUICtrlRichEdit_SetCharColor($Edit, $color)
	_GUICtrlRichEdit_Deselect($Edit)

EndFunc

Func Gui_Create()

	$GUI = GUICreate("SERVER Chat room", 580, 435)
	GUISetBkColor(0x2C2C25)

	$Edit =  _GUICtrlRichEdit_Create($GUI, "", 10, 10, 400, 380, $ES_NOHIDESEL + $ES_READONLY + $ES_MULTILINE + 0x00200000 , 0x00000200 + 0x00000200)
	_GUICtrlRichEdit_SetBkColor($Edit, $cBackground)
	GUI_DrawBox(10, 10, 400, 380)

	$Input = GUICtrlCreateInput("", 10, 400, 400, 25)
	GUICtrlSetFont($Input, 12, 500, Default, "CONSOLAS", 5)
	GUICtrlSetColor($Input, $c_White)
	GUICtrlSetBkColor($Input, 0x5C5C55)
	GUISetState()
EndFunc

Func GUI_DrawBox($left = 0, $top = 0, $width = 100, $height = 100, $brush= 1, $color = $c_White)
	Local $Ctrl[4]
	$Ctrl[0] = GUICtrlCreateLabel("", $left - $brush, $top - $brush, $brush, $height + $brush * 2)
		GUICtrlSetBkColor(-1, $color)
	$Ctrl[1] = GUICtrlCreateLabel("", $left + $width + $brush, $top - $brush, $brush, $height + $brush * 3)
		GUICtrlSetBkColor(-1, $color)

	$Ctrl[2] = GUICtrlCreateLabel("", $left - $brush, $top - $brush, $width + $brush * 2, $brush)
		GUICtrlSetBkColor(-1, $color)
	$Ctrl[3] = GUICtrlCreateLabel("", $left - $brush, $top + $height + $brush, $width + $brush * 2, $brush)
		GUICtrlSetBkColor(-1, $color)
	Return $Ctrl
EndFunc
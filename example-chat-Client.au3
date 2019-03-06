#include <GuiRichEdit.au3>
#include <Misc.au3>
#include "TCP.au3"

;=================================================================
; make color
Global $cBackground = 0x2C2C25
Global $cText = 0xDBF6FF
Global $c_Blue = 0xD4B84D, $c_Green = 0x12C47B, $c_Red = 0x4408D5, $c_Yellow = 0x37C9B4
Global $c_Gray = 0x9BBEAD, $c_Orange = 0x42A7F4, $c_White = 0xFFFFFF

; GUI
Global $GUI, $Edit, $Input


; ===============================================================

Gui_Create()

$name = InputBox("", "Enter your name", "Anonymous3")

; connect to server with $name as this client info
$ip = @IPAddress1
$port = 1000
Global $Client = Client($ip, $port, $name)

; if connection failed
If $Client = False Then
	MsgBox(0, "", "Cannot connect to server")
	Exit
EndIf

Message("-------------------->", $c_Gray)

While 1

	; recieve data from server
	$recv = $Client.recv()

	; if recieved data then print it out
	If $recv <> False Then Message($recv)

	; recv = -1 mean server closed
	If $recv = -1 Then Message("Server Closed >", $c_Red)

	CheckEnter()

	Switch GUIGetMsg()
		Case -3
			Exit
	EndSwitch
WEnd

Func CheckEnter()

	$Read = GUICtrlRead($Input)

	; whenever hit enter
	If _IsPressed("0D") And $Read <> "" Then

		; send message to server
		$Client.send($Read)

		GUICtrlSetData($Input, "")
	EndIf

EndFunc


; ========== SHITTY CODE, DONT MIND IT
Func Message($msg, $color = False, $color_txt = $c_White)

	If $color = False Then $color = StringInStr(StringRight($msg, 2), ">") ? $c_Gray : $c_Blue

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

	$GUI = GUICreate("CLIENT Chat room", 580, 435)
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
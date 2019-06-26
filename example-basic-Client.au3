

#include <GUIConstants.au3>
#include <GUIEdit.au3>
#include "TCP.au3"


Global $Server, $Recv, $info
Global $GUI, $inputMsg, $editChat, $btnSend

$info = InputBox("Kết nối đến server", "Nhập tên của bạn vào", "name")
If $info = "" Then Exit

; Kết nối đến server ===================================================================
; kết nối đến server với ip là @IPAddress1, và port là 80, số port có thể chọn bất kỳ
; nhưng số port của server và client phải giống nhau
; $info là tên client, có thể là array
$Server = _TCPClient(@IPAddress1, 80, $info)

; nếu tạo server thât bại
If $Server = -1 Then
	MsgBox("", "Lỗi", StringFormat("Không thể kết nối đến server\nMã lỗi %s", @error))
	Exit
EndIf
;=================================================================================

; tạo gui ==================================
$GUI = GUICreate("Client", 400, 400)

$editChat = GUICtrlCreateEdit("", 0, 0, 400, 360, $ES_READONLY + $ES_WANTRETURN + $WS_VSCROLL + $ES_AUTOVSCROLL)
GUICtrlSetFont(-1, 13)

$inputMsg = GUICtrlCreateInput("",0, 360, 350, 40)
GUICtrlSetFont(-1, 13)

$btnSend = GUICtrlCreateButton("GỬI", 350, 360, 50, 40)

; để khi nhấn enter thì gửi msg
Local $aAccel[1][2] = [["{ENTER}", $btnSend]]
GUISetAccelerators($aAccel, $GUI)

GUISetState()
;=============================================

While 1

	RecvServerMsg()

	Switch GUIGetMsg()
		Case -3
			Exit

		Case $btnSend
			$read = GUICtrlRead($inputMsg)
			If $read = "" Then ContinueCase

			; gửi tin nhắn đến server
			GUICtrlSetData($inputMsg, "")
			_TCPSend($Server, $read)
	EndSwitch
	Sleep(10)
WEnd

Func RecvServerMsg()
	If $Server <> -1 Then
		; nhận tin nhắn từ server
		$Recv = _TCPRecv($Server)

		; nếu $Recv = -1 có nghĩa là mất kết nối đến server
		If $Recv = -1 Then
			$Server = -1
			_GUICtrlEdit_AppendText($editChat, "Mất kết nối đến server" & @CRLF)
		ElseIf $Recv Then
			_GUICtrlEdit_AppendText($editChat, $Recv & @CRLF)
		EndIf
	EndIf
EndFunc

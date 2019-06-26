

#include <GUIConstants.au3>
#include <GUIEdit.au3>
#include "TCP.au3"


Global $Server, $ClientAccept, $ClientRecv, $ClientDis
Global $GUI, $inputMsg, $editChat, $btnSend

; TẠO SERVER ===================================================================
; tạo server với ip là @IPAddress1, và port là 80, số port có thể chọn bất kỳ
; nhưng số port của server và client phải giống nhau
$Server = _TCPServer(@IPAddress1, 80)

; nếu tạo server thât bại
If $Server = -1 Then
	MsgBox("", "Lỗi", StringFormat("Không thể tạo server\nMã lỗi %s", @error))
	Exit
EndIf
;=================================================================================

; tạo gui ==================================
$GUI = GUICreate("SERVER", 400, 400)

$editChat = GUICtrlCreateEdit("Đã khởi tạo server" & @CRLF, 0, 0, 400, 360, $ES_READONLY + $ES_WANTRETURN + $WS_VSCROLL + $ES_AUTOVSCROLL)
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
	; trong vòng lặp của server phải có 3 hàm này, lưu ý nên để theo thứ tự này để chạy tối ưu nhất có thể
	$ClientAccept = _TCPServerAccept($Server) ; chấp nhận kết nối của client
	$ClientRecv = _TCPServerRecv($Server) ; nhận tin nhắn của client
	$ClientDis = _TCPServerGetDisconnect($Server) ; get client mới vừa ngắt kết nối

	If IsObj($ClientAccept) Then ClientConnect($ClientAccept)
	If IsObj($ClientRecv) Then ClientMessage($ClientRecv)
	If IsObj($ClientDis) Then ClientDisconnect($ClientDis)

	Switch GUIGetMsg()
		Case -3
			Exit

		Case $btnSend
			$read = GUICtrlRead($inputMsg)
			If $read = "" Then ContinueCase

			; gửi tin nhắn đến clients
			GUICtrlSetData($inputMsg, "")
			_GUICtrlEdit_AppendText($editChat, "SERVER: " & $read & @CRLF)
			_TCPServerSend($Server, "SERVER: " & $read)
	EndSwitch
WEnd

Func ClientConnect($client)
	Local $msg = $client.info & " đã tham gia"
	_GUICtrlEdit_AppendText($editChat, $msg & @CRLF)
	_TCPServerSend($Server, $msg)
EndFunc

Func ClientMessage($client)
	Local $msg = $client.info & ": " & $client.msg
	_GUICtrlEdit_AppendText($editChat, $msg & @CRLF)
	_TCPServerSend($Server, $msg)
EndFunc

Func ClientDisconnect($client)
	Local $msg = $client.info & " đã thoát"
	_GUICtrlEdit_AppendText($editChat, $msg & @CRLF)
	_TCPServerSend($Server, $msg)
EndFunc

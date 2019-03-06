#include <ScreenCapture.au3>
#include "TCP.au3"

; connect to server
$ip = @IPAddress1
$port = 1000
$Client = Client($ip, $port)

If $Client = False Then
	MsgBox(0,"","Cannot connect to server")
	Exit
EndIf


GUICreate("SERVER", 200, 200)
$btn = GUICtrlCreateButton("Send", 10, 10, 180, 180)
GUISetState()

While 1
	Switch GUIGetMsg()
		Case -3

			Exit
		Case $btn

			Local $msg[2] = ["Send an Array", "through TCP"]
			$Client.sendWait("Hello World")
			$Client.sendWait($msg)
	EndSwitch
WEnd

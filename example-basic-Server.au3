#include <Array.au3>
#include "TCP.au3"

; open server
$ip = @IPAddress1
$port = 1000
$Server = Server($ip, $port)

GUICreate("SERVER", 200, 200)
GUISetState()

While 1
	Switch GUIGetMsg()
		Case - 3
			Exit
	EndSwitch

	$Server.accept()
	$Recv = $Server.recv()

	CheckMessage($Recv)
WEnd

Func CheckMessage($Recv)

	If IsArray($Recv) Then

		; all clients
		$Clients = $Server.clients

		; loop through clients that sent msg
		For $i = 0 To UBound($Recv) - 1

			$index = $Recv[$i] ; index of client that sent msg

			$msg = $Clients[$index].msg

			If IsArray($msg) Then
				_ArrayDisplay($msg)
			Else
				MsgBox(0, "", $msg)
			EndIf
		Next
	EndIf

EndFunc
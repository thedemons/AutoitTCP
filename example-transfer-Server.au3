#include "TCP.au3"

; open server
$ip = @IPAddress1
$port = 1000
$Server = Server($ip, $port)

$guiW = Round( @DesktopWidth / 1.5 )
$guiH = Round( @DesktopHeight / 1.5 )

GUICreate("TCP Transfer", $guiW, $guiH)
$Pic = GUICtrlCreatePic("", 0, 0, $guiW, $guiH)
GUISetState()

While 1
	$Server.accept()
	$Recv = $Server.recv()

	CheckMessage($Recv)

	Switch GUIGetMsg()
		Case -3
			Exit
	EndSwitch
WEnd

Func CheckMessage($Recv)

	If IsArray($Recv) Then

		$Clients = $Server.clients

		For $i = 0 To UBound($Recv) - 1

			$index = $Recv[$i]

			; if data type is image
			If $Clients[$index].type = "IMG" Then

				$File =  $Clients[$index].msg
				GUICtrlSetImage($Pic, $File)

				FileDelete($File)
			EndIf
		Next
	EndIf

EndFunc
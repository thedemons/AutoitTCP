#include "TCP.au3"

; open server
$ip = @IPAddress1
$port = 1000
$Server = Server($ip, $port)


While 1
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

			MsgBox(0, "", $Clients[$index].msg )
			Exit
		Next
	EndIf

EndFunc
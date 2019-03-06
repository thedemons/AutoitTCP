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

$Client.send("Hello World")
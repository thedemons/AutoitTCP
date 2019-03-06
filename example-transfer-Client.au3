#include <ScreenCapture.au3>
#include <GDIPlus.au3>
#include "TCP.au3"

; connect to server
$ip = @IPAddress1
$port = 1000
$Client = Client($ip, $port)

If $Client = False Then
	MsgBox(0,"","Cannot connect to server")
	Exit
EndIf

$guiW = Round( @DesktopWidth / 4 )
$guiH = Round( @DesktopHeight / 4 )

GUICreate("Client", $guiW, $guiH)
$Pic = GUICtrlCreatePic("", 0, 0, $guiW, $guiH)

GUISetState()

$File = "capture.jpg"

While 1

	; capture screen
	$hHBmp = _ScreenCapture_Capture($File)

	$hHBmp = _GDIPlus_ImageResize($hHBmp, $guiW, $guiH)
	_GDIPlus_ImageSaveToFile($hHBmp, $File)

	GUICtrlSetImage($Pic, $File)

	; send file image
	$Send = $Client.sendFile($File)

	Switch GUIGetMsg()
		Case -3
			Exit
	EndSwitch
WEnd
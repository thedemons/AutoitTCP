#include-once
#include <WinAPI.au3>
#include <File.au3>
#include "AutoitObject_Internal.au3"

; all server and client created, to close socket at exiting
Global $__SOCKET[0]
Global $c_DAT_VERIFY = "\{VERIFY}"
Global $c_DAT_WAITING = "\{WAITING}"
Global $c_DAT_FILE = "\{FILE}"
Global $c_TYPE_TXT = "TXT"
Global $c_TYPE_IMG = "IMG"
Global $c_TYPE_FILE = "FILE"

Global $C_DIR_DATA = @ScriptDir & "\data"

Global $C_TRANSFER_SPLIT = 100000000
Global $C_TRANSFER_CONTINUE = "\{CONTINUE}"
Global $C_TRANSFER_END = "\{END}"

If Not FileExists($C_DIR_DATA) Then DirCreate($C_DIR_DATA)


OnAutoItExitRegister("CloseTCP")
TCPStartup()
__ClearConsole()

print("---------------------------")
print("> TCP starting up")

Func Server($ip, $port)

	Local $Server = IDispatch()
	$Server.ip = $ip
	$Server.port = $port
	$Server.maxLen = 10000000000
	$Server.listDis = False
	$Server.timeOut = 10000 ; 10s
	$Server.listen = TCPListen($ip, $port)

	If @error Then Return print("!	ERROR >	Cannot create listen socket")

	print("-	Server started > ip = " & $ip & "; port = " & $port)

	Local $aClients[0]
	$Server.clients = $aClients
	$Server.__defineGetter("accept", TCP_Server_Accept)
	$Server.__defineGetter("recv", TCP_Server_Recv)
	$Server.__defineGetter("send", TCP_Server_Send)
	$Server.__defineGetter("getDisconnect", TCP_Server_GetDisconnect)
	__AllSocketAppend($Server.listen)

	Return $Server
EndFunc

Func TCP_Server_GetDisconnect($this)

	Local $Server = $this.parent
	$Disconect = $Server.listDis
	$Server.listDis = False

	Return $Disconect
EndFunc


Func TCP_Server_Accept($this)

	Local $Server = $this.parent

	; accept connection
	Local $Accept = TCPAccept($Server.listen)
	If $Accept = -1 Then Return False

	; get info from connection
	Local $tTime = TimerInit()
	Do
		Local $Recv = TCPRecv($Accept, $Server.maxLen)

		If TimerDiff($tTime) > $Server.timeOut Then
			TCPCloseSocket($Accept)
			Return print("!	Client doesn't send any info >")
		EndIf
	Until $Recv <> ""

	; create client
	Local $Info = __DecodeMsg( $Recv )
	Local $Client = IDispatch()

	$Client.info = $Info
	$Client.msg = False
	$Client.socket = $Accept
	$Client.maxLen = $Server.maxLen
	$Client.timeOut = $Server.timeOut
	$Client.__defineGetter("send", TCP_Client_Send)
	$Client.__defineGetter("recv", TCP_Client_Recv)
	$Client.__defineGetter("recvWait", TCP_Client_RecvWait)
	$Client.__defineGetter("sendFile", TCP_Client_SendFile)
	Local $index = __ClientAppend($Server, $Client)

	; send verify msg to client
	$Client.send($c_DAT_VERIFY)

	print("-	Client connected index " & $index & " > info = " & __csString($Info))

	Return $Info
EndFunc

Func TCP_Server_Recv($this)

	Local $Server = $this.parent

	Local $isLog = $this.arguments.length >= 1 ? $this.arguments.values[0] : True

	; recv data from all client
	Local $IndexReturn[0], $IndexDiss[0], $InfoDiss[0]
	Local $aClients = $Server.clients
	For $i = 0 To UBound($aClients) - 1

		Local $Recv = $aClients[$i].recv()

		; client disconnected
		If $Recv = -1 Then

			print("-	Client disconnected index " & $i & " > info = " & __csString( $aClients[$i].info ))
			__ArrayAppend($IndexDiss, $i)
			__ArrayAppend($InfoDiss, $aClients[$i].info)
			ContinueLoop
		EndIf

		If $Recv <> False Then

			__ArrayAppend($IndexReturn, $i)
			If $isLog Then print("-	Recv Client index " & $i & " > msg = " & __csString( $Recv ))
		EndIf
	Next

	If UBound($IndexDiss) > 0 Then
		__ArrayDelete($aClients, $IndexDiss)
		$Server.listDis = $InfoDiss
	EndIf

	$Server.clients = $aClients

	Return UBound($IndexReturn) > 0 ? $IndexReturn : False
EndFunc

Func TCP_Server_Send($this)

	If $this.arguments.length < 1 Then Return print("!	ERROR > Invalid parameters || $Server.send( $Data )")

	Local $Server = $this.parent
	Local $Data = $this.arguments.values[0]
	$Data = __isEncoded($Data) ? $Data : __GetSendData($Data)

	$aClients = $Server.clients

	For $i = 0 To UBound($aClients) - 1

		$aClients[$i].send($Data)

	Next

EndFunc

Func Client($ip, $port, $Info = False)

	$Client = IDispatch()
	$Client.ip = $ip
	$Client.port = $port
	$Client.maxLen = 10000000000
	$Client.timeOut = 10000 ; 10s
	$Client.socket = TCPConnect($ip, $port)
	If $Client.socket <= 0 Then Return print("!	ERROR >	Cannot connect to server")

	; connected
	print("-	Connection started > ip = " & $ip & "; port = " & $port)

	$Client.__defineGetter("send", TCP_Client_Send)
	$Client.__defineGetter("sendFile", TCP_Client_SendFile)
	$Client.__defineGetter("recv", TCP_Client_Recv)
	$Client.__defineGetter("recvWait", TCP_Client_RecvWait)

	; sending info
	$Client.send( __GetSendData($Info, @IPAddress1) )

	; waiting for verify from server
	$Recv = $Client.recvWait()

	If $Recv = - 1 Then
		TCPCloseSocket($Client.socket)
		Return print("!	Server doesn't send verification info >")

	ElseIf $Recv = False Then
		TCPCloseSocket($Client.socket)
		Return print("!	Cannot connect to server >")
	EndIf

	If $Recv <> $c_DAT_VERIFY Then
		TCPCloseSocket($Client.socket)
		Return print("!	Verification failed, something has happend >")
	EndIf

	__AllSocketAppend($Client.socket)
	Return $Client
EndFunc

Func TCP_Client_Send($this)

	If $this.arguments.length < 1 Then Return print("!	ERROR > Invalid parameters || $Client.send( $Data )")

	Local $Client = $this.parent
	Local $Data = $this.arguments.values[0]
	$Data = __isEncoded($Data) ? $Data : __GetSendData($Data)

	; send msg to socket
	If TCPSend($Client.socket, $Data) = 0 Then Return False
	Return True
EndFunc

Func TCP_Client_SendFile($this)

	If $this.arguments.length < 1 Then Return False
	Local $Client = $this.parent
	Local $file = $this.arguments.values[0]

	If FileExists($file) = 0 Then Return False

	; read file
	Local $hFile = FileOpen($file, 16)

	; img info
	Local $type = __FileGetType($file)
	If $type = False Then Return False

	; send info about img
	Local $Info[2] = [ $c_DAT_FILE, $type ]
	If $Client.send($Info) = False Then Return print("!	Cannot send info to server >")

	$Recv = $Client.recvWait()

	If $Recv = -2 Then Return print("!	Time out waiting for server")
	If $Recv = -1 Then Return print("!	Server disconnected", -1)
	If $Recv = False Then Return print("!	Failed to receive from server")

	If $Recv <> $c_DAT_WAITING Then Return print("!	Server verification failed")

	Local $pos = 0
	$Client.timeOut = 1000
	Do
		FileSetPos($hFile, $pos, 0)
		Local $Split = FileRead($hFile, $C_TRANSFER_SPLIT)

		TCPSend($Client.socket, $Split)
		$pos += $C_TRANSFER_SPLIT

		$Recv = $Client.recvWait()
		$Recv = $Recv
		If $Recv = -2 Then Return print("!	Time out waiting for image")
		If $Recv <> $C_TRANSFER_CONTINUE Then Return print("!	Server verification failed")

	Until StringLen($Split) < $C_TRANSFER_SPLIT

	$Client.send($C_TRANSFER_END)

	FileClose($hFile)

	Return print("+	Send file success", True)
EndFunc

Func TCP_Client_RecvWait($this)

	Local $Client = $this.parent

	Local $len = $this.arguments.length >= 1 ? ($this.arguments.values[0] = Default ? $Client.maxLen : $this.arguments.values[0]) : $Client.maxLen
	Local $isDecode = $this.arguments.length >= 2 ? $this.arguments.values[1] : True

	Local $tTime = TimerInit()
	Do
		$Recv = $Client.recv($len, $isDecode)
		If TimerDiff($tTime) > $Client.timeOut Then Return -2
	Until $Recv <> False

	Return $Recv
EndFunc

Func TCP_Client_Recv($this)

	Local $Client = $this.parent

	Local $len = $this.arguments.length >= 1 ? ($this.arguments.values[0] = Default ? $Client.maxLen : $this.arguments.values[0]) : $Client.maxLen
	Local $isDecode = $this.arguments.length >= 2 ? $this.arguments.values[1] : True

	; recv msg from socket
	Local $Recv = TCPRecv($Client.socket, $len)

	If @error Then Return -1
	If $Recv = "" Then Return False

	$Recv = $isDecode ? __DecodeMsg($Recv) : $Recv
	$Client.type = $c_TYPE_TXT

	; if this is image
	If UBound($Recv) >= 2 And $Recv[0] = $c_DAT_FILE Then
		; tell then client to send image
		$Client.send($c_DAT_WAITING)
		$Client.timeOut = 1000
		Local $type = $Recv[1]

		; waiting for image
		Local $DataImg = "0x"
		While 1

			$Recv = $Client.recvWait($C_TRANSFER_SPLIT, False)
			If $Recv = -2 Then Return print("!	Time out waiting for image")

			; if client say end, mean end :)
			If $Recv = $C_TRANSFER_END Or StringInStr($Recv, "|") Then ExitLoop

			; strim 0x
			$DataImg &= StringTrimLeft($Recv, 2)

			; tell client to continue transfer
			$Client.send($C_TRANSFER_CONTINUE)
		WEnd

		If $type = "png" Or $type = "jpg" Or $type = "jpeg" Then
			$Client.type = $c_TYPE_IMG
		Else
			$Client.type = $c_TYPE_FILE
		EndIf

		; write img to file
		Local $fileName = _TempFile($C_DIR_DATA, "img-", $type)
		Local $hFile = FileOpen( $fileName, 16 + 2)
		FileWrite($hFile, $DataImg)
		FileClose($hFile)

		$Client.msg = $fileName
		Return $fileName
	EndIf

	$Client.msg = $Recv
	Return $Recv
EndFunc

Func CloseTCP()

	print("> TCP shutting down")
	TCPShutdown()

	print("> Sockets closing")
	For $i = 0 To UBound($__SOCKET) - 1
		TCPCloseSocket($__SOCKET[$i])
	Next

EndFunc

Func __GetSendData($Data, $ip = False)

	If IsArray($Data) Then

		Local $DataReturn = $ip = False ? "" : StringToBinary($ip, 4) & "|"
		For $iData = 0 To UBound($Data) - 1

			$DataReturn &= StringToBinary($Data[$iData], 4) & "|"
		Next

		Return $DataReturn

	ElseIf $Data = False And $ip Then

		Return StringToBinary($ip, 4)

	ElseIf $ip = False Then

		Return StringToBinary($Data, 4)
	Else
		Return  StringToBinary($ip, 4) & "|" & StringToBinary($Data, 4)
	EndIf

EndFunc

Func __DecodeMsg($Data)

	; data is array
	If StringInStr($Data, "|") Then

		If StringRight($Data, 1) = "|" Then $Data = StringTrimRight($Data, 1)
		$Split = StringSplit($Data, "|", 1)

		Local $DataReturn[$Split[0]]

		For $i = 1 To $Split[0]

			$DataReturn[$i - 1] = BinaryToString($Split[$i], 4)
		Next
		Return $DataReturn
	Else
		Return BinaryToString($Data, 4)
	EndIf

	Return $Data
EndFunc

Func __csString($Data)

	If IsArray($Data) Then
		Local $DataReturn = "["
		For $i = 0 To UBound($Data) - 1

			$DataReturn &= $Data[$i]
			$DataReturn &= $i = UBound($Data) - 1 ? "" : ", "
		Next
		Return $DataReturn & "]"
	Else
		Return "[" & $Data & "]"
	EndIf
EndFunc

Func __isEncoded($Data)
	If IsArray($Data) Or StringInStr($Data, "|") = False Or StringInStr($Data, "0x") = False Or StringRight($Data, 1) <> "|" Then Return False
	Return True
EndFunc

Func __AllSocketAppend($Socket)

	$UBound = UBound($__SOCKET)
	ReDim $__SOCKET[$UBound + 1]

	$__SOCKET[$UBound] = $Socket
EndFunc

Func __ClientAppend($Server, $Client)

	Local $aClients = $Server.clients
	Local $UBound = UBound($aClients)
	ReDim $aClients[$UBound + 1]

	$aClients[$UBound] = $Client
	$Server.clients = $aClients
	Return $UBound
EndFunc

Func __ArrayAppend(ByRef $Array, $value)

	Local $UBound = UBound($Array)
	ReDim $Array[$UBound + 1]

	$Array[$UBound] = $value
EndFunc

Func __ArrayDelete(ByRef $Array, $aIndex)

	Local $return[ UBound($Array) - UBound($aIndex) ]

	Local $n = 0, $z = 0
	For $i = 0 To UBound($Array) - 1

		If $n < UBound($aIndex) and $i = $aIndex[$n] Then
			$n += 1
			ContinueLoop
		EndIf
		$return[$z] = $Array[$i]
		$z += 1
	Next

	$Array = $return
EndFunc

; copied
Func __ClearConsole()
	Local $sCmd = "menucommand:420"
    Local $Scite_hwnd = WinGetHandle("DirectorExtension")
    Local $WM_COPYDATA = 74
    Local $CmdStruct = DllStructCreate('Char[' & StringLen($sCmd) + 1 & ']')
    DllStructSetData($CmdStruct, 1, $sCmd)
    Local $COPYDATA = DllStructCreate('Ptr;DWord;Ptr')
    DllStructSetData($COPYDATA, 1, 1)
    DllStructSetData($COPYDATA, 2, StringLen($sCmd) + 1)
    DllStructSetData($COPYDATA, 3, DllStructGetPtr($CmdStruct))
    DllCall('User32.dll', 'None', 'SendMessage', 'HWnd', $Scite_hwnd, _
            'Int', $WM_COPYDATA, 'HWnd', 0, _
            'Ptr', DllStructGetPtr($COPYDATA))
EndFunc   ;==>SendSciTE_Command

Func __FileGetType($str)

	$Split = StringSplit($str, ".", 1)

	If $Split[0] < 2 Then Return False

	Return $Split[ $Split[0] ]

EndFunc

Func print($msg, $return = False)

	ConsoleWrite($msg & @CRLF)
	Return $return
EndFunc
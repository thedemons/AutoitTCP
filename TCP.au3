#include-once
#include <Array.au3>
#include "AutoItObject.au3"

; no documents
Global Const $iHeadLen = 16

TCPStartup()
_AutoItObject_Startup()

#cs

	< External function >
		For Server
			_TCPServer
			_TCPServerAccept
			_TCPServerGetDisconnect
			_TCPServerRecv
			_TCPServerSend
			_TCPRecv
			_TCPSend

		For Client
			_TCPClient
			_TCPRecv
			_TCPSend

	< Internal usage only >
			_TCPEncode
			_TCPDecode
			_TCPArrayToData
			_TCPDataToArray
#ce

#cs
	_TCPServer($ip, $port = 80, $maxConn = 10000)
		Usage:
			To open a TCP Server

		Parameters:
			$ip: The IP address to open TCP server
			$port: Custom port, can be any number, the client connected to this ip must have the same port opened
			$maxConn: Max number of clients can be connected to this serever

		Return value:
			Success:
				The handle to a server, this is an object that contain:

					+ $Server.ClientCount	= return the number of clients
					+ $Server.clients		= an array contains all clients connected, in object type

					+ $Server.ip		= the ip of this server
					+ $Server.port		= the port of this server
					+ $Server.maxconn	= $maxConn
					+ $Server.iCursor	= internal use only, don't alter this please!
			Error:
				-1, and set the @error to non-zero, look for TCPListen in the help file to learn more
#ce

Func _TCPServer($ip, $port = 80, $maxConn = 10000)

	Local $listen = TCPListen($ip, $port, $maxConn)
	Local $err = @error
	If $err Then Return SetError($err, 0, -1)

	Local $Server = IDispatch(), $clients[0]

	$Server.__add('ip', $ip)
	$Server.__add('port', $port)
	$Server.__add('maxConn', $maxConn)
	$Server.__add('clients', $clients)
	$Server.__add('iCursor', 0)
	$Server.__add('ClientCount', 0)
	$Server.__add('clientdisconnected', 0)
	$Server.__add('listen', $listen)

	$Server.__method('GetDisconnect', '_TCPServerGetDisconnect')
	$Server.__method('accept', '_TCPServerAccept')
	$Server.__method('recv', '_TCPServerRecv')
	$Server.__method('send', '_TCPServerSend')

	Return $Server
EndFunc

#cs
	_TCPServerAccept($Server)
		Usage:
			To accept new client's connection

		Parameters:
			$Server: Handle to a server, return by _TCPServer() function

		Return value:
			An object that contain client connected information
				+ $client.socket => client's socket
				+ $client.info 	 => can be an array, contain client name, ip address, etc,.. this is upon your choice when using TCPClient() function, which info to send
				+ $client.msg 	 => this is only matter when you use _TCPServerRecv()
			For example:
				$client = _TCPServerAccept($server)
				If IsObj($client) Then ... (handle the client login here)
#ce

Func _TCPServerAccept($Server)

	Local $socket = TCPAccept($Server.listen)

	If $socket = -1 Then Return 0

	; get info from client
	Local $info = _TCPRecv($socket)

	If $info = False Then
		TCPCloseSocket($socket)
		Return 0
	EndIf

	; add client
	Local $clients = $Server.clients
	Local $client = IDispatch()
	$client.__add("msg", "")
	$client.__add("socket", $socket)
	$client.__add("info", $info)

	_ArrayAdd($clients, $client)
	$Server.clients = $clients

	$Server.ClientCount += 1

	Return $client
EndFunc

#cs
	_TCPServerGetDisconnect($Server)
		Usage:
			To retrive the client that has just been disconnected

		Parameters:
			$Server: Handle to a server, return by _TCPServer() function

		Return value:
			An object that contain client connected information
				+ $client.socket => client's socket
				+ $client.info 	 => client name, can be an array, ip address, etc,.. this is upon your choice when using TCPClient() function, which info to send
				+ $client.msg 	 => this is only matter when you use _TCPServerRecv()
			For example:
				$clientDisconnected = _TCPServerAccept($server)
				If IsObj($clientDisconnected) Then ... (handle the client disconnetion event here)
#ce

Func _TCPServerGetDisconnect($Server)
	Local $dis = $Server.clientdisconnected
	$Server.clientdisconnected = 0
	Return $dis
EndFunc

#cs
	_TCPServerRecv($Server)
		Usage:
			To receive clients message

		Parameters:
			$Server: Handle to a server, return by _TCPServer() function

		Return value:
			An object that contain client connected information
				+ $client.socket => client's socket
				+ $client.info 	 => can be an array, contain client name, ip address, etc,.. this is upon your choice when using TCPClient() function, which info to send
				+ $client.msg 	 => can be an array, contain the client's message
			For example:
				$recv = _TCPServerRecv($server)
				If IsObj($recv) Then MsgBox(0, $recv.info, $recv.msg)
#ce

Func _TCPServerRecv($Server)

	Local $clients = $Server.clients, $recv, $i = $Server.iCursor

	If $i >= UBound($clients) Then $i = 0

	Do
		If $i = UBound($clients) Then ExitLoop

		$recv = _TCPRecv($clients[$i].socket)

		If $recv = -1 Then
			$Server.clientdisconnected = $clients[$i]
			_ArrayDelete($clients, $i)
			$Server.ClientCount -= 1
			$i -= 1
		EndIf

		If $recv <> -1 And ($recv Or IsArray($recv)) Then

			$Server.clients = $clients
			$Server.iCursor = $i + 1

			$clients[$i].msg = $recv
			Return $clients[$i]
		EndIf

		$i += 1
	Until "me" = "handsome"

	$Server.iCursor = 0
	$Server.clients = $clients
EndFunc

#cs
	_TCPServerSend($Server)
		Usage:
			To send a message to all the clients connected

		Parameters:
			$Server: Handle to a server, return by _TCPServer() function

		Return value:
			No return value, is it even matter ?? :D ????
#ce

Func _TCPServerSend($Server, $data)

	Local $clients = $Server.clients

	For $i = 0 To UBound($clients) - 1
		_TCPSend($clients[$i].socket, $data)
	Next

EndFunc

#cs
	_TCPRecv($socket)
		Usage:
			To receive message from a socket

		Parameters:
			$socket:
				+ The return value from _TCPClient() function
				+ or $client.socket, which is returned from _TCPServerAccept(), or _TCPServerRecv(),... etc

		Return value:
			Success:
				The message that received, can be an array
			Error:
				-1: $socket is closed, mean lose connection or the client/server has disconnected, in which case of a client, you can try to reconnect
#ce

Func _TCPRecv($socket)

	Local $len = TCPRecv($socket, $iHeadLen), $err = @error

	If $err Then Return -1
	If @extended = 1 Then Return 0
	$len = Number("0x" & $len)
	If $len <= 0 Or $len = "" Then Return False
;~ 	MsgBox(0,"",$len)
	Local $recv = TCPRecv($socket, $len)
	$err = @error
	If $err Then Return -1
	If @extended = 1 Then Return 0


	$recv = _TCPDataToArray($recv)
	If IsArray($recv) And $recv[0] = "/img" Then Return $recv

	Return _TCPDecode($recv)
EndFunc

#cs
	_TCPSend($socket, $data)
		Usage:
			To receive message from a socket

		Parameters:
			$socket:
				+ The return value from _TCPClient() function
				+ or $client.socket, which is returned from _TCPServerAccept(), or _TCPServerRecv(),... etc
			$data:
				Data to send, can be an array

		Return value:
			Success:
				The number of bytes sent to the socket
			Error:
				0, and set the @error value to non-zero, look in help file of TCPSend to learn more
#ce

Func _TCPSend($socket, $data)

	$data = _TCPEncode($data)

	If IsArray($data) Then $data = _TCPArrayToData($data)

	Local $len = StringLen($data)
	Local $send = TCPSend($socket, String(Hex($len, $iHeadLen)) & $data)

	Return $send
EndFunc

#cs
	_TCPClient($ip, $port = 80, $info = DriveGetSerial(@HomeDrive & "\"))
		Usage:
			To connect to a TCP server

		Parameters:
			$ip:
				The IP of the TCP server
			$port:
				Port of the TCP server, this port must match between client and server in order to connect
			$info:
				The info of this client, name, ip, hwid, etc.. depend on your choice, can be an array

		Return value:
			Success:
				The socket of the TCP server
			Error:
				False, and set the @error value to non-zero, see help file of TCPConnect to learn more
#ce

Func _TCPClient($ip, $port = 80, $info = DriveGetSerial(@HomeDrive & "\"))

	Local $socket = TCPConnect($ip, $port)
	Local $err = @error
	If $err Then Return SetError($err, 0, -1)

	_TCPSend($socket, $info)
	Return $socket
EndFunc

#cs
	_TCPEncode($data)
		internal usage only, no documents.
#ce

Func _TCPEncode($data)

	If IsArray($data) Then

		For $i = 0 To UBound($data) - 1

			$data[$i] = StringToBinary($data[$i], 4)
		Next
		Return $data

	Else
		Return StringToBinary($data, 4)
	EndIf
EndFunc

#cs
	_TCPDecode($data)
		internal usage only, no documents.
#ce

Func _TCPDecode($data)

	If IsArray($data) Then

		For $i = 0 To UBound($data) - 1

			If IsInt(StringLen($data[$i]) / 2) = False Then $data[$i] &= "0"
			$data[$i] = BinaryToString($data[$i], 4)
		Next
		Return $data

	Else
		Return BinaryToString($data, 4)
	EndIf
EndFunc

#cs
	_TCPArrayToData($data)
		internal usage only, no documents.
#ce

Func _TCPArrayToData($array)
	If IsArray($array) = False Then Return False

	Local $return

	For $x in $array
		$return &= $x & ";"
	Next

	Return StringTrimRight($return, 1)
EndFunc

#cs
	_TCPDataToArray($data)
		internal usage only, no documents.
#ce

Func _TCPDataToArray($data)

	If StringInStr($data, ";") = 0 Then Return $data

	Return StringSplit($data, ";", 2)
EndFunc

; just a trash function, what r u looking here mate?
Func __log($type, $txt, $return = False)

	Local $head = ">	"
	Switch $type
		Case 1
			$head = "+>	"
		Case 2
			$head = "!	"
	EndSwitch
	ConsoleWrite($head & $txt & @CRLF)
	Return $return
EndFunc

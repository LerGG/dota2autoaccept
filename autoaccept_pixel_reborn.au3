;-------------------------------------------
; @@@@@@@ INCLUDES @@@@@@@@@@@@@@@@@@@@@@@@@
;-------------------------------------------
#include <File.au3>
#include <WindowsConstants.au3>
#include <WinAPISysWin.au3>

; HOTKEYS - Courier
Global Const $hotKeyDeliverItems = "{F3}"
Global Const $hotKeySpeedCourier = "{F4}"
Global Const $hotKeyExecuteDelivery = "{+}"

; HOTKEYS - Script Functions
Global Const $hotkeyRoshanTimer = "{F6}"
Global Const $hotkeyExit = "{F11}"

; Hotkey Binds
HotKeySet($hotkeyRoshanTimer, "_startRoshanTimer")
HotKeySet($hotKeyExecuteDelivery, "_courierDeliver")
HotKeySet("^b", "_checkDotabuffID")
HotKeySet($hotkeyExit, "_exit")

; TCP Variables
; Assign Local variables the loopback IP Address and the Port.
; This IP Address only works for testing on your own computer.
Global Const $sIPAddress = "127.0.0.1" 
Global Const $iPort = 13300; Port used for the connection.
; Assign a Global variable the socket and connect to a Listening socket,
; with the IP Address and Port specified.
Global $iSocket

; Menu Checksums
Global Const $cs_gameFound = 2836413501 ; Accept Match Button
Global Const $cs_MainMenu = 191222980 ; Main Menu Boarder after last button
Global Const $cs_readyCheck = 1862865057 ; Ready Check Button
Global Const $cs_queue = 905880408 ; Cancel Queue Button

; Ingame Checksums
Global Const $cs_ingame = 487072004 ; Minimap Top Boarder
Global Const $color_pause = 16777215 ; text color white |
Global Const $color_pause_bp = 16777215 ; Text Color battlepass pause
Global Const $color_pause_event = 0
Global Const $cs_Draft = 147008508 ; Edit Hero Grid Button in draft

; Timers
Global $hTimerRoshan = 0
Global $bTimerRoshan = False
Global $hTimerGame = 0
Global $bTimerGame = False
Global $pauseTime = 0
Global $pauseTimeRosh = 0
Global $queueTime = 0

; Day time state
Global $day_Time = True

; ini states
Global $draft = False
Global $queue = False

; GUI Components

;Global $TransparentColor = 0x123456
;Global $ctrlTimer = ""
;Global $hGUI = GUICreate("YTB", 200, 80, 300, 1024, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TRANSPARENT, $WS_EX_LAYERED))
;_WinAPI_SetLayeredWindowAttributes($hGUI, $TransparentColor)
;GUISetBkColor(0x303030)
;GUISetState(@SW_SHOW, $hGUI)
;WinSetOnTop($hGUI, "", $WINDOWS_ONTOP)
;$ctrlTimer = GUICtrlCreateLabel("Timer/Sec:" & $hTimerRoshan,0,0)


;-------------------------------------------------------------------------------
; @@@@@@@ MAIN @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;-------------------------------------------------------------------------------

While 1
	Sleep(200)
	;GUICtrlSetData($ctrlTimer, "Timer/Sec: " & _converttimer($hTimerRoshan))
	_tt("")
	_sendTimer()
	_stopQueue()
	_queueGame()
	_checkQueue()
	_resetGame()
	_acceptReadyCheck()
	_acceptInvite()
	_checkDraft()
	;_pauseTime()
	;_startGameTime()
	;_runes()
	;_dayAndNight()
	;_neutralItems()
	;_roshan()
WEnd

; #FUNCTION# ===================================================================
; Name ..........: _tt
; Description ...: Tooltip function @ 0,0
; Syntax ........: _tt($sToolTip)
; Parameters ....: $sToolTip            - String to display
; Return values .: None
; ==============================================================================
Func _tt($sToolTip)
	If UBound($sToolTip) = 2 Then
		ToolTip("X: " & $sToolTip[0] & "Y: " & $sToolTip[1], 0, 0)
	Else
		ToolTip($sToolTip, 0, 0)
	EndIf
EndFunc   ;==>_tt

; #FUNCTION# ===================================================================
; Name ..........: _pauseTime
; Description ...: Adds pause time to running timers.
; Syntax ........: _pauseTime()
; ==============================================================================
Func _pauseTime()
	If _checkPause() = True Then
		Local $hPauseTime = TimerInit()
		While _checkPause() = True
			_tt("Paused. Don't open main menu")
			Sleep(100)
			If _acceptInvite() = True Then
				Exitloop
			EndIf
		Wend
		; Adds 3 second unpause time on unpause
		$pauseTime 			+= _convertTimer($hPauseTime) + 3
		$pauseTimeRosh 		+= _convertTimer($hPauseTime) + 3 
		$hPauseTime 		= 0 
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _startGameTime
; Description ...: Starts timers on game start.
; Syntax ........: _startGameTime()
; ==============================================================================
Func _startGameTime()
	If _checkTime() = True and $bTimerGame = False and _checkIngame() = True Then
		; Reset pre game pause timers
		$pauseTime = 0
		$pauseTimeRosh = 0
		; start game timers
		_gameTime()
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _runes
; Description ...: Announces runes.
; Syntax ........: _runes()
; ==============================================================================
Func _runes()
	; Action Runes
	If Mod((_convertTimer($hTimerGame) - $pauseTime),120) = 105 AND $bTimerGame = True Then
		_playSound(40,100,"action_runes")
	EndIf

	; Bounty Runes
	If Mod((_convertTimer($hTimerGame) - $pauseTime),180) = 160 AND $bTimerGame = True Then
		_playSound(40,100,"bounty_runes")
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _dayAndNight
; Description ...: Announces day and night.
; Syntax ........: _dayAndNight()
; ==============================================================================
Func _dayAndNight()
	If Mod((_convertTimer($hTimerGame) - $pauseTime),300) = 295 AND $bTimerGame = True Then
		If $day_time = True Then
			_playSound(40,100,"night_time")
			$day_time = False
		ElseIf $day_time = False Then
			_playSound(40,100,"day_time")
			$day_time = True
		EndIf
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _outposts
; Description ...: Announces Outposts
; Syntax ........: _outposts()
; ==============================================================================
Func _outposts()
	If _convertTimer($hTimerGame) > 500 and $bTimerGame = True Then
		If Mod((_convertTimer($hTimerGame) - $pauseTime),600) = 520 AND $bTimerGame = True Then
			_playSound(40,100,"outposts")
		EndIf
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _neutralItems
; Description ...: Announces neutral item drops.
; Syntax ........: _neutralItems()
; ==============================================================================
Func _neutralItems()
	; T1 Items
	If _convertTimer($hTimerGame) > 7*60 and $bTimerGame = True Then
		If (_convertTimer($hTimerGame) - $pauseTime) = (7*60)+1 Then
			_playSound(40,100,"toneitem")
		EndIf
	EndIf
	; T2 Items
	If _convertTimer($hTimerGame) > 17*60 and $bTimerGame = True Then
		If (_convertTimer($hTimerGame) - $pauseTime) = (17*60)+1 Then
			_playSound(40,100,"ttwoitem")
		EndIf
	EndIf
	; T3 Items
	If _convertTimer($hTimerGame) > 27*60 and $bTimerGame = True Then
		If (_convertTimer($hTimerGame) - $pauseTime) = (27*60)+1 Then
			_playSound(40,100,"tthreeitem")
		EndIf
	EndIf
	; T4 Items
	If _convertTimer($hTimerGame) > 37*60 and $bTimerGame = True Then
		If (_convertTimer($hTimerGame) - $pauseTime) = (37*60)+1 Then
			_playSound(40,100,"tfouritem")
		EndIf
	EndIf
	; T5 Items
	If _convertTimer($hTimerGame) > 60*60 and $bTimerGame = True Then
		If (_convertTimer($hTimerGame) - $pauseTime) = (60*60)+1 Then
			_playSound(40,100,"tfiveitem")
		EndIf
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _roshan
; Description ...: Announces Roshan timer states
; Syntax ........: _roshan()
; ==============================================================================
Func _roshan()
	; Aegis Timer - Four Minutes
	If _convertTimer($hTimerRoshan) - $pauseTimeRosh = 60 And $bTimerRoshan = True Then
		_playSound(40,100,"four_minute")
	EndIf
	; Aegis Timer - Three Minutes
	If _convertTimer($hTimerRoshan) - $pauseTimeRosh = 120 And $bTimerRoshan = True Then
		_playSound(40,100,"three_minute")
	EndIf
	; Aegis Timer - Two Minutes
	If _convertTimer($hTimerRoshan) - $pauseTimeRosh = 180 And $bTimerRoshan = True Then
		_playSound(40,100,"two_minute")
	EndIf
	; Aegis Timer - One Minutes
	If _convertTimer($hTimerRoshan) - $pauseTimeRosh = 240 And $bTimerRoshan = True Then
		_playSound(40,100,"one_minute")
	EndIf
	; Aegis Timer - Aegis Expire
	If _convertTimer($hTimerRoshan) - $pauseTimeRosh = 295 And $bTimerRoshan = True Then
		_playSound(20,100,"5")
		_playSound(20,100,"4")
		_playSound(20,100,"3")
		_playSound(20,100,"2")
		_playSound(20,100,"1")
	EndIf
	; Roshan Respawn
	If _convertTimer($hTimerRoshan) - $pauseTimeRosh = 420 And $bTimerRoshan = True Then ;420
		$hTimerRoshan = 0
		$bTimerRoshan = False
		$pauseTimeRosh = 0
		_playSound(60,100,"beware")
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _checkTime
; Description ...: Checks in-game clock for 0:00
; Syntax ........: _checkTime()
; Return values .: True = ingame time is 0:00; False
; ==============================================================================
Func _checkTime()
	; First Zero - Up down right left
	Local $pos_1 = PixelSearch(948,25,948,25,16645629,3)
	Local $pos_2 = PixelSearch(948,33,948,33,16777214,3)
	Local $pos_3 = PixelSearch(951,29,951,29,16777215,3)
	Local $pos_4 = PixelSearch(946,29,946,29,16777215,3)
	; Second Zero
	Local $pos_5 = PixelSearch(961,25,961,25,16645628,3)
	Local $pos_6 = PixelSearch(961,33,961,33,16777215,3)
	Local $pos_7 = PixelSearch(964,29,964,29,16777214,3)
	Local $pos_8 = PixelSearch(959,29,959,29,16777214,3)
	; Third Zero
	Local $pos_9 =  PixelSearch(970,25,970,25,16645628,3)
	Local $pos_10 = PixelSearch(970,33,970,33,16777214,3)
	Local $pos_11 = PixelSearch(973,29,973,29,16777214,3)
	Local $pos_12 = PixelSearch(968,30,968,30,16777214,3)
	; Checks for 0:00 ingame time
	If IsArray($pos_1) = True AND IsArray($pos_2) = True AND  IsArray($pos_3) = True AND  IsArray($pos_4) = True Then
		If IsArray($pos_5) = True AND IsArray($pos_6) = True AND  IsArray($pos_7) = True AND  IsArray($pos_8) = True Then
			If IsArray($pos_9) = True AND IsArray($pos_10) = True AND  IsArray($pos_11) = True AND  IsArray($pos_12) = True Then
				Return True
			EndIf
		EndIf
	Else
		Return False
	EndIf

EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _courierDeliver
; Description ...: One click courier (Deliver and Speedboost)
; Syntax ........: _courierDeliver()
; ==============================================================================
Func _courierDeliver()
	Send($hotKeyDeliverItems)
	Sleep(50)
	Send($hotKeySpeedCourier)
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _startRoshanTimer
; Description ...: Starts Roshan Timer
; Syntax ........: _startRoshanTimer()
; ==============================================================================
Func _startRoshanTimer()	
	$hTimerRoshan = TimerInit()
	$bTimerRoshan = True
	_tt("Roshan Timer Started")
	Sleep(1000)
	_tt("")
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _gameTime
; Description ...: Initiates game timer
; Syntax ........: _gameTime()
; ==============================================================================
Func _gameTime()
	$hTimerGame = TimerInit()
	$bTimerGame = True
EndFunc   ;==>_gameTime

; #FUNCTION# ===================================================================
; Name ..........: _acceptInvite
; Description ...: Presses Accept Match if button appears
; Syntax ........: _acceptInvite()
; Return values .: True = Game Found; False
; ==============================================================================
Func _acceptInvite()
	Local $cs_current = PixelChecksum(725, 505, 735, 515)
	; Clicks accept game button.
	If $cs_current = $cs_gameFound Then
		_forceResetGame()
		MouseClick("left", "936", "541", 2)
		Sleep(1000)
		Return True
	EndIf
	Return False
EndFunc   ;==>_acceptInvite

; #FUNCTION# ===================================================================
; Name ..........: _checkDraft
; Description ...: Checks if a draft was started and sends information to TCP server
; Syntax ........: _checkDraft()
; Return values .: True = Game Found; False
; ==============================================================================
Func _checkDraft()
	Local $cs_current = PixelChecksum(513,810, 564,835)
	If $cs_current = $cs_Draft Then
		_sendDraftState("True") ; TCP
		$queueTime = 0
	Else
		_sendDraftState("False") ; TCP
		Return False
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _checkinGame
; Description ...: Checks if in-game
; Syntax ........: _checkinGame()
; Return values .: True = in-game; False
; ==============================================================================
Func _checkinGame()
	Local $cs_current = PixelChecksum(130,800,135,805)
	If $cs_current = $cs_ingame Then
		Return True
	Else
		Return False
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _resetGame
; Description ...:  Resets timers and states after game finnishes
; Syntax ........: _resetGame()
; ==============================================================================
Func _resetGame()
	If _checkMainMenu() = True AND _checkFindGameButton() = True AND $bTimerGame = True Then
		$hTimerGame = 0
		$bTimerGame = False
		$hTimerRoshan = 0
		$bTimerRoshan = False
		$pauseTimeRosh = 0
		$pauseTime = 0
		$day_Time = True
		_tt("Game State reset")
		Sleep(1000)
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _forceResetGame
; Description ...: Resets states without condition.
; Syntax ........: _forceResetGame()
; ==============================================================================
Func _forceResetGame()
	$hTimerGame = 0
	$bTimerGame = False
	$hTimerRoshan = 0
	$bTimerRoshan = False
	$pauseTimeRosh = 0
	$pauseTime = 0
	$day_Time = True
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _checkMainMenu
; Description ...: Checks for main menu
; Syntax ........: _checkMainMenu()
; Return values .: True = Main menu active; False
; ==============================================================================
Func _checkMainMenu()
	Local $currentCheckSum_Menu = PixelChecksum(1230, 1, 1280, 25)
	If $currentCheckSum_Menu = $cs_MainMenu Then
		Return True
	Else
		Return False
	EndIf
EndFunc   ;==>_checkMainMenu

; #FUNCTION# ===================================================================
; Name ..........: _checkPause
; Description ...: Checks if game is paused
; Syntax ........: _checkPause()
; Return values .: True = Game Paused; False
; ==============================================================================
Func _checkPause()

	; Normal Pause
	Local $pos1 = PixelGetColor(874,401)
	Local $pos2 = PixelGetColor(941,398)
	Local $pos3 = PixelGetColor(1058,399)

	; Battlepass pause
	Local $pos1_bp = PixelGetColor(861,100)
    Local $pos2_bp = PixelGetColor(941,98)
    Local $pos3_bp = PixelGetColor(1046,99)

	If ($pos1 = $color_pause and $pos2 = $color_pause and $pos3 = $color_pause) OR ($pos1_bp = $color_pause_bp and $pos2_bp = $color_pause_bp and $pos3_bp = $color_pause_bp) Then
		Return True
	EndIf
	Return False
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _checkTP
; Description ...: Checks TP scrolls.
; Syntax ........: _checkTP()
; Return values .: True = Not Found; False = Found
; ==============================================================================
;~ Func _checkTP()
;~ 	Local $iColorTpScrollEmpty = PixelGetColor(1321,1043)
;~ 	If $color_TPScrollEmpty = $iColorTpScrollEmpty Then
;~ 		Return True
;~ 	Else
;~ 		Return False
;~ 	EndIf
;~ EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _checkFindGameButton
; Description ...: Returns Boolean if Button is there
; Syntax ........: _checkFindGameButton()
; Return values .: True = Button Found else False
; ==============================================================================
Func _checkFindGameButton()
	Local $pos1 = PixelGetColor(1616,1026)
	Local $pos2 = PixelGetColor(1675,1032)
	Local $pos3 = PixelGetColor(1731,1026)
	Local $pos4 = PixelGetColor(1770,1028)
	; Checks for find game button
	If $pos1 = $color_pause AND $pos2 = $color_pause AND $pos3 = $color_pause AND $pos4 = $color_pause Then
		Return True
	Else
		Return False
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _acceptReadyCheck
; Description ...: Automatically accepts ready-check.
; Syntax ........: _acceptReadyCheck()
; ==============================================================================
Func _acceptReadyCheck()
    Local $cs_current = PixelChecksum(799,420,1125,451)
    ; Clicks ready check button.
    If $cs_current = $cs_readyCheck Then
	    _tt("Ready Check Accept")
        MouseClick("left", "792", "632", 2)
        Sleep(Random(350, 1000))
        MouseMove(0,0)
        Sleep(Random(350, 1000))
		Return True
    Else
		Return False
	EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _playSound
; Description ...:  Plays sound in same directory as script.
; Syntax ........: _playSound($iVolumeStart, $iVolumeEnd, $sName)
; Parameters ....: $iVolumeStart        - 0-100 Volume Level
;                  $iVolumeEnd          - 0-100 Volume level, always 100
;                  $sName               - Audio file name. Mp3 only
; Return values .: None
; ==============================================================================
Func _playSound($iVolumeStart,$iVolumeEnd,$sName)
	Local $volumeStart = $iVolumeStart
	Local $volumeEnd = $iVolumeEnd
	Local $path = "sounds\" & $sName & ".mp3"
	SoundSetWaveVolume($volumeStart)
	SoundPlay($path)
	Sleep(1000)
	SoundSetWaveVolume($volumeEnd)
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _convertTimer
; Description ...: Calculates time run in seconds
; Syntax ........: _convertTimer($timer)
; Parameters ....: $timer               - Timer object
; Return values .: Timer in Seconds
; ==============================================================================
Func _convertTimer($timer)
	Local $iConvertedTimer = Int(TimerDiff($timer) / 1000, 1)
	Return $iConvertedTimer
EndFunc   ;==>_convertTimer

; #FUNCTION# ===================================================================
; Name ..........: _checkDotabuffID
; Description ...: Opens a browser tab with a selected dotabuff ID.
; Syntax ........: _checkDotabuffID()
; ==============================================================================
Func _checkDotabuffID()
	Send("^c")
	$iData = ClipGet()
	$sURL = "http://www.dotabuff.com/players/"&$iData
	ShellExecute($sURL)
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _checkQueue
; Description ...: Checks if game queue is active and starts timer if active.
; Syntax ........: _checkQueue()
; ==============================================================================
Func _checkQueue()

	Local $cs_current = PixelChecksum(1826,1018, 1859,1023)

	If _checkMainMenu() = True AND $cs_current = $cs_queue AND $queue = False Then
		$queue = True
		$queueTime = TimerInit()
		Return True
	ElseIf _checkMainMenu() = True AND _checkFindGameButton() = True AND $queue = True Then
		$queue = False
		$queueTime = 0
		Return False
	EndIf
EndFunc


Func _sendDraftState($state)
	TCPStartup()
	OnAutoItExitRegister("OnAutoItExit")
	$iSocket = TCPConnect($sIPAddress, $iPort)
	; If an error occurred display the error code and return False.
    If @error Then
        ; The server is probably offline/port is not opened on the server.
        Local $iError = @error
        MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", "Could not connect, Error code: " & $iError)
        Return False
    Else
		; handles incoming tcp stuff so stuff does not break lul
		Local $blank = TCPRecv($iSocket, 100)
		Local $str = "gameState:" & $state
		TCPSend($iSocket, $str)
		; Close the socket.
		TCPCloseSocket($iSocket)
    EndIf
EndFunc

Func _sendTimer()
	TCPStartup()
	OnAutoItExitRegister("OnAutoItExit")
	$iSocket = TCPConnect($sIPAddress, $iPort)
	; If an error occurred display the error code and return False.
    If @error Then
        ; The server is probably offline/port is not opened on the server.
        Local $iError = @error
        MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", "Could not connect, Error code: " & $iError)
        Return False
    Else
		; handles incoming tcp stuff so stuff does not break lul
		Local $blank = TCPRecv($iSocket, 100)
		Local $strTimer = "" & _convertTimer($queueTime) & ""
		TCPSend($iSocket, $strTimer)
		; Close the socket.
		TCPCloseSocket($iSocket)
    EndIf
EndFunc

Func _stopQueue()
	TCPStartup()
	OnAutoItExitRegister("OnAutoItExit")
	$iSocket = TCPConnect($sIPAddress, $iPort)
	; If an error occurred display the error code and return False.
    If @error Then
        ; The server is probably offline/port is not opened on the server.
        Local $iError = @error
        MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", "Could not connect, Error code: " & $iError)
        Return False
    Else
		Local $bool = TCPRecv($iSocket, 100)
		If $bool = "queueGame:Stop" Then
			MouseClick("left", 1835, 1023)
			Sleep(500)
			MouseMove(0, 0)
			TCPSend($iSocket, "queueGame:False")
			$queueTime = 0
		EndIF
		; Close the socket.
		TCPCloseSocket($iSocket)
    EndIf
EndFunc

Func _queueGame()
	TCPStartup()
	OnAutoItExitRegister("OnAutoItExit")
	$iSocket = TCPConnect($sIPAddress, $iPort)
	; If an error occurred display the error code and return False.
    If @error Then
        ; The server is probably offline/port is not opened on the server.
        Local $iError = @error
        MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", "Could not connect, Error code: " & $iError)
        Return False
    Else
		Local $bool = TCPRecv($iSocket, 100)
		If $bool = "queueGame:True" Then
			MouseClick("left", 1703, 1026)
			Sleep(1000)
			MouseClick("left", 1703, 1026)
			Sleep(500)
			MouseMove(0, 0)
			TCPSend($iSocket, "queueGame:False")
		EndIF
		; Close the socket.
		TCPCloseSocket($iSocket)
    EndIf
EndFunc

; #FUNCTION# ===================================================================
; Name ..........: _exit
; Description ...: Exits script
; Syntax ........: _exit()
; ==============================================================================
Func _exit()
	TCPShutdown() ; Close the TCP service.
	Exit
EndFunc   ;==>_exit

Func OnAutoItExit()
    TCPShutdown() ; Close the TCP service.
EndFunc   ;==>OnAutoItExit

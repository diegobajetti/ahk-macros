#NoEnv
SetWorkingDir %A_ScriptDir%
; #IfWinActive ahk_class Red Dead Redemption 2
#SingleInstance, force

Cook := "["
IncCook := "'"
DecCook := ";"

CookBtn := "space"
StowBtn := "r"

global PlaceOnGrillAnimationDelay := 2060
global CookDelay := 5340
global StowAnimationDelay := 2858

global GameKeyDelay := 200
global KeySendDelay := 100
global KeyPressDuration := 100

global CookNo := 20

global ToolTip1 := false
global ToolTip2 := false

Hotkey, %Cook%, Cook
Hotkey, %IncCook%, IncCook
Hotkey, %DecCook%, DecCook

F1::suspend
  return
  setkeydelay, KeySendDelay, KeyPressDuration

Cook:
  Loop, %CookNo% {
    ToolTip2 := true
    n := getActiveToolTips()
    yPos := n * 25 + 10
    Tooltip, STARTED COOK #%A_Index%, 10, %yPos%, 2

    send {%CookBtn% down}
    sleep, GameKeyDelay
    send {%CookBtn% up}
    sleep, PlaceOnGrillAnimationDelay
    
    send {%CookBtn% down}
    sleep, CookDelay
    send {%CookBtn% up}
    
    send {%StowBtn% down}
    sleep, GameKeyDelay
    send {%StowBtn% up}
    sleep, StowAnimationDelay
  }
  n := getActiveToolTips()
  yPos := n * 25 + 10
  ToolTip, FINISHED COOK, 10, %yPos%, 2
  SetTimer, RemoveToolTip2, -3000
  return

IncCook:
  if (ToolTip2)
    return
  
  CookNo++
  ToolTip1 := true
  n := getActiveToolTips()
  yPos := n * 25 + 10
  ToolTip, COOK=%CookNo%, 10, %yPos%, 1
  SetTimer, RemoveToolTip1, -3000
  return

DecCook:
  if (ToolTip2)
    return
  
  CookNo--
  if (CookNo < 1)
    CookNo := 1
  Tooltip1 := true
  n := getActiveToolTips()
  yPos := n * 25 + 10
  Tooltip, COOK=%CookNo%, 10, %yPos%, 1
  SetTimer, RemoveToolTip1, -3000
  return

getActiveToolTips() {
  ToolTipCounter := -1
  if (ToolTip1)
    ToolTipCounter++
  if (ToolTip2)
    ToolTipCounter++
  return ToolTipCounter
}

RemoveToolTip1:
  Tooltip,,,,1
  ToolTip1 := false
  return

RemoveToolTip2:
  Tooltip,,,,2
  ToolTip2 := false
  return

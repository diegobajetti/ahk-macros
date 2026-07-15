#requires AutoHotkey v2

#SingleInstance Force
#HotIf WinActive('ahk_exe explorer.exe')
#Warn Unreachable, Off
SetWorkingDir A_InitialWorkingDir

~Enter::{
  path := ControlGetText("DirectUIHWND2")
  Sleep 100
  new_path := ControlGetText("DirectUIHWND2")
  if (new_path != path)
    Send "^{Space}"
  Return
}
#HotIf


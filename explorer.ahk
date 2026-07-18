#requires AutoHotkey v2

#SingleInstance Force
#HotIf WinActive('ahk_exe explorer.exe')
#Warn Unreachable, Off
SetWorkingDir A_InitialWorkingDir

GetExplorerPath(hWnd := WinExist("A")) {
  for window in ComObject("Shell.Application").Windows {
    if window.hwnd != hWnd
      continue
    return window.Document.Folder.Self.Path
  }
}

~Enter::{
  path := GetExplorerPath()
  Sleep 100
  newPath := GetExplorerPath()
  if (newPath != path)
    Send "^{Space}"
  Return
}
#HotIf


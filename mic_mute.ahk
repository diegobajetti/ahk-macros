#requires AutoHotkey v2
#include Lib/Info.ahk

#SingleInstance Force
#Warn Unreachable, Off
SetWorkingDir A_InitialWorkingDir

global muteInfo := 0
global devicesInfo := 0

>^F13::{
  global muteInfo
  Infos.DestroyAll()
  mute := SoundGetMute(, "Microphone:1")
  SoundSetMute(-1,, "Microphone:1")
  muteInfo := Info(Format("Microphone {1}", mute ? "U" : "M"),, "Screen",)
}


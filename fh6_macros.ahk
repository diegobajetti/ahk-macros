#requires AutoHotkey v2

#SingleInstance Force
#HotIf WinActive('ahk_exe forzahorizon6.exe')
XButton1::{
  Press("enter")
}

Q::{
  Press("left")
}

E::{
  Press("right")
}
#HotIf

/**
 * @description  
 * Mimics the way a human would press a key by holding it down and releasing it after a specified amount of time.
 * @param {String} key  
 * The name of the key to be pressed. Refer to the {@link https://www.autohotkey.com/docs/v2/KeyList.htm#keyboard|documentation} for the full set of available keys.
 * @param {Integer} times  
 * The number of times the specified key will be pressed.
 * @param {Integer} delay  
 * The number in milliseconds between keystrokes.
 * @param {Boolean} invalid  
 * Specifies whether the action taken should be considered towards the current position of the program in the f6 menu.  
 * Useful when traversing the wheels or paint section, where the current position is not needed/irrelevant.
 * @returns  
 */
Press(key, times:=1, delay:=35, invalid?) {
  Loop times {
    Send "{" key " down}"
    Sleep delay
    Send "{" key " up}"
    Sleep delay
  }
}

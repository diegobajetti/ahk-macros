#requires AutoHotkey v2
#include Lib/OCR.ahk
#include Lib/Info.ahk

#SingleInstance Force
#HotIf WinActive('ahk_exe forzahorizon6.exe')
#Warn Unreachable, Off
SetWorkingDir A_InitialWorkingDir

CoordMode "ToolTip", "Client"
CoordMode "Pixel", "Client"

global DEBUG := false
global CURRENT_POS := 0

global KeySendDelay := 50
global KeyPressDuration := 15
SetKeyDelay(KeySendDelay, KeyPressDuration)

global ENTRY_WIDTH := 330
global ENTRY_HEIGHT := 38
global MENU_Y := 182

F1::Reload

F2::{
  global DEBUG
  DEBUG := !DEBUG
  if DEBUG {
    Infos.DestroyAll()
    debugInfo := Info("DEBUG MODE ON", 0)
  } else {
    Infos.DestroyAll()
    Info("DEBUG MODE OFF")
  }
}

XButton1::Enter

Q::Left

E::Right

S::Down

W::Up


/**
 * @description  
 * Mimics the way a human would press a key by holding it down and releasing it after a specified amount of time.
 * @param {String} key  
 * The name of the key to be pressed. Refer to the {@link https://www.autohotkey.com/docs/v2/KeyList.htm#keyboard|documentation} for the full set of available keys.
 * @param {Integer} times  
 * The number of times the specified key will be pressed.
 * @param {Integer} delay  
 * The number in milliseconds between keystrokes.
 * @returns  
 */
Press(key, times:=1, delay:=35) {
  Loop times {
    Send "{" key " down}"
    Sleep delay
    Send "{" key " up}"
    Sleep delay
  }
}

/**
 * @description  
 * Draws a rectangle on the screen and returns the GUI object associated with it.
 * @param {Integer} x  
 * The left edge of the rectangle.
 * @param {Integer} y  
 * The top edge of the rectangle.
 * @param {Integer} w  
 * The width of the rectangle.
 * @param {Integer} h  
 * The height of the rectangle.
 * @param {String} color  
 * The color of the rectangle.
 * @param {Integer} d  
 * The border thickness of the rectangle.
 * @param {Integer} showTime  
 * The time in milliseconds the rectangle should stay visible on the screen.  
 * If this number is more than zero, it halts further execution of the script.
 * @returns {Object}  
 * The rectangle GUI.
 */
DrawRectangle(x, y, w, h, color:="Red", d:=2, showTime:=2000) {
  RectGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
  RectGui.BackColor := color
  WinGetClientPos(&rX, &rY,,, WinExist("A"))
  x += rX
  y += rY
  x -= d
  y -= d
  w += d * 2
  h += d * 2

  innerW := w - (d * 2)
  innerH := h - (d * 2)
  WinSetRegion(Format(
    "0-0 {1}-0 {1}-{2} 0-{2} 0-0 "             ; Outer rectangle
    "{3}-{3} {4}-{3} {4}-{5} {3}-{5} {3}-{3}", ; Inner rectangle
    w, h, d, w - d, h - d
  ), RectGui.Hwnd)
  RectGui.Show("NA x" x " y" y " w" w " h" h)

  if (showTime > 0) {
    Sleep(showTime)
    RectGui.Destroy()
  }
  return RectGui
}

/**
 * @description  
 * Verifies that a 10x10 area at (x, y) coordinates is white.  
 * This method can be used to verify the current position of the script since  
 * the menu at the specified coordinates should be white. It is also useful to  
 * verify whether or not the script is the last item of the menu.
 * @param {Integer} x  
 * The left edge of the search area.
 * @param {Integer} y  
 * The top edge of the search area.
 * @param {Integer} w  
 * The width of the rectangle.
 * @param {Integer} h  
 * The height of the rectangle.
 * @param {String} color  
 * The color to match.
 * @param {Integer} precision  
 * The number of times to check the specified area, as the code may fail on a perfectly white pixel.
 * @returns {Boolean}  
 * - `1` Selected  
 * - `0` Not selected
 */
VerifySelection(x, y, w:=10, h:=10, color:=0xFFFFFF, precision:=5) {
  x1 := x
  y1 := y + 1
  x2 := x1 + w
  y2 := y1 + h
  Loop precision
    if PixelSearch(&Px, &Py, x1, y1, x2, y2, color, 10) {
      found := true
      break
    }
  if DEBUG {
    color := PixelGetColor(Px ? Px : x1, Py ? Py : y1)
    Info(Format(
      "Pixel at ({1}, {2}) is {3}`nResult: {4}",
      Px ? Px : x1, Py ? Py : y1, color, (IsSet(found) ? "selected" : "not selected")
    ),,, 1)
    DrawRectangle(x1, y1, w, h,,, 2300)
    Sleep 100
  }
  return IsSet(found)
}

/**
 * @description  
 * Reads from the screen at the specified coordinates using a {@link https://github.com/Descolada/OCR|OCR library}.  
 * @param {VarRef} found  
 * A variable to receive the result of the match operation.  
 * If a match was not made, this var will be `false`. Otherwise, it will be `true`.
 * @param {VarRef} str  
 * A variable to receive the string read from the screen.  
 * If OCR was unsuccessful at reading anything from the screen, this var will be empty. Otherwise, it will house the string that was read.
 * @param {Integer} x  
 * The left edge of the search area.
 * @param {Integer} y  
 * The top edge of the search area.
 * @param {Integer} w  
 * The width of the search area.
 * @param {Integer} h  
 * The height of the search area.
 * @param {Any} match  
 * Zero, one, or two values to match for in the found string.  
 * - Empty: if match is not provided or empty, return the OCR result; the VarRef `found` will be `unset`  
 * - One: if match has one string, it will match for the specified string; the VarRef `found` will be `true` if the string was matched, and `false` if not  
 * - Two: if match has two strings, it will match for either string; the VarRef `found` will be `true` if either string was matched, and `false` if neither matched
 * @returns
 */
OCRFromScreen(&found, &str, x, y, w, h, match*) {
  hWnd := WinExist("A")
  result := OCR.FromWindow(hWnd, {X: x, Y: y, W: w, H: h})
  str := result.Text
  if !IsSet(match)
    return

  match1 := match.Has(1) ? match[1] : ""
  match2 := match.Has(2) ? match[2] : ""
  try res1 := result.FindString(match1)
  try res2 := result.FindString(match2)
  found := IsSet(res1) || IsSet(res2)
  if DEBUG {
    txt := ""
    for _, y in result.Lines
      txt .= y.text
    x1 := !txt ? x + w : result.BoundingRect.X + result.BoundingRect.W + 2
    y1 := !txt ? y : result.BoundingRect.Y - 2
    Info('OCR result: "' txt '"',,, 1)
    for line in result.Lines
      line.Highlight(2300)
    else
      Sleep 2400
  }
  return
}

/**
 * @description  
 * Verifies that the current selection in the f6 menu is `ON`.  
 * For instance, if `Xenon Lights` is turned on, or if `Custom Wheels` is turned on.
 * @returns {Boolean}  
 * - `1` If current selection is `ON`  
 * - `0` If current selection is `OFF`
 */
IsOn() {
  x := 1776
  y := MENU_Y + (CURRENT_POS * ENTRY_HEIGHT)
  w := 52
  h := ENTRY_HEIGHT
  OCRFromScreen(&found, &result, x, y, w, h, "ON")
  return found
}

F13::{
  Loop {
    Press("enter", 2, 120)
    Sleep(570)
    if !VerifySelection(133, 343, 10, 10, 0xFFFFFF) && VerifySelection(133, 397, 10, 10, 0xEADE00) {
      Press("esc")
      Sleep(600)
      continue
    }
    Press("y")
    Sleep(140)
    Press("down")
    Sleep(120)
    Press("enter", 2, 120)
    break
  }
}
#HotIf

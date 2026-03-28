#requires AutoHotkey v2
#include Lib/OCR.ahk
#include Lib/Info.ahk

#SingleInstance Force
#HotIf WinActive('ahk_exe FiveM_b3751_GTAProcess.exe')
#Warn Unreachable, Off
SetWorkingDir A_InitialWorkingDir

CoordMode "ToolTip", "Client"
CoordMode "Pixel", "Client"

global DEBUG := false
global CURRENT_CAR := 0
global CURRENT_POS := 0

global KeySendDelay := 50
global KeyPressDuration := 15
SetKeyDelay(KeySendDelay, KeyPressDuration)

global ENTRY_WIDTH := 330
global ENTRY_HEIGHT := 38
global MENU_Y := 182

global debugInfo := 0
global carInfo := 0
global positionInfo := 0

F1::Reload

F2::{
  global DEBUG, debugInfo, carInfo, positionInfo
  DEBUG := !DEBUG
  if DEBUG {
    Infos.DestroyAll()
    debugInfo := Info("DEBUG MODE ON", 0)
    carInfo := Info("Current car: " Format("{:02}", CURRENT_CAR), 0,, 1)
    positionInfo := Info("Current position: " Format("{:02}", CURRENT_POS+1), 0,, 1)
  } else {
    Infos.DestroyAll()
    positionInfo := 0
    carInfo := 0
    Info("DEBUG MODE OFF")
  }
}

XButton1::{
  Press("enter")
}

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
  global CURRENT_POS
  if IsSet(invalid)
    GoTo press

  if key == "down"
    CURRENT_POS++
  else if key == "right" || key == "f6"
    CURRENT_POS := 0
  if positionInfo is Infos
    positionInfo.ReplaceText("Current position: " Format("{:02}", CURRENT_POS+1))

  press:
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
 * @param {Integer} precision  
 * The number of times to check the specified area, as the code may fail on a perfectly white pixel.
 * @returns {Boolean}  
 * - `1` Selected  
 * - `0` Not selected
 */
VerifySelection(x, y, precision:=5) {
  x1 := x
  y1 := y + 1
  x2 := x1 + 10
  y2 := y1 + 10
  Loop precision
    if PixelSearch(&Px, &Py, x1, y1, x2, y2, 0xFFFFFF, 16) {
      found := true
      break
    }
  if DEBUG {
    color := PixelGetColor(Px ? Px : x1, Py ? Py : y1)
    Info(Format(
      "Pixel at ({1}, {2}) is {3}`nResult: {4}",
      Px ? Px : x1, Py ? Py : y1, color, (IsSet(found) ? "selected" : "not selected")
    ),,, 1)
    DrawRectangle(x1, y1, 10, 10,,, 2300)
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
 * Verifies if the script is currently at the last position of the menu.  
 * Useful for determining whether the script should press `down` or `right`.
 * @returns {Boolean}  
 * - `1` Is at last position  
 * - `0` Is not at last position
 */
IsLastMenuItem() {
  x := 1820
  y := MENU_Y + (11 * ENTRY_HEIGHT)
  return CURRENT_POS != 0 && VerifySelection(x, y) 
}

/**
 * @description  
 * Finds the total number of pages in the f6 menu.
 * @returns {String}  
 * The number of pages.
 */
FindPage() {
  x := 1740
  y := 150
  w := 80
  h := 25
  OCRFromScreen(&found, &result, x, y, w, h)
  return result != "" ? SubStr(result, -1) : 1
}

/**
 * @description  
 * Finds and selects the `Customization` option when first opening the f6 menu.
 * @returns
 */
FindCustomization() {
  x := 1820
  i := 0
  Loop 3 {
    y := MENU_Y + ((A_Index - 1) * ENTRY_HEIGHT) + 10
    if VerifySelection(x, y) {
      i := A_Index
      break
    }
  }
  switch i {
    case 1:
      Press("down",,, true)
    case 3:
      Press("up")
  }
  Press("enter", 2)
}

/**
 * @description  
 * Finds `Horn` in the f6 menu.
 * @returns {Boolean}  
 * - `1` Successful at finding `Horn`  
 * - `0` Unsuccessful at finding `Horn`
 */
FindHorn() {
  global CURRENT_POS
  CURRENT_POS := 0
  if positionInfo is Infos
    positionInfo.ReplaceText("Current position: " Format("{:02}", CURRENT_POS+1))

  i := FindPage()
  outer:
  Loop i {
    Loop 12 {
      try found := IsHorn()
      catch as e {
        MsgBox e.Message
        Press("right")
        GoTo outer
      }
      if found {
        result := true
        break outer
      } else if !found && CURRENT_POS != 11
        Press("down")
    }
    Press("right")
  }
  if !IsSet(result) {
    MsgBox "Unable to find Horn, repeating search"
    GoTo outer
  }
  return IsSet(result)
}

/**
 * @description  
 * Verifies that the current selection in the f6 menu is `Horn`.
 * @returns {Boolean}  
 * - `1` If `Horn` was found
 * - `0` If `Horn` was not found
 */
IsHorn() {
  ; start of entry:  1470x182
  ; end of entry:    1800x220
  ; width of "Horn":     62px
  ; height of entry:     38px
  x := 1470
  y := MENU_Y + (CURRENT_POS * ENTRY_HEIGHT)
  w := 70
  h := ENTRY_HEIGHT
  x1 := x + ENTRY_WIDTH + 20
  y1 := y + 10
  if !VerifySelection(x1, y1)
    throw Error("Unable to find Horn:`nDetection failed after iterating through all pages of the menu.")
  OCRFromScreen(&found, &result, x, y, w, h, "Livery", "Horn")
  if result == "Livery" {
    Press("enter", 2)
    Press("backspace")
  }
  return found && result == "Horn"
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

F14::{
  global CURRENT_CAR, carInfo
  start := 1
  i := 0, j := -1
  Loop 1 {
    ; f7
    Press("f7",, 100)
    Press("enter", 3, 100)
    Press("right", 5, 100, true)
    Press("down", 2, 100, true)
    Press("up",, 100)
    Press("enter",, 100)
    
    ; find car
    right := Floor((start - 1) / 5)
    down := Mod(start - 1, 5)
    Loop right
      Press("right",, 120, true)
    Loop down
      Press("down",, 120, true)
    if A_Index != 1 && !Mod(A_Index - 1, 5) {
      j := 0
      Loop ++i
        Press("right",, 120, true)
    } else {
      Loop i
        Press("right",, 120, true)
      Loop ++j
        Press("down",, 120, true)
    }
    Press("enter",, 120)
    
    ; car info bubble
    CURRENT_CAR++
    if carInfo is Infos
      carInfo.ReplaceText("Current car: " Format("{:02}", CURRENT_CAR))
    else
      carInfo := Info("Current car: " Format("{:02}", CURRENT_CAR), 0,, 1)
    Sleep(1600)
    continue

    ; carbon menu
    Press("f6",, 100)
    FindCustomization()
    Sleep 500

    ; horn
    FindHorn()
    Sleep 500
    Press("enter")
    Press("down", 3,, true)
    Press("enter")
    Press("backspace")

    ; window tint
    Press(IsLastMenuItem() ? "right" : "down")
    Press("enter")
    Press("down",,, true)
    Press("enter")
    Press("backspace")

    ; license plate
    Press(IsLastMenuItem() ? "right" : "down")
    Press("enter")
    Press("up", 2)
    Press("enter")
    Press("backspace")

    ; plate text
    Press(IsLastMenuItem() ? "right" : "down")
    Press("enter")
    Loop 10 {
      Send "{Backspace down}"
      Sleep 25
    }
    Send "{Backspace up}"
    SendInput "{Raw}1      "
    Press("enter")
    Sleep 600

    ; wheels
    Press(IsLastMenuItem() ? "right" : "down")
    Press("enter")
    Press("down", 5,, true)
    Press("enter", 2)
    Press("up", 2)
    Press("enter")
    Press("backspace", 3)

    ; xenon lights
    Loop 4
      Press(IsLastMenuItem() ? "right" : "down")
    if !IsOn()
      Press("enter")

    ; custom tires
    Press(IsLastMenuItem() ? "right" : "down")
    Press(IsLastMenuItem() ? "right" : "down")
    if IsOn()
      Press("enter")
    Press("backspace")

    ; paint
    Press("down",,, true)
    Press("enter")

    ; primary and secondary color
    Press("down", 2,, true)
    Press("enter")
    Press("down", 3,, true)
    Press("enter")
    Press("right",,, true)
    Press("down",,, true)
    Press("enter")
    Press("backspace", 2)

    ; pearl color
    Press("down",,, true)
    Press("enter")
    Press("right", 7,, true)
    Press("enter")
    Press("backspace")

    ; wheel color
    Press("down",,, true)
    Press("enter", 2)
    Press("backspace")

    ; accent trim color
    Press("down",,, true)
    Press("enter", 2)
    Press("backspace")

    ; dashboard color
    Press("down",,, true)
    Press("enter", 2)

    ; save car
    Press("f7",, 100)
    Press("enter",, 100)
    Press("down",, 100, true)
    Press("enter",, 100)
  }
}
#HotIf

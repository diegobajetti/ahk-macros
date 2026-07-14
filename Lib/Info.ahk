#Include Extensions/Array.ahk
#Include Extensions/Gui.ahk
#Include Extensions/String.ahk

class Infos {

	/**
	 * To use Info, you just need to create an instance of it, no need to call any method after
	 * @param text *String*
	 * @param autoCloseTimeout *Integer* in milliseconds. Doesn't close automatically
	 */
	__New(text, autoCloseTimeout := 0, coordMode := "Client", location := 0) {
		this.text := text
		this.autoCloseTimeout := autoCloseTimeout
		this.coordMode := coordMode
		if !IsInteger(location) || location < 0 || location > 1
			throw Error("Invalid parameter: location")
		this.loc := location
		this._CreateGui()
		this.hwnd := this.gInfo.hwnd
		if !this._GetAvailableSpace() {
			this._StopDueToNoSpace()
			return
		}
		this._SetupHotkeysAndEvents()
		this._SetupAutoclose()
		this._Show()
	}


	static fontSizeL          := 12
	static fontSizeR          := 10
	static distanceL          := 3
	static distanceR          := 2.5
	static unit               := A_ScreenDPI / 96
	static guiHeightL         := Infos.fontSizeL * Infos.unit * Infos.distanceL
	static guiHeightR         := Infos.fontSizeR * Infos.unit * Infos.distanceR
	static maximumInfosL      := Floor(A_ScreenHeight / Infos.guiHeightL)
	static maximumInfosR      := Floor(A_ScreenHeight / Infos.guiHeightR)
	static spots              := Infos._GeneratePlacesArray()
	static foDestroyAll       := (*) => Infos.DestroyAll()
	static maxNumberedHotkeys := 12
	static maxWidthInChars    := 104

	
	static DestroyAll() {
		for spot in Infos.spots {
			for index, infoObj in spot {
				if !infoObj
					continue
				infoObj.Destroy()
			}
		}
	}


	static DestroyAllL() {
		for index, infoObj in Infos.spots[1] {
			if !infoObj
				continue
			infoObj.Destroy()
		}
	}


	static DestroyAllR() {
		for index, infoObj in Infos.spots[2] {
			if !infoObj
				continue
			infoObj.Destroy()
		}
	}
	

	static _GeneratePlacesArray() {
		availablePlacesL := []
		availablePlacesR := []
		loop Infos.maximumInfosL {
			availablePlacesL.Push(false)
		}
		loop Infos.maximumInfosR {
			availablePlacesR.Push(false)
		}
		return [availablePlacesL, availablePlacesR]
	}


	autoCloseTimeout := 0
	bfDestroy := this.Destroy.Bind(this)


	/**
	 * Will replace the text in the Info
	 * If the window is destoyed, just creates a new Info. Otherwise:
	 * If the text is the same length, will just replace the text without recreating the gui.
	 * If the text is of different length, will recreate the gui in the same place
	 * (once again, only if the window is not destroyed)
	 * @param newText *String*
	 * @returns {Infos} the class object
	 */
	ReplaceText(newText) {
		try WinExist(this.gInfo)
		catch
			return Infos(newText, this.autoCloseTimeout)

		if StrLen(newText) = StrLen(this.gcText.Text) {
			this.gcText.Text := newText
			this._SetupAutoclose()
			return this
		}

		Infos.spots[this.loc+1][this.spaceIndex] := false
		return Infos(newText, this.autoCloseTimeout, this.coordMode, this.loc)
	}

	Destroy(*) {
		try HotIfWinExist("ahk_id " this.gInfo.Hwnd)
		catch Any {
			return false
		}
		Hotkey("^Escape", "Off")
		if this.spaceIndex <= Infos.maxNumberedHotkeys
			Hotkey("F" this.spaceIndex, "Off")
		this.gInfo.Destroy()
		Infos.spots[this.loc+1][this.spaceIndex] := false
		return true
	}


	_CreateGui() {
		this.gInfo  := Gui("AlwaysOnTop -Caption +ToolWindow").DarkMode().MakeFontNicer(!this.loc ? Infos.fontSizeL : Infos.fontSizeR).NeverFocusWindow()
		this.gcText := this.gInfo.AddText(, this._FormatText())
	}

	_FormatText() {
		text := String(this.text)
		lines := text.Split("`n")
		if lines.Length > 1 {
			text := this._FormatByLine(lines)
		}
		else {
			text := this._LimitWidth(text)
		}
		return text.Replace("&", "&&")
	}

	_FormatByLine(lines) {
		newLines := []
		for index, line in lines {
			newLines.Push(this._LimitWidth(line))
		}
		text := ""
		for index, line in newLines {
			if index = newLines.Length {
				text .= line
				break
			}
			text .= line "`n"
		}
		return text
	}

	_LimitWidth(text) {
		if StrLen(text) < Infos.maxWidthInChars {
			return text
		}
		insertions := 0
		while (insertions + 1) * Infos.maxWidthInChars + insertions < StrLen(text) {
			insertions++
			text := text.Insert("`n", insertions * Infos.maxWidthInChars + insertions)
		}
		return text
	}

	_GetAvailableSpace() {
		spaceIndex := unset
		for index, isOccupied in Infos.spots[this.loc+1] {
			if isOccupied
				continue
			spaceIndex := index
			Infos.spots[this.loc+1][spaceIndex] := this
			break
		}
		if !IsSet(spaceIndex)
			return false
		this.spaceIndex := spaceIndex
		return true
	}

	_CalculateYCoord() {
		guiHeight := !this.loc ? Infos.guiHeightL : Infos.guiHeightR
		return Round(this.spaceIndex * guiHeight - guiHeight)
	}

	_StopDueToNoSpace() => this.gInfo.Destroy()

	_SetupHotkeysAndEvents() {
		HotIfWinExist("ahk_id " this.gInfo.Hwnd)
		Hotkey("^Escape", Infos.foDestroyAll, "On")
		if this.spaceIndex <= Infos.maxNumberedHotkeys
			Hotkey("F" this.spaceIndex, this.bfDestroy, "On")
		this.gcText.OnEvent("Click", this.bfDestroy)
		this.gInfo.OnEvent("Close", this.bfDestroy)
	}

	_SetupAutoclose() {
		if this.autoCloseTimeout {
			SetTimer(this.bfDestroy, -this.autoCloseTimeout)
		}
	}

	_Show() {
		if this.coordMode == "Screen" {
			this.gInfo.Show("AutoSize NA x0 y" this._CalculateYCoord())
			return
		}

		hWnd := WinExist("A")
		if this.coordMode == "Client"
			WinGetClientPos(&rX, &rY, &rW,, hWnd)
		else
			WinGetPos(&rX, &rY, &rW,, hWnd)
		x := rX
		if this.loc {
			this.gInfo.Show("AutoSize NA x-10000 y-10000")
			WinGetPos(,, &iW,, "ahk_id " this.Hwnd)
			x := rX + rW - iW
		}
		y := rY + this._CalculateYCoord()
		this.gInfo.Show("AutoSize NA x" x " y" y)
	}

}

Info(text, timeout?, coordMode?, location?) => Infos(text, timeout ?? 2000, coordMode ?? "Client", location ?? 0)

; ScreenshotToClaude.ahk v19
; XButton1 — выделить область мышкой (нативный GDI)
; XButton2 — весь левый монитор 1920x1080 (нативный GDI)
; F9       — toggle озвучки Claude

#Requires AutoHotkey v2.0
#Warn VarUnset, Off

screenshotsDir := "C:\Users\rostr\Desktop\claude-voice\screens"
if !DirExist(screenshotsDir)
    DirCreate(screenshotsDir)

CaptureRegion(x, y, w, h, filePath) {
    if (w <= 0 || h <= 0)
        return false
    hDC     := DllCall("GetDC", "ptr", 0, "ptr")
    hMemDC  := DllCall("CreateCompatibleDC", "ptr", hDC, "ptr")
    hBitmap := DllCall("CreateCompatibleBitmap", "ptr", hDC, "int", w, "int", h, "ptr")
    DllCall("SelectObject", "ptr", hMemDC, "ptr", hBitmap)
    DllCall("BitBlt", "ptr", hMemDC, "int", 0, "int", 0, "int", w, "int", h,
            "ptr", hDC, "int", x, "int", y, "uint", 0x00CC0020)
    DllCall("gdiplus\GdiplusStartup", "uint*", &tok := 0, "ptr", Buffer(16, 0), "ptr", 0)
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hBitmap, "ptr", 0, "ptr*", &pBitmap := 0)
    clsid := Buffer(16)
    DllCall("ole32\CLSIDFromString", "wstr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "ptr", clsid)
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", filePath, "ptr", clsid, "ptr", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    DllCall("gdiplus\GdiplusShutdown", "uint", tok)
    DllCall("DeleteObject", "ptr", hBitmap)
    DllCall("DeleteDC", "ptr", hMemDC)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hDC)
    return true
}

DrawRect(x1, y1, x2, y2) {
    hDC := DllCall("GetDC", "ptr", 0, "ptr")
    hPen := DllCall("CreatePen", "int", 0, "int", 2, "uint", 0x0000FF00, "ptr")
    DllCall("SelectObject", "ptr", hDC, "ptr", hPen)
    DllCall("SetROP2", "ptr", hDC, "int", 6)
    DllCall("MoveToEx", "ptr", hDC, "int", x1, "int", y1, "ptr", 0)
    DllCall("LineTo",   "ptr", hDC, "int", x2, "int", y1)
    DllCall("LineTo",   "ptr", hDC, "int", x2, "int", y2)
    DllCall("LineTo",   "ptr", hDC, "int", x1, "int", y2)
    DllCall("LineTo",   "ptr", hDC, "int", x1, "int", y1)
    DllCall("DeleteObject", "ptr", hPen)
    DllCall("ReleaseDC", "ptr", 0, "ptr", hDC)
}

XButton1:: {
    global screenshotsDir

    hCursor := DllCall("LoadCursor", "ptr", 0, "ptr", 32515, "ptr")
    DllCall("SetSystemCursor", "ptr", hCursor, "uint", 32512)

    KeyWait "LButton", "D"
    sX := A_ScreenX
    sY := A_ScreenY
    pX := sX
    pY := sY

    while GetKeyState("LButton", "P") {
        cX := A_ScreenX
        cY := A_ScreenY
        if (cX != pX || cY != pY) {
            DrawRect(sX, sY, pX, pY)
            DrawRect(sX, sY, cX, cY)
            pX := cX
            pY := cY
        }
        Sleep 16
    }

    DrawRect(sX, sY, pX, pY)
    DllCall("SystemParametersInfo", "uint", 0x57, "uint", 0, "ptr", 0, "uint", 0)

    eX := A_ScreenX
    eY := A_ScreenY
    rx := Min(sX, eX)
    ry := Min(sY, eY)
    rw := Abs(eX - sX)
    rh := Abs(eY - sY)

    if (rw < 5 || rh < 5)
        return

    Sleep 50
    ts := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    fp := screenshotsDir "\" "shot_" ts ".png"
    CaptureRegion(rx, ry, rw, rh, fp)
    A_Clipboard := fp
}

XButton2:: {
    global screenshotsDir
    ts := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    fp := screenshotsDir "\" "shot_" ts ".png"
    CaptureRegion(0, 0, 1920, 1080, fp)
    A_Clipboard := fp
}

F9:: {
    Run 'pythonw "C:\Users\rostr\.claude\skills\voice-output\voice_toggle.py"',, "Hide"
}

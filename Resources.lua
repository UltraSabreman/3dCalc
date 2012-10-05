local font1 = {
    font = "Times New Roman",
    size = 15,
    weight = 100,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = true,
    outline = false,
}
local font2 = {
    font = "Times New Roman",
    size = 15,
    weight = 100,
    blursize = 0,
    scanlines = 0,
    antialias = false,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = false,
    outline = true,
}


MESSEGE_TYPE_NORMAL = 0
MESSEGE_TYPE_ERROR = 1
MESSEGE_TYPE_WARNING = 2
MESSEGE_TYPE_NOTICE = 3
MESSEGE_TYPE_SUCCESS = 4
MESSEGE_TYPE_FAIL = 5

surface.CreateFont("Test", font1)
surface.CreateFont("Test2", font2)


SolidMat = CreateMaterial("SolidFill", "UnlitGeneric", {
    ["$basetexture"]        = "models/debug/debugwhite",
    ["$reflectivity"]       = "[0 0 0]",
    ["$vertexcolor"]        = 1,
    ["$color"]              = "[0.5 0.5 0.5]",
    ["$nocull"]             = 1,
})

WireHighlight = CreateMaterial("WireHighLight", "Wireframe", {
    ["$basetexture"]        = "editor/wireframe",
    ["$vertexcolor"]        = 0,
    ["$color"]              = "[ 0 0 0 ]",
    ["$nocull"]             = 1,
})

WireMat = CreateMaterial("WireFill", "Wireframe", {
    ["$basetexture"]        = "editor/wireframe",
    ["$vertexcolor"]        = 1,
    ["$nocull"]             = 1,
})

function messege(msg, msgType)
    if(msgType == MESSEGE_TYPE_NOTICE) then
        chat.AddText(Color(150,150,150), "[NOTICE]", Color(255,255,255), ": "..msg)
    elseif(msgType == MESSEGE_TYPE_ERROR) then
        chat.AddText(Color(255,0,0), "[ERROR]", Color(255,255,255), ": "..msg)
    elseif(msgType == MESSEGE_TYPE_WARNING) then
        chat.AddText(Color(255,150,0), "[WARNING]", Color(255,255,255), ": "..msg)
    elseif(msgType == MESSEGE_TYPE_NORMAL) then
        chat.AddText(Color(255,255,255), msg)
    elseif(msgType == MESSEGE_TYPE_SUCCESS) then
        chat.AddText(Color(0,255,0), "[SUCCESS]", Color(255,255,255), ": "..msg)
    elseif(msgType == MESSEGE_TYPE_FAIL) then
        chat.AddText(Color(255,0,0), "[FAIL]", Color(255,255,255), ": "..msg)
    else
        chat.AddText(Color(255,255,255),msg)
    end
end
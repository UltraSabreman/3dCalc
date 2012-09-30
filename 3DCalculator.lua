local func = "cos(abs(x)+abs(y))*(abs(x)+abs(y))"
local VertexStep = Vector(0.2,0.2,0.2)
local Min = -Vector(3,3,3)
local Max = Vector(3,3,3)

local GridStep = Vector(1,1,1)
local Ratio = Vector(1,1,1)

local TimeStep = 0.05
local AxisColoring = false 
local ScaleGridToZoom = true --When you zoom it, it makes sure that the grid still fills in the original size 

local RenderMode = "wire" --"wire","solid","solid+wire",
local dir = true

--[[ WHAT TO-DO:
[X] 1) Fix Zooming : Fix axis scaling when zooming (prob re-write code to start at 0,0 and draw out) [FUCK YEA CUNTS]
[ ] 2) Orginize
[ ] 3) Optimize
[ ] 4) Ui-anize

Optional:
[X] 5) Figure out how to get rid of the tangent lines....
]]

 
local SmallHudFont = {
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
local shit = {
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
surface.CreateFont("Test", SmallHudFont)
surface.CreateFont("Test2", shit)


local Percent = 0
local buildRoutine = nil
local Building = false
local Kill = false
local NumMeshes = 0
local ent = nil
local RenderMesh = false
local MeshIndex = 1
local DrawMatrix = Matrix()
local Meshes = {}
local Grid = {}
local ZoomStates = {
    {
        min = Min,
        max = Max,
        step = VertexStep,
        gridstep = GridStep,
    }
}

local MESSEGE_TYPE_NORMAL = 0
local MESSEGE_TYPE_ERROR = 1
local MESSEGE_TYPE_WARNING = 2
local MESSEGE_TYPE_NOTICE = 3
local MESSEGE_TYPE_SUCCESS = 4
local MESSEGE_TYPE_FAIL = 5

local SolidMat = CreateMaterial("SolidFill", "UnlitGeneric", {
    ["$basetexture"]        = "models/debug/debugwhite",
    ["$reflectivity"]       = "[0 0 0]",
    ["$vertexcolor"]        = 1,
    ["$color"]              = "[0.5 0.5 0.5]",
    ["$nocull"]             = 1,
})

local WireHighlight = CreateMaterial("WireHighLight", "Wireframe", {
    ["$basetexture"]        = "editor/wireframe",
    ["$vertexcolor"]        = 0,
    ["$color"]              = "[ 0 0 0 ]",
    --["$ignorez"]          = 1,
    ["$nocull"]             = 1,
})

local WireMat = CreateMaterial("WireFill", "Wireframe", {
    ["$basetexture"]        = "editor/wireframe",
    ["$vertexcolor"]        = 1,
    ["$nocull"]             = 1,
})

local badArgs = {
    "return", "local", "function", "if", "and", 
    "then", "do", "or", "nil", "false", "true",
    "while", "break", "for", "end", "%{", "%}",
    "%[", "%]"
}

---------------------------------------------------------------------------

local function generateFunctionFromText(infunc)
    if(!infunc or infunc == "") then chat.AddText(Color(255,0,0), "ERROR", Color(255,255,255), ": You need to give it a function to graph!") return false end

    local tempfunc = string.lower(infunc)

    for i,v in pairs(badArgs) do
        local pos = string.find(tempfunc, v)
        if(pos) then
            messege("Illigal Lua keyword '"..v.."' detected at position: "..pos, MESSEGE_TYPE_ERROR)
            return false
        end
    end

    local newfunction = CompileString("function getZ(x,y,t) return ("..tempfunc..") end setfenv(getZ, math)", "Z(X,Y,T) = "..infunc, false)
    if(type(newfunction) == "string") then
        messege(newfunction,MESSEGE_TYPE_ERROR)
        return false
    else
        newfunction()
        return true
    end
end

local function messege(msg, msgType)
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

local function DrawZoomPoints(Pos1, Pos2)
    local Pos1 = Pos1 or Min
    local Pos2 = Pos2 or Min

    local col = Color(255,127,0)

    render.DrawWireframeSphere(Pos1, 0.1, 4, 4, Color(0,255,0), true)
    render.DrawWireframeSphere(Pos2, 0.1, 4, 4, Color(255,0,0), true)

    --face 1
    render.DrawLine(Vector(Pos1.X, Pos1.Y, Pos1.Z), Vector(Pos1.X, Pos2.Y, Pos1.Z), col, true)
    render.DrawLine(Vector(Pos1.X, Pos2.Y, Pos1.Z), Vector(Pos1.X, Pos2.Y, Pos2.Z), col, true)
    render.DrawLine(Vector(Pos1.X, Pos2.Y, Pos2.Z), Vector(Pos1.X, Pos1.Y, Pos2.Z), col, true)
    render.DrawLine(Vector(Pos1.X, Pos1.Y, Pos2.Z), Vector(Pos1.X, Pos1.Y, Pos1.Z), col, true)

    --face 2
    render.DrawLine(Vector(Pos2.X, Pos2.Y, Pos2.Z), Vector(Pos2.X, Pos1.Y, Pos2.Z), col, true)
    render.DrawLine(Vector(Pos2.X, Pos1.Y, Pos2.Z), Vector(Pos2.X, Pos1.Y, Pos1.Z), col, true)
    render.DrawLine(Vector(Pos2.X, Pos1.Y, Pos1.Z), Vector(Pos2.X, Pos2.Y, Pos1.Z), col, true)
    render.DrawLine(Vector(Pos2.X, Pos2.Y, Pos1.Z), Vector(Pos2.X, Pos2.Y, Pos2.Z), col, true)

    --Conectors
    render.DrawLine(Vector(Pos1.X, Pos1.Y, Pos1.Z), Vector(Pos2.X, Pos1.Y, Pos1.Z), col, true)
    render.DrawLine(Vector(Pos1.X, Pos2.Y, Pos1.Z), Vector(Pos2.X, Pos2.Y, Pos1.Z), col, true)
    render.DrawLine(Vector(Pos1.X, Pos1.Y, Pos2.Z), Vector(Pos2.X, Pos1.Y, Pos2.Z), col, true)
    render.DrawLine(Vector(Pos1.X, Pos2.Y, Pos2.Z), Vector(Pos2.X, Pos2.Y, Pos2.Z), col, true)
end

local off1 = Vector((Min.X + Max.X)/2, (Min.Y + Max.Y)/2, (Min.Z + Max.Z)/2)
--local off2 = Vector()

local function zoom(Pos1, Pos2)
    local count = #ZoomStates

    if(!Pos1 and !Pos2) then 
        if(count != 1) then
            Min = ZoomStates[count].min
            Max = ZoomStates[count].max
            VertexStep = ZoomStates[count].step
            Ratio = ZoomStates[count].ratio
            off1 = ZoomStates[count].off

            ZoomStates[count] = nil
        else
            messege("Compleatly Zoomed Out!", MESSEGE_TYPE_NOTICE)
        end
    else
        if(Pos1.X == Pos2.X or Pos1.Y == Pos2.Y or Pos1.Z == Pos2.Z) then 
            messege("Invalid Zoom Coordinates (Division By Zero!)", MESSEGE_TYPE_ERROR)
            return
        end

        --make sure pos 1 constains smallest components (can't make an inverted graph can we?)
        if(Pos2.X < Pos1.X) then
            local x = Pos2.X
            Pos2.X = Pos1.X
            Pos1.X = x
        end
        if(Pos2.Y < Pos1.Y) then
            local y = Pos2.Y
            Pos2.Y = Pos1.Y
            Pos1.Y = y
        end
        if(Pos2.Z < Pos1.Z) then
            local z = Pos2.Z
            Pos2.Z = Pos1.Z
            Pos1.Z = z
        end

        if (Pos1 == Min and Pos2 == Max) then
            messege("Can't Zoom in on thesame coordinates.", MESSEGE_TYPE_NOTICE)
            return
        end

        ZoomStates[count + 1] = {
            min = Min,
            max = Max,
            step = VertexStep,
            ratio = Ratio,
            off = off1,
        }

        local abs = math.abs
        local V1 = Vector((Max.X),(Max.Y),(Max.Z)) - Vector((Min.X), (Min.Y), (Min.Z)) --get orig volume
        local V2 = Vector((Pos2.X),(Pos2.Y),(Pos2.Z)) - Vector((Pos1.X), (Pos1.Y), (Pos1.Z))
        V1 = Vector(abs(V1.X),abs(V1.Y),abs(V1.Z))
        V2 = Vector(abs(V2.X),abs(V2.Y),abs(V2.Z))

        Ratio = Vector(V2.X / V1.X, V2.Y / V1.Y, V2.Z / V1.Z)



        print("----------------------")
        print("Min|Max: "..tostring(Min).."|"..tostring(Max))
        print("Pos1|Pos2: "..tostring(Pos1).."|"..tostring(Pos2))
        print("Ratio: "..tostring(Ratio))
        print("Old VertexStep: "..tostring(VertexStep))
        print("Old GridStep: "..tostring(GridStep))

        
        Min = Pos1
        Max = Pos2
        off1 = Vector((Min.X + Max.X)/2, (Min.Y + Max.Y)/2, (Min.Z + Max.Z)/2)

        VertexStep = VertexStep * Ratio
        print("Offset: "..tostring(off1))
        print("New VertexStep: "..tostring(VertexStep))
        print("New GridStep: "..tostring(GridStep))
        print("----------------------")


    end
    --MeshBuildManager() --todo
end
        
local function checkFails(Range, ...)
    local verts = {...}
    local Flag = false

    for i,v in pairs(verts) do
        Flag = (v.Z < (Min.Z) or v.Z > (Max.Z)) --todo

        local dFlag
        for _,l in pairs(verts) do
            if(!dFlag) then
                dFlag = (v:Distance(l) >= (Range/1.5))
            end
        end

        if(!Flag) then Flag = dFlag end
    end
    
    return Flag
end

function buildMesh(Frames, tMin, tMax)  
    tMin = tMin or 0
    tMax = tMax or 0
    Frames = Frames or 1

    local StartTime = SysTime()
    local TRange = (math.abs(tMin) + math.abs(tMax)) or 1
    local GRange = math.abs(Min.Z - Max.Z)
    
    for i = 1, Frames do
        if(Meshes[i]) then
            Meshes[i]:Destroy()
        end
        Meshes["Compleated "..i] = false
        Meshes[i] = Mesh()
    end

    for MeshId = 1, Frames do
        local meshData = {}
        local Points = {}

        local Lowest = Max.Z
        local Highest = Min.Z
        if(AxisColoring) then
            Lowest = Min.Z
            Highest = Max.Z
        end 

        for X = Min.X, Max.X, (VertexStep.X) do
            for Y = Min.Y, Max.Y, (VertexStep.Y) do
                local Z = math.Clamp(getZ(X,Y, (MeshId/Frames)*TRange + tMin ), Min.Z - VertexStep.Z, Max.Z + VertexStep.Z) --todo

                if(!AxisColoring) then
                    Lowest = math.min(Lowest, Z)
                    Highest = math.max(Highest, Z)
                end

                Points[tostring(Vector(X,Y))] = Vector(X, Y, Z)-- + off1 - off2
            end
        end
        local CRange = math.abs(Lowest - Highest)
        local hsv = HSVToColor

        local hsv2rgb = function(h)
            return hsv((math.abs(h - Lowest)/CRange) * 180 - 45, 1, 1)

        end
    
    
        local RoutineIndex = 0

        for X = Min.X, Max.X, VertexStep.X do
            for Y = Min.Y, Max.Y, VertexStep.Y do

                local verts = {
                    Points[tostring(Vector(X, Y))],
                    Points[tostring(Vector(X, Y + VertexStep.Y))],
                    Points[tostring(Vector(X + VertexStep.X, Y + VertexStep.Y))],
                    Points[tostring(Vector(X + VertexStep.X, Y))],
                }

                if(verts[1] and verts[2] and verts[3] and verts[4]) then 
                    if(!checkFails(GRange, verts[1], verts[2], verts[3])) then
                        meshData[#meshData + 1] = {
                            pos = verts[1],
                            color = hsv2rgb(verts[1].Z),
                        }
                        meshData[#meshData + 1] = {
                            pos = verts[2],
                            color = hsv2rgb(verts[2].Z),
                        }
                        meshData[#meshData + 1] = {
                            pos = verts[3],
                            color = hsv2rgb(verts[3].Z),
                        }
                    end
                    
                    if(!checkFails(GRange, verts[3], verts[4], verts[1])) then
                        meshData[#meshData + 1] = {
                            pos = verts[3],
                            color = hsv2rgb(verts[3].Z),
                        }                       
                        meshData[#meshData + 1] = {
                            pos = verts[4],
                            color = hsv2rgb(verts[4].Z),
                        }
                        meshData[#meshData + 1] = {
                            pos = verts[1],
                            color = hsv2rgb(verts[1].Z),
                        }
                    end
                end
            end
            RoutineIndex = RoutineIndex + 1
            if(RoutineIndex % 10 == 0) then
                local Percent = (MeshId / Frames)
                coroutine.yield(Percent)
            end
        end
        Meshes[MeshId]:BuildFromTriangles(meshData)
        Meshes["Compleated "..MeshId] = true
    end
    messege("Done Generating, took: "..string.format("%.2f",(SysTime() - StartTime)).."s", MESSEGE_TYPE_SUCCESS)
end

local function getCompleatedMeshes()
    local num = 0
    for i = 1, #Meshes do
        if(Meshes["Compleated "..i]) then
            num = num + 1
        end
    end

    return num
end

local function MeshBuildManager(a,b,c)
    buildRoutine = coroutine.create(buildMesh, a,b,c)
    Building = true
    RenderMesh = false
    coroutine.resume(buildRoutine, a,b,c)
    timer.Create("Cocheck", 0.1, 0, function()
        local Status = coroutine.status(buildRoutine)
        if(Status == "dead") then
            timer.Remove("Cocheck")
            Building = false
            RenderMesh = true
            NumMeshes = getCompleatedMeshes()
        elseif(Status == "suspended") then
            Status, Percent = coroutine.resume(buildRoutine, a,b,c)
        end

        if(Kill) then
            timer.Remove("Cocheck")
            buildRoutine = nil
            Kill = false
            Building = false
            RenderMesh = true
            NumMeshes = getCompleatedMeshes()
        end

    end)
end

local Vec1 = Vector(-43,0,-4.34)
local Vec2 = Vector(-24,1,4)

local function generateGridVectors()
    local GridPoints = {
        X_Axis = {},
        Y_Axis = {},
        Z_Axis = {},
    }

    local Col = Color(255,0,0)
    local TickLineIndex = 0
    local CenterLineDrawn = false


   for X = Min.X +  GridStep.X/2 , Max.X - GridStep.X/2, GridStep.X/2  do
        if(TickLineIndex % 2 == 0) then
            Col = Color(50,50,50)
        else
            Col = Color(255,0,0)
        end

        if(X != 0) then
            GridPoints.X_Axis[TickLineIndex] = {}
            GridPoints.X_Axis[TickLineIndex].Start1 = Vector(X, Min.Y, Min.Z)
            GridPoints.X_Axis[TickLineIndex].Start2 = Vector(X, Min.Y, Min.Z)
            GridPoints.X_Axis[TickLineIndex].End1 = Vector(X,Max.Y,Min.Z)
            GridPoints.X_Axis[TickLineIndex].End2 = Vector(X,Min.Y,Max.Z)
            GridPoints.X_Axis[TickLineIndex].Color = Col
        end

        --[[Labels.X_Axis[TickLineIndex] = ""
        if(TickLineIndex % 2 != 0) then
            Labels.X_Axis[TickLineIndex] = tostring(X)
        else
            Labels.X_Axis[TickLineIndex] = ""
        end]]


        TickLineIndex = TickLineIndex + 1
    end


    TickLineIndex = 1
    for Y = (Min.Y + GridStep.Y / 2), Max.Y - GridStep.Y / 2, GridStep.Y / 2 do
        if(TickLineIndex % 2 != 0) then
            Col = Color(50,50,50)
        else
            Col = Color(0,255,0)
        end

        if(Y != 0) then
            GridPoints.Y_Axis[TickLineIndex] = {}
            GridPoints.Y_Axis[TickLineIndex].Start1 = Vector(Min.X, Y, Min.Z)
            GridPoints.Y_Axis[TickLineIndex].Start2 = Vector(Min.X, Y, Min.Z)
            GridPoints.Y_Axis[TickLineIndex].End1 = Vector(Max.X, Y, Min.Z)
            GridPoints.Y_Axis[TickLineIndex].End2 = Vector(Min.X, Y, Max.Z)
            GridPoints.Y_Axis[TickLineIndex].Color = Col

            --[[if(TickLineIndex % 2 != 0) then
                GridPoints.Y_Axis[TickLineIndex].Label = tostring(Y)
            else
                GridPoints.Y_Axis[TickLineIndex].Label = ""
            end]]
        end
        TickLineIndex = TickLineIndex + 1
    end

    TickLineIndex = 1
    for Z = (Min.Z + GridStep.Z / 2), Max.Z - GridStep.Z / 2, GridStep.Z / 2 do
        if(TickLineIndex % 2 != 0) then
            Col = Color(50,50,50)
        else
            Col = Color(0,0,255)
        end

        if(Z != 0) then
            GridPoints.Z_Axis[TickLineIndex] = {}
            GridPoints.Z_Axis[TickLineIndex].Start1 = Vector(Min.X, Min.Y, Z)
            GridPoints.Z_Axis[TickLineIndex].Start2 = Vector(Min.X, Min.Y, Z)
            GridPoints.Z_Axis[TickLineIndex].End1 = Vector(Max.X, Min.Y, Z)
            GridPoints.Z_Axis[TickLineIndex].End2 = Vector(Min.X, Max.Y, Z)
            GridPoints.Z_Axis[TickLineIndex].Color = Col

            --[[if(TickLineIndex % 2 == 0) then
                GridPoints.Z_Axis[TickLineIndex].Label = tostring(Z)
            else
                GridPoints.Z_Axis[TickLineIndex].Label = ""
            end]]
        end

        TickLineIndex = TickLineIndex + 1
    end

    
    return GridPoints, Labels
end
local labels = {}
Grid,labels = generateGridVectors()

local function drawAxis()
    local Col = Color(255,0,0)

    --X-Axis
    if (Min.X < 0 and Max.X > 0) then
        Col = Color(255,255,255)
        render.DrawLine(Vector(0,Min.Y,Min.Z), Vector(0,Max.Y,Min.Z), Col, true)
        render.DrawLine(Vector(0,Min.Y,Min.Z), Vector(0,Min.Y,Max.Z), Col, true)
    end

    Col = Color(255,0,0)
    render.DrawLine(Vector(Min.X,Min.Y,Min.Z), Vector(Max.X+(1*Ratio.X),Min.Y,Min.Z), Col, true)
    render.DrawLine(Vector(Max.X,Min.Y,Min.Z), Vector(Max.X,Max.Y,Min.Z), Col, true)
    render.DrawLine(Vector(Max.X,Min.Y,Min.Z), Vector(Max.X,Min.Y,Max.Z), Col, true)


    --Y-Axis
    if (Min.Y < 0 and Max.Y > 0) then
        Col = Color(255,255,255)
        render.DrawLine(Vector(Min.X,0,Min.Z), Vector(Max.X,0,Min.Z), Col, true)
        render.DrawLine(Vector(Min.X,0,Min.Z), Vector(Min.X,0,Max.Z), Col, true)
    end
    
    Col = Color(0,255,0)
    render.DrawLine(Vector(Min.X,Min.Y,Min.Z), Vector(Min.X,Max.Y+(1*Ratio.Y),Min.Z), Col, true)
    render.DrawLine(Vector(Min.X,Max.Y,Min.Z), Vector(Max.X,Max.Y,Min.Z), Col, true)
    render.DrawLine(Vector(Min.X,Max.Y,Min.Z), Vector(Min.X,Max.Y,Max.Z), Col, true)

    --Z-Axis
    if (Min.Z < 0 and Max.Z > 0) then
        Col = Color(255,255,255)
        render.DrawLine(Vector(Min.X,Min.Y,0), Vector(Min.X,Max.Y,0), Col, true)
        render.DrawLine(Vector(Min.X,Min.Y,0), Vector(Max.X,Min.Y,0), Col, true)
    end
    
    Col = Color(0,0,255)
    render.DrawLine(Vector(Min.X,Min.Y,Min.Z), Vector(Min.X,Min.Y,Max.Z +(1*Ratio.Z)), Col, true)
    render.DrawLine(Vector(Min.X,Min.Y,Max.Z), Vector(Min.X,Max.Y,Max.Z), Col, true)
    render.DrawLine(Vector(Min.X,Min.Y,Max.Z), Vector(Max.X,Min.Y,Max.Z), Col, true)
    
end

local function drawGrid()
    drawAxis()

    for i,Line in pairs(Grid.X_Axis) do
        render.DrawLine(Line.Start1, Line.End1, Line.Color, true)
        render.DrawLine(Line.Start2, Line.End2, Line.Color, true)
        --[[local Label = labels.X_Axis[i]
        if(Label != "") then
                local v = ent:LocalToWorld(Line.Start1)

            cam.Start3D2D(v, Angle(0,0,90), 0.1)
                surface.SetTextColor(Color(255,0,0))
                local w,h = surface.GetTextSize(Label)

                surface.SetTextPos(0,h/2)
                surface.SetFont("Test2")
                surface.DrawText(Label)
            cam.End3D2D()

        end]]
    end

    for _,Line in pairs(Grid.Y_Axis) do
        render.DrawLine(Line.Start1, Line.End1, Line.Color, true)
        render.DrawLine(Line.Start2, Line.End2, Line.Color, true)
    end

    for _,Line in pairs(Grid.Z_Axis) do
        render.DrawLine(Line.Start1, Line.End1, Line.Color, true)
        render.DrawLine(Line.Start2, Line.End2, Line.Color, true)
    end
end

hook.Add("HUDPaint", "Progress Bar", function()
    if(Building) then
        Percent = Percent or 0
        surface.SetDrawColor(Color(150,150,150, 150))
        surface.DrawRect((ScrW() / 2) - 151, 10, 301, 30)
        surface.SetDrawColor(Color(0,0,0, 150)) 
        surface.DrawOutlinedRect((ScrW() / 2) - 151, 10, 301, 30)

        surface.SetDrawColor(Color(0,255,0, 150))   
        surface.DrawRect((ScrW() / 2) - 141, 20, 281 * (Percent or 0), 10)
        surface.SetDrawColor(Color(0,0,0, 150)) 
        surface.DrawOutlinedRect((ScrW() / 2) - 141, 20, 281, 10)

        local w,h = surface.GetTextSize("Building Mesh: "..(Percent * 100).."%")
        surface.SetDrawColor(Color(150,150,150, 150))
        surface.DrawRect((ScrW() / 2) - w/2 - 10, 39, w + 20, 20)
        surface.SetDrawColor(Color(0,0,0, 150)) 
        surface.DrawOutlinedRect((ScrW() / 2) - w/2 - 10, 39, w + 20, 20)

        
        surface.SetFont("Test")
        surface.SetTextPos((ScrW() / 2) - w/2, 42, w + 20, 20)
        surface.SetTextColor(Color(255,255,255, 150))
        surface.DrawText("Building Mesh: "..(Percent * 100).."%")
    end
end)

hook.Add("PostDrawOpaqueRenderables", "MeshTest", function()
    if(IsValid(ent)) then
        DrawMatrix:SetAngles(ent:GetAngles())
        DrawMatrix:SetTranslation(ent:LocalToWorld(-(off1 * Vector(1/Ratio.X,1/Ratio.Y,1/Ratio.Z) * 4 )))--Vector(ent:GetPos().X/Ratio.X, ent:GetPos().Y/Ratio.Y, ent:GetPos().Z/Ratio.Z))
        DrawMatrix:Scale(Vector(1/Ratio.X,1/Ratio.Y,1/Ratio.Z) * 4)
        --DrawMatrix:SetTranslation(ent:GetPos())
        --DrawMatrix:Scale(Vector(1,1,1) * 4)
         
        cam.PushModelMatrix(DrawMatrix)
            
            if(RenderMesh) then
                render.SetMaterial(WireMat)

                if(RenderMode == "solid") then
                    render.SetMaterial(SolidMat)
                elseif(RenderMode == "solid+wire") then
                    render.SetMaterial(WireHighlight)
                    Meshes[MeshIndex]:Draw()
                    render.SetMaterial(SolidMat)
                end

                Meshes[MeshIndex]:Draw()
            end

            drawGrid()
            DrawZoomPoints()
        cam.PopModelMatrix()
    end
end)
---------------------------------------------------------------------------

hook.Add("Think", "test", function()
    if (!IsValid(ent) and IsValid(LocalPlayer():GetEyeTrace().Entity)) then
        ent = LocalPlayer():GetEyeTrace().Entity
        messege("Target Entity Selected.",MESSEGE_TYPE_NOTICE)
    end
end)
concommand.Add("zoomout", function(ply, name, args)
    zoom()
    Grid = generateGridVectors()
    MeshBuildManager()
end)

concommand.Add("zoomin", function(ply, name, args)
    zoom(Vec1, Vec2)
    Grid =  generateGridVectors()
    MeshBuildManager()  
end)

concommand.Add("stopgen", function()
    if(Building) then
        Kill = true
        messege("Mesh generation aborted! What was made up to now will draw.",  MESSEGE_TYPE_FAIL)
    end
end)

concommand.Add("graph", function(ply, name, args)

    if(args[1] and args[1] != "") then
        func = table.concat(args)
    end

    messege("Computing points and building mesh, possible small freeze.", MESSEGE_TYPE_WARNING)
    timer.Remove("MeshAnim")

    if(!generateFunctionFromText(func)) then 
        messege("Something is wrong with your funciton! Make sure you have the correct syntax.", MESSEGE_TYPE_ERROR)
        return false
    end

    MeshBuildManager()--100, 0, 3.14159*2)

    timer.Create("MeshAnim", TimeStep, 0, function()
        if(dir ) then
            if(MeshIndex < NumMeshes) then
                MeshIndex = MeshIndex + 1
            else
                dir = false
            end
        else
            if(MeshIndex > 1) then
                MeshIndex = MeshIndex - 1
            else
                dir = true
            end
        end
            
    end)
end)

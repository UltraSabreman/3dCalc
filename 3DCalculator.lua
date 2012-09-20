local func = "cos(abs(x)+abs(y))*(abs(x)+abs(y))"
local VertexStep = Vector(0.3,0.3,0.3)
local Min = -Vector(3,3,3)
local Max = Vector(3,3,3)

local GridStep = Vector(1,1,1)
local GridMin = Min
local GridMax = Max
local Ratio = Vector(1,1,1) --todo
local TimeStep = 0.05
local AxisColoring = false 
local RenderMode = "solid+wire" --"wire","solid","solid+wire",
local dir = true

--[[ WHAT TO-DO:
[\] 1) Fix Zooming : Fix axis scaling when zooming (prob re-write code to start at 0,0 and draw out)
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
surface.CreateFont("Test", SmallHudFont)
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

local SolidMat = CreateMaterial("SolidFill4", "UnlitGeneric", { --VertexLitGeneric
	["$basetexture"]		= "models/debug/debugwhite",
	["$reflectivity"] 		= "[0 0 0]",
	["$vertexcolor"] 		= 1,
	["$color"]				= "[0.5 0.5 0.5]",
	["$nocull"]				= 1,
})

local WireHighlight = CreateMaterial("WireHighLight2", "Wireframe", {
	["$basetexture"]		= "editor/wireframe",
	["$vertexcolor"] 		= 0,
	["$color"]				= "[ 0 0 0 ]",
	--["$ignorez"]			= 1,
	["$nocull"]				= 1,
})

local WireMat = CreateMaterial("WireFill", "Wireframe", {
	["$basetexture"]		= "editor/wireframe",
	["$vertexcolor"] 		= 1,
	["$nocull"]				= 1,
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
	local Pos1 = Pos1 or GridMin
	local Pos2 = Pos2 or GridMin

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

local function zoom(Pos1, Pos2)
	local count = #ZoomStates
	if(!Pos1 and !Pos2) then 
		if(count != 1) then
			Min = ZoomStates[count].min
			Max = ZoomStates[count].max
			VertexStep = ZoomStates[count].step
			GridStep = ZoomStates[count].gridstep
			Ratio = ZoomStates[count].ratio

			ZoomStates[count] = nil
		else
			messege("Compleatly Zoomed Out!", MESSEGE_TYPE_NOTICE)
		end
	else
		Pos1 = Pos1 or Min
		Pos2 = Pos2 or Min
		ZoomStates[count + 1] = {
			min = Min,
			max = Max,
			step = VertexStep,
			gridstep = GridStep,
			ratio = Ratio
		}

		local V1 = Vector(math.abs(Max.X), math.abs(Max.Y), math.abs(Max.Z)) + Vector(math.abs(Min.X), math.abs(Min.Y), math.abs(Min.Z)) 
		local V2 = Vector(math.abs(Pos1.X), math.abs(Pos1.Y), math.abs(Pos1.Z)) + Vector(math.abs(Pos2.X), math.abs(Pos2.Y), math.abs(Pos2.Z))
		Ratio = Vector(V2.X / V1.X, V2.Y / V1.Y, V2.Z / V1.Z)

		Min = Pos1
		Max = Pos2

		VertexStep = VertexStep * Ratio
		GridStep = Vector(GridStep.X / Ratio.X, GridStep.Y / Ratio.Y, GridStep.Z / Ratio.Z)
	end
	--MeshBuildManager() --todo
end
		
local function checkFails(Range, ...)
	local verts = {...}
	local Flag = false

	for i,v in pairs(verts) do
		Flag = (v.Z < (Min.Z - VertexStep.Z) or v.Z > (Max.Z + VertexStep.Z))

		local dFlag
		for _,l in pairs(verts) do
			if(!dFlag) then
				dFlag = (v:Distance(l) >= (Range/2))
			end
		end

		if(!Flag) then Flag = dFlag end
	end
	
	return Flag
end

function buildMesh(Frames, tMin, tMax)	
	local GridMin = Min
	local GridMax = Max
	tMin = tMin or 0
	tMax = tMax or 0
	Frames = Frames or 1

	local StartTime = SysTime()
	local TRange = (math.abs(tMin) + math.abs(tMax)) or 1
	local GRange = math.abs(GridMin.Z - GridMax.Z)
	
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

		local Lowest = GridMax.Z
		local Highest = GridMin.Z
		if(AxisColoring) then
			Lowest = GridMin.Z
			Highest = GridMax.Z
		end	

		for X = Min.X, Max.X, (VertexStep.X) do
			for Y = Min.Y, Max.Y, (VertexStep.Y) do
				local Z = math.Clamp(getZ(X,Y, (MeshId/Frames)*TRange + tMin ), GridMin.Z - VertexStep.Z, GridMax.Z + VertexStep.Z) --todo

				if(!AxisColoring) then
					Lowest = math.min(Lowest, Z)
					Highest = math.max(Highest, Z)
				end

				Points[tostring(Vector(X,Y))] = Vector(X/Ratio.X,Y/Ratio.Y,Z/Ratio.Z) 
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

local function generateGridVectors()
	local Min = GridMin
	local Max = GridMax
	local GridPoints = {
		X_Axis = {},
		Y_Axis = {},
		Z_Axis = {},
	}

	local Col = Color(255,0,0)
	local TickLineIndex = 1
	local CenterLineDrawn = false

	for X = (Min.X + GridStep.X / 2), Max.X, GridStep.X / 2 do
		if(!CenterLineDrawn and X >= 0) then
			Col = Color(255,255,255)
			CenterLineDrawn = true
		elseif(TickLineIndex % 2 != 0) then
			Col = Color(50,50,50)
		else
			Col = Color(255,0,0)
		end

		GridPoints.X_Axis[TickLineIndex] = {}
		GridPoints.X_Axis[TickLineIndex].Start1 = Vector(X, Min.Y, Min.Z)
		GridPoints.X_Axis[TickLineIndex].Start2 = Vector(X, Min.Y, Min.Z)
		GridPoints.X_Axis[TickLineIndex].End1 = Vector(X,Max.Y,Min.Z)
		GridPoints.X_Axis[TickLineIndex].End2 = Vector(X,Min.Y,Max.Z)
		GridPoints.X_Axis[TickLineIndex].Color = Col
		TickLineIndex = TickLineIndex + 1
	end

	TickLineIndex = 1
	CenterLineDrawn = false
	for Y = (Min.Y + GridStep.Y / 2), Max.Y, GridStep.Y / 2 do
		if(!CenterLineDrawn and Y >= 0) then
			Col = Color(255,255,255)
			CenterLineDrawn = true
		elseif(TickLineIndex % 2 != 0) then
			Col = Color(50,50,50)
		else
			Col = Color(0,255,0)
		end

		
		GridPoints.Y_Axis[TickLineIndex] = {}
		GridPoints.Y_Axis[TickLineIndex].Start1 = Vector(Min.Y, Y, Min.Z)
		GridPoints.Y_Axis[TickLineIndex].Start2 = Vector(Min.Y, Y, Min.Z)
		GridPoints.Y_Axis[TickLineIndex].End1 = Vector(Max.Y, Y, Min.Z)
		GridPoints.Y_Axis[TickLineIndex].End2 = Vector(Min.Y, Y, Max.Z)
		GridPoints.Y_Axis[TickLineIndex].Color = Col
		TickLineIndex = TickLineIndex + 1
	end

	TickLineIndex = 1
	CenterLineDrawn = false
	for Z = (Min.Z + GridStep.Z / 2), Max.Z, GridStep.Z / 2 do
		if(!CenterLineDrawn and Z >= 0) then
			Col = Color(255,255,255)
			CenterLineDrawn = true
		elseif(TickLineIndex % 2 != 0) then
			Col = Color(50,50,50)
		else
			Col = Color(0,0,255)
		end

		GridPoints.Z_Axis[TickLineIndex] = {}
		GridPoints.Z_Axis[TickLineIndex].Start1 = Vector(Min.X, Min.Y, Z)
		GridPoints.Z_Axis[TickLineIndex].Start2 = Vector(Min.X, Min.Y, Z)
		GridPoints.Z_Axis[TickLineIndex].End1 = Vector(Max.X, Min.Y, Z)
		GridPoints.Z_Axis[TickLineIndex].End2 = Vector(Min.X, Max.Y, Z)
		GridPoints.Z_Axis[TickLineIndex].Color = Col
		TickLineIndex = TickLineIndex + 1
	end

	
	return GridPoints
end

Grid = generateGridVectors()

local function drawGrid()
	local Min = GridMin
	local Max = GridMax
	render.DrawLine(Min, Vector(Max.X + GridStep.X,Min.Y,Min.Z), Color(255,0,0), true)
	render.DrawLine(Min, Vector(Min.X,Max.Y + GridStep.Y,Min.Z), Color(0,255,0), true)
	render.DrawLine(Min, Vector(Min.X,Min.Y,Max.Z + GridStep.Z), Color(0,0,255), true)

	for _,Line in pairs(Grid.X_Axis) do
		render.DrawLine(Line.Start1, Line.End1, Line.Color, true)
		render.DrawLine(Line.Start2, Line.End2, Line.Color, true)
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
	if(ValidEntity(ent)) then
		DrawMatrix:SetAngles(ent:GetAngles())
		DrawMatrix:SetTranslation(ent:GetPos())
		DrawMatrix:Scale(Vector(1,1,1) * 3)
		 
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
	if (!ValidEntity(ent) and ValidEntity(LocalPlayer():GetEyeTrace().Entity)) then
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
	zoom(Vector(1,1,1),-Vector(1,1,1))
	Grid = 	generateGridVectors()
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
	
	Print = false		

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

-- Castlevania SotN Live Map Screen
-- Written By MottZilla
-- December 5th 2023

EndScript = false

function CloseWindow()
	forms.destroy(formLiveMap)
	console.log("Window Closed!")
	EndScript = true
end

-- Create Window
formLiveMap = forms.newform(660,620,"SotN Live Map",CloseWindow)
pbLiveMap = forms.pictureBox(formLiveMap,0,0,680,620)
forms.drawBox(pbLiveMap,0,0,680,620, 0xFF000000, 0xFF000000)

-- Globals
UpdateFrameCount = 0
UpdateMap = 0
curHour = 0
curMin = 0
curSecs = 0
curFrames = 0
TimeStr = ""
RunStartFrame = 0
RunEndFrame = 0
MapSize = 2
curCastle = 0
lastCastleRedraw = 0
Zone = 0
CheckSet = 2

PreviousX = -10	-- For Live Position trail
PreviousY = -10
PreviousCastleX = -1
PreviousCastleY = -1

-- Create Map Arrays
rec_map1 = {}
rec_map2 = {}
for i=0, 4096 do
	rec_map1[i] = 0
	rec_map2[i] = 0
end


function AutoTimer()
	local Zone = memory.read_u8(0x974A0,MainRAM)

		-- Read in game time.
		curHour = memory.read_u8(0x97C30,MainRAM)
		curMin = memory.read_u8(0x97C34,MainRAM)
		curSecs = memory.read_u8(0x97C38,MainRAM)

	-- Start for Alucard
	if(Zone == 0x1F and curHour == 0 and curMin == 0 and curSecs == 2 and RunStartFrame == 0) then
		console.log("Run Started!")
		RunStartFrame = emu.framecount()
		console.log("Frame:" .. RunStartFrame)
	end
	-- Start for Richter
	if(Zone == 0x41 and curHour == 0 and curMin == 0 and curSecs == 0 and RunStartFrame == 0) then
		console.log("Run Started! " .. "Frame:" .. emu.framecount())
		RunStartFrame = emu.framecount()
		console.log("Frame:" .. RunStartFrame)
	end
	-- Detect Dracula Defeated
	if(Zone == 0x38 and RunEndFrame == 0) then
		if(memory.read_u8(0x76ED7) > 0x7F) then
			console.log("Run Ended! " .. "Frame:" .. emu.framecount())
			RunEndFrame = emu.framecount()
		end
	end
end

-- For Emu Frame Count Timer from Run Start
function BuildAutoTimerStr()
	-- Timer not started
	if(RunStartFrame == 0) then
		--TimeStr = "Run Timer - ??:??:??"
		TimeStr = "00:00:00"
		return
	end
	-- Timer running
	if(RunEndFrame > 0) then
		curHour = (RunEndFrame - RunStartFrame) / 216000 % 99
		curMin = ((RunEndFrame - RunStartFrame) / 3600) % 60
		curSecs = ((RunEndFrame - RunStartFrame) / 60) % 60
	end
	-- Timer ended
	if(RunEndFrame == 0) then
		curHour = (emu.framecount() - RunStartFrame) / 216000 % 99
		curMin = ((emu.framecount() - RunStartFrame) / 3600) % 60
		curSecs = ((emu.framecount() - RunStartFrame) / 60) % 60
	end

	-- Floor to remove decimals
	curHour = math.floor(curHour)
	curMin = math.floor(curMin)
	curSecs = math.floor(curSecs)
	
	-- Construct Time String
	--TimeStr = "Run Timer - "
	TimeStr = ""
	if curHour < 10 then
		TimeStr = TimeStr .. "0"
	end
	TimeStr = TimeStr .. curHour .. ":"
	if curMin < 10 then
		TimeStr = TimeStr .. "0"
	end
	TimeStr = TimeStr .. curMin .. ":"
	if curSecs < 10 then
		TimeStr = TimeStr .. "0"
	end
	TimeStr = TimeStr .. curSecs
end

function UpdateTimerAndText()
	local txcolor = 0xFFFFFFFF

	if(RunEndFrame > 0) then txcolor = 0xFFFFD700 end
	if(RunStartFrame == 0) then txcolor = 0xFF808080 end

	BuildAutoTimerStr()
	forms.drawText(pbLiveMap,8,530,TimeStr,txcolor,0xFF000000, 32)

	forms.drawText(pbLiveMap,4,500,"RESET!",0xFFFF0000,16)
	forms.drawText(pbLiveMap,104,500,"Change Map Size",0xFFFFFFFF,16)

	forms.drawBox(pbLiveMap,230,500,400,520,0xFF000000, 0xFF000000)
	if(CheckSet == 0) then forms.drawText(pbLiveMap,230,500,"??? Checks",0xFF00FF00,16) end
	if(CheckSet == 1) then forms.drawText(pbLiveMap,230,500,"Classic Checks",0xFF00FF00,16) end
	if(CheckSet == 2) then forms.drawText(pbLiveMap,230,500,"Guarded Checks",0xFF00FF00,16) end
	if(CheckSet == 3) then forms.drawText(pbLiveMap,230,500,"??? Checks",0xFF00FF00,16) end
	if(CheckSet == 4) then forms.drawText(pbLiveMap,230,500,"??? Checks",0xFF00FF00,16) end

	forms.refresh(pbLiveMap)
end

function DoCastleMap()

local stringbufA
local stringbufB
local drawX
local drawY
local NewCastle

-- Read variables
Zone = memory.read_u8(0x974A0)
castleX = memory.read_u8(0x730B0)
castleY = memory.read_u8(0x730B4)
roomX = memory.read_u16_le(0x973F0)
roomY = memory.read_u16_le(0x973F4)

-- Calculate position
roomX = math.floor(roomX/256)
roomY = math.floor(roomY/256)

castleX = castleX+roomX
castleY = castleY+roomY

--[[
-- Debug Output
stringbufA = bizstring.hex(castleX)
stringbufB = bizstring.hex(castleY)
print(stringbufA .. "," .. stringbufB)
]]--

	-- Find which castle we are currently in.
	NewCastle = bit.band(memory.read_u8(0x974A0),0x20)
	if(NewCastle == 0x20) then
		NewCastle = 2
	end
	if(NewCastle == 0x00) then
		NewCastle = 1
	end

	-- Update which Castle we are in if we changed.
	if(NewCastle ~= lastCastleRedraw) then
		curCastle = NewCastle
		ChangeCastle()
		lastCastleRedraw = NewCastle
	end

	-- Castle Entrance, Don't log before entering the Gate.
	if(Zone == 0x41 and (castleY >41 or castleX<2) ) then return end
	-- Don't log during Prologue or Final Dracula
	if(Zone == 0x1F or Zone == 0x38) then return end

	-- If Teleporting abort
	if(memory.read_u8(0x73404) == 0x12) then
		PreviousX = -10
		PreviousY = -10
		PreviousCastleX = -1
		PreviousCastleY = -1	
		return
	end

	-- Adjust Y Position for Castle 2
	if(curCastle == 2) then castleY = castleY - 7 end

	-- Calculate Drawing Position
	drawX = (castleX * (5*MapSize) )
	drawY = (castleY * (5*MapSize)) - (15 * MapSize)

	-- Update Previous Square. This will be blue.
	if(MapSize == 1) then
		forms.drawBox(pbLiveMap,PreviousX,PreviousY,PreviousX+4,PreviousY+4,0xFF0000E0, 0xFF00000E0)
		if(curCastle == 1) then	forms.drawImageRegion(pbLiveMap,"Images/Castle1_Empty_TP.png",PreviousCastleX * 5,(PreviousCastleY*5) - 15,5,5,PreviousX,PreviousY,5,5) end
		if(curCastle == 2) then	forms.drawImageRegion(pbLiveMap,"Images/Castle2_Empty_TP.png",PreviousCastleX * 5,(PreviousCastleY*5) - 15,5,5,PreviousX,PreviousY,5,5) end
	end
	if(MapSize == 2) then 
		forms.drawBox(pbLiveMap,PreviousX,PreviousY,PreviousX+9,PreviousY+9,0xFF0000E0, 0xFF00000E0)
		if(curCastle == 1) then forms.drawImageRegion(pbLiveMap,"Images/Castle1_Empty_TP.png",PreviousCastleX * 5,(PreviousCastleY*5) - 15,5,5,PreviousX,PreviousY,10,10) end
		if(curCastle == 2) then forms.drawImageRegion(pbLiveMap,"Images/Castle2_Empty_TP.png",PreviousCastleX * 5,(PreviousCastleY*5) - 15,5,5,PreviousX,PreviousY,10,10) end
	end

	-- Abort Here so Pink Cursor is erased and not left on map.
	-- If we aren't in Gameplay, don't Update Map Progress
	if(memory.read_u8(0x73060) ~= 3) then

		-- Move last Square to nowhere
		PreviousX = -10
		PreviousY = -10
		PreviousCastleX = -1
		PreviousCastleY = -1
		return
	end

	-- If we aren't in Gameplay, don't Update Map Progress
	if(memory.read_u8(0x3C9A4) ~= 1) then return end

	-- Abort during teleport
	if(memory.read_u8(0x97C98) ~= 0) then return end

	PreviousX = drawX
	PreviousY = drawY
	PreviousCastleX = castleX
	PreviousCastleY = castleY
	
	-- End of Previous Square Update

	-- Update Current Square. This will be Pink.
	if(MapSize == 1) then
		forms.drawBox(pbLiveMap,drawX,drawY,drawX+4,drawY+4,0xFFE000E0, 0xFFE000E0)
		if(curCastle == 1) then	forms.drawImageRegion(pbLiveMap,"Images/Castle1_Empty_TP.png",castleX * 5,(castleY*5) - 15,5,5,drawX,drawY,5,5) end
		if(curCastle == 2) then	forms.drawImageRegion(pbLiveMap,"Images/Castle2_Empty_TP.png",castleX * 5,(castleY*5) - 15,5,5,drawX,drawY,5,5) end
	end
	if(MapSize == 2) then 
		forms.drawBox(pbLiveMap,drawX,drawY,drawX+9,drawY+9,0xFFE000E0, 0xFFE000E0)
		if(curCastle == 1) then forms.drawImageRegion(pbLiveMap,"Images/Castle1_Empty_TP.png",castleX * 5,(castleY*5) - 15,5,5,drawX,drawY,10,10) end
		if(curCastle == 2) then forms.drawImageRegion(pbLiveMap,"Images/Castle2_Empty_TP.png",castleX * 5,(castleY*5) - 15,5,5,drawX,drawY,10,10) end
	end

	-- Mark Map Location
	if(curCastle == 1) then
		rec_map1[castleX + (castleY*64)] = 1
	end
	if(curCastle == 2) then
		rec_map2[castleX + (castleY*64)] = 1
	end

end

function ChangeCastle()

	-- Clear Canvas
	forms.drawBox(pbLiveMap,0,0,640,500, 0xFF000000, 0xFF000000)

	-- Draw Castle Progress
	if(curCastle == 1) then
		for x=0, 63 do
			for y=0, 63 do
				if(MapSize == 2) then
					if(rec_map1[x + (y*64)] == 1) then
						forms.drawBox(pbLiveMap,(x*10),(y*10) - 30,9 + (x*10),(y*10) - 21,0xFF0000E0, 0xFF0000E0)
					end
				end
				if(MapSize == 1) then
					if(rec_map1[x + (y*64)] == 1) then
						forms.drawBox(pbLiveMap,(x*5),(y*5) - 15,4 + (x*5),(y*5) - 11,0xFF0000E0, 0xFF0000E0)
					end
				end
				-- Draw Checks
				if(MapSize == 2) then
					if(rec_map1[x + (y*64)] == 2) then
						forms.drawBox(pbLiveMap,(x*10),(y*10) - 30,8 + (x*10),(y*10) - 22,0xFF00FF00, 0xFF00FF00)
					end
				end
				if(MapSize == 1) then
					if(rec_map1[x + (y*64)] == 2) then
						forms.drawBox(pbLiveMap,(x*5),(y*5) - 15,4 + (x*5),(y*5) - 11,0xFF00FF00, 0xFF00FF00)
					end
				end
			end
		end
	end
	if(curCastle == 2) then
		for x=0, 63 do
			for y=0, 63 do
				if(MapSize == 2) then
					if(rec_map2[x + (y*64)] == 1) then
						forms.drawBox(pbLiveMap,(x*10),(y*10) - 30,9 + (x*10),(y*10) - 21,0xFF0000E0, 0xFF0000E0)
					end
				end
				if(MapSize == 1) then
					if(rec_map2[x + (y*64)] == 1) then
						forms.drawBox(pbLiveMap,(x*5),(y*5) - 15,4 + (x*5),(y*5) - 11,0xFF0000E0, 0xFF0000E0)
					end
				end
				-- Draw Checks
				if(MapSize == 2) then
					if(rec_map2[x + (y*64)] == 2) then
						forms.drawBox(pbLiveMap,(x*10),(y*10) - 30,8 + (x*10),(y*10) - 22,0xFF00FF00, 0xFF00FF00)
					end
				end
				if(MapSize == 1) then
					if(rec_map2[x + (y*64)] == 2) then
						forms.drawBox(pbLiveMap,(x*5),(y*5) - 15,4 + (x*5),(y*5) - 11,0xFF00FF00, 0xFF00FF00)
					end
				end
			end
		end
	end

	-- Draw Castle Outline
	if(curCastle == 1) then
		if(MapSize == 1) then
			forms.drawImage(pbLiveMap,"Images/Castle1_Empty_TP.png",0,0,320*MapSize,255*MapSize,true)
		end
		if(MapSize == 2) then
			forms.drawImage(pbLiveMap,"Images/Castle1_Empty_TP.png",0,0,320*MapSize,255*MapSize,true)
		end
	end
	if(curCastle == 2) then
		if(MapSize == 1) then
			forms.drawImage(pbLiveMap,"Images/Castle2_Empty_TP.png",0,0,320*MapSize,255*MapSize,true)
		end
		if(MapSize == 2) then
			forms.drawImage(pbLiveMap,"Images/Castle2_Empty_TP.png",0,0,320*MapSize,255*MapSize,true)
		end
	end

	forms.refresh(pbLiveMap)
end


function PictureBoxClick()
	WX = forms.getMouseX(pbLiveMap)
	WY = forms.getMouseY(pbLiveMap)

	-- Clicked Map Size
	if(WX>104 and WX<220 and WY>500 and WY<520) then
		MapSize = MapSize + 1
		if(MapSize>=3) then MapSize = 1 end
		forms.drawBox(pbLiveMap,0,0,660,520, 0xFF000000, 0xFF000000)
		ChangeCastle()
	end

	-- Clicked Reset
	if(WX<44 and WY>500 and WY<520) then
		RunStartFrame = 0

		for i=0, 4096 do
			rec_map1[i] = 0
			rec_map2[i] = 0
		end
		RelicChecks()
		if(CheckSet>=1) then KeyItemChecks() end
		if(CheckSet>=2) then GuardedChecks() end
		ChangeCastle()
	end

	-- Clicked CheckSet Change
	if(WX>230 and WX<300 and WY>500 and WY<520) then
		for i=0, 4096 do
			if(rec_map1[i] == 2) then rec_map1[i] = 0 end
			if(rec_map2[i] == 2) then rec_map2[i] = 0 end
		end
		CheckSet = CheckSet + 1
		if(CheckSet>2) then CheckSet = 1 end
		RelicChecks()
		if(CheckSet>=1) then KeyItemChecks() end
		if(CheckSet>=2) then GuardedChecks() end
		ChangeCastle()
	end

	-- Clicked Timer
	if(WX<176 and WY>530 and WY<562) then
		if(Zone == 0x45) then RunStartFrame = 0 end
	end
end

-- Add check location using pixel position.
function AddCheckpx(posX,posY,castlenum)
	posX = math.floor(posX / 5)
	posY = posY + 15
	posY = math.floor(posY / 5)

	if(castlenum == 1) then rec_map1[ posX + (posY * 64) ] = 2 end
	if(castlenum == 2) then rec_map2[ posX + (posY * 64) ] = 2 end
end

function RelicChecks()
AddCheckpx(240,90,1)	-- Soul of Bat
AddCheckpx(295,40,1)	-- Fire of Bat
AddCheckpx(80,65,1)	-- Echo of Bat
AddCheckpx(40,60,2)	-- Force of Echo
AddCheckpx(305,75,1)	-- Soul of Wolf
AddCheckpx(10,175,1)	-- Power of Wolf
AddCheckpx(75,150,1)	-- Skill of Wolf
AddCheckpx(105,95,1)	-- Form of Mist
AddCheckpx(155,30,1)	-- Power of Mist
AddCheckpx(230,15,2)	-- Gas Cloud
AddCheckpx(95,165,1)	-- Cube of Zoe
AddCheckpx(125,145,1)	-- Spirit Orb
AddCheckpx(170,100,1)	-- Gravity Boots
AddCheckpx(155,40,1)	-- Leap Stone
AddCheckpx(275,190,1)	-- Holy Symbol
AddCheckpx(295,75,1)	-- Faerie Scroll
AddCheckpx(245,85,1)	-- Jewel of Open
AddCheckpx(40,195,1)	-- Merman Statue
AddCheckpx(65,120,1)	-- Bat Card
AddCheckpx(195,20,1)	-- Ghost Card
AddCheckpx(260,75,1)	-- Faerie Card
AddCheckpx(145,205,1)	-- Demon Card
--AddCheckpx(165,75,1)	-- Sword Card (JP)
AddCheckpx(100,75,1)	-- Sprite Card (Sword Card US)
--AddCheckpx(95,85,1)	-- Nosedevil Card
AddCheckpx(195,200,2)	-- Heart of Vlad
AddCheckpx(25,150,2)	-- Tooth of Vlad
AddCheckpx(220,185,2)	-- Rib of Vlad
AddCheckpx(115,215,2)	-- Ring of Vlad
AddCheckpx(160,65,2)	-- Eye of Vlad
end

function KeyItemChecks()
AddCheckpx(225,150,1)	-- Gold Ring
AddCheckpx(40,60,1)	-- Silver Ring
AddCheckpx(160,140,1)	-- Holy Glasses
AddCheckpx(205,240,1)	-- Spikebreaker
end

function GuardedChecks()
AddCheckpx(85,235,1)	-- Mormegil
AddCheckpx(200,175,1)	-- Crystal Cloak
AddCheckpx(115,75,2)	-- Dark Blade
AddCheckpx(215,155,2)	-- Trio
AddCheckpx(250,130,2)	-- Ring of Arcana
end


-- Add Event
forms.addclick(pbLiveMap,PictureBoxClick)

-- Add Checks
RelicChecks()
if(CheckSet>=1) then KeyItemChecks() end
if(CheckSet>=2) then GuardedChecks() end

-- Fix Annoying Warning Messages on Bizhawk 2.9 and above.
BizVersion = client.getversion()
if(bizstring.contains(BizVersion,"2.9")) then
	bit = (require "migration_helpers").EmuHawk_pre_2_9_bit();
end

-- Main Loop
while EndScript == false do
	UpdateFrameCount = UpdateFrameCount + 1
	if (UpdateFrameCount >= 60) then
		UpdateTimerAndText()
		UpdateFrameCount = 0
	end

	UpdateMap = UpdateMap + 1
	if(UpdateMap >= 15) then	-- How often do we update the map. 
		DoCastleMap()
		UpdateMap = 0
	end

	AutoTimer()
	emu.frameadvance()
	
end


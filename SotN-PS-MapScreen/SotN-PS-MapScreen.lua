-- Castlevania SotN Live Map Screen
-- Written By MottZilla
-- Special Thanks to Project_OMEG4 for adding Equipment & Tourist Check Location Data
-- July 9th 2024 Rev A

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
	if(CheckSet == 3) then forms.drawText(pbLiveMap,230,500,"Spread Checks",0xFF00FF00,16) end
	if(CheckSet == 4) then forms.drawText(pbLiveMap,230,500,"Equipment Checks",0xFF00FF00,16) end
	if(CheckSet == 5) then forms.drawText(pbLiveMap,230,500,"Tourist Checks",0xFF00FF00,16) end
	if(CheckSet == 6) then forms.drawText(pbLiveMap,230,500,"Wanderer Checks",0xFF00FF00,16) end

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
		if(CheckSet>=1) then KeyItemChecks()   end
		if(CheckSet>=2) then GuardedChecks()   end
		if(CheckSet>=3) then SpreadChecks()   end
		if(CheckSet>=4 and CheckSet~=6) then EquipmentChecks() end	-- Don't add Equipment to Wanderer
		if(CheckSet>=5) then TouristChecks()   end
		if(CheckSet>=6) then WandererChecks()   end
		ChangeCastle()
	end

	-- Clicked CheckSet Change
	if(WX>230 and WX<300 and WY>500 and WY<520) then
		for i=0, 4096 do
			if(rec_map1[i] == 2) then rec_map1[i] = 0 end
			if(rec_map2[i] == 2) then rec_map2[i] = 0 end
		end
		CheckSet = CheckSet + 1
		if(CheckSet>6) then CheckSet = 1 end
		RelicChecks()
		if(CheckSet>=1) then KeyItemChecks()   end
		if(CheckSet>=2) then GuardedChecks()   end
		if(CheckSet>=3) then SpreadChecks()   end
		if(CheckSet>=4 and CheckSet~=6) then EquipmentChecks() end	-- Don't add Equipment to Wanderer
		if(CheckSet>=5) then TouristChecks()   end
		if(CheckSet>=6) then WandererChecks()   end
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
AddCheckpx(100,75,1)	-- Sprite Card (Sword Card US)
AddCheckpx(195,200,2)	-- Heart of Vlad
AddCheckpx(25,150,2)	-- Tooth of Vlad
AddCheckpx(220,185,2)	-- Rib of Vlad
AddCheckpx(115,215,2)	-- Ring of Vlad
AddCheckpx(160,65,2)	-- Eye of Vlad
--AddCheckpx(165,75,1)	-- Sword Card (JP)
--AddCheckpx(95,85,1)	-- Nosedevil Card
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

function SpreadChecks()
AddCheckpx(65,175,2)	-- Bookcase
AddCheckpx(70,165,2)	-- Reverse Shop
end

-- Adding Equipment, Wanderer, Tourist Checks
function EquipmentChecks()
-- First Castle Checks
AddCheckpx(25, 175, 1)	-- Holy Mail			(Equipment)
AddCheckpx(50, 190, 1)	-- Jewel Sword			(Equipment)
AddCheckpx(50, 130, 1)	-- Cloth Cape			(Equipment)
AddCheckpx(80, 140, 1)	-- Sunglasses			(Equipment)
AddCheckpx(295, 100, 1)	-- Gladius 			(Equipment)
AddCheckpx(245, 90, 1)	-- Bronze Cuirass		(Equipment)
AddCheckpx(250, 75, 1)	-- Holy Rod 			(Equipment)
AddCheckpx(230, 90, 1)	-- Library Onyx 		(Equipment)
AddCheckpx(195, 25, 1)	-- Falchion 			(Equipment)
AddCheckpx(20, 110, 1)	-- Ankh of Life 		(Equipment)
AddCheckpx(40, 90, 1)	-- Morningstar 			(Equipment)
AddCheckpx(135, 35, 1)	-- Cutlass 			(Equipment)
AddCheckpx(160, 95, 1)	-- Olrox Onyx 			(Equipment)
AddCheckpx(150, 60, 1)	-- Estoc 			(Equipment)
AddCheckpx(165, 75, 1)	-- Olrox Garnet 		(Equipment)
AddCheckpx(65, 105, 1)	-- Sheild Rod 			(Equipment)
AddCheckpx(100, 105, 1)	-- Blood Cloak 			(Equipment)
AddCheckpx(95, 85, 1)	-- Holy Sword 			(Equipment)
AddCheckpx(70, 95, 1)	-- Knight Sheild 		(Equipment)
AddCheckpx(175, 120, 1)	-- Bandanna 			(Equipment)
AddCheckpx(120, 180, 1)	-- Secret Boots 		(Equipment)
AddCheckpx(200, 195, 1)	-- Knuckle Duster 		(Equipment)
AddCheckpx(230, 190, 1)	-- Caverns Onyx 		(Equipment)
AddCheckpx(155, 225, 1)	-- Combat Knife 		(Equipment)
AddCheckpx(140, 235, 1)	-- Bloodstone 			(Equipment)
AddCheckpx(120, 235, 1)	-- Icebrand 			(Equipment)
AddCheckpx(115, 235, 1)	-- Walk Armor 			(Equipment)
AddCheckpx(80, 155, 1)	-- Basilard			(Equipment/Wanderer)
AddCheckpx(170, 110, 1)	-- Alucart Sword		(Equipment/Wanderer)
AddCheckpx(295, 120, 1)	-- Jewel Knuckles		(Equipment/Wanderer)
AddCheckpx(275, 50, 1)	-- Bekatowa			(Equipment/Wanderer)
AddCheckpx(245, 55, 1)	-- Gold Plate			(Equipment/Wanderer)
AddCheckpx(175, 15, 1)	-- Platinum Mail		(Equipment/Wanderer)
AddCheckpx(10, 120, 1)	-- Mystic Pendant		(Equipment/Wanderer)
AddCheckpx(50, 85, 1)	-- Goggles			(Equipment/Wanderer)
AddCheckpx(70, 45, 1)	-- Silver Plate			(Equipment/Wanderer)
AddCheckpx(180, 175, 1)	-- Nunchaku 			(Equipment/Wanderer)
AddCheckpx(185, 190, 1)	-- Ring of Ares 		(Equipment/Wanderer)

-- Second Castle Checks
AddCheckpx(150, 235, 2)	-- Bastard Sword		(Equipment)
AddCheckpx(140, 235, 2)	-- Royal Cloack			(Equipment)
AddCheckpx(160, 210, 2)	-- Sword of Dawn		(Equipment)
AddCheckpx(120, 210, 2)	-- Lightning Mail		(Equipment)
AddCheckpx(20, 210, 2)	-- Dragon Helm			(Equipment)
AddCheckpx(70, 195, 2)	-- Sun Stone			(Equipment)
AddCheckpx(220, 210, 2)	-- Talwar			(Equipment)
AddCheckpx(150, 175, 2)	-- Alucard Mail			(Equipment)
AddCheckpx(155, 155, 2)	-- Sword of Hador		(Equipment)
AddCheckpx(220, 165, 2)	-- Fury Plate			(Equipment)
AddCheckpx(235, 110, 2)	-- Goddess Shield		(Equipment)
AddCheckpx(20, 130, 2)	-- Shotel			(Equipment)
AddCheckpx(140, 130, 2)	-- R. Caverns Diamond		(Equipment)
AddCheckpx(205, 80, 2)	-- R. Caverns Garnet		(Equipment)
AddCheckpx(275, 55, 2)	-- Alucard Shield		(Equipment)
AddCheckpx(170, 45, 2)	-- Alucard Sword		(Equipment)
AddCheckpx(195, 15, 2)	-- Necklace of J		(Equipment)
AddCheckpx(200, 15, 2)	-- R. Catacombs Diamond		(Equipment)
AddCheckpx(215, 80, 2)	-- Talisman			(Equipment)
AddCheckpx(65, 175, 2)	-- Staurolite			(Equipment)
AddCheckpx(105, 210, 2)	-- Moon Rod			(Equipment/Wanderer)
AddCheckpx(40, 200, 2)	-- Luminus 			(Equipment/Wanderer)
AddCheckpx(275, 190, 2)	-- Twilight Cloak		(Equipment/Wanderer)
AddCheckpx(215, 145, 2)	-- Gram 			(Equipment/Wanderer)
AddCheckpx(255, 85, 2)	-- Katana			(Equipment/Wanderer)
AddCheckpx(130, 105, 2)	-- R. Caverns Opal		(Equipment/Wanderer)
AddCheckpx(190, 55, 2)	-- Osafune Katana		(Equipment/Wanderer)
AddCheckpx(265, 60, 2)	-- Beryl Circlet		(Equipment/Wanderer)
AddCheckpx(70, 160, 2)	-- R. Library Opal		(Equipment/Wanderer)
AddCheckpx(75, 160, 2)	-- Badelaire			(Equipment/Wanderer)
end

function TouristChecks()
-- First Castle Checks
AddCheckpx(300, 130, 1)	-- Telescope / Bottom of Outer Wall		(Tourist/Wanderer)
AddCheckpx(255, 25, 1)	-- Cloaked Knight in Clock Tower		(Tourist/Wanderer)
AddCheckpx(125, 195, 1)	-- Waterfall Cave with Frozen Shade		(Tourist/Wanderer)
AddCheckpx(80, 90, 1)	-- Royal Chapel Confessional			(Tourist/Wanderer)
AddCheckpx(95, 105, 1)	-- Green Tea / Colosseum Fountain		(Tourist/Wanderer)
-- Second Castle Checks
AddCheckpx(120, 235, 2)	-- High Potion / Window Sill			(Tourist/Wanderer)
AddCheckpx(250, 145, 2)	-- R. Colosseum Zircon / R. Shield Rod	(Tourist/Wanderer)
AddCheckpx(155, 150, 2)	-- Vats / R. Center Clock Room			(Tourist/Wanderer)
AddCheckpx(85, 145, 2)	-- Meal Ticket / R. JoO Switch			(Tourist/Wanderer)
AddCheckpx(185, 95, 2)	-- Library Card / R. Forbidden Route		(Tourist/Wanderer)
AddCheckpx(135, 60, 2)	-- Life Apple / R. Demon Switch Door		(Tourist/Wanderer)
AddCheckpx(110, 10, 2)	-- R. Catacombs Elixir / R. Spike Breaker	(Tourist/Wanderer)
AddCheckpx(305, 75, 2)	-- R. Entrance Antivenom / R. Power of Wolf	(Tourist/Wanderer)
end

function WandererChecks()
AddCheckpx(80, 155, 1)	-- Basilard			(Equipment/Wanderer)
AddCheckpx(170, 110, 1)	-- Alucart Sword		(Equipment/Wanderer)
AddCheckpx(295, 120, 1)	-- Jewel Knuckles		(Equipment/Wanderer)
AddCheckpx(275, 50, 1)	-- Bekatowa			(Equipment/Wanderer)
AddCheckpx(245, 55, 1)	-- Gold Plate			(Equipment/Wanderer)
AddCheckpx(175, 15, 1)	-- Platinum Mail		(Equipment/Wanderer)
AddCheckpx(10, 120, 1)	-- Mystic Pendant		(Equipment/Wanderer)
AddCheckpx(50, 85, 1)	-- Goggles			(Equipment/Wanderer)
AddCheckpx(70, 45, 1)	-- Silver Plate			(Equipment/Wanderer)
AddCheckpx(180, 175, 1)	-- Nunchaku 			(Equipment/Wanderer)
AddCheckpx(185, 190, 1)	-- Ring of Ares 		(Equipment/Wanderer)
-- Castle 2
AddCheckpx(105, 210, 2)	-- Moon Rod			(Equipment/Wanderer)
AddCheckpx(40, 200, 2)	-- Luminus 			(Equipment/Wanderer)
AddCheckpx(275, 190, 2)	-- Twilight Cloak		(Equipment/Wanderer)
AddCheckpx(215, 145, 2)	-- Gram 			(Equipment/Wanderer)
AddCheckpx(255, 85, 2)	-- Katana			(Equipment/Wanderer)
AddCheckpx(130, 105, 2)	-- R. Caverns Opal		(Equipment/Wanderer)
AddCheckpx(190, 55, 2)	-- Osafune Katana		(Equipment/Wanderer)
AddCheckpx(265, 60, 2)	-- Beryl Circlet		(Equipment/Wanderer)
AddCheckpx(70, 160, 2)	-- R. Library Opal		(Equipment/Wanderer)
AddCheckpx(75, 160, 2)	-- Badelaire			(Equipment/Wanderer)
end

-- Add Event
forms.addclick(pbLiveMap,PictureBoxClick)

-- Add Checks
RelicChecks()
if(CheckSet>=1) then KeyItemChecks()   end
if(CheckSet>=2) then GuardedChecks()   end
if(CheckSet>=3) then SpreadChecks()   end
if(CheckSet>=4 and CheckSet~=6) then EquipmentChecks() end -- Don't Add these for Wanderer
if(CheckSet>=5) then TouristChecks()   end
if(CheckSet>=6) then WandererChecks()   end

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
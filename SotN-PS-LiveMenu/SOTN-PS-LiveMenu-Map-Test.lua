-- Castlevania SOTN Live Menu
-- Written By Project_OMEG4
-- July 14 2024 - Basic wireframe completed
-- July 16 2024 - Core components fleshed out
-- July 18 2024 - Searching SotN for memory addresses
-- July 20 2024 - Mottzilla's LiveMap included in LiveMenu (trouble running both scripts at the same time)
-- July 22 2024 - Push to Github for version 1.0 release

EndScript = false

function CloseWindow()
	forms.destroy(formLiveMenu)
	console.log("Window Closed!")
	EndScript = true
end

-- Globals
NextXP      = 0
CurrentLvl  = 0
CurrentXP   = 0
updateFrame = 0
updateMap = 0
curHour = 0
curMin = 0
curSecs = 0
curFrames = 0
RTATimeStr = ""
RunStartFrame = 0
RunEndFrame = 0
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
		curMin  = memory.read_u8(0x97C34,MainRAM)
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
	if(RunStartFrame == 0) then RTATimeStr = "00:00:00" return end 	-- Timer not started
	if(RunEndFrame > 0) then                                        -- Timer running
		curHour = ((RunEndFrame - RunStartFrame) / 216000) % 99
		curMin  = ((RunEndFrame - RunStartFrame) / 3600) % 60
		curSecs = ((RunEndFrame - RunStartFrame) / 60) % 60
	end
	if(RunEndFrame == 0) then                                       -- Timer ended
		curHour = ((emu.framecount() - RunStartFrame) / 216000) % 99
		curMin  = ((emu.framecount() - RunStartFrame) / 3600) % 60
		curSecs = ((emu.framecount() - RunStartFrame) / 60) % 60
	end
	RTATimeStr = string.format("%02d:%02d:%02d", math.floor(curHour), math.floor(curMin), math.floor(curSecs))
end

-- Create Window
formLiveMenu = forms.newform(680,620,"SOTN Live Menu",CloseWindow)
pbLiveMenu   = forms.pictureBox(formLiveMenu,0,0,680,620)
forms.drawBox(pbLiveMenu,0,0,680,620, 0xFF000000, 0xFF000066)

function UpdateText()
	txcolor = 0xFFFFFFFF
  bgcolor = 0xFF000066
  squareB = 0xFFFF6666
  circleB = 0xFFFF0000
  invFont = 16

--  Room Stuff
   CurrentRoom     = memory.read_u16_le(0x3C760,MainRAM) --Room Count: 942 = 100%, 1890 = 200.6%
   RoomPercent     = math.floor(((CurrentRoom / 942) * 100)*10)/10
   RoomPercentStr  = RoomPercent .. "%"

-- Time Stuff
   TimeStr       = ""
     TimeHours   = memory.read_u16_le(0x097C30,MainRAM)
     TimeMinutes = memory.read_u16_le(0x097C34,MainRAM)
     TimeSeconds = memory.read_u16_le(0x097C38,MainRAM)
   TimeStr       = string.format("IGT : %02d:%02d:%02d", TimeHours, TimeMinutes, TimeSeconds)

--  Grab values from memory

    CurrentGold = memory.read_u24_le(0x97BF0,MainRAM)
    CurrentKill = memory.read_u16_le(0x97BF4,MainRAM)
    CurrentXP   = memory.read_u24_le(0x97BEC,MainRAM)
    CurrentLvl  = memory.read_u16_le(0x97BE8,MainRAM)
    AttackLeft  = memory.read_u16_le(0x97C1C,MainRAM)
    AttackRight = memory.read_u16_le(0x97C20,MainRAM)
    CurrentDef  = memory.read_u16_le(0x97C24,MainRAM)
    CurrentStr  = memory.read_u16_le(0x97BB8,MainRAM)
       StrBuff  = memory.read_u16_le(0x97BC8,MainRAM)
    CurrentCon  = memory.read_u16_le(0x97BBC,MainRAM)
       ConBuff  = memory.read_u16_le(0x97BCC,MainRAM)
    CurrentInt  = memory.read_u16_le(0x97BC0,MainRAM)
       IntBuff  = memory.read_u16_le(0x97BD0,MainRAM)
    CurrentLck  = memory.read_u16_le(0x97BC4,MainRAM)
      LuckBuff  = memory.read_u16_le(0x97BD4,MainRAM)

    -- XP Level array. There's no easier way to do this because SOTN. 
      local XPValues = {100,250,450,700,1000,1350,1750,2200,2700,3250,3850,4500,5200,5950,6750,7600,8500,9450,10450,11700,13200,15100,17500,
      20400,23700,27200,30900,35000,39500,44500,50000,56000,61500,68500,76000,84000,92500,101500,110000,120000,130000,140000,150000,160000,
      170000,180000,190000,200000,210000,222000,234000,246000,258000,270000,282000,294000,306000,318000,330000,344000,358000,372000,386000,
      400000,414000,428000,442000,456000,470000,486000,502000,518000,534000,550000,566000,582000,598000,614000,630000,648000,666000,684000,
      702000,720000,738000,756000,774000,792000,810000,830000,850000,870000,890000,910000,930000,950000,970000,999999}

      NextXP = XPValues[CurrentLvl] - CurrentXP

    -- Prepare strings
    -- HP Data
    CurrentHP = memory.read_u16_le(0x97BA0,MainRAM)
    MaxHP     = memory.read_u16_le(0x97BA4,MainRAM)
    HPStr     = "HP    " .. CurrentHP   .. "/ " .. MaxHP

    -- MP Data
    CurrentMP = memory.read_u16_le(0x97BB0,MainRAM)
    MaxMP     = memory.read_u16_le(0x97BB4,MainRAM)
    MPStr     = "MP    " .. CurrentMP   .. "/ " .. MaxMP

    -- Hearts
    CurrentHrt = memory.read_u16_le(0x97BA8,MainRAM)
    MaxHeart   = memory.read_u16_le(0x97BAC,MainRAM)
    HeartStr   = "HEART " .. CurrentHrt  .. "/ " .. MaxHeart

    -- Sub-Weapons: 0 Empty | 1 Knife | 2 Axe | 3 Holy Water | 4 Holy Cross | 5 Holy Bible | 6 Stopwatch | 7 Rebound Stone | 8 Vibhuti | 9 Agunea
    subWeaponSlot = memory.read_u8(0x097BFC,MainRAM)
    local swArray = {[0]=0,[1]=1,[2]=4,[3]=3,[4]=100,[5]=5,[6]=20,[7]=2,[8]=3,[9]=5}
    swCost = swArray[subWeaponSlot]
    swUses = math.floor(CurrentHrt/swCost)
    forms.drawImageRegion(pbLiveMenu,"subweapons/sw_".. subWeaponSlot ..".png",0,0,100,100,130,130,80,80)
    forms.drawText(pbLiveMenu,130,215," -".. swCost .." ♥",txcolor,bgcolor,12)
    forms.drawText(pbLiveMenu,130,230,"(".. swUses .." left)",txcolor,bgcolor,12)

    GoldStr   = "GOLD  " .. CurrentGold
    XPStr     = "EXP   " .. CurrentXP
    NextXPStr = "NEXT  " .. NextXP
    LevelStr  = "LEVEL " .. CurrentLvl
    RoomStr   = "ROOMS " .. CurrentRoom .. "(" .. RoomPercentStr .. ")"
    KillStr   = "KILLS " .. CurrentKill
    StrStr    = "STR   " .. CurrentStr  .. " +" .. StrBuff
    ConStr    = "CON   " .. CurrentCon  .. " +" .. ConBuff
    IntStr    = "INT   " .. CurrentInt  .. " +" .. IntBuff
    LckStr    = "LCK   " .. CurrentLck  .. " +" .. LuckBuff
    DefStr    = "  " .. CurrentDef
    AttackLeftStr   = "□ "
    AttackRightStr  = "O "

  --Draw Alucard
  --Todo: Create several versions to denote Stoned, Cursed, Low HP
    forms.drawImageRegion(pbLiveMenu,"alucard_portrait.png",0,0,335,635,10,10,120,250)

  --Start Menu Text Items  
  --forms.drawText(PictureBoxToDrawOn,xxx,yyy,variable,txtColor, bgColor, txtSize)
  local tl_txtXpos = 200
  local tr_txtXpos = 400

--------------------------------------------------------------------
-- Top Left Side
--------------------------------------------------------------------

    forms.drawText(pbLiveMenu,tl_txtXpos,10,"ALUCARD",txcolor,bgcolor,20)
    if (CurrentHP<(MaxHP*0.25)) then forms.drawText(pbLiveMenu,tl_txtXpos,50,HPStr,0xFFDFB50B,bgcolor,18) -- If HP goes below 25% max HP, show orange caution color
      else forms.drawText(pbLiveMenu,tl_txtXpos,50,HPStr,txcolor,bgcolor,18) end

    forms.drawText(pbLiveMenu,tl_txtXpos, 70,MPStr,    txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tl_txtXpos, 90,HeartStr, txcolor,bgcolor,18)

    forms.drawText(pbLiveMenu,tl_txtXpos,130,StrStr,   txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tl_txtXpos,150,ConStr,   txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tl_txtXpos,170,IntStr,   txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tl_txtXpos,190,LckStr,   txcolor,bgcolor,18)

    forms.drawText(pbLiveMenu,tl_txtXpos,230,XPStr,    txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tl_txtXpos,250,NextXPStr,txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tl_txtXpos,270,GoldStr,  txcolor,bgcolor,18)

--------------------------------------------------------------------
-- Top Right Side
--------------------------------------------------------------------

    -- Level Stuff
    forms.drawText(pbLiveMenu,tr_txtXpos, 10,LevelStr, txcolor,bgcolor,20)

    -- Status
    statusStr = "GOOD"
    forms.drawText(pbLiveMenu,tr_txtXpos, 50,"STATUS"..string.char(10).."   "..statusStr, txcolor,bgcolor,20)

    -- ATT Stats
    --Todo: Hands seem to set attack to non-zero when it should be 0 sometimes; might be rounding error. Might need more investigation
    forms.drawText(pbLiveMenu,tr_txtXpos,120,"ATT ",   txcolor,bgcolor,40)
      forms.drawText(pbLiveMenu,500,120,AttackLeftStr, squareB,bgcolor,18) -- Pink Square
      forms.drawText(pbLiveMenu,530,120,AttackLeft,    txcolor,bgcolor,18)
      forms.drawText(pbLiveMenu,500,140,AttackRightStr,circleB,bgcolor,18)
      forms.drawText(pbLiveMenu,530,140,AttackRight,   txcolor,bgcolor,18)
    -- DEF Stats
    forms.drawText(pbLiveMenu,tr_txtXpos,160,"DEF ",   txcolor,bgcolor,40)
      forms.drawText(pbLiveMenu,500,180,DefStr,        txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tr_txtXpos,230,RoomStr,  txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tr_txtXpos,250,KillStr,  txcolor,bgcolor,18)
    forms.drawText(pbLiveMenu,tr_txtXpos,270,TimeStr,  txcolor,bgcolor,18)

--------------------------------------------------------------------
-- Bottom Left Side
--------------------------------------------------------------------

--  Inventory Stuff
rightHandSlot   = memory.read_u8(0x097C00,MainRAM)
leftHandSlot    = memory.read_u8(0x097C04,MainRAM)

local itemArray = {
 [0]="Empty Hand",[1]="Monster Vial 1",[2]="Monster Vial 2",[3]="Monster Vial 3",[4]="Shield Rod",[5]="Leather Shield",[6]="Knight Shield",[7]="Iron Shield",[8]="AxeLord Shield",[9]="Herald Shield",[10]="Dark Shield",[11]="Goddess Shield",
 [12]="Shaman Shield",[13]="Medusa Shield",[14]="Skull Shield",[15]="Fire Shield",[16]="Alucard Shield",[17]="Sword of Dawn",[18]="Basilard",[19]="Short Sword",[20]="Combat Knife",[21]="Nunchacku ",[22]="Were Bane ",[23]="Rapier ",[24]="Karma Coin",
 [25]="Magic Missile",[26]="Red Rust",[27]="Takemitsu ",[28]="Shotel ",[29]="Orange",[30]="Apple",[31]="Banana",[32]="Grapes",[33]="Strawberry",[34]="Pineapple ",[35]="Peanuts",[36]="Toadstool",[37]="Shiitake ",[38]="Cheesecake",[39]="Shortcake",
 [40]="Tart",[41]="Parfait",[42]="Pudding",[43]="Ice Cream",[44]="Frankfurter",[45]="Hamburger",[46]="Pizza",[47]="Cheese",[48]="Ham And Eggs",[49]="Omelette ",[50]="Morning Set",[51]="Lunch A",[52]="Lunch B",[53]="Curry Rice",[54]="Gyros Plate",
 [55]="Spaghetti ",[56]="Grape Juice",[57]="Barley Tea",[58]="Green Tea",[59]="Natou ",[60]="Ramen",[61]="Miso Soup",[62]="Sushi",[63]="Pork Bun",[64]="Red Bean Bun",[65]="Chinese Bun",[66]="Dim Dum Set",[67]="Pot Roast",[68]="Sirloin",
 [69]="Turkey",[70]="Meal Ticket",[71]="Neutron Bomb",[72]="Power of Sire",[73]="Pentagram",[74]="Bat Pentagram",[75]="Shuriken",[76]="Cross Shuriken",[77]="Buffalo Star",[78]="Flame Star",[79]="TNT",[80]="Bwaka Knife",[81]="Boomerang",[82]="Javelin",
 [83]="Tyrfing ",[84]="Nakamura ",[85]="Knuckle Duster",[86]="Gladius ",[87]="Scimitar ",[88]="Cutlass",[89]="Saber",[90]="Falchion ",[91]="Broadsword ",[92]="Bekatowa ",[93]="Damascus Sword",[94]="Hunter Sword",[95]="Estoc",[96]="Bastard Sword",
 [97]="Jewel Knuckles",[98]="Claymore",[99]="Talwar ",[100]="Katana",[101]="Flamberge",[102]="Iron Fist",[103]="Zwei Hander",[104]="Sword of Hador",[105]="Luminus",[106]="Harper",[107]="Obsidian Sword",[108]="Gram",[109]="Jewel Sword",[110]="Mormegil ",
 [111]="Firebrand",[112]="Thunderbrand",[113]="Icebrand",[114]="Stone Sword",[115]="Holy Sword",[116]="Terminus Est",[117]="Marsil",[118]="Dark Blade",[119]="Heaven Sword",[120]="Fist of Tulkas",[121]="Gurthang ",[122]="Mourneblade",
 [123]="Alucard Sword",[124]="Mablung Sword",[125]="Badelaire ",[126]="Sword Familiar ",[127]="Great Sword",[128]="Mace",[129]="Morning Star",[130]="Holy Rod",[131]="Star Flail",[132]="Moon Rod",[133]="Chakram ",[134]="Fire Boomerang",
 [135]="Iron Ball",[136]="Holbein Dagger",[137]="Blue Knuckles",[138]="Dynamite",[139]="Osafune Katana",[140]="Masamune",[141]="Muramasa",[142]="Heart Refresh",[143]="Rune sword",[144]="Anti-Venom",[145]="Uncurse",[146]="Life Apple",[147]="Hammer",
 [148]="Strength Potion",[149]="Luck Potion ",[150]="Smart Potion",[151]="Attack Potion",[152]="Shield Potion",[153]="Resist Fire",[154]="Resist Thunder",[155]="Resist Ice",[156]="Resist Stone",[157]="Resist Holy",[158]="Resist Dark",[159]="Potion",
 [160]="High Potion",[161]="Elixir",[162]="Mana Prism",[163]="Vorpal Blade",[164]="Crissaegrim",[165]="Yasutsuna",[166]="Library Card",[167]="Alucart Shield",[168]="Alucart Sword"}

 if itemArray[rightHandSlot] then
   forms.drawText(pbLiveMenu,10,300,"R",txcolor,bgcolor,15)
   forms.drawImageRegion(pbLiveMenu,"rhand.png",0,0,15,15,25,300,15,15)
   forms.drawImageRegion(pbLiveMenu,"items/".. rightHandSlot ..".png",0,0,15,15,40,300,15,15)
   forms.drawText(pbLiveMenu,60,300,itemArray[rightHandSlot],txcolor,bgcolor,invFont)
 end
 if itemArray[leftHandSlot]  then
   forms.drawText(pbLiveMenu,10,320,"L", txcolor,bgcolor,15)
   forms.drawImageRegion(pbLiveMenu,"lhand.png",0,0,15,15,25,320,15,15)
   forms.drawImageRegion(pbLiveMenu,"items/".. leftHandSlot ..".png",0,0,15,15,40,320,15,15)
   forms.drawText(pbLiveMenu,60,320,itemArray[leftHandSlot],txcolor,bgcolor,invFont)
 end

-- Armor Items - Head, Body, Clock, and both Accessories share an item pool
headSlot   = memory.read_u8(0x097C08,MainRAM)
armorSlot  = memory.read_u8(0x097C0C,MainRAM)
cloakSlot  = memory.read_u8(0x097C10,MainRAM)
otherSlot1 = memory.read_u8(0x097C14,MainRAM)
otherSlot2 = memory.read_u8(0x097C18,MainRAM)

local armorArray = {
 [0]="Empty Armor",[1]="Cloth Tunic",[2]="Hide Cuirass",[3]="Bronze Cuirass",[4]="Iron Cuirass",[5]="Steel Cuirass",[6]="Silver Plate",[7]="Gold Plate",[8]="Platinum Mail",[9]="Diamond Plate",[10]="Fire Mail",[11]="Lightning Mail",
 [12]="Ice Mail",[13]="Mirror Cuirass",[14]="Spike Breaker",[15]="Alucard Mail",[16]="Dark Armor",[17]="Healing Mail",[18]="Holy Mail",[19]="Walk Armor",[20]="Brilliant Mail",[21]="Mojo Mail",[22]="Fury Plate",[23]="Dracula Tunic",
 [24]="God's Garb",[25]="Axe Lord Armor",[26]="Empty Head",[27]="Sunglasses",[28]="Ballroom Mask",[29]="Bandanna",[30]="Felt Hat",[31]="Velvet Hat",[32]="Googles",[33]="Leather Hat",[34]="Holy Glasses",[35]="Steel Helm",[36]="Stone Mask",[37]="Circlet",
 [38]="Gold Circlet",[39]="Ruby Circlet",[40]="Opal Circlet",[41]="Topaz Circlet",[42]="Beryl Circlet",[43]="Cat-Eye Circlet",[44]="Coral Circlet",[45]="Dragon Helm",[46]="Silver Crown",[47]="Wizard Hat",[48]="Empty Cloak",[49]="Cloth Cape",
 [50]="Reverse Cloak ",[51]="Elven Cloak",[52]="Crystal Cloak",[53]="Royal Cloak",[54]="Blood Cloak",[55]="Joseph's Cloak",[56]="Twilight Cloak",[57]="Empty Accessory",[58]="Moonstone",[59]="Sunstone",[60]="Bloodstone",[61]="Staurolite",
 [62]="Ring of Pales",[63]="Zircon",[64]="Aquamarine ",[65]="Turquoise ",[66]="Onyx ",[67]="Garnet",[68]="Opal",[69]="Diamond",[70]="Lapis Lazuli",[71]="Ring of Ares",[72]="Gold Ring",[73]="Silver Ring",[74]="Ring of Varda",[75]="Ring of Arcana",
 [76]="Mystic Pendant",[77]="Heart Broach",[78]="Necklace of J",[79]="Gauntlet ",[80]="Ankh of Life",[81]="Ring of Feanor",[82]="Medal",[83]="Talisman",[84]="Duplicator",[85]="King's Stone",[86]="Covenant Stone",[87]="Nauglamir",[88]="Secret Boots",[89]="Alucart Mail"}

 if armorArray[headSlot]   then
   forms.drawImageRegion(pbLiveMenu,"head.png",0,0,15,15,25,340,15,15)
   forms.drawImageRegion(pbLiveMenu,"armor/".. headSlot ..".png",0,0,15,15,40,340,15,15)
   forms.drawText(pbLiveMenu,60,340,armorArray[headSlot],  txcolor,bgcolor,invFont)
 end
 if armorArray[armorSlot]  then
   forms.drawImageRegion(pbLiveMenu,"armor.png",0,0,15,15,25,360,15,15)
   forms.drawImageRegion(pbLiveMenu,"armor/".. armorSlot ..".png",0,0,15,15,40,360,15,15)
   forms.drawText(pbLiveMenu,60,360,armorArray[armorSlot], txcolor,bgcolor,invFont)
 end
 if armorArray[cloakSlot]  then
   forms.drawImageRegion(pbLiveMenu,"other.png",0,0,15,15,25,380,15,15)
   forms.drawImageRegion(pbLiveMenu,"armor/".. cloakSlot ..".png",0,0,15,15,40,380,15,15)
   forms.drawText(pbLiveMenu,60,380,armorArray[cloakSlot], txcolor,bgcolor,invFont)
 end
 if armorArray[otherSlot1] then
   forms.drawImageRegion(pbLiveMenu,"other.png",0,0,15,15,25,400,15,15)
   forms.drawImageRegion(pbLiveMenu,"armor/".. otherSlot1 ..".png",0,0,15,15,40,400,15,15)
   forms.drawText(pbLiveMenu,60,400,armorArray[otherSlot1],txcolor,bgcolor,invFont)
 end
 if armorArray[otherSlot2] then
   forms.drawImageRegion(pbLiveMenu,"other.png",0,0,15,15,25,420,15,15)
   forms.drawImageRegion(pbLiveMenu,"armor/".. otherSlot2 ..".png",0,0,15,15,40,420,15,15)
   forms.drawText(pbLiveMenu,60,420,armorArray[otherSlot2],txcolor,bgcolor,invFont)
 end

-- Castle Entrance, Don't log before entering the Gate.
if(Zone == 0x41 and (castleY >41 or castleX<2) ) then return end
-- Don't log during Prologue or Final Dracula
if(Zone == 0x1F or Zone == 0x38) then return end

-- [[
--------------------------------------------------------------------
-- Bottom Right - Mini Map Stuff
--------------------------------------------------------------------
if(RunEndFrame > 0)     then tmrtxcolor = 0xFFFFD700 end
if(RunStartFrame == 0)  then tmrtxcolorxcolor = 0xFF808080 end

br_txtXpos = 270

BuildAutoTimerStr()
forms.drawText(pbLiveMenu,tr_txtXpos,290,"RTA :"..RTATimeStr,tmrtxcolor,bgcolor, 20)
forms.drawText(pbLiveMenu,tr_txtXpos+170,290,"< RESET",txcolor, bgcolor,16)
--forms.drawBox(pbLiveMenu,br_txtXpos,500,400,520,0xFF000000, bgcolor)

local checkRelicSet = { [0] = "??? Checks",
[1] = "Classic Checks",     [2] = "Guarded Checks", [3] = "Spread Checks",
[4] = "Equipment Checks",   [5] = "Tourist Checks", [6] = "Wanderer Checks" }

if checkRelicSet[CheckSet] then forms.drawText(pbLiveMenu, br_txtXpos, 550, checkRelicSet[CheckSet], 0xFF00FF00, 16) end -- Relic Selector



--]]-
--------------------------------------------------------------------
  -- Refresh the form
    forms.refresh(pbLiveMenu)
end

--------------------------------------------------------------------
-- End of main text updating function
--------------------------------------------------------------------


function DoCastleMap()
  local drawX
  local drawY
  local NewCastle

  -- Read variables
  Zone    = memory.read_u8(0x974A0)
  castleX = memory.read_u8(0x730B0)
  castleY = memory.read_u8(0x730B4)
  roomX   = memory.read_u16_le(0x973F0)
  roomY   = memory.read_u16_le(0x973F4)

  -- Calculate position
  roomX = math.floor(roomX/256)
  roomY = math.floor(roomY/256)

  castleX = castleX+roomX
  castleY = castleY+roomY

  -- Debug Output
  -- local stringbufA
  -- local stringbufB
  -- stringbufA = bizstring.hex(castleX)
  -- stringbufB = bizstring.hex(castleY)
  -- print(stringbufA .. "," .. stringbufB)

  -- Find which castle we are currently in.
  NewCastle = bit.band(memory.read_u8(0x974A0),0x20)
  if(NewCastle == 0x20) then NewCastle = 2 end
  if(NewCastle == 0x00) then NewCastle = 1 end

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
  drawX = (castleX * 5)
  drawY = (castleY * 5) - 15

  -- Update Previous Square. This will be blue.
  forms.drawBox(pbLiveMenu,PreviousX,PreviousY,PreviousX+4,PreviousY+4,0xFF0000E0, 0xFF00000E0)
  if(curCastle == 1) then	forms.drawImageRegion(pbLiveMenu,"map/Castle1_Empty_TP.png",PreviousCastleX * 5,(PreviousCastleY*5) - 15,5,5,PreviousX,PreviousY,5,5) end
  if(curCastle == 2) then	forms.drawImageRegion(pbLiveMenu,"map/Castle2_Empty_TP.png",PreviousCastleX * 5,(PreviousCastleY*5) - 15,5,5,PreviousX,PreviousY,5,5) end

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
  forms.drawBox(pbLiveMenu,drawX,drawY,drawX+4,drawY+4,0xFFE000E0, 0xFFE000E0)
  if(curCastle == 1) then	forms.drawImageRegion(pbLiveMenu,"map/Castle1_Empty_TP.png",castleX * 5,(castleY*5) - 15,5,5,drawX,drawY,5,5) end
  if(curCastle == 2) then	forms.drawImageRegion(pbLiveMenu,"map/Castle2_Empty_TP.png",castleX * 5,(castleY*5) - 15,5,5,drawX,drawY,5,5) end

  -- Mark Map Location
  if(curCastle == 1) then rec_map1[castleX + (castleY*64)] = 1 end
  if(curCastle == 2) then rec_map2[castleX + (castleY*64)] = 1 end
end

function ChangeCastle()
    -- Clear Canvas
    forms.drawBox(pbLiveMenu,260,340,260+320,340+255, 0xFF000000, 0xFF000000)

    -- Draw Castle Progress
    if(curCastle == 1) then
        for x=0, 63 do
            for y=0, 63 do
              if(rec_map1[x + (y*64)] == 1) then forms.drawBox(pbLiveMenu,(x*5),(y*5) - 15,4 + (x*5),(y*5) - 11,0xFF0000E0, 0xFF0000E0) end
              if(rec_map1[x + (y*64)] == 2) then forms.drawBox(pbLiveMenu,(x*5),(y*5) - 15,4 + (x*5),(y*5) - 11,0xFF00FF00, 0xFF00FF00) end
            end
        end
    end

    if(curCastle == 2) then
        for x=0, 63 do
            for y=0, 63 do
                if(rec_map2[x + (y*64)] == 1) then forms.drawBox(pbLiveMenu,(x*5),(y*5) - 15,4 + (x*5),(y*5) - 11,0xFF0000E0, 0xFF0000E0) end
                if(rec_map2[x + (y*64)] == 2) then forms.drawBox(pbLiveMenu,(x*5),(y*5) - 15,4 + (x*5),(y*5) - 11,0xFF00FF00, 0xFF00FF00) end
            end
        end
    end

    -- Draw Castle Outline
    if(curCastle == 1) then forms.drawImage(pbLiveMenu,"map/Castle1_Empty_TP.png",260,340,320,340+255,true) end
    if(curCastle == 2) then forms.drawImage(pbLiveMenu,"map/Castle2_Empty_TP.png",260,340,320,340+255,true) end
    forms.refresh(pbLiveMenu)
end

function PictureBoxClick()
    WX = forms.getMouseX(pbLiveMenu)
    WY = forms.getMouseY(pbLiveMenu)

    -- Clicked Reset
    if(WX<570 and WY>280 and WY<320) then
        RunStartFrame = 0
      for i=0, 4096 do
            rec_map1[i] = 0
            rec_map2[i] = 0
      end
        RelicChecks()
        if(CheckSet>=1) then KeyItemChecks()  end
        if(CheckSet>=2) then GuardedChecks()  end
        if(CheckSet>=3) then SpreadChecks()   end
        if(CheckSet>=4  and  CheckSet~=6)     then EquipmentChecks() end	-- Don't add Equipment to Wanderer
        if(CheckSet>=5) then TouristChecks()  end
        if(CheckSet>=6) then WandererChecks() end
        ChangeCastle()
    end

    -- Clicked CheckSet Change
    if(WX>570 and WX<280 and WY>660 and WY<320) then
        for i=0, 4096 do
            if(rec_map1[i] == 2) then rec_map1[i] = 0 end
            if(rec_map2[i] == 2) then rec_map2[i] = 0 end
        end
        CheckSet = CheckSet + 1
        if(CheckSet>6) then CheckSet = 1 end
        RelicChecks()
        if(CheckSet>=1) then KeyItemChecks()  end
        if(CheckSet>=2) then GuardedChecks()  end
        if(CheckSet>=3) then SpreadChecks()   end
        if(CheckSet>=4  and  CheckSet~=6)     then EquipmentChecks() end	-- Don't add Equipment to Wanderer
        if(CheckSet>=5) then TouristChecks()  end
        if(CheckSet>=6) then WandererChecks() end
        ChangeCastle()
    end

    -- Clicked Timer
    --if(WX<176 and WY>530 and WY<562) then
    --    if(Zone == 0x45) then RunStartFrame = 0 end
    --end
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
    AddCheckpx(240, 90,1)	-- Soul of Bat
    AddCheckpx(295, 40,1)	-- Fire of Bat
    AddCheckpx( 80, 65,1)	-- Echo of Bat
    AddCheckpx( 40, 60,2)	-- Force of Echo
    AddCheckpx(305, 75,1)	-- Soul of Wolf
    AddCheckpx( 15,175,1)	-- Power of Wolf
    AddCheckpx( 75,150,1)	-- Skill of Wolf
    AddCheckpx(105, 95,1)	-- Form of Mist
    AddCheckpx(155, 30,1)	-- Power of Mist
    AddCheckpx(230, 15,2)	-- Gas Cloud
    AddCheckpx( 95,165,1)	-- Cube of Zoe
    AddCheckpx(125,145,1)	-- Spirit Orb
    AddCheckpx(170,100,1)	-- Gravity Boots
    AddCheckpx(155, 40,1)	-- Leap Stone
    AddCheckpx(275,190,1)	-- Holy Symbol
    AddCheckpx(295, 75,1)	-- Faerie Scroll
    AddCheckpx(245, 85,1)	-- Jewel of Open
    AddCheckpx( 40,195,1)	-- Merman Statue
    AddCheckpx( 65,120,1)	-- Bat Card
    AddCheckpx(195, 20,1)	-- Ghost Card
    AddCheckpx(260, 75,1)	-- Faerie Card
    AddCheckpx(145,205,1)	-- Demon Card
    AddCheckpx(100, 75,1)	-- Sprite Card (Sword Card US)
    AddCheckpx(195,200,2)	-- Heart of Vlad
    AddCheckpx( 25,150,2)	-- Tooth of Vlad
    AddCheckpx(220,185,2)	-- Rib of Vlad
    AddCheckpx(115,215,2)	-- Ring of Vlad
    AddCheckpx(160, 65,2)	-- Eye of Vlad
    -- AddCheckpx(165,75,1)	-- Sword Card (JP)
    -- AddCheckpx(95,85,1)	-- Nosedevil Card
end

function KeyItemChecks()
    AddCheckpx(225,150,1)	-- Gold Ring
    AddCheckpx( 40, 60,1)	-- Silver Ring
    AddCheckpx(160,140,1)	-- Holy Glasses
    AddCheckpx(205,240,1)	-- Spikebreaker
end

function GuardedChecks()
    AddCheckpx( 85,235,1)	-- Mormegil
    AddCheckpx(200,175,1)	-- Crystal Cloak
    AddCheckpx(115, 75,2)	-- Dark Blade
    AddCheckpx(215,155,2)	-- Trio
    AddCheckpx(250,130,2)	-- Ring of Arcana
end

function SpreadChecks()
    AddCheckpx(65,175,2)	-- Bookcase
    AddCheckpx(70,165,2)	-- Reverse Shop
end

-- Adding Equipment, Wanderer, Tourist Checks
function EquipmentChecks()
    AddCheckpx( 25,175,1)	-- Holy Mail			(Equipment)
    AddCheckpx( 50,190,1)	-- Jewel Sword			(Equipment)
    AddCheckpx( 50,130,1)	-- Cloth Cape			(Equipment)
    AddCheckpx( 80,140,1)	-- Sunglasses			(Equipment)
    AddCheckpx(295,100,1)	-- Gladius 		    	(Equipment)
    AddCheckpx(245, 90,1)	-- Bronze Cuirass		(Equipment)
    AddCheckpx(250, 75,1)	-- Holy Rod 			(Equipment)
    AddCheckpx(230, 90,1)	-- Library Onyx 		(Equipment)
    AddCheckpx(195, 25,1)	-- Falchion 			(Equipment)
    AddCheckpx( 20,110,1)	-- Ankh of Life 		(Equipment)
    AddCheckpx( 40, 90,1)	-- Morningstar 			(Equipment)
    AddCheckpx(135, 35,1)	-- Cutlass 			    (Equipment)
    AddCheckpx(160, 95,1)	-- Olrox Onyx 			(Equipment)
    AddCheckpx(150, 60,1)	-- Estoc 			    (Equipment)
    AddCheckpx(165, 75,1)	-- Olrox Garnet 		(Equipment)
    AddCheckpx( 65,105,1)	-- Sheild Rod 			(Equipment)
    AddCheckpx(100,105,1)	-- Blood Cloak 			(Equipment)
    AddCheckpx( 95, 85,1)	-- Holy Sword 			(Equipment)
    AddCheckpx( 70, 95,1)	-- Knight Sheild 		(Equipment)
    AddCheckpx(175,120,1)	-- Bandanna 			(Equipment)
    AddCheckpx(120,180,1)	-- Secret Boots 		(Equipment)
    AddCheckpx(200,195,1)	-- Knuckle Duster 		(Equipment)
    AddCheckpx(225,190,1)	-- Caverns Onyx 		(Equipment)
    AddCheckpx(155,225,1)	-- Combat Knife 		(Equipment)
    AddCheckpx(140,235,1)	-- Bloodstone 			(Equipment)
    AddCheckpx(120,235,1)	-- Icebrand 			(Equipment)
    AddCheckpx(115,235,1)	-- Walk Armor 			(Equipment)
    AddCheckpx( 80,155,1)	-- Basilard			    (Equipment/Wanderer)
    AddCheckpx(170,110,1)	-- Alucart Sword		(Equipment/Wanderer)
    AddCheckpx(295,120,1)	-- Jewel Knuckles		(Equipment/Wanderer)
    AddCheckpx(275, 50,1)	-- Bekatowa	    		(Equipment/Wanderer)
    AddCheckpx(245, 55,1)	-- Gold Plate			(Equipment/Wanderer)
    AddCheckpx(175, 15,1)	-- Platinum Mail		(Equipment/Wanderer)
    AddCheckpx( 10,120,1)	-- Mystic Pendant		(Equipment/Wanderer)
    AddCheckpx( 50, 85,1)	-- Goggles  			(Equipment/Wanderer)
    AddCheckpx( 70, 45,1)	-- Silver Plate			(Equipment/Wanderer)
    AddCheckpx(190,175,1)	-- Nunchaku 			(Equipment/Wanderer)
    AddCheckpx(185,190,1)	-- Ring of Ares 		(Equipment/Wanderer)
    AddCheckpx(150,235,2)	-- Bastard Sword		(Equipment)
    AddCheckpx(140,235,2)	-- Royal Cloack			(Equipment)
    AddCheckpx(160,210,2)	-- Sword of Dawn		(Equipment)
    AddCheckpx(120,210,2)	-- Lightning Mail		(Equipment)
    AddCheckpx( 20,210,2)	-- Dragon Helm			(Equipment)
    AddCheckpx( 70,195,2)	-- Sun Stone			(Equipment)
    AddCheckpx(220,210,2)	-- Talwar		    	(Equipment)
    AddCheckpx(150,175,2)	-- Alucard Mail			(Equipment)
    AddCheckpx(155,155,2)	-- Sword of Hador		(Equipment)
    AddCheckpx(220,165,2)	-- Fury Plate			(Equipment)
    AddCheckpx(235,110,2)	-- Goddess Shield		(Equipment)
    AddCheckpx( 20,130,2)	-- Shotel			    (Equipment)
    AddCheckpx(140,130,2)	-- R. Caverns Diamond	(Equipment)
    AddCheckpx(205, 80,2)	-- R. Caverns Garnet	(Equipment)
    AddCheckpx(275, 55,2)	-- Alucard Shield		(Equipment)
    AddCheckpx(170, 45,2)	-- Alucard Sword		(Equipment)
    AddCheckpx(195, 15,2)	-- Necklace of J		(Equipment)
    AddCheckpx(200, 15,2)	-- R. Catacombs Diamond	(Equipment)
    AddCheckpx(215, 80,2)	-- Talisman		    	(Equipment)
    AddCheckpx( 65,175,2)	-- Staurolite			(Equipment)
    AddCheckpx(105,210,2)	-- Moon Rod			    (Equipment/Wanderer)
    AddCheckpx( 40,200,2)	-- Luminus 			    (Equipment/Wanderer)
    AddCheckpx(275,190,2)	-- Twilight Cloak		(Equipment/Wanderer)
    AddCheckpx(215,145,2)	-- Gram 			    (Equipment/Wanderer)
    AddCheckpx(255, 85,2)	-- Katana		    	(Equipment/Wanderer)
    AddCheckpx(130,105,2)	-- R. Caverns Opal		(Equipment/Wanderer)
    AddCheckpx(190, 55,2)	-- Osafune Katana		(Equipment/Wanderer)
    AddCheckpx(265, 60,2)	-- Beryl Circlet		(Equipment/Wanderer)
    AddCheckpx( 70,160,2)	-- R. Library Opal		(Equipment/Wanderer)
    AddCheckpx( 75,160,2)	-- Badelaire			(Equipment/Wanderer)
end

function TouristChecks()
    AddCheckpx(300,130,1)	-- Telescope / Bottom of Outer Wall		(Tourist/Wanderer)
    AddCheckpx(255, 25,1)	-- Cloaked Knight in Clock Tower		(Tourist/Wanderer)
    AddCheckpx(125,195,1)	-- Waterfall Cave with Frozen Shade		(Tourist/Wanderer)
    AddCheckpx( 80, 90,1)	-- Royal Chapel Confessional			(Tourist/Wanderer)
    AddCheckpx( 95,105,1)	-- Green Tea / Colosseum Fountain		(Tourist/Wanderer)
    AddCheckpx(120,235,2)	-- High Potion / Window Sill			(Tourist/Wanderer)
    AddCheckpx(250,145,2)	-- R. Colosseum Zircon / R. Shield Rod	(Tourist/Wanderer)
    AddCheckpx(155,150,2)	-- Vats / R. Center Clock Room			(Tourist/Wanderer)
    AddCheckpx( 85,145,2)	-- Meal Ticket / R. JoO Switch			(Tourist/Wanderer)
    AddCheckpx(185, 95,2)	-- Library Card / R. Forbidden Route		(Tourist/Wanderer)
    AddCheckpx(135, 60,2)	-- Life Apple / R. Demon Switch Door		(Tourist/Wanderer)
    AddCheckpx(110, 10,2)	-- R. Catacombs Elixir / R. Spike Breaker	(Tourist/Wanderer)
    AddCheckpx(305, 75,2)	-- R. Entrance Antivenom / R. Power of Wolf	(Tourist/Wanderer)
end

function WandererChecks()
    AddCheckpx( 80,155,1)	-- Basilard			(Equipment/Wanderer)
    AddCheckpx(170,110,1)	-- Alucart Sword	(Equipment/Wanderer)
    AddCheckpx(295,120,1)	-- Jewel Knuckles	(Equipment/Wanderer)
    AddCheckpx(275, 50,1)	-- Bekatowa			(Equipment/Wanderer)
    AddCheckpx(245, 55,1)	-- Gold Plate		(Equipment/Wanderer)
    AddCheckpx(175, 15,1)	-- Platinum Mail	(Equipment/Wanderer)
    AddCheckpx( 10,120,1)	-- Mystic Pendant	(Equipment/Wanderer)
    AddCheckpx( 50, 85,1)	-- Goggles			(Equipment/Wanderer)
    AddCheckpx( 70, 45,1)	-- Silver Plate		(Equipment/Wanderer)
    AddCheckpx(180,175,1)	-- Nunchaku 		(Equipment/Wanderer)
    AddCheckpx(185,190,1)	-- Ring of Ares 	(Equipment/Wanderer)
    AddCheckpx(105,210,2)	-- Moon Rod			(Equipment/Wanderer)
    AddCheckpx( 40,200,2)	-- Luminus 			(Equipment/Wanderer)
    AddCheckpx(275,190,2)	-- Twilight Cloak	(Equipment/Wanderer)
    AddCheckpx(215,145,2)	-- Gram 			(Equipment/Wanderer)
    AddCheckpx(255, 85,2)	-- Katana			(Equipment/Wanderer)
    AddCheckpx(130,105,2)	-- R. Caverns Opal	(Equipment/Wanderer)
    AddCheckpx(190, 55,2)	-- Osafune Katana	(Equipment/Wanderer)
    AddCheckpx(265, 60,2)	-- Beryl Circlet	(Equipment/Wanderer)
    AddCheckpx( 70,160,2)	-- R. Library Opal	(Equipment/Wanderer)
    AddCheckpx( 75,160,2)	-- Badelaire		(Equipment/Wanderer)
    AddCheckpx(300,130,1)	-- Telescope / Bottom of Outer Wall		(Tourist/Wanderer)
    AddCheckpx(255, 25,1)	-- Cloaked Knight in Clock Tower		(Tourist/Wanderer)
    AddCheckpx(125,195,1)	-- Waterfall Cave with Frozen Shade		(Tourist/Wanderer)
    AddCheckpx( 80, 90,1)	-- Royal Chapel Confessional			(Tourist/Wanderer)
    AddCheckpx( 95,105,1)	-- Green Tea / Colosseum Fountain		(Tourist/Wanderer)
    AddCheckpx(120,235,2)	-- High Potion / Window Sill			(Tourist/Wanderer)
    AddCheckpx(250,145,2)	-- R. Colosseum Zircon / R. Shield Rod	(Tourist/Wanderer)
    AddCheckpx(155,150,2)	-- Vats / R. Center Clock Room			(Tourist/Wanderer)
    AddCheckpx( 85,145,2)	-- Meal Ticket / R. JoO Switch			(Tourist/Wanderer)
    AddCheckpx(185, 95,2)	-- Library Card / R. Forbidden Route		(Tourist/Wanderer)
    AddCheckpx(135, 60,2)	-- Life Apple / R. Demon Switch Door		(Tourist/Wanderer)
    AddCheckpx(110, 10,2)	-- R. Catacombs Elixir / R. Spike Breaker	(Tourist/Wanderer)
    AddCheckpx(305, 75,2)	-- R. Entrance Antivenom / R. Power of Wolf	(Tourist/Wanderer)
end

-- Add Event
forms.addclick(pbLiveMenu,PictureBoxClick)

-- Add Checks
RelicChecks()
if(CheckSet>=1) then KeyItemChecks()  end
if(CheckSet>=2) then GuardedChecks()  end
if(CheckSet>=3) then SpreadChecks()   end
if(CheckSet>=4  and  CheckSet~=6)     then EquipmentChecks() end -- Don't Add these for Wanderer
if(CheckSet>=5) then TouristChecks()  end
if(CheckSet>=6) then WandererChecks() end

-- Fix Annoying Warning Messages on Bizhawk 2.9 and above.
BizVersion = client.getversion()
if(bizstring.contains(BizVersion,"2.9")) then bit = (require "migration_helpers").EmuHawk_pre_2_9_bit(); end

-- Main Loop
while EndScript == false do
	updateFrame = updateFrame + 1
	if (updateFrame >= 60) then           -- Update every 60 frames
		forms.clear(pbLiveMenu, 0xFF000066) -- Clear the form to remove persistent on-screen text
    UpdateText()
    updateFrame = 0
	end

  updateMap = updateMap + 1
	if(updateMap >= 15) then	-- How often do we update the map. 
		DoCastleMap()
		updateMap = 0
	end

	AutoTimer()
  emu.frameadvance()
end
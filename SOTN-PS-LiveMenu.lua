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
UpdateMap = 0
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

-- Create Window
formLiveMenu = forms.newform(680,620,"SOTN Live Menu",CloseWindow)
pbLiveMenu   = forms.pictureBox(formLiveMenu,0,0,680,620)
forms.drawBox(pbLiveMenu,0,0,680,620, 0xFF000000, 0xFF000066)

function UpdateText()
	txcolor = 0xFFFFFFFF
  bgcolor = 0xFF000066
  squareB = 0xFFFF6666
  circleB = 0xFFFF0000
  bl_txtXpos = 10

--  Room Stuff
    CurrentRoom     = memory.read_u16_le(0x3C760,MainRAM) --Room Count: 942 = 100%, 1890 = 200.6%
    RoomPercent     = math.floor(((CurrentRoom / 942) * 100)*10)/10
    RoomPercentStr  = RoomPercent .. "%"

--  Inventory Stuff
    rightHandSlot   = memory.read_u8(0x097C00,MainRAM)
    leftHandSlot    = memory.read_u8(0x097C04,MainRAM)

    local itemArray = {
      [0] = "Empty Hand",[1] = "Monster Vial 1",[2] = "Monster Vial 2",[3] = "Monster Vial 3",[4] = "Shield Rod",[5] = "Leather Shield",
      [6] = "Knight Shield",[7] = "Iron Shield",[8] = "AxeLord Shield",[9] = "Herald Shield",[10] = "Dark Shield",[11] = "Goddess Shield",
      [12] = "Shaman Shield",[13] = "Medusa Shield",[14] = "Skull Shield",[15] = "Fire Shield",[16] = "Alucard Shield",[17] = "Sword of Dawn",
      [18] = "Basilard",[19] = "Short Sword",[20] = "Combat Knife",[21] = "Nunchacku ",[22] = "Were Bane ",[23] = "Rapier ",[24] = "Karma Coin",
      [25] = "Magic Missile",[26] = "Red Rust",[27] = "Takemitsu ",[28] = "Shotel ",[29] = "Orange",[30] = "Apple",[31] = "Banana",[32] = "Grapes",
      [33] = "Strawberry",[34] = "Pineapple ",[35] = "Peanuts",[36] = "Toadstool",[37] = "Shiitake ",[38] = "Cheesecake",[39] = "Shortcake",
      [40] = "Tart",[41] = "Parfait",[42] = "Pudding",[43] = "Ice Cream",[44] = "Frankfurter",[45] = "Hamburger",[46] = "Pizza",[47] = "Cheese",
      [48] = "Ham And Eggs",[49] = "Omelette ",[50] = "Morning Set",[51] = "Lunch A",[52] = "Lunch B",[53] = "Curry Rice",[54] = "Gyros Plate",
      [55] = "Spaghetti ",[56] = "Grape Juice",[57] = "Barley Tea",[58] = "Green Tea",[59] = "Natou ",[60] = "Ramen",[61] = "Miso Soup",
      [62] = "Sushi",[63] = "Pork Bun",[64] = "Red Bean Bun",[65] = "Chinese Bun",[66] = "Dim Dum Set",[67] = "Pot Roast",[68] = "Sirloin",
      [69] = "Turkey",[70] = "Meal Ticket",[71] = "Neutron Bomb",[72] = "Power of Sire",[73] = "Pentagram",[74] = "Bat Pentagram",[75] = "Shuriken",
      [76] = "Cross Shuriken",[77] = "Buffalo Star",[78] = "Flame Star",[79] = "TNT",[80] = "Bwaka Knife",[81] = "Boomerang",[82] = "Javelin",
      [83] = "Tyrfing ",[84] = "Nakamura ",[85] = "Knuckle Duster",[86] = "Gladius ",[87] = "Scimitar ",[88] = "Cutlass",[89] = "Saber",
      [90] = "Falchion ",[91] = "Broadsword ",[92] = "Bekatowa ",[93] = "Damascus Sword",[94] = "Hunter Sword",[95] = "Estoc",[96] = "Bastard Sword",
      [97] = "Jewel Knuckles",[98] = "Claymore",[99] = "Talwar ",[100] = "Katana",[101] = "Flamberge",[102] = "Iron Fist",[103] = "Zwei Hander",
      [104] = "Sword of Hador",[105] = "Luminus",[106] = "Harper",[107] = "Obsidian Sword",[108] = "Gram",[109] = "Jewel Sword",[110] = "Mormegil ",
      [111] = "Firebrand",[112] = "Thunderbrand",[113] = "Icebrand",[114] = "Stone Sword",[115] = "Holy Sword",[116] = "Terminus Est",
      [117] = "Marsil",[118] = "Dark Blade",[119] = "Heaven Sword",[120] = "Fist of Tulkas",[121] = "Gurthang ",[122] = "Mourneblade",
      [123] = "Alucard Sword",[124] = "Mablung Sword",[125] = "Badelaire ",[126] = "Sword Familiar ",[127] = "Great Sword",[128] = "Mace",
      [129] = "Morning Star",[130] = "Holy Rod",[131] = "Star Flail",[132] = "Moon Rod",[133] = "Chakram ",[134] = "Fire Boomerang",
      [135] = "Iron Ball",[136] = "Holbein Dagger",[137] = "Blue Knuckles",[138] = "Dynamite",[139] = "Osafune Katana",[140] = "Masamune",
      [141] = "Muramasa",[142] = "Heart Refresh",[143] = "Rune sword",[144] = "Anti-Venom",[145] = "Uncurse",[146] = "Life Apple",[147] = "Hammer",
      [148] = "Strength Potion",[149] = "Luck Potion ",[150] = "Smart Potion",[151] = "Attack Potion",[152] = "Shield Potion",[153] = "Resist Fire",
      [154] = "Resist Thunder",[155] = "Resist Ice",[156] = "Resist Stone",[157] = "Resist Holy",[158] = "Resist Dark",[159] = "Potion",
      [160] = "High Potion",[161] = "Elixir",[162] = "Mana Prism",[163] = "Vorpal Blade",[164] = "Crissaegrim",[165] = "Yasutsuna",
      [166] = "Library Card",[167] = "Alucart Shield",[168] = "Alucart Sword",[169] = "Now Make"}

      if itemArray[rightHandSlot] then forms.drawText(pbLiveMenu,bl_txtXpos,400,"Right Hand: " .. itemArray[rightHandSlot],txcolor,bgcolor,20) end
      if itemArray[leftHandSlot]  then forms.drawText(pbLiveMenu,bl_txtXpos,420," Left Hand: " .. itemArray[leftHandSlot], txcolor,bgcolor,20) end

-- Armor Items - Head, Body, Clock, and both Accessories share an item pool
    headSlot   = memory.read_u8(0x097C08,MainRAM)
    armorSlot  = memory.read_u8(0x097C0C,MainRAM)
    cloakSlot  = memory.read_u8(0x097C10,MainRAM)
    otherSlot1 = memory.read_u8(0x097C14,MainRAM)
    otherSlot2 = memory.read_u8(0x097C18,MainRAM)

    armorArray = {
      [0] = "Empty Armor",[1] = "Cloth Tunic",[2] = "Hide Cuirass",[3] = "Bronze Cuirass",[4] = "Iron Cuirass",[5] = "Steel Cuirass",
      [6] = "Silver Plate",[7] = "Gold Plate",[8] = "Platinum Mail",[9] = "Diamond Plate",[10] = "Fire Mail",[11] = "Lightning Mail",
      [12] = "Ice Mail",[13] = "Mirror Cuirass",[14] = "Spike Breaker",[15] = "Alucard Mail",[16] = "Dark Armor",[17] = "Healing Mail",
      [18] = "Holy Mail",[19] = "Walk Armor",[20] = "Brilliant Mail",[21] = "Mojo Mail",[22] = "Fury Plate",[23] = "Dracula Tunic",
      [24] = "God's Garb",[25] = "Axe Lord Armor",[26] = "Empty Head",[27] = "Sunglasses",[28] = "Ballroom Mask",[29] = "Bandanna",[30] = "Felt Hat",
      [31] = "Velvet Hat",[32] = "Googles",[33] = "Leather Hat",[34] = "Holy Glasses",[35] = "Steel Helm",[36] = "Stone Mask",[37] = "Circlet",
      [38] = "Gold Circlet",[39] = "Ruby Circlet",[40] = "Opal Circlet",[41] = "Topaz Circlet",[42] = "Beryl Circlet",[43] = "Cat-Eye Circlet",
      [44] = "Coral Circlet",[45] = "Dragon Helm",[46] = "Silver Crown",[47] = "Wizard Hat",[48] = "Empty Cloak",[49] = "Cloth Cape",
      [50] = "Reverse Cloak ",[51] = "Elven Cloak",[52] = "Crystal Cloak",[53] = "Royal Cloak",[54] = "Blood Cloak",[55] = "Joseph's Cloak",
      [56] = "Twilight Cloak",[57] = "Empty Accessory",[58] = "Moonstone",[59] = "Sunstone",[60] = "Bloodstone",[61] = "Staurolite",
      [62] = "Ring of Pales",[63] = "Zircon",[64] = "Aquamarine ",[65] = "Turquoise ",[66] = "Onyx ",[67] = "Garnet",[68] = "Opal",[69] = "Diamond",
      [70] = "Lapis Lazuli",[71] = "Ring of Ares",[72] = "Gold Ring",[73] = "Silver Ring",[74] = "Ring of Varda",[75] = "Ring of Arcana",
      [76] = "Mystic Pendant",[77] = "Heart Broach",[78] = "Necklace of J",[79] = "Gauntlet ",[80] = "Ankh of Life",[81] = "Ring of Feanor",
      [82] = "Medal",[83] = "Talisman",[84] = "Duplicator",[85] = "King's Stone",[86] = "Covenant Stone",[87] = "Nauglamir",[88] = "Secret Boots",
      [89] = "Alucart Mail"}
      
      if armorArray[headSlot]   then forms.drawText(pbLiveMenu,bl_txtXpos,440,"      Head: " .. armorArray[headSlot],  txcolor,bgcolor,20) end
      if armorArray[armorSlot]  then forms.drawText(pbLiveMenu,bl_txtXpos,460,"     Armor: " .. armorArray[armorSlot], txcolor,bgcolor,20) end
      if armorArray[cloakSlot]  then forms.drawText(pbLiveMenu,bl_txtXpos,480,"     Cloak: " .. armorArray[cloakSlot], txcolor,bgcolor,20) end
      if armorArray[otherSlot1] then forms.drawText(pbLiveMenu,bl_txtXpos,500,"   Other 1: " .. armorArray[otherSlot1],txcolor,bgcolor,20) end
      if armorArray[otherSlot2] then forms.drawText(pbLiveMenu,bl_txtXpos,520,"   Other 2: " .. armorArray[otherSlot2],txcolor,bgcolor,20) end

-- Sub-Weapon Stuff
    subWeaponSlot   = memory.read_u8(0x097BFC,MainRAM) -- 0 Empty | 1 Knife | 2 Axe | 3 Water | 4 Cross | 5 Bible | 6 Watch | 7 Stone | 8 Vibhuti | 9 Agunea
      forms.drawImageRegion(pbLiveMenu,"sw_".. subWeaponSlot ..".png",0,0,100,100,130,180,80,80)

--  Time Stuff
    TimeStr       = ""
      TimeHours   = memory.read_u16_le(0x097C30,MainRAM)
      TimeMinutes = memory.read_u16_le(0x097C34,MainRAM)
      TimeSeconds = memory.read_u16_le(0x097C38,MainRAM)
    TimeStr       = string.format("Time: %02d:%02d:%02d", TimeHours, TimeMinutes, TimeSeconds)

--  Grab values from memory
    CurrentHP   = memory.read_u16_le(0x97BA0,MainRAM)
    MaxHP       = memory.read_u16_le(0x97BA4,MainRAM)
    CurrentMP   = memory.read_u16_le(0x97BB0,MainRAM)
    MaxMP       = memory.read_u16_le(0x97BB4,MainRAM)
    CurrentHrt  = memory.read_u16_le(0x97BA8,MainRAM)
    MaxHeart    = memory.read_u16_le(0x97BAC,MainRAM)
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
    HPStr     = "HP    " .. CurrentHP   .. "/ " .. MaxHP
    MPStr     = "MP    " .. CurrentMP   .. "/ " .. MaxMP
    HeartStr  = "HEART " .. CurrentHrt  .. "/ " .. MaxHeart
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
    PositionDataStr = "z:" .. Zone .. " | cX:" .. castleX .. " | cY:" .. castleY .. " | rX:" .. roomX .. " | rY:" .. roomY

  --Draw Alucard
  --Todo: Create several versions to denote Stoned, Cursed, Low HP
    forms.drawImageRegion(pbLiveMenu,"alucard_portrait.png",0,0,335,635,10,10,120,250)

  --Start Menu Text Items  
  --forms.drawText(PictureBoxToDrawOn,xxx,yyy,variable,txtColor, bgColor, txtSize)
  local tl_txtXpos = 200
  local tr_txtXpos = 400

    -- Top Left Side 
    forms.drawText(pbLiveMenu,tl_txtXpos,10,"ALUCARD",txcolor,bgcolor,20)
    if (CurrentHP<(MaxHP*0.25)) then forms.drawText(pbLiveMenu,tl_txtXpos,50,HPStr,0xFFDFB50B,bgcolor,20) -- If HP goes below 25% max HP, show orange caution color
      else forms.drawText(pbLiveMenu,tl_txtXpos,50,HPStr,txcolor,bgcolor,20) end

    forms.drawText(pbLiveMenu,tl_txtXpos, 70,MPStr,    txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tl_txtXpos, 90,HeartStr, txcolor,bgcolor,20)

    forms.drawText(pbLiveMenu,tl_txtXpos,120,StrStr,   txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tl_txtXpos,140,ConStr,   txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tl_txtXpos,160,IntStr,   txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tl_txtXpos,180,LckStr,   txcolor,bgcolor,20)

    forms.drawText(pbLiveMenu,tl_txtXpos,240,XPStr,    txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tl_txtXpos,260,NextXPStr,txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tl_txtXpos,280,GoldStr,  txcolor,bgcolor,20)

    -- Top Right Side
    forms.drawText(pbLiveMenu,tr_txtXpos, 10,LevelStr, txcolor,bgcolor,20)
    
    -- ATT Stats
    --Todo: Hands seem to set attack to non-zero when it should be 0 sometimes; might be rounding error. Might need more investigation
    forms.drawText(pbLiveMenu,tr_txtXpos,120,"ATT ",   txcolor,bgcolor,40)
      forms.drawText(pbLiveMenu,500,120,AttackLeftStr, squareB,bgcolor,20)
      forms.drawText(pbLiveMenu,530,120,AttackLeft,    txcolor,bgcolor,20)
      forms.drawText(pbLiveMenu,500,140,AttackRightStr,circleB,bgcolor,20)
      forms.drawText(pbLiveMenu,530,140,AttackRight,   txcolor,bgcolor,20)
    -- DEF Stats
    forms.drawText(pbLiveMenu,tr_txtXpos,160,"DEF ", txcolor,bgcolor,40)
      forms.drawText(pbLiveMenu,500,180,DefStr,      txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tr_txtXpos,240,RoomStr,txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tr_txtXpos,260,KillStr,txcolor,bgcolor,20)
    forms.drawText(pbLiveMenu,tr_txtXpos,280,TimeStr,txcolor,bgcolor,20)

    forms.drawText(pbLiveMenu,10,600,PositionDataStr,  txcolor,bgcolor,15)
    forms.refresh(pbLiveMenu)
end

-- Fix Annoying Warning Messages on Bizhawk 2.9 and above.
BizVersion = client.getversion()
if(bizstring.contains(BizVersion,"2.9")) then bit = (require "migration_helpers").EmuHawk_pre_2_9_bit(); end

-- Main Loop
while EndScript == false do
	updateFrame = updateFrame + 1
	if (updateFrame >= 60) then
		forms.clear(pbLiveMenu, 0xFF000066)
    UpdateText()
    updateFrame = 0
	end

  emu.frameadvance()
end
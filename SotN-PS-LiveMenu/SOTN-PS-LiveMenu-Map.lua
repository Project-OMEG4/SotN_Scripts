-- Castlevania SOTN Live Menu
-- Written By Project_OMEG4
-- Based on Mottzilla's LiveMap code
-- Useful Links
-- For Built-in Lua functions for Bizhawk: https://tasvideos.org/Bizhawk/LuaFunctions
-- Item/Armor Addresses: https://docs.google.com/spreadsheets/d/1w01w-ocIN2jIxHU67yK5QGVcdCNXNmabEJxmco_2xTo/edit?usp=sharing

EndScript = false

function CloseWindow()
	forms.destroy(formLiveMenu)
	console.log("Window Closed!")
	EndScript = true
end

-- Global Variables
NextXP          = 0
currentLvl      = 0
currentXP       = 0
updateFrames    = 0
mem_u16         = memory.read_u16_le
mem_u8          = memory.read_u8
bgcolor         = 0xFF000066

-- Create Window
formLiveMenu = forms.newform(700,700,"SOTN Live Menu 2",CloseWindow)
pbLiveMenu   = forms.pictureBox(formLiveMenu,0,0,700,700)
forms.drawBox(pbLiveMenu,0,0,700,700, 0xFF000000, bgcolor)

function UpdateText()

	txcolor = 0xFFFFFFFF
        squareB = 0xFFFF6666
        circleB = 0xFFFF0000
        invFontSize = 16

        -- Alucard General Stats
        -------------------------------------------------------------------------
        genStats_x = 200
        genStats_y = 50

        --Draw Alucard
        --Todo: Create several versions to denote Stoned, Cursed, Low HP
        forms.drawImageRegion(pbLiveMenu,"alucard_portrait.png",0,0,335,635,10,10,120,250)
        forms.drawText(pbLiveMenu,genStats_x,10,"ALUCARD",txcolor,bgcolor,20)

        -- HP Data
        currentHP = mem_u16(0x97BA0,MainRAM)
        MaxHP     = mem_u16(0x97BA4,MainRAM)
        HPString     = "HP    " .. currentHP   .. "/ " .. MaxHP
        lowHPcolor  = 0xFFDFB50B -- Orange for low health
        hpColor  = currentHP < MaxHP * 0.25 and lowHPcolor or txcolor
        forms.drawText(pbLiveMenu, genStats_x, genStats_y, HPString, hpColor, bgcolor, 18)
        genStats_y = genStats_y + 20

        -- MP Data
        currentMP = mem_u16(0x97BB0,MainRAM)
        MaxMP     = mem_u16(0x97BB4,MainRAM)
        MPString  = "MP    " .. currentMP   .. "/ " .. MaxMP
        forms.drawText(pbLiveMenu,genStats_x, genStats_y,MPString,txcolor,bgcolor,18)
        genStats_y = genStats_y + 20

        -- Hearts
        currentHrt  = mem_u16(0x97BA8,MainRAM)
        MaxHeart    = mem_u16(0x97BAC,MainRAM)
        HeartString = "HEART " .. currentHrt  .. "/ " .. MaxHeart
        forms.drawText(pbLiveMenu,genStats_x, genStats_y,HeartString, txcolor,bgcolor,18)
        genStats_y = genStats_y + 20

        -- Stats
        -- Strength
        currentStr      = mem_u16(0x97BB8,MainRAM)
        StrBuff         = memory.read_s8(0x97BC8,MainRAM)
        StrBuffString   = (math.abs(StrBuff) < 10 and " " or "") .. StrBuff
        StrString       = "STR   " .. currentStr .. (StrBuff < 0 and "" or " +") .. StrBuffString
        forms.drawText(pbLiveMenu,genStats_x,130,StrString,txcolor,bgcolor,18)

        -- Constitution
        currentCon      = mem_u16(0x97BBC,MainRAM)
        ConBuff         = memory.read_s8(0x97BCC,MainRAM)
        ConBuffString   = (math.abs(ConBuff) < 10 and " " or "") .. ConBuff
        ConString       = "CON   " .. currentCon .. (ConBuff < 0 and "" or " +") .. ConBuffString
        forms.drawText(pbLiveMenu,genStats_x,150,ConString,txcolor,bgcolor,18)

        -- Intelligence
        currentInt      = mem_u16(0x97BC0,MainRAM)
        IntBuff         = memory.read_s8(0x97BD0,MainRAM)
        IntBuffString   = (math.abs(IntBuff) < 10 and " " or "") .. IntBuff
        IntString       = "INT   " .. currentInt .. (IntBuff < 0 and "" or " +") .. IntBuffString
        forms.drawText(pbLiveMenu,genStats_x,170,IntString,txcolor,bgcolor,18)

        -- Luck
        currentLck      = mem_u16(0x97BC4,MainRAM)
        LuckBuff        = memory.read_s8(0x97BD4,MainRAM)
        LuckBuffString  = (math.abs(LuckBuff) < 10 and " " or "") .. LuckBuff
        LckString       = "LCK   " .. currentLck .. (LuckBuff < 0 and "" or " +") .. LuckBuffString
        forms.drawText(pbLiveMenu,genStats_x,190,LckString,txcolor,bgcolor,18)

        -- Current XP
        currentXP       = memory.read_u24_le(0x97BEC,MainRAM)
        currentLvl      = mem_u16(0x97BE8,MainRAM)
        XPString        = "EXP   " .. currentXP
        forms.drawText(pbLiveMenu,genStats_x,220,XPString,txcolor,bgcolor,18)

        -- Next XP
        -- How much XP is needed until the next level up. I couldnt find the memory address for this, so we calculate it
        xpArray   = {
                   100,   250,   450,   700,  1000,  1350,  1750,  2200,  2700,  3250,  3850,  4500,  5200,  5950, -- Level 02 - 15
                  6750,  7600,  8500,  9450, 10450, 11700, 13200, 15100, 17500, 20400, 23700, 27200, 30900, 35000, -- Level 16 - 29
                 39500, 44500, 50000, 56000, 61500, 68500, 76000, 84000, 92500,101500,110000,120000,130000,140000, -- Level 30 - 43
                150000,160000,170000,180000,190000,200000,210000,222000,234000,246000,258000,270000,282000,294000, -- Level 44 - 57
                306000,318000,330000,344000,358000,372000,386000,400000,414000,428000,442000,456000,470000,486000, -- Level 58 - 71
                502000,518000,534000,550000,566000,582000,598000,614000,630000,648000,666000,684000,702000,720000, -- Level 72 - 85
                738000,756000,774000,792000,810000,830000,850000,870000,890000,910000,930000,950000,970000,999999  -- Level 86 - 99
        }
        NextXP          = xpArray[currentLvl] - currentXP
        NextXPString    = "NEXT  " .. NextXP
        forms.drawText(pbLiveMenu,genStats_x,240,NextXPString,txcolor,bgcolor,18)

        -- Current Gold Count
        currentGold = memory.read_u24_le(0x97BF0,MainRAM)
        GoldString  = "GOLD  " .. currentGold
        forms.drawText(pbLiveMenu,genStats_x,260,GoldString,  txcolor,bgcolor,18)

        -------------------------------------------------------------------------
        -- Top Right Side
        -------------------------------------------------------------------------
        tr_x = 420

        -- Levels
        levelString     = "LEVEL " .. currentLvl
        forms.drawText(pbLiveMenu,tr_x, 10,levelString, txcolor,bgcolor,20)

        -- Status
        statusArray = {
                [0] = "GOOD",[1] = "BAT",[2] = "MIST",[4] = "WOLF",[32] = "CROUCH",[128] = "STONE"
        }
        currentStatus   = mem_u8(0x072F2C, MainRAM)
        IsPoisoned      = mem_u8(0x072F00, MainRAM)
        IsCursed        = mem_u8(0x072F02, MainRAM)
        statusString    = statusArray[currentStatus] or currentStatus
        if (IsPoisoned > 0) then statusString = "POISON" end
        if (IsCursed > 0) then statusString = "CURSE" end

        forms.drawText(pbLiveMenu,tr_x,50,"STATUS\n   "..statusString,txcolor,bgcolor,20)
        --forms.drawText(pbLiveMenu,tr_x, 50,"STATUS"..string.char(10).."   "..statusString, txcolor,bgcolor,20)

        -- ATT Stats
        --Todo: Hands seem to set attack to non-zero when it should be; need more investigation
        attLeftString   = " □ "
        attRightString  = " O "
        AttackLeft      = mem_u16(0x97C1C,MainRAM)
        AttackRight     = mem_u16(0x97C20,MainRAM)
        forms.drawText(pbLiveMenu,tr_x,108,"ATT ",        txcolor,bgcolor,40)
        forms.drawText(pbLiveMenu,500, 110,attLeftString, squareB,bgcolor,18)
        forms.drawText(pbLiveMenu,530, 110,AttackLeft,    txcolor,bgcolor,18)
        forms.drawText(pbLiveMenu,500, 130,attRightString,circleB,bgcolor,18)
        forms.drawText(pbLiveMenu,530, 130,AttackRight,   txcolor,bgcolor,18)

        -- DEF Stats
        currentDef      = mem_u16(0x97C24,MainRAM)
        DefString       = "  " .. currentDef
        forms.drawText(pbLiveMenu,tr_x,150,"DEF ",   txcolor,bgcolor,40)
        forms.drawText(pbLiveMenu,500, 170,DefString,txcolor,bgcolor,18)

        --  Room Data
        currentRoom     = mem_u16(0x3C760,MainRAM) --Count: 942 = 100%, 1890 = 200.6%
        roomString      = string.format("ROOMS %d (%.1f%%)", currentRoom, (currentRoom / 942) * 100)
        forms.drawText(pbLiveMenu,tr_x,220,roomString,txcolor,bgcolor,18)

        -- Kills
        currentKill     = mem_u16(0x97BF4,MainRAM)
        killString      = "KILLS " .. currentKill
        forms.drawText(pbLiveMenu,tr_x,240,killString,txcolor,bgcolor,18)

        -- In Game Time
        timeHours       = mem_u16(0x097C30,MainRAM)
        timeMinutes     = mem_u16(0x097C34,MainRAM)
        timeSeconds     = mem_u16(0x097C38,MainRAM)
        timeString      = string.format("Time  %02d:%02d:%02d", timeHours, timeMinutes, timeSeconds)
        forms.drawText(pbLiveMenu,tr_x,260,timeString,txcolor,bgcolor,18)

        -------------------------------------------------------------------------
        -- Bottom Left Side - Inventory
        -------------------------------------------------------------------------
        invX = 10
        invY = 275

        --  Inventory 
        forms.drawText(pbLiveMenu,invX+30,invY,"Inventory",txcolor,bgcolor,20)

        invY = invY + 25 -- 300

        itemArray       = {
                  [0]="Empty Hand",      [1]="Monster Vial 1", [2]="Monster Vial 2", [3]="Monster Vial 3", [4]="Shield Rod",      [5]="Leather Shield", [6]="Knight Shield",   [7]="Iron Shield",     [8]="AxeLord Shield",   [9]="Herald Shield",
                 [10]="Dark Shield",    [11]="Goddess Shield",[12]="Shaman Shield", [13]="Medusa Shield", [14]="Skull Shield",   [15]="Fire Shield",   [16]="Alucard Shield", [17]="Sword of Dawn",  [18]="Basilard",        [19]="Short Sword",
                 [20]="Combat Knife",   [21]="Nunchacku",     [22]="Were Bane",     [23]="Rapier",        [24]="Karma Coin",     [25]="Magic Missile", [26]="Red Rust",       [27]="Takemitsu",      [28]="Shotel",          [29]="Orange",
                 [30]="Apple",          [31]="Banana",        [32]="Grapes",        [33]="Strawberry",    [34]="Pineapple",      [35]="Peanuts",       [36]="Toadstool",      [37]="Shiitake",       [38]="Cheesecake",      [39]="Shortcake",
                 [40]="Tart",           [41]="Parfait",       [42]="Pudding",       [43]="Ice Cream",     [44]="Frankfurter",    [45]="Hamburger",     [46]="Pizza",          [47]="Cheese",         [48]="Ham And Eggs",    [49]="Omelette",
                 [50]="Morning Set",    [51]="Lunch A",       [52]="Lunch B",       [53]="Curry Rice",    [54]="Gyros Plate",    [55]="Spaghetti",     [56]="Grape Juice",    [57]="Barley Tea",     [58]="Green Tea",       [59]="Natou",
                 [60]="Ramen",          [61]="Miso Soup",     [62]="Sushi",         [63]="Pork Bun",      [64]="Red Bean Bun",   [65]="Chinese Bun",   [66]="Dim Dum Set",    [67]="Pot Roast",      [68]="Sirloin",         [69]="Turkey",
                 [70]="Meal Ticket",    [71]="Neutron Bomb",  [72]="Power of Sire", [73]="Pentagram",     [74]="Bat Pentagram",  [75]="Shuriken",      [76]="Cross Shuriken", [77]="Buffalo Star",   [78]="Flame Star",      [79]="TNT",
                 [80]="Bwaka Knife",    [81]="Boomerang",     [82]="Javelin",       [83]="Tyrfing",       [84]="Nakamura",       [85]="Knuckle Duster",[86]="Gladius",        [87]="Scimitar",       [88]="Cutlass",         [89]="Saber",
                 [90]="Falchion",       [91]="Broadsword",    [92]="Bekatowa",      [93]="Damascus Sword",[94]="Hunter Sword",   [95]="Estoc",         [96]="Bastard Sword",  [97]="Jewel Knuckles", [98]="Claymore",        [99]="Talwar",
                [100]="Katana",        [101]="Flamberge",    [102]="Iron Fist",    [103]="Zwei Hander",  [104]="Sword of Hador",[105]="Luminus",      [106]="Harper",        [107]="Obsidian Sword",[108]="Gram",           [109]="Jewel Sword",
                [110]="Mormegil",      [111]="Firebrand",    [112]="Thunderbrand", [113]="Icebrand",     [114]="Stone Sword",   [115]="Holy Sword",   [116]="Terminus Est",  [117]="Marsil",        [118]="Dark Blade",     [119]="Heaven Sword",
                [120]="Fist of Tulkas",[121]="Gurthang",     [122]="Mourneblade",  [123]="Alucard Sword",[124]="Mablung Sword", [125]="Badelaire",    [126]="Sword Familiar",[127]="Great Sword",   [128]="Mace",           [129]="Morning Star",
                [130]="Holy Rod",      [131]="Star Flail",   [132]="Moon Rod",     [133]="Chakram",      [134]="Fire Boomerang",[135]="Iron Ball",    [136]="Holbein Dagger",[137]="Blue Knuckles", [138]="Dynamite",       [139]="Osafune Katana",
                [140]="Masamune",      [141]="Muramasa",     [142]="Heart Refresh",[143]="Rune sword",   [144]="Anti-Venom",    [145]="Uncurse",      [146]="Life Apple",    [147]="Hammer",        [148]="Strength Potion",[149]="Luck Potion",
                [150]="Smart Potion",  [151]="Attack Potion",[152]="Shield Potion",[153]="Resist Fire",  [154]="Resist Thunder",[155]="Resist Ice",   [156]="Resist Stone",  [157]="Resist Holy",   [158]="Resist Dark",    [159]="Potion",
                [160]="High Potion",   [161]="Elixir",       [162]="Mana Prism",   [163]="Vorpal Blade", [164]="Crissaegrim",   [165]="Yasutsuna",    [166]="Library Card",  [167]="Alucart Shield",[168]="Alucart Sword"
        }

        -- Right Hand Slot
        rightHandSlot   = mem_u8(0x097C00,MainRAM)
        if itemArray[rightHandSlot] then
                forms.drawImageRegion(pbLiveMenu,"rhand.png",0,0,20,20,invX,invY,20,20)
                forms.drawImageRegion(pbLiveMenu,"items/".. rightHandSlot ..".png",0,0,20,20,invX+20,invY,20,20)
                forms.drawText(pbLiveMenu,invX+40,invY,itemArray[rightHandSlot],txcolor,bgcolor,invFontSize)
        end

        invY = invY + 20 -- 320

        -- Left Hand Slot
        leftHandSlot    = mem_u8(0x097C04,MainRAM)
        if itemArray[leftHandSlot] then
                forms.drawImageRegion(pbLiveMenu,"lhand.png",0,0,20,20,invX,invY,20,20)
                forms.drawImageRegion(pbLiveMenu,"items/".. leftHandSlot ..".png",0,0,20,20,invX+20,invY,20,20)
                forms.drawText(pbLiveMenu,invX+40,invY,itemArray[leftHandSlot],txcolor,bgcolor,invFontSize)
        end

        -- Armor Items - Head, Body, Clock, and both Accessories share an item pool
        armorArray      = {
                 [0]="Empty Armor",    [1]="Cloth Tunic",    [2]="Hide Cuirass",  [3]="Bronze Cuirass",  [4]="Iron Cuirass",  [5]="Steel Cuirass",  [6]="Silver Plate",   [7]="Gold Plate",      [8]="Platinum Mail", [9]="Diamond Plate",
                [10]="Fire Mail",     [11]="Lightning Mail",[12]="Ice Mail",     [13]="Mirror Cuirass", [14]="Spike Breaker",[15]="Alucard Mail",  [16]="Dark Armor",    [17]="Healing Mail",   [18]="Holy Mail",    [19]="Walk Armor",
                [20]="Brilliant Mail",[21]="Mojo Mail",     [22]="Fury Plate",   [23]="Dracula Tunic",  [24]="God's Garb",   [25]="Axe Lord Armor",[26]="Empty Head",    [27]="Sunglasses",     [28]="Ballroom Mask",[29]="Bandanna",
                [30]="Felt Hat",      [31]="Velvet Hat",    [32]="Googles",      [33]="Leather Hat",    [34]="Holy Glasses", [35]="Steel Helm",    [36]="Stone Mask",    [37]="Circlet",        [38]="Gold Circlet", [39]="Ruby Circlet",  
                [40]="Opal Circlet",  [41]="Topaz Circlet", [42]="Beryl Circlet",[43]="Cat-Eye Circlet",[44]="Coral Circlet",[45]="Dragon Helm",   [46]="Silver Crown",  [47]="Wizard Hat",     [48]="Empty Cloak",  [49]="Cloth Cape",
                [50]="Reverse Cloak", [51]="Elven Cloak",   [52]="Crystal Cloak",[53]="Royal Cloak",    [54]="Blood Cloak",  [55]="Joseph's Cloak",[56]="Twilight Cloak",[57]="Empty Accessory",[58]="Moonstone",    [59]="Sunstone",
                [60]="Bloodstone",    [61]="Staurolite",    [62]="Ring of Pales",[63]="Zircon",         [64]="Aquamarine",   [65]="Turquoise",     [66]="Onyx",          [67]="Garnet",         [68]="Opal",         [69]="Diamond",     
                [70]="Lapis Lazuli",  [71]="Ring of Ares",  [72]="Gold Ring",    [73]="Silver Ring",    [74]="Ring of Varda",[75]="Ring of Arcana",[76]="Mystic Pendant",[77]="Heart Broach",   [78]="Necklace of J",[79]="Gauntlet",
                [80]="Ankh of Life",  [81]="Ring of Feanor",[82]="Medal",        [83]="Talisman",       [84]="Duplicator",   [85]="King's Stone",  [86]="Covenant Stone",[87]="Nauglamir",      [88]="Secret Boots", [89]="Alucart Mail"
        }
        invY = invY + 20 -- 340

        -- Head Slot
        headSlot        = mem_u8(0x097C08,MainRAM)
        if armorArray[headSlot] then
                forms.drawImageRegion(pbLiveMenu,"head.png",0,0,20,20,invX,invY,20,20)
                forms.drawImageRegion(pbLiveMenu,"armor/".. headSlot ..".png",0,0,20,20,invX+20,invY,20,20)
                forms.drawText(pbLiveMenu,invX+40,invY,armorArray[headSlot],  txcolor,bgcolor,invFontSize)
        end

        invY = invY + 20 -- 360

        -- Armor Slot
        armorSlot       = mem_u8(0x097C0C,MainRAM)
        if armorArray[armorSlot] then
                forms.drawImageRegion(pbLiveMenu,"armor.png",0,0,20,20,invX,invY,20,20)
                forms.drawImageRegion(pbLiveMenu,"armor/".. armorSlot ..".png",0,0,20,20,invX+20,invY,20,20)
                forms.drawText(pbLiveMenu,invX+40,invY,armorArray[armorSlot], txcolor,bgcolor,invFontSize)
        end

        invY = invY + 20 -- 380

        -- Cloak Slot
        cloakSlot       = mem_u8(0x097C10,MainRAM)
        if armorArray[cloakSlot]  then
                forms.drawImageRegion(pbLiveMenu,"other.png",0,0,20,20,invX,invY,20,20)
                forms.drawImageRegion(pbLiveMenu,"armor/".. cloakSlot ..".png",0,0,20,20,invX+20,invY,20,20)
                forms.drawText(pbLiveMenu,invX+40,invY,armorArray[cloakSlot], txcolor,bgcolor,invFontSize)
        end

        invY = invY + 20 -- 400

        -- Other Slot 1
        otherSlot1      = mem_u8(0x097C14,MainRAM)
        if armorArray[otherSlot1] then
                forms.drawImageRegion(pbLiveMenu,"other.png",0,0,20,20,invX,invY,20,20)
                forms.drawImageRegion(pbLiveMenu,"armor/".. otherSlot1 ..".png",0,0,20,20,invX+20,invY,20,20)
                forms.drawText(pbLiveMenu,invX+40,invY,armorArray[otherSlot1],txcolor,bgcolor,invFontSize)
        end

        invY = invY + 20 -- 420

        -- Other Slot 2
        otherSlot2      = mem_u8(0x097C18,MainRAM)
        if armorArray[otherSlot2] then
                forms.drawImageRegion(pbLiveMenu,"other.png",0,0,20,20,invX,invY,20,20)
                forms.drawImageRegion(pbLiveMenu,"armor/".. otherSlot2 ..".png",0,0,20,20,invX+20,invY,20,20)
                forms.drawText(pbLiveMenu,invX+40,invY,armorArray[otherSlot2],txcolor,bgcolor,invFontSize)
        end

        invY = invY + 20 -- 440

        -- Sub-Weapons
        -- 0 Empty | 1 Knife | 2 Axe | 3 Holy Water | 4 Holy Cross | 5 Holy Bible | 6 Stopwatch | 7 Rebound Stone | 8 Vibhuti | 9 Agunea
        -- The subWeaponArray is to calculate the number of hearts each sub-weapon uses, to then calculate how many total can be used.
        subWeaponSlot = mem_u8(0x097BFC,MainRAM)
        subWeaponArray = {[0]=0,[1]=1,[2]=4,[3]=3,[4]=100,[5]=5,[6]=20,[7]=2,[8]=3,[9]=5}
        subWeaponCost = subWeaponArray[subWeaponSlot]
        if (subWeaponCost==0) then
                subWeaponUses = 0
                forms.drawText(pbLiveMenu,130,230,"(".. subWeaponUses .." left)",txcolor,bgcolor,12)
        else
                subWeaponUses = math.floor(currentHrt/subWeaponCost)
                forms.drawText(pbLiveMenu,130,230,"(".. subWeaponUses .." left)",txcolor,bgcolor,12)
        end
        forms.drawImageRegion(pbLiveMenu,"subweapons/sw_blank.png",0,0,20,20,invX,invY,20,20)
        forms.drawImageRegion(pbLiveMenu,"subweapons/sw_".. subWeaponSlot .."_20x20.png",0,0,20,20,invX+20,invY,20,20)
        forms.drawText(pbLiveMenu,invX+40,invY," -".. subWeaponCost .." ♥",txcolor,bgcolor,12)

        -------------------------------------------------------------------------
        -- Bottom Right Side - Familiar Area
        -------------------------------------------------------------------------
        brsX1 = 240
        brsX2 = 450
        ffont = 13

        forms.drawImage(pbLiveMenu,"f_box_thin_grey_n_gold.png",200,330) -- Image wrapper around familiars
        forms.drawText(pbLiveMenu,380,360,"Familiars", txcolor,bgcolor,20)

        -- Sword Familiar
        f_sword         = mem_u8(0x09797A,MainRAM)
        f_swordXP       = mem_u16(0x097C78,MainRAM)
        f_swordLevel    = (f_swordXP < 1) and 1 or 1 + math.floor(f_swordXP / 100)
        f_swordExp      = (f_swordXP < 1) and 0 or 100 - ((f_swordLevel * 100) - f_swordXP)
        if (f_sword==0) then forms.drawImageRegion(pbLiveMenu,"familiars/no_f_sword1.png",0,0,58,140,brsX1+10,400,30,80) end
        if (f_sword==1) then forms.drawImageRegion(pbLiveMenu,"familiars/gf_sword1.png",  0,0,58,140,brsX1+10,400,30,80) end
        if (f_sword==3) then forms.drawImageRegion(pbLiveMenu,"familiars/f_sword1.png",   0,0,58,140,brsX1+10,400,30,80) end
        forms.drawText(pbLiveMenu,brsX1+60,420,"Level:    "..f_swordLevel,txcolor,bgcolor,ffont)
        forms.drawText(pbLiveMenu,brsX1+60,440,"Next  XP: "..f_swordExp,  txcolor,bgcolor,ffont)

        -- Bat Familiar
        f_bat           = mem_u8(0x097976,MainRAM)
        f_batXP         = mem_u16(0x097C48,MainRAM)
        f_batLevel      = (f_batXP < 1) and 1 or 1 + math.floor(f_batXP / 100)
        f_batExp        = (f_batXP < 1) and 0 or 100 - ((f_batLevel * 100) - f_batXP)
        if (f_bat==0) then forms.drawImageRegion(pbLiveMenu,"familiars/no_f_bat.png",0,0,58,66,brsX2+10,400,30,33) end
        if (f_bat==1) then forms.drawImageRegion(pbLiveMenu,"familiars/gf_bat.png",  0,0,58,66,brsX2+10,400,30,33) end
        if (f_bat==3) then forms.drawImageRegion(pbLiveMenu,"familiars/f_bat.png",   0,0,58,66,brsX2+10,400,30,33) end
        forms.drawText(pbLiveMenu,brsX2+60,400,"Level:    "..f_batLevel,txcolor,bgcolor,ffont)
        forms.drawText(pbLiveMenu,brsX2+60,420,"Next  XP: "..f_batExp,  txcolor,bgcolor,ffont)

        -- Ghost Familiar
        f_ghost         = mem_u8(0x097977,MainRAM)
        f_ghostXP       = mem_u16(0x097C54,MainRAM)
        f_ghostLevel    = (f_ghostXP < 1) and 1 or 1 + math.floor(f_ghostXP / 100)
        f_ghostExp      = (f_ghostXP < 1) and 0 or 100 - ((f_ghostLevel * 100) - f_ghostXP)
        if (f_ghost==0) then forms.drawImageRegion(pbLiveMenu,"familiars/no_f_ghost.png",0,0,58,66,brsX2+10,460,30,33) end
        if (f_ghost==1) then forms.drawImageRegion(pbLiveMenu,"familiars/gf_ghost.png",  0,0,58,66,brsX2+10,460,30,33) end
        if (f_ghost==3) then forms.drawImageRegion(pbLiveMenu,"familiars/f_ghost.png",   0,0,58,66,brsX2+10,460,30,33) end
        forms.drawText(pbLiveMenu,brsX2+60,460,"Level:    "..f_ghostLevel,txcolor,bgcolor,ffont)
        forms.drawText(pbLiveMenu,brsX2+60,480,"Next  XP: "..f_ghostExp,  txcolor,bgcolor,ffont)

        -- Fairy & Sprite familiars
        f_fairy         = mem_u8(0x097978,MainRAM)
        f_sprite        = mem_u8(0x09797B,MainRAM)
        f_fairyXP       = mem_u16(0x097C60,MainRAM)
        f_spriteXP      = mem_u16(0x097C84,MainRAM)
        f_fairyLevel    = (f_fairyXP < 1) and 1 or 1 + math.floor(f_fairyXP / 100)
        f_fairyExp      = (f_fairyXP < 1) and 0 or 100 - ((f_fairyLevel * 100) - f_fairyXP)
        f_spriteLevel   = (f_spriteXP < 1) and 1 or 1 + math.floor(f_spriteXP / 100)
        f_spriteExp     = (f_spriteXP < 1) and 0 or 100 - ((f_spriteLevel * 100) - f_spriteXP)
        if (f_fairy==0)  then forms.drawImageRegion(pbLiveMenu,"familiars/no_f_fairy.png", 0,0,58,66,brsX1,   520,30,33) end
        if (f_sprite==0) then forms.drawImageRegion(pbLiveMenu,"familiars/no_f_sprite.png",0,0,58,66,brsX1+30,520,30,33) end
        if (f_fairy==1)  then forms.drawImageRegion(pbLiveMenu,"familiars/gf_fairy.png",   0,0,58,66,brsX1,   520,30,33) end
        if (f_sprite==1) then forms.drawImageRegion(pbLiveMenu,"familiars/gf_sprite.png",  0,0,58,66,brsX1+30,520,30,33) end
        if (f_fairy==3)  then forms.drawImageRegion(pbLiveMenu,"familiars/f_fairy.png",    0,0,58,66,brsX1,   520,30,33) end
        if (f_sprite==3) then forms.drawImageRegion(pbLiveMenu,"familiars/f_sprite.png",   0,0,58,66,brsX1+30,520,30,33) end
        forms.drawText(pbLiveMenu,brsX1+65,520,"Level:    "..f_fairyLevel.." | "..f_spriteLevel,txcolor,bgcolor,ffont)
        forms.drawText(pbLiveMenu,brsX1+65,540,"Next  XP: "..f_fairyExp.." | "..f_spriteExp,  txcolor,bgcolor,ffont)

        -- Demon & Nose Demon Familiar
        f_demon         = mem_u8(0x097979,MainRAM)
        f_nose          = mem_u8(0x09797C,MainRAM)
        f_demonXP       = mem_u16(0x097C6C,MainRAM)
        f_noseXP        = mem_u16(0x097C90,MainRAM)
        f_demonLevel    = (f_demonXP < 1) and 1 or 1 + math.floor(f_demonXP / 100)
        f_demonExp      = (f_demonXP < 1) and 0 or 100 - ((f_demonLevel * 100) - f_demonXP)
        f_noseLevel     = (f_noseXP < 1) and 1 or 1 + math.floor(f_noseXP / 100)
        f_noseExp       = (f_noseXP < 1) and 0 or 100 - ((f_noseLevel * 100) - f_noseXP)
        if (f_demon==0) then forms.drawImageRegion(pbLiveMenu,"familiars/no_f_demon.png",0,0,58,66,brsX2,   520,30,33) end
        if (f_nose==0)  then forms.drawImageRegion(pbLiveMenu,"familiars/no_f_nose.png", 0,0,58,66,brsX2+30,520,30,33) end
        if (f_demon==1) then forms.drawImageRegion(pbLiveMenu,"familiars/gf_demon.png",  0,0,58,66,brsX2,   520,30,33) end
        if (f_nose==1)  then forms.drawImageRegion(pbLiveMenu,"familiars/gf_nose.png",   0,0,58,66,brsX2+30,520,30,33) end
        if (f_demon==3) then forms.drawImageRegion(pbLiveMenu,"familiars/f_demon.png",   0,0,58,66,brsX2,   520,30,33) end
        if (f_nose==3)  then forms.drawImageRegion(pbLiveMenu,"familiars/f_nose.png",    0,0,58,66,brsX2+30,520,30,33) end
        forms.drawText(pbLiveMenu,brsX2+65,520,"Level:    "..f_demonLevel.." | "..f_noseLevel,txcolor,bgcolor,ffont)
        forms.drawText(pbLiveMenu,brsX2+65,540,"Next  XP: "..f_demonExp.." | "..f_noseExp,  txcolor,bgcolor,ffont)

        -- Version
        forms.drawText(pbLiveMenu,10,625,"Ver 0.1.5",txcolor,bgcolor,10)

        forms.refresh(pbLiveMenu) -- Refresh the form
end

-- Fix Annoying Warning Messages on Bizhawk 2.9 and above.
BizVersion = client.getversion()
if(bizstring.contains(BizVersion,"2.9")) then bit = (require "migration_helpers").EmuHawk_pre_2_9_bit(); end

-- Main Loop
while EndScript == false do
        updateFrames = updateFrames + 1
        if (updateFrames >= 60) then --Update every 60 frames
                forms.clear(pbLiveMenu, 0xFF000066) -- Clear the form to remove persistent on-screen text
                UpdateText()
                updateFrames = 0
        end
        emu.frameadvance()
end
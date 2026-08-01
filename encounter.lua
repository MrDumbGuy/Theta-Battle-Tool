--And so begins the dreaded "refactor".
--With this new object I aim to turn this project into a proper engine
--[[Goals I have with this file:

    1) Many previously global variables will be pulled from the encounter object
    2) The code here will serve as an example encounter to modify
        This will be much easier to modify compared to main.lua, as it contained engine code alongside the encounter configuration
]]

--Load your custom enemies in here!

require "mizzle"

Encounter = Object:extend()

function Encounter:new() --Called once in love.load(). Initialise all your encounter-specific variables and arrays here.

    self.Box = Battlebox()

    local kris_anims = {
        --The order of these first 10 animations must be the exact same for every party member.
        --Other misc. animations may be ordered on a per-character basis.

        --[id] = {"name", total number of frames, fps, loops, offsetX, offsetY}
        [0] = {"krisIdle", 6, 6, true, 0, 0},
        [1] = {"krisAttack", 8, 15, false, 5, -20},
        [2] = {"krisAct", 11, 11, false, 0, 0},
        [3] = {"krisItem", 8, 12, false, -21, -15},
        [4] = {"krisAct", 11, 11, false, 0, 0}, --I'm fairly confident that Kris uses the same animation for sparing and acting.
        [5] = {"krisDefend", 6, 12, false, 0, -7},
        [6] = {"krisAttackWait", 1, 1, true, 0, -20},
        [7] = {"krisActWait", 1, 1, true, 0, 0},
        [8] = {"krisActWait", 1, 1, true, 0, 0}, --Again, sparing is visually the same as acting. 
        [9] = {"krisDefendLoop", 1, 1, true, 0, -7}, --Unlooping animations set animation to default, so this animation is required to keep their last sprite.
    }

    local kris_buttons = { --Generally FIGHT/ACT/ITEM/SPARE/DEFEND but I used ATTACK for some reason
                           --And because it's written all over the code I can't change it anymore
                           --A monster party member could use MAGIC through the ACT menu
        [1] = {"attack"},
        [2] = {"act"},
        [3] = {"item"},
        [4] = {"spare"},
        [5] = {"defend"},
    }

    local krisSpecialLoops = {
        [5] = 9,
    }

    local krissheet = love.graphics.newImage("sprites/krissheet.png")
    local krissheetarr
    local krisjson = io.open("sprites/krissheet.json", "r")
    if krisjson then
        local tempkrissheetarr = krisjson:read("*a")
        krissheetarr = json.decode(tempkrissheetarr)
        krisjson:close()
    end

    local kris_1 = PartyMember("Kris1", 100, 202, kris_anims, "krisplace.png", 0, krisSpecialLoops, krissheetarr, krissheet, 4, 200, 35, 10)
    kris_1:set_animation("ATTACK")

    local kris_2 = PartyMember("Kris2", 100, 402, kris_anims, "krisplace.png", 0, krisSpecialLoops, krissheetarr, krissheet, 4, 200, 35, 10)
    kris_2:set_animation("ATTACK")

    self.party_members = {
        kris_1,
        kris_2,
    }

    --Load BattleUi sheet and data

    local BattleUISheet = love.graphics.newImage("sprites/battleUI.png")
    local BattleSheetQuadrantData
    local sheetjson = io.open("sprites/battleUI.json", "r")
    if sheetjson then
        local tempsheetarr = sheetjson:read("*a")
        BattleSheetQuadrantData = json.decode(tempsheetarr)
        sheetjson:close()
    end

    local Kris1UI = BattleUi("Kris1", "kris", "kris", kris_buttons, 308, 630, 1, BattleUISheet, BattleSheetQuadrantData)
    local Kris2UI = BattleUi("Kris2", "kris", "kris", kris_buttons, 628, 630, 2, BattleUISheet, BattleSheetQuadrantData)

    self.UIs = {
        Kris1UI,
        Kris2UI,
    }

    current_party_member = 1

    --Background
    self.Bg = Background("b")

    --Enemy related data
    local mizzle_anims = {
        [0] = {"mizzleIdle", 5, 5, true, 0, 0},
        [1] = {"mizzleIdlePink", 5, 5, true, 0, -0.3},
        [2] = {"mizzleAlarm", 10, 10, true, 0, 0},
        [3] = {"mizzleAlarmPink", 10, 10, true, 0, -0.3},
        [4] = {"mizzleHurt", 1, 1, true, 0, 0},
        [5] = {"mizzleHurtPink", 1, 1, true, 0, 0}
    }

    local mizzlesheet = love.graphics.newImage("sprites/mizzle.png")
    local mizzlearr
    local mizzlejson = io.open("sprites/mizzle.json", "r")
    if mizzlejson then
        local tempmizzlearr = mizzlejson:read("*a")
        mizzlearr = json.decode(tempmizzlearr)
    end

    self.enemies = {}

    self.enemies[1] = Mizzle("Mizzr", 980, 102, mizzle_anims, mizzlesheet, mizzlearr, 0, 3, 1000)
    self.enemies[2] = Mizzle("Mizzy", 980, 252, mizzle_anims, mizzlesheet, mizzlearr, 0, 3, 1000)
    self.enemies[3] = Mizzle("Mizzle", 980, 402, mizzle_anims, mizzlesheet, mizzlearr, 0, 3, 1000)

    --Submenus and their options
    --These get used to generate the submenus' text and their positions
    --Check out submenu.lua for more info

    Enemysubarray = { --The array used when generating a submenu with the enemies' names
                      --You must define the positions of the enemy names yourself.
        [1] = {"* "..self.enemies[1].name, 218, 771},
        [2] = {"* "..self.enemies[2].name, 778, 771},
        [3] = {"* "..self.enemies[3].name, 218, 851},
    }

    self.act_sub_subs = { --ACT -> enemies[i] (in your original array) -> These show up
        [self.enemies[1]] = { --Handle these in enemies[1]:act(actname)
            [1] = {"* Alarm", 218, 771, function () return "* Mizzr is awoken!\n* This sounds like a bad idea." end},
            [2] = {"* Lullaby", 778, 771, function (party_members) return"* "..party_members[current_party_member].name.." sung a lullaby!\n* Not as good as Ralsei's, but it worked." end},
        },
        [self.enemies[2]] = {
            [1] = {"* Alarm", 218, 771, function () return "* Mizzy is awoken!\n* This sounds like a bad idea." end},
            [2] = {"* Lullaby", 778, 771, function (party_members) return"* "..party_members[current_party_member].name.." sung a lullaby!\n* Not as good as Ralsei's, but it worked." end},
        },
        [self.enemies[3]] = {
            [1] = {"* Alarm", 218, 771, function () return "* Mizzle is awoken!\n* This sounds like a bad idea." end},
            [2] = {"* Lullaby", 778, 771, function (party_members) return"* "..party_members[current_party_member].name.." sung a lullaby!\n* Not as good as Ralsei's, but it worked." end},
        },
    }

    self.Enemysub = Submenu(Enemysubarray, {"ATTACKUI", "ACTUI", "SPAREUI"}, nil, true)

    self.Enemysubsubs = {
        Submenu(self.act_sub_subs[self.enemies[1]], {"ACTSUBSUB"}, self.enemies[1], false),
        Submenu(self.act_sub_subs[self.enemies[2]], {"ACTSUBSUB"}, self.enemies[2], false),
        Submenu(self.act_sub_subs[self.enemies[3]], {"ACTSUBSUB"}, self.enemies[3], false),
    }

    self.PartyMemberSubArray = {
        [1] = {"* "..self.party_members[1].name, 218, 771},
        [2] = {"* "..self.party_members[2].name, 778, 771}
    }
    self.PartyMemberSub = Submenu(self.PartyMemberSubArray, {"MEMBERUI"}, nil, false)

    self.items = {
        [1] = Item("70cm Zurna", 180),
        [2] = Item("Ayran", 80)
    }

    self.ItemSubArray = {
        [1] = {"* "..self.items[1].name, 218, 771},
        [2] = {"* "..self.items[2].name, 778, 771}
    }

    self.ItemSub = Submenu(self.ItemSubArray, {"ITEMUI"}, nil, false)

    self.ItemManager = ItemManager(self.items, self.ItemSubArray)

    love.graphics.setFont(Battlefont)

    --Load certain feedback sprites (Recruit, Lost, Frozen etc.)
    LOST = love.graphics.newImage("sprites/LOST.png")
    RECRUIT = love.graphics.newImage("sprites/RECRUIT.png")

    --The very culmination of your being ;)
    Sole = Soul() --It's named "Sole" because the object name cannot be the class name.

    --Music
    --This should allow one to dynamically swap songs
    --Maybe a jukebox enemy with a unique act could change the song :)
    self.MUS_Vaporbattle = love.audio.newSource("music/battle_vapor.ogg", "stream")
    self.MUS_Churchbattle = love.audio.newSource("music/ch4_battle.ogg", "stream")

    self.MUS_Battlemusic = self.MUS_Churchbattle

    love.audio.play(self.MUS_Battlemusic)

    --Initialise program by setting the first state
    self.current_state = "BATTLEUI"
    self.UIs[current_party_member]:subtext("* Cool initial description")

end
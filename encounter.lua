--Load your custom enemies in here!

require "mizzle"

Encounter = Object:extend()

function Encounter:new() --Called once in love.load(). Initialise all your encounter-specific variables and arrays here.

    self.Box = Battlebox()

    local kris_anims = {

        --These used to be number-indexed. They are now string-indexed for clarity.
        --The animations of these specific keys still need to exist for all party members.
        --(Not the names)

        ["idle"] = {name = "krisIdle", length = 6, FPS = 6, looping = true, xOffset = 0, yOffset = 0},
        ["attack"] = {name = "krisAttack", length = 8, FPS = 15, looping = false, xOffset = 5, yOffset = -20},
        ["act"] = {name = "krisAct", length = 11, FPS = 11, looping = false, xOffset = 0, yOffset = 0},
        ["item"] = {name = "krisItem", length = 8, FPS = 12, looping = false, xOffset = -21, yOffset = -15},
        ["spare"] = {name = "krisAct", length = 11, FPS = 11, looping = false, xOffset = 0, yOffset = 0}, --I'm fairly confident that Kris uses the same animation for sparing and acting.
        ["defend"] = {name = "krisDefend", length = 6, FPS = 12, looping = false, xOffset = 0, yOffset = -7},
        ["hurt"] = {name = "krisHurt", length = 1, FPS = 1, looping = true, xOffset = 0, yOffset = -20},
        ["down"] = {name = "krisDown", length = 1, FPS = 1, looping = true, xOffset = -60, yOffset = -20},
        ["end"] = {name = "krisEnd", length = 9, FPS = 10, looping = false, xOffset = -48, yOffset = -24},
        ["endloop"] = {name = "krisEndLoop", length = 1, FPS = 1, looping = true, xOffset = -48, yOffset = -24},
        ["ATTACKUI"] = {name = "krisAttackWait", length = 1, FPS = 1, looping = true, xOffset = 0, yOffset = -20},
        ["ACTUI"] = {name = "krisActWait", length = 1, FPS = 1, looping = true, xOffset = 0, yOffset = 0},
        ["SPAREUI"] = {name = "krisActWait", length = 1, FPS = 1, looping = true, xOffset = 0, yOffset = 0}, --Again, sparing is visually the same as acting. 
        ["DEFEND"] = {name = "krisDefendLoop", length = 1, FPS = 1, looping = true, xOffset = 0, yOffset = -7}, --Unlooping animations set animation to default, so this animation is required to keep their last sprite.
    }

    local kris_buttons = { --Generally FIGHT/ACT/ITEM/SPARE/DEFEND but I used ATTACK for some reason
                           --And because it's written all over the code I can't change it anymore
                           --Not to be confused with the keys in kris_anims
        [1] = {"attack"},
        [2] = {"act"},
        [3] = {"item"},
        [4] = {"spare"},
        [5] = {"defend"},
    }

    local krisSpecialLoops = {
        ["defend"] = "DEFEND",
        ["end"] = "endloop"
    }

    local krissheet = love.graphics.newImage("sprites/krissheet.png")
    local krissheetarr
    local krisjson = io.open("sprites/krissheet.json", "r")
    if krisjson then
        local tempkrissheetarr = krisjson:read("*a")
        krissheetarr = json.decode(tempkrissheetarr)
        krisjson:close()
    end

    local kris_button_states = {
        "ATTACKUI",
        "ACTUI",
        "ITEMUI",
        "SPAREUI",
        "DEFEND",
    }

    local kris_1 = PartyMember("Kris1", 100, 52, kris_button_states, kris_anims, "krisplace.png", "idle", krisSpecialLoops, krissheetarr, krissheet, 4, 200, 35, 10)
    kris_1:set_animation("attack")

    local kris_2 = PartyMember("Kris2", 100, 252, kris_button_states, kris_anims, "krisplace.png", "idle", krisSpecialLoops, krissheetarr, krissheet, 4, 200, 35, 10)
    kris_2:set_animation("attack")

    local kris_3 = PartyMember("Kris3", 100, 452, kris_button_states, kris_anims, "krisplace.png", "idle", krisSpecialLoops, krissheetarr, krissheet, 4, 200, 35, 10)
    kris_3:set_animation("attack")

    self.party_members = {
        kris_1,
        kris_2,
        kris_3,
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

    local Kris1UI = BattleUi("Kris1", "kris", "kris", kris_buttons, 118, 630, 1, BattleUISheet, BattleSheetQuadrantData)
    local Kris2UI = BattleUi("Kris2", "kris", "kris", kris_buttons, 438, 630, 2, BattleUISheet, BattleSheetQuadrantData)
    local Kris3UI = BattleUi("Kris3", "kris", "kris", kris_buttons, 760, 630, 3, BattleUISheet, BattleSheetQuadrantData)
    self.UIs = {
        Kris1UI,
        Kris2UI,
        Kris3UI,
    }

    --Background
    self.Bg = Background("b")

    --Enemy related data
    local mizzle_anims = {
        --These will remain as numbers, as the in-class code relies on numeric keys.
        [0] = {name = "mizzleIdle", length = 5, FPS = 5, looping = true, xOffset = 0, yOffset = 0},
        [1] = {name = "mizzleIdlePink", length = 5, FPS = 5, looping = true, xOffset = 0, yOffset = -0.3},
        [2] = {name = "mizzleAlarm", length = 10, FPS = 10, looping = true, xOffset = 0, yOffset = 0},
        [3] = {name = "mizzleAlarmPink", length = 10, FPS = 10, looping = true, xOffset = 0, yOffset = -0.3},
        [4] = {name = "mizzleHurt", length = 1, FPS = 1, looping = true, xOffset = 0, yOffset = 0},
        [5] = {name = "mizzleHurtPink", length = 1, FPS = 1, looping = true, xOffset = 0, yOffset = 0}
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
            [2] = {"* Lullaby", 778, 771, function (party_members) return"* "..party_members[Controller:getPartyMember()].name.." sung a lullaby!\n* Not as good as Ralsei's, but it worked." end},
        },
        [self.enemies[2]] = {
            [1] = {"* Alarm", 218, 771, function () return "* Mizzy is awoken!\n* This sounds like a bad idea." end},
            [2] = {"* Lullaby", 778, 771, function (party_members) return"* "..party_members[Controller:getPartyMember()].name.." sung a lullaby!\n* Not as good as Ralsei's, but it worked." end},
        },
        [self.enemies[3]] = {
            [1] = {"* Alarm", 218, 771, function () return "* Mizzle is awoken!\n* This sounds like a bad idea." end},
            [2] = {"* Lullaby", 778, 771, function (party_members) return"* "..party_members[Controller:getPartyMember()].name.." sung a lullaby!\n* Not as good as Ralsei's, but it worked." end},
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
        [2] = {"* "..self.party_members[2].name, 778, 771},
        [3] = {"* "..self.party_members[3].name, 218, 851},
    }
    self.PartyMemberSub = Submenu(self.PartyMemberSubArray, {"MEMBERUI"}, nil, false)

    self.items = {
        [1] = Item("70cm Zurna", 180),
        [2] = Item("Ayran", 80),
        [3] = Item("S. POISON", -200),
    }

    self.ItemSubArray = {
        [1] = {"* "..self.items[1].name, 218, 771},
        [2] = {"* "..self.items[2].name, 778, 771},
        [3] = {"* "..self.items[3].name, 218, 851},
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
    self.MUS_Flowerbattle = love.audio.newSource("music/rakuichi_buster_wip.ogg", "stream")

    self.MUS_Battlemusic = self.MUS_Flowerbattle

    love.audio.play(self.MUS_Battlemusic)

    --Initialise program by setting the first state
    self.current_state = "BATTLEUI"
    self.UIs[1]:subtext("* Cool initial description")

end
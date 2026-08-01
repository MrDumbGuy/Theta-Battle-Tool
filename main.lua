Object = require "classic"
require "partyMember"
require "background"
require "battleui"
require "battlebar"
require "soul"
require "submenu"
require "battlebox"
require "bullet"
require "encounter"
flux = require "flux"
tick = require "tick"
json = require "json"
local tlfres = require "tlfres"
require "item"
require "itemmanager"
Controller = require "battlecontroller"
--Best for blurless scaling
love.graphics.setDefaultFilter( "nearest", "nearest", 1)

--Place constant values here.

local WIDTH = 1280
local HEIGHT = 960

local ARR_STATES = {--UI Buttons to states as used in battle.current_state
                    --MAGIC will also be used in ACTUI since behavior is similar enough
                    --It still has a graphical difference (magic button over act button) but no functional one.
    "ATTACKUI",
    "ACTUI",
    "ITEMUI",
    "SPAREUI",
    "DEFEND",
}

--The game's fonts.
--These need to be global because too many engine components rely on them.
--They're also present in every Deltarune battle ever
--If you need your own fonts, feel free to load them in your Encounter() and implement custom fonts for your draw() calls!
Battlefont = love.graphics.newFont("fonts/8bitOperatorPlus-Bold.ttf", 30)
Goldenfont = love.graphics.newImageFont("sprites/goldennumeralfont.png", "0123456789+-%/ ")--The mercy increased font
HPfont = love.graphics.newFont("fonts/deltarune-hp-font.otf", 14)

--Basic sound effects.
--Again, only global because these are present in every encounter
--You can load your custom sound effects in your battle!
SND_MENUMOVE = love.audio.newSource("sfx/snd_menumove.wav", "static")
SND_SELECT = love.audio.newSource("sfx/snd_select.wav", "static")
SND_ATTACK = love.audio.newSource("sfx/snd_attack.wav", "static")

--Place state-tracking variables here

selected_enemy = nil

--Just in case I add a menu for changing battles or something.
local battling = true

local members_to_attack = {}
local enemies_to_attack = {}
local battlebars = {}

local actname = {}
local actindex = {}

--Arrays used for submenus:
local selected_enemies = {}

--The encounter object.
local battle

local Commands = {}

--[[
    Although you can, I'd advise against placing anything battle-specific here.
    That kind of defeats the point of having made an engine instead of a messily-coded fangame.
    (Also in the far future there's a chance support is added for an exchangable battle loader)
]]

function love.load()

    battle = Encounter()
    Controller:new(battle)

end

function love.update(dt)

    --TODO: Decouple battle updates to be handled by battle:update()

    Controller:update(dt)

    for i = 1, #battlebars do
        if battlebars[i] then
            battlebars[i]:update(dt)
        end
    end

    tick.update(dt)

    flux.update(dt)

    local battleovercheck = true

    for i = 1, #battle.enemies do
        if battle.enemies[i] then
            if battle.enemies[i].hp > 0 then
                battleovercheck = false
                break
            end
        end
    end

    if battleovercheck then
        battle.current_state = "BATTLEOVER"
    end

    if battle.current_state == "BATTLEOVER" then
        for i = 1, #battle.party_members do
            battle.UIs[i]:subtext("* Battle is over!\n* Press any key to exit.")
        end
        Sole:updatePosArray(nil)
    end

    collectgarbage("collect")

end

local function BULLETSCleanup()

    battle.current_state = "BATTLEUI"
    battle.Box:set_animation(3)
    Sole:updateLimits(battle.Box)

    --Collect garbage
        current_party_member = 1
        selected_enemies = {}
        actname = {}
        actindex = {}
        Controller:resetCommands()
    collectgarbage("collect")

    for i = 1, #battle.party_members do
        battle.party_members[i].isdefending = false
        if battle.party_members[i].hp > 0 then battle.party_members[i]:set_animation(0) end
        battle.UIs[i]:subtext("* A wild battle commentary appeared!")
    end

end

local function StartBULLETS()
        --Collect garbage
        members_to_attack = {}
        enemies_to_attack = {}
        battlebars = {}
        collectgarbage("collect")

        current_party_member = 1
        for i = 1, #battle.party_members do
            battle.UIs[i]:subtext("* A wild battle commentary appeared!")
        end
        battle.Box:set_animation(1)
        Sole:updateLimits(battle.Box)
        Sole:centerInBox()
        tick.delay(function() BULLETSCleanup() end, 5)
        battle.current_state = "BULLETS"
end

local function ExecuteAttack(enemies)

    print("ExecuteAttack()")
    print("current_party_member: "..current_party_member)

    battle.current_state = "ATTACKING"

    if #members_to_attack > 0 and #battlebars == 0 then
        print("members_to_attack: "..#members_to_attack)

        for i = 1, #members_to_attack do
            local k = 1
            local baroffsetcoefficient = 1 --Used to position the battlebars correctly

            while k < #battle.party_members + 1 do
                if battle.party_members[k] == members_to_attack[i] then
                    baroffsetcoefficient = k
                    print("baroffsetcoefficient: "..baroffsetcoefficient)
                end
                k = k+1
            end

            battlebars[i] = BattleBar(900+100*baroffsetcoefficient, 738+41*1.5*(baroffsetcoefficient-1), i,battle.party_members)

        end

    elseif current_party_member <= #battlebars then

        if battlebars[current_party_member] then
            battlebars[current_party_member]:attack(enemies, enemies_to_attack, members_to_attack)
        end

    end

    if current_party_member > #battlebars then

        StartBULLETS()

    end


end

--Don't touch this unless you are CERTAIN you know what you are doing.
--This function handles every command passed through the UI.
--That means all of FIGHT/ACT...MERCY is handled here.

local function ExecuteCommands()

    print("ExecuteCommands()")

    local CommandReturned
    current_party_member = current_party_member + 1

    print("current_party_member @ COMMANDS: "..current_party_member)

    if current_party_member <= #battle.party_members then
        if Controller:getCommand(current_party_member, 1) then --TODO Ensure that the Command for a downed partyMember is empty.
            battle.UIs[current_party_member]:subtext(Controller:getCommand(current_party_member,2))
            CommandReturned = Controller:runCommand(current_party_member, 1)
            if CommandReturned then print("Command executed: "..CommandReturned.." by: "..battle.party_members[current_party_member].name) end
        end
    end
    if CommandReturned == "DEFCOMMAND" then
        battle.party_members[current_party_member].isdefending = true
        ExecuteCommands()
    elseif CommandReturned == "ATTACKCOMMAND" then
        members_to_attack[#members_to_attack+1] = battle.party_members[current_party_member]
        print("Latest member to attack: "..members_to_attack[#members_to_attack].name)
        ExecuteCommands()
    end

    if current_party_member >= #battle.party_members + 1 then

        Commands = {}
        for i = 1, #battle.party_members do
            Commands[i] = {}
        end

        for i = 1, #battle.party_members do
            battle.party_members[i].hpup = nil
        end

        if #members_to_attack > 0 then
            current_party_member = 1
            for i = 1, #battle.party_members do
                battle.UIs[i]:subtext("")
            end
            battle.current_state = "ATTACKING"
            ExecuteAttack()
        else
            StartBULLETS()
        end

    end

end

function love.mousepressed(x, y, button)

    if button == 1 then
        print(x..", "..y)
    end

end

function love.keypressed(key)

    --This if else statement is one of the cores of Theta Battle Tool
    --It handles a majority of the UI logic and every single UI-related state change
    --Do not edit this unless you're CERTAIN you know what you're doing.
    --(Or have a backup, like the official one over at https://github.com/sedat-34/Theta-Battle-Tool)

    if battle.current_state == "BATTLEUI" then --The main battle menu. If you see the five buttons, you're in this state.

        if key == "right" then
            battle.UIs[current_party_member]:changeselect(1)
        elseif key == "left" then
            battle.UIs[current_party_member]:changeselect(-1)
        elseif key == "x" and current_party_member ~= 1 then
            if Commands[current_party_member-1][1]() == "ITEMCOMMAND" then
                battle.ItemManager:undoAddition()
            end
            battle.current_state = "BATTLEUI"
            Controller:setCommand(current_party_member, 1, nil)
            Controller:setCommand(current_party_member, 2, nil)
            current_party_member = current_party_member - 1
        elseif key == "z" then
            battle.UIs[current_party_member]:subtext(nil)
            love.audio.play(SND_SELECT)

            --Quick exception for selecting items versus any submenus with the enemy list
            if ARR_STATES[battle.UIs[current_party_member].buttonmode] == "ITEMUI" then
                if #battle.ItemManager.itemsSubArray > 0 then
                    Sole:updatePosArray(battle.ItemManager.itemsSubArray)
                    battle.UIs[current_party_member]:menuState(Sole, 631, 471, ARR_STATES[battle.UIs[current_party_member].buttonmode], battle.ItemManager.itemsSubArray, battle)
                else
                    battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                end
            else
                battle.UIs[current_party_member]:menuState(Sole, 631, 471, ARR_STATES[battle.UIs[current_party_member].buttonmode], Enemysubarray, battle)
            end

            if battle.current_state ~= "BATTLEUI" then
                battle.party_members[current_party_member]:set_animation(ARR_STATES[battle.UIs[current_party_member].buttonmode])
            end

            if ARR_STATES[battle.UIs[current_party_member].buttonmode] == "DEFEND" then

                --No extra commands neeed for the party member to defend
                Controller:setCommand(current_party_member, 1,

                    function ()

                        return "DEFCOMMAND"

                    end)

                Controller:setCommand(current_party_member, 2, battle.party_members[current_party_member].name.." defended!") --Not displayed, necessary for regular flow of program.

                --Advance to next opponent or move on to executing every command?
                current_party_member = current_party_member + 1
                if current_party_member > #battle.party_members then
                    current_party_member = 0
                    battle.current_state = "COMMANDS"
                    ExecuteCommands()
                else
                    battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                    battle.current_state = "BATTLEUI"
                end
                selected_enemy = nil
                end
        end

    elseif battle.current_state == "ATTACKUI" then --This is when you select which enemy to attack

        if key == "x" then
            love.audio.play(SND_SELECT)
            battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            battle.UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI", {}, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = battle.enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = battle.enemies[Sole.currentmenuposition]

            enemies_to_attack[#enemies_to_attack+1] = selected_enemy
            Controller:setCommand(current_party_member, 1,

            function ()
                return "ATTACKCOMMAND"
            end)

            Controller:setCommand(current_party_member, 2, "* "..battle.party_members[current_party_member].name.." attacked "..selected_enemy.name.."!") --Not displayed, necessary for regular flow of program.

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #battle.party_members then
                current_party_member = 0
                battle.current_state = "COMMANDS"
                ExecuteCommands()
            else
                battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                battle.current_state = "BATTLEUI"
            end
                selected_enemy = nil
            Sole:updatePosArray(nil)
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif battle.current_state == "ACTUI" then --This is where you select which enemy to act with
        if key == "x" then
            love.audio.play(SND_SELECT)
            battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            battle.UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI", {}, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = battle.enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = battle.enemies[Sole.currentmenuposition]
            battle.UIs[current_party_member]:menuState(Sole, 0, 0, "ACTSUBSUB", battle.act_sub_subs[selected_enemy], battle)
            Sole:updatePosArray(battle.act_sub_subs[selected_enemy])
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif battle.current_state == "ACTSUBSUB" then --The various acts done with an enemy show up in this state
        if key == "x" then
            love.audio.play(SND_SELECT)
            selected_enemy = nil
            battle.UIs[current_party_member]:menuState(Sole, 0, 0, "ACTUI", Enemysubarray, battle)
            battle.party_members[current_party_member]:set_animation(0)

        elseif key == "z" then
            actname[current_party_member] = Sole.positions[Sole.currentmenuposition][1]
            actindex[current_party_member] = Sole.currentmenuposition
            love.audio.play(SND_SELECT)
            print(selected_enemies[current_party_member].name.." added to queue to be acted with.")

            Controller:setCommand(current_party_member, 1,

            function()

                if battle.current_state == "COMMANDS" then battle.party_members[current_party_member]:act(selected_enemies[current_party_member], actname[current_party_member], battle.UIs[current_party_member]) end
                return "ACTCOMMAND"

            end)

            Controller:setCommand(current_party_member, 2, battle.act_sub_subs[selected_enemies[current_party_member]][actindex[current_party_member]][4](battle.party_members))

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #battle.party_members then
                current_party_member = 0
                battle.current_state = "COMMANDS"
                ExecuteCommands()
            else
                battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                battle.current_state = "BATTLEUI"
            end
            selected_enemy = nil

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif battle.current_state == "ITEMUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            battle.UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI", {}, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            battle.ItemManager.tempitem = battle.items[Sole.currentmenuposition]
            print(battle.ItemManager.tempitem.name)
            battle.UIs[current_party_member]:menuState(Sole, 0, 0, "MEMBERUI", battle.PartyMemberSubArray, battle)
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif battle.current_state == "MEMBERUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            battle.UIs[current_party_member]:menuState(Sole, 0, 0, "ITEMUI", battle.ItemSubArray, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)


            local itemtext = battle.ItemManager:generateItemText(Sole.currentmenuposition, current_party_member, battle.party_members)
            battle.ItemManager:addItem(Sole.currentmenuposition, current_party_member)

            Controller:setCommand(current_party_member, 1,

                function()

                    if battle.current_state == "COMMANDS" then battle.ItemManager:useItem(battle) end
                    return "ITEMCOMMAND" --Functionally the same as an ACTCOMMAND, but labelled seperately for debugging purposes and code cleanliness.

                end)

            Controller:setCommand(current_party_member, 2, itemtext)
            current_party_member = current_party_member + 1
            if current_party_member > #battle.party_members then
                current_party_member = 0
                battle.current_state = "COMMANDS"
                ExecuteCommands()
            else
                battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                battle.current_state = "BATTLEUI"
            end

            selected_enemy = nil

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif battle.current_state == "SPAREUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            battle.UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI", {}, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = battle.enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = battle.enemies[Sole.currentmenuposition]
            print(selected_enemies[current_party_member].name.." added to queue to be spared.")

            Controller:setCommand(current_party_member, 1,

                function()

                    if battle.current_state == "COMMANDS" then
                        battle.party_members[current_party_member]:spare(selected_enemies[current_party_member])
                        battle.party_members[current_party_member]:set_animation(4)
                    end

                    return "SPARECOMMAND"

                end)

            Controller:setCommand(current_party_member, 2, "* "..battle.party_members[current_party_member].name.." spared "..selected_enemy.name.."!")

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #battle.party_members then
                current_party_member = 0
                battle.current_state = "COMMANDS"
                ExecuteCommands()
            else
                battle.UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                battle.current_state = "BATTLEUI"
            end
            selected_enemy = nil

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)

        end

    elseif battle.current_state == "COMMANDS" then

        if current_party_member <= #battle.party_members then
            ExecuteCommands()
        end

    elseif  battle.current_state == "ATTACKING" and key == "z" then

        ExecuteAttack(battle.enemies)

    elseif battle.current_state == "BATTLEOVER" then
        love.event.quit()
    end

    if battle.current_state ~= "BULLETS" then
        print("Current State: "..battle.current_state)
        print("Party Member:"..current_party_member)
    end

end

function love.draw()
    tlfres.beginRendering(WIDTH, HEIGHT)

    love.graphics.setPointSize(tlfres.getScale())

    Controller:drawBackground()

    --UI Purple line (top)
    love.graphics.setColor(51/255, 32/255, 51/255)
    love.graphics.rectangle("fill", 0, 684, 1280, 4)

    --UI Background (black)
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",0,687,1280,273)

    --UI Purple line (bottom)
    love.graphics.setColor(51/255, 32/255, 51/255)
    love.graphics.rectangle("fill", 0, 733, 1280, 4)

    love.graphics.setColor(1,1,1,1) --If you don't set to white when drawing images, the image colors get altered.

    --TODO Decouple draw calls specific to the battle from main by restructuring encounter.lua such that battle has a :draw() function

    Controller:drawForeground()

    for i = 1, #battle.UIs do
        battle.UIs[i]:draw(battle.current_state, battle.party_members)
    end

    for i = 1, #battlebars do
        battlebars[i]:draw()
    end

    Sole:draw(battle.current_state)

    local FPS = love.timer.getFPS()

    if FPS >= 30 then
        love.graphics.setColor(0,1,0,1)
    elseif 30 >= FPS and FPS > 15 then
        love.graphics.setColor(1,1,0,1)
    elseif FPS < 15 then
        love.graphics.setColor(1,0,0,1)
    end

    love.graphics.setFont(Battlefont)
    love.graphics.print("FPS:"..FPS, 0, 0, 0, 1, 1)

    tlfres.endRendering()

    FPS = nil

end
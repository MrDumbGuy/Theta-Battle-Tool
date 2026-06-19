---@diagnostic disable: undefined-field
Object = require "classic"
require "partyMember"
require "background"
require "battleui"
require "battlebar"
require "soul"
require "submenu"
require "mizzle"
require "battlebox"
require "animate"
require "bullet"
require "encounter"
flux = require "flux"
tick = require "tick"
json = require "json"

--Best for blurless scaling
love.graphics.setDefaultFilter( "nearest", "nearest", 1)


--Place constant values here.

--Honestly I don't think I used either of these anywhere but maybe someone will need them.
WIDTH = love.graphics.getWidth()
HEIGHT = love.graphics.getHeight()

ARR_STATES = { --UI Buttons to states as used in battle.current_state
               --MAGIC will also be used in ACTUI since behavior is similar enough
               --It still has a graphical difference (magic button over act button) but no functional one.
    "ATTACKUI",
    "ACTUI",
    "MEMBERUI",
    "SPAREUI",
    "DEFEND",
}

--Place state-tracking variables here

selected_enemy = nil

members_to_attack = {}
enemies_to_attack = {}
battlebars = {}

local actname = {}
local actindex = {}

--Arrays used for submenus:
enemies = {}
local selected_enemies = {}

--The encounter object.
local battle

Commands = {}

--Misc. stuff required for your battle

function love.load()

    battle = Encounter()

end

function love.update(dt)

    for i = 1, #enemies do
        if enemies[i] then
            enemies[i]:update(dt, battle.current_state)
        end
    end

    for i = 1, #battle.party_members do
        battle.party_members[i]:update(dt)
    end

    for i = 1, #battlebars do
        if battlebars[i] then
            battlebars[i]:update(dt)
        end
    end

    battle.Bg:update(dt)

    Sole:update(dt, battle.current_state)

    battle.Box:update(dt)

    --print(love.mouse.getX().." , "..love.mouse.getY()) --I use this when checking positions in the UI.

    if not MUS_Battlemusic:isPlaying() then
        love.audio.play(MUS_Battlemusic)
    end

    tick.update(dt)

    flux.update(dt)

    local battleovercheck = true

    for i = 1, #enemies do
        if enemies[i] then
            if enemies[i].hp > 0 then
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
            UIs[i]:subtext("* Battle is over!\n* Press any key to exit")
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
        for i = 1, #battle.party_members do
            Commands[i] = {}
            UIs[i].buttonmode = 1
        end
    collectgarbage("collect")

    for i = 1, #battle.party_members do
        battle.party_members[i].isdefending = false
        if battle.party_members[i].hp > 0 then battle.party_members[i]:set_animation(0) end
        UIs[i]:subtext("* A wild battle commentary appeared!")
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
            UIs[i]:subtext("* A wild battle commentary appeared!")
        end
        battle.Box:set_animation(1)
        Sole:updateLimits(battle.Box)
        Sole:centerInBox()
        tick.delay(function() BULLETSCleanup() end, 5)
        battle.current_state = "BULLETS"
end

local function ExecuteAttack()

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
            battlebars[current_party_member]:attack()
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

    print("current_party_member @ COMMANDS:"..current_party_member)

    if current_party_member <= #battle.party_members then
        if Commands[current_party_member][1] then --Ensure that the Command for a downed partyMember is empty.
            UIs[current_party_member]:subtext(Commands[current_party_member][2])
            CommandReturned = Commands[current_party_member][1]()
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

        if #members_to_attack > 0 then
            current_party_member = 1
            battle.current_state = "ATTACKING"
            for i = 1, #battle.party_members do
                UIs[i]:subtext("")
            end
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
            UIs[current_party_member]:changeselect(1)
        elseif key == "left" then
            UIs[current_party_member]:changeselect(-1)
        elseif key == "z" then
            UIs[current_party_member]:subtext(nil)
            love.audio.play(SND_SELECT)
            UIs[current_party_member]:menuState(Sole, 631, 471, ARR_STATES[UIs[current_party_member].buttonmode], Enemysubarray, battle)
            if battle.current_state == "MEMBERUI" then Sole:updatePosArray(battle.PartyMemberSubArray) end
            battle.party_members[current_party_member]:set_animation(ARR_STATES[UIs[current_party_member].buttonmode])
            if ARR_STATES[UIs[current_party_member].buttonmode] == "DEFEND" then

                --No extra commands neeed for the party member to defend
                Commands[current_party_member][1] = function ()

                    return "DEFCOMMAND"

                end

                Commands[current_party_member][2] = battle.party_members[current_party_member].name.." defended!" --Not displayed, necessary for regular flow of program.

                --Advance to next opponent or move on to executing every command?
                current_party_member = current_party_member + 1
                if current_party_member > #battle.party_members then
                    current_party_member = 0
                    battle.current_state = "COMMANDS"
                    ExecuteCommands()
                else
                    UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                    battle.current_state = "BATTLEUI"
                end
                selected_enemy = nil
                end
        end

    elseif battle.current_state == "ATTACKUI" then --This is when you select which enemy to attack

        if key == "x" then
            love.audio.play(SND_SELECT)
            UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI", {}, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = enemies[Sole.currentmenuposition]

            enemies_to_attack[#enemies_to_attack+1] = selected_enemy
            Commands[current_party_member][1] = function ()
                return "ATTACKCOMMAND"
            end

            Commands[current_party_member][2] = "* "..battle.party_members[current_party_member].name.." attacked "..selected_enemy.name.."!" --Not displayed, necessary for regular flow of program.

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #battle.party_members then
                current_party_member = 0
                battle.current_state = "COMMANDS"
                ExecuteCommands()
            else
                UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
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
            UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI", {}, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = enemies[Sole.currentmenuposition]
            UIs[current_party_member]:menuState(Sole, 0, 0, "ACTSUBSUB", battle.act_sub_subs[selected_enemy], battle)
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
            UIs[current_party_member]:menuState(Sole, 0, 0, "ACTUI", Enemysubarray, battle)
            battle.party_members[current_party_member]:set_animation(0)

        elseif key == "z" then
            actname[current_party_member] = Sole.positions[Sole.currentmenuposition][1]
            actindex[current_party_member] = Sole.currentmenuposition
            love.audio.play(SND_SELECT)
            print(selected_enemies[current_party_member].name.." added to queue to be acted with.")

            Commands[current_party_member][1] = function()


                battle.party_members[current_party_member]:act(selected_enemies[current_party_member], actname[current_party_member], UIs[current_party_member])
                return "ACTCOMMAND"

            end

            Commands[current_party_member][2] = battle.act_sub_subs[selected_enemies[current_party_member]][actindex[current_party_member]][4](battle.party_members)

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #battle.party_members then
                current_party_member = 0
                battle.current_state = "COMMANDS"
                ExecuteCommands()
            else
                UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                battle.current_state = "BATTLEUI"
            end
            selected_enemy = nil

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif battle.current_state == "MEMBERUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI", {}, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            --TODO: ADD SUPPORT FOR CUSTOM NEXT STATE. FOR NOW, THIS ONLY WORKS FOR ITEMS
            love.audio.play(SND_SELECT)
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif battle.current_state == "ITEMUI" then
        if key == "x" then
            UIs[current_party_member]:menuState(Sole, 0, 0, "MEMBERUI", battle.PartyMemberSubArray, battle)
            love.audio.play(SND_SELECT)
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif battle.current_state == "SPAREUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI", {}, battle)
            battle.party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = enemies[Sole.currentmenuposition]
            print(selected_enemies[current_party_member].name.." added to queue to be spared.")

            Commands[current_party_member][1] = function()

                battle.party_members[current_party_member]:spare(selected_enemies[current_party_member])
                battle.party_members[current_party_member]:set_animation(4)

                end

            Commands[current_party_member][2] = "* "..battle.party_members[current_party_member].name.." spared "..selected_enemy.name.."!"

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #battle.party_members then
                current_party_member = 0
                battle.current_state = "COMMANDS"
                ExecuteCommands()
            else
                UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
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
        
        ExecuteAttack()

    elseif battle.current_state == "BATTLEOVER" then
        love.event.quit()
    end

    if battle.current_state ~= "BULLETS" then
        print("Current State: "..battle.current_state)
        print("Party Member:"..current_party_member)
    end

end

function love.draw()

    battle.Bg:draw()

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

    for i = 1, #battle.party_members do
        battle.party_members[i]:draw()
    end

    for i = 1, #UIs do
        UIs[i]:draw(battle.current_state)
    end
    for i = 1,#enemies do
        if enemies[i] then
            enemies[i]:draw()
        end
    end

    battle.Enemysub:draw(battle.current_state)
    battle.PartyMemberSub:draw(battle.current_state)

    for i = 1, #battle.Enemysubsubs do
        battle.Enemysubsubs[i]:draw(battle.current_state)
    end

    for i = 1, #battlebars do
        battlebars[i]:draw()
    end

    battle.Box:draw()

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

    FPS = nil

end
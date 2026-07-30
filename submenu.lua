--Here you can find all the submenus of the game
--It's actually really simple, and most of the logic related to selection is handled externally (the soul's position and the main game loop)
--This class only generates the graphics of any submenu

Submenu = Object:extend()

function Submenu:new(posarray, targetstatearr, targetenemy, isEnemyList)
    
    --These are absolutely REQUIRED. No exceptions.
    self.positions = posarray
    self.targetstatearr = targetstatearr

    --If targetenmy is nil, the submenu only appears if no enemy is selected
    --Useful for when you select a button from the BattleUi() 
    self.targetenemy = targetenemy
    
    if self.targetenemy and enemies then
        for i = 1, #enemies do
            if enemies[i] == targetenemy then
                self.targetenemynumber = i
                break
            end
        end
    end

    self.isEnemyList = isEnemyList

end

function Submenu:updatePosArray(posarray)
    self.positions = posarray
    print("Submenu position array updated")
    print(#self.positions)
    print(self.positions[1])
end

function Submenu:draw(localcurrentstate, enemies)
    local targetstate = false

    for i = 1, #self.targetstatearr do
        if self.targetstatearr[i] == localcurrentstate then
            targetstate = true
        end
    end

    if self.positions and targetstate and selected_enemy == self.targetenemy then
        for i = 1, #self.positions do

            love.graphics.setFont(Battlefont)
            love.graphics.setColor(1, 1, 1, 1)

            if self.isEnemyList and enemies[i].sparable then--Sparable enemies show up as Yellow on all enemy submenus
                love.graphics.setColor(1, 0.85, 0.3, 1)
            end

            love.graphics.print(self.positions[i][1], self.positions[i][2], self.positions[i][3])
        end
    end
end
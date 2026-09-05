--An example bullet pattern.
--You can execute any arbitrary code in here, ideally related to your pattern, but go wild!
--As of right now, you CAN'T use the BulletManager to have pattenrs with custom backgrounds due to the draw loop structure.

--This function makes a bullet move in a sinewave to the right, starting from the left side of the screen.
function MizzleBulletPattern(BulletManager, dt)
    local firstrun = false

    if #BulletManager.bullets.isactive ~= 1 then firstrun = true end

    if firstrun then
        BulletManager.bullets.custombulletpositions = true
        BulletManager.bullets.x[1] = 400
        BulletManager.bullets.y[1] = 300
        BulletManager.bullets.velocity_x[1] = 100
        BulletManager.bullets.quadrantID[1] = "horizontalDrop.png"
        BulletManager.bullets.isactive[1] = true
    end

    if BulletManager.bullets.isactive[1] ~= nil then
        BulletManager.bullets.y[1] = 300 + (math.sin(love.timer.getTime() * 2) * 50)
        BulletManager.bullets.x[1] = BulletManager.bullets.x[1] + (BulletManager.bullets.velocity_x[1] * dt)
    end
end

return MizzleBulletPattern
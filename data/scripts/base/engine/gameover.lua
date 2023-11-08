local t = 0

function onDraw()
    t = t + 1
    if t >= 1 then
        _gameoverComplete = true
    end
end
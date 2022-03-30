--[[
        CLICK.LUA
         V 1.2
       BY  YOSHI021
]]

local click = {}

click.state = false
click.click = false
click.hold = false
click.released = false

click.speedX = 0
click.speedY = 0

click.x = 0
click.y = 0

click.sceneX = 0
click.sceneY = 0

click.defaultImg = Graphics.sprites.hardcoded["42-2"].img;

click.dragBox = {
  active = false,
  startX = 0,
  startY = 0,
  diagonal = 0,
  width = 0,
  height = 0,
  top = 0,
  bottom = 0,
  left = 0,
  right = 0,
  frames = 0
}

local cursorID = 0

local hist_click = false
local hist_posX = 0
local hist_posY = 0

local cursorData = {}

local cam = Camera.get()
local cams = {cam[1], cam[2]}

--------------------

--------------------

local function between(a,b,c)
  if a <= b  and b <= c then
    return true
  end
  return false
end

function click.getCursorID()
  return cursorID
end

function click.setCursorID(num)
  frame = 1
  timer = 0
  if between(0, num, #cursorData) then
    cursorID = num
  else
    cursorID = 0
  end
end

--{{img}, priority, Xoffset, Yoffset, framespeed}
function click.loadCursor(table)
  table = table or {{}}
  for i = 1, #table do
    if table[i][1] == nil then
      table[i][1] = {click.defaultImg}
    elseif type(table[i][1]) ~= "table" then
      table[i][1] = {table[i][1]}
    end
    for k, v in pairs(table[i][1]) do
      table[i][1][k] = v or click.defaultImg
    end
    table[i][2] = table[i][2] or 5.1
    table[i][3] = table[i][3] or 0
    table[i][4] = table[i][4] or 0
    table[i][5] = table[i][5] or 8
  end
  cursorData = table

  if cursorID > #cursorData then
    cursorID = 0
  end
end

-- x y (x2 y2) width height | scene useXY2
function click.box(table)
  if table.x == nil or table.y == nil or (table.useXY2 and (table.x2 == nil or table.y2 == nil)) or (not table.useXY2 and (table.width == nil or table.height == nil)) then
    error("Missing parameter in 'click.box()'")
  end

  local topleft = {x = table.x, y = table.y}
  local bottomright = {}
  local point = {}
  if table.useXY2 then
    bottomright.x = table.x2
    bottomright.y = table.y2
  else
    bottomright.x = topleft.x + table.width
    bottomright.y = topleft.y + table.height
  end
  if table.scene then
    point.x = click.sceneX
    point.y = click.sceneY
  else
    point.x = click.x
    point.y = click.y
  end

  if between(topleft.x, point.x, bottomright.x) and between(topleft.y, point.y, bottomright.y) then
    return true
  end
  return false
end

-- x y radius | scene
function click.circle(table)
  if table.x == nil or table.y == nil or table.radius == nil then
    error("Missing parameter in 'click.circle()'")
  end

  local point = {}
  if table.scene then
    point.x = click.sceneX
    point.y = click.sceneY
  else
    point.x = click.x
    point.y = click.y
  end

  if ((point.x - table.x)^2 + (point.y - table.y)^2 <= table.radius^2) then
    return true
  end
  return false
end

local frame = 1
local timer = 0

function click.onDraw()
  click.x = mem(0x00B2D6BC, FIELD_DFLOAT)
  click.y = mem(0x00B2D6C4, FIELD_DFLOAT)

  if click.box{x = cams[1].renderX, y = cams[1].renderY, width = cams[1].width, height = cams[1].height} then
    click.sceneX = cams[1].x + (click.x - cams[1].renderX)
    click.sceneY = cams[1].y + (click.y - cams[1].renderY)
  elseif player2 and click.box{x = cams[2].renderX, y = cams[2].renderY, width = cams[2].width, height = cams[2].height} then
    click.sceneX = cams[2].x + (click.x - cams[2].renderX)
    click.sceneY = cams[2].y + (click.y - cams[2].renderY)
  end

  click.speedX = click.x - hist_posX
  click.speedY = click.y - hist_posY

  click.hold = mem(0x00B2D6CC, FIELD_BOOL)
  click.state = click.hold

  if click.hold and not hist_click then
    click.click = true
    click.state = KEYS_PRESSED

    click.dragBox.active = true
    click.dragBox.startX = click.x
    click.dragBox.startY = click.y
    click.dragBox.frames = 0
  else
    click.click = false
  end
  if not click.hold and hist_click then
    click.released = true
    click.state = KEYS_RELEASED

    click.dragBox.active = false
  else
    click.released = false
  end

  if click.dragBox.active then
    click.dragBox.width = math.abs(click.x - click.dragBox.startX)
    click.dragBox.height = math.abs(click.y - click.dragBox.startY)
    click.dragBox.diagonal = math.sqrt((click.dragBox.width)^2 + (click.dragBox.height)^2)
    click.dragBox.frames = click.dragBox.frames + 1

    if click.x < click.dragBox.startX then
      click.dragBox.left = click.x
      click.dragBox.right = click.dragBox.startX
    else
      click.dragBox.left = click.dragBox.startX
      click.dragBox.right = click.x
    end
    if click.y < click.dragBox.startY then
      click.dragBox.top = click.y
      click.dragBox.bottom = click.dragBox.startY
    else
      click.dragBox.top = click.dragBox.startY
      click.dragBox.bottom = click.y
    end
  end

  hist_click = click.hold
  hist_posX = click.x
  hist_posY = click.y

  if cursorID > 0 then
    img = cursorData[cursorID][1][frame]
    timer = timer + 1
    if timer >= cursorData[cursorID][5] then
      timer = 0
      frame = frame + 1
      if frame > #cursorData[cursorID][1] then
        frame = 1
      end
    end
    Graphics.drawImageToSceneWP(img, click.sceneX + cursorData[cursorID][3], click.sceneY + cursorData[cursorID][4], cursorData[cursorID][2])
  end
end

function click.onInitAPI()
  registerEvent(click, "onDraw", "onDraw")
end

return click

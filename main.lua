-- Sudoku board
local board = {}
local tile = {posibles = {1,2,3,4,5,6,7,8,9}, num = -1}

function fullCopyTable(original)
    local copy = {}

    for key, element in pairs(original) do
        if type(element) == 'table' then
            copy[key] = fullCopyTable(element)
        else
            copy[key] = element
        end
    end

    return copy
end

local input_board = {0, 0, 4, 2, 0, 5, 6, 0, 0, 
                    0, 0, 0, 0, 8, 9, 1, 2, 0, 
                    2, 6, 8, 7, 1, 0, 3, 9, 0, 
                    0, 1, 9, 0, 0, 2, 7, 0, 0, 
                    3, 0, 2, 8, 9, 6, 0, 0, 0, 
                    5, 4, 0, 0, 0, 3, 9, 0, 0, 
                    4, 2, 1, 9, 0, 7, 0, 6, 3, 
                    0, 3, 7, 4, 0, 8, 0, 1, 9, 
                    0, 8, 5, 0, 0, 0, 2, 0, 7} --9 * 9 array of numbers

-- load the main board with tiles
for x = 1, 9 do
    local row = {}
    for y = 1, 9 do
        row[y] = fullCopyTable(tile)
    end

    board[x] = row
end

-- 
function tableLength(t)
    local length = 0
    for _, e in pairs(t) do
        length = length + 1
    end

    return length
end

function tableRemoveNum(input, num)
    for key, element in pairs(input) do
        if element == num then
            table.remove(input, key)
            return
        end
    end
end

function entropies()
    local result = {}

    for x, row in ipairs(board) do
        for y, tile in ipairs(row) do
            if tile.num < 1 then
                table.insert(result, {x = x, y = y, entropy = tableLength(tile.posibles)})
            end
        end
    end

    table.sort(result, function(a,b) return a.entropy < b.entropy end)

    return result
end

function tileCollapse(x, y, num)
    local tile = board[x][y]

    local chosen = num or tile.posibles[math.random(#tile.posibles - 1)]-- chosen num
    tile.num = chosen

    --  actualize entropy
    --  row
    for i = 1, 9 do
        local t = board[i][y] -- iterate through that row

        if t.num < 1 then
            tableRemoveNum(t.posibles, chosen)
        end
    end

    -- col
    for i = 1, 9 do
        local t = board[x][i] -- iterate through that column
        if t.num < 1 then
            tableRemoveNum(t.posibles, chosen)
        end
    end

    -- block
    local blockX, blockY = math.floor((x - 1) / 3), math.floor((y - 1) / 3)

    for i = 1, 3 do
        for j = 1, 3 do
            local t = board[blockX * 3 + i][blockY * 3+ j]

            if t.num < 1 then
                tableRemoveNum(t.posibles, chosen)
            end
        end
    end
end


-- insert the num values of the input_board
for x = 1, 9 do
    for y = 1, 9 do
        tileCollapse(x, y, input_board[x + (y - 1) * 9])
    end
end

-- solve board
local ent = entropies()
while #ent > 0 do
    -- print(#ent)
    -- print(ent[1].x, ent[1].y)
    tileCollapse(ent[1].x, ent[1].y)

    ent = entropies()
end


-- draw board
local function drawBoard()
    love.graphics.setColor(1,1,1,1)

    for x, row in ipairs(board) do 
        for y, tile in ipairs(row) do

            -- draw different if the number was originaly there
            if input_board[x + (y - 1) * 9] > 0 then
                love.graphics.setColor(0,1,1,0.5)
                love.graphics.rectangle('fill', x * 30, y * 30, 30, 30, 0, 5)
                love.graphics.setColor(1,1,1,1)
            end


            love.graphics.rectangle('line', x * 30, y * 30, 30, 30)
            love.graphics.print(tile.num, x * 30, y * 30)
        end
    end

    for i = 1, 3 do
        for j = 1, 3 do
            local x = (i * 3 - 2) * 30
            local y = (j * 3 - 2) * 30
            love.graphics.setColor(1,1,0,1)

            love.graphics.rectangle('line', x, y, 90, 90)
        end
    end
end

function love.draw()
    drawBoard()
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'r' then
        love.event.quit('restart')
    end
end

-- wave function collapse: Compute the entropy of each tile,
-- pick one of the less entropy and collapse it ( leave a marker if there's more than one option)
-- check if there are tiles to colapse
-- repeat
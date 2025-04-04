-- CHARACTER LOCALS --
local characterCollumn
local characterRow
local characterOrientation = "up"
local orientationArray = {
    [1] = "up",
    [2] = "down",
    [3] = "left",
    [4] = "right"
}
local directionOffsets = {{orientationArray[1], 0, -1}, -- Up
{orientationArray[2], 0, 1}, -- Down
{orientationArray[4], 1, 0}, -- Right
{orientationArray[3], -1, 0} -- Left
}
local orientationTable = {
    up = {
        left = "left",
        right = "right"
    },
    down = {
        left = "right",
        right = "left"
    },
    left = {
        left = "down",
        right = "up"
    },
    right = {
        left = "up",
        right = "down"
    }
}
local ouchieArray = {"Wall there.", "Can't do that.", "Can't go there, there's a wall.",
                     "Ow... That hurt. There's a wall there.", "There's a wall there.", "That's... a wall.",
                     "I can't walk through walls."}

local nextMessage

-- WIN CONDITION --
local winCollumn
local winRow

-- DATA STRUCTURES --
local Array2D = {}
Array2D.__index = Array2D

function Array2D.new(width, height, default)
    local self = {}

    self.Width = width
    self.Height = height
    self.Data = {}

    for collumn = 1, self.Width do
        self.Data[collumn] = {}

        for row = 1, self.Height do
            self.Data[collumn][row] = default or 0
        end
    end

    return setmetatable(self, Array2D)
end

function Array2D:Set(y, x, value)
    assert(x <= self.Width and y <= self.Height, "Set out of bounds")

    self.Data[x][y] = value
end

function Array2D:Get(y, x)
    assert(type(x) == "number" and type(y) == "number",
        string.format("X and Y are not numbers! X is %s and Y is %s.", type(x), type(y)))
    assert(x <= self.Width and y <= self.Height, "Get out of bounds")

    return self.Data[x][y]
end

function Array2D:PrintMap(debug)
    for collumn = 1, self.Width do
        local colValues = {}

        for row = 1, self.Height do
            if row == characterCollumn and collumn == characterRow and debug then
                local representation = {
                    up = '^',
                    down = 'v',
                    left = '<',
                    right = '>'
                }

                table.insert(colValues, representation[characterOrientation])
            else
                table.insert(colValues, self:Get(row, collumn) == 0 and '.' or 'X')
            end
        end

        print(table.concat(colValues, ' '))
    end
end

function Array2D:RawPrint()
    for collumn = 1, self.Width do
        local colValues = {}

        for row = 1, self.Height do
            table.insert(colValues, string.format("%d [%d, %d]", self:Get(row, collumn), row, collumn))
        end

        -- print(table.concat(colValues, ' '))
    end
end

-- UTILITY FUNCTIONS --

local function printf(str, ...)
    print(string.format(str, ...))
end

local function sleep(duration)
    local now = os.clock()
    while os.clock() - now < duration do
        -- nothing!
    end

    return true
end

function table.find(haystack, needle)
    for index, value in pairs(haystack) do
        if value == needle then
            return index
        end
    end
end

-- Shame that normal lua doesn't have a built-in clamp
function math.clamp(x, min, max)
    if x > max then
        return max
    elseif x < min then
        return min
    else
        return x
    end
end

local function printTable(tbl)
    print(table.concat(tbl, ', '))
end

-- DIALOGUE STUFF --
local misunderstoodArray = {"Sorry, my head is killing me. What did you say?", "English, please.",
                            "Translate that to stupid, please?", "What are you saying?", "Can you... repeat that?",
                            "Sorry, I don't understand."}

local idleTalk = {"How long have we been down here?", "I keep hearing voices...",
                  "*cough* Would kill *cough* for a cough drop.", "Something brushed up against my leg!",
                  "Something brushed up against my leg! No wait, that was just my backpack rope.",
                  "I wish I had saved my flashlight battery.",
                  "I'm wounded pretty badly, glad it\'s dark so I don\'t have to see it."}

local introDictionary = {{"Hello?", 2.5}, {"Is anybody there?", 3}, {"I-if you hear me, please say something.", -0.85},
                         {"Oh my god, contact!", 3},
                         {"I'm uh-, lost in a maze right now... you must have a map, right?", 4},
                         {"If so, tell me where to go, please.", 3},
                         {"I don't know where I am or where I am facing.", 2},
                         {"But I can reach out in the dark, *cough*,", 2},
                         {"tell you how many walls there are around me,", 2.5},
                         {"and you'll tell me where to go, okay?", -1}, {"*cough* Alright...", 2},
                         {"Tell me to turn left or right and I'll turn 90 degrees,", 2},
                         {"and forwards or backwards if you want me to move.", 3},
                         {"Got it? I'm gonna need verbal confirmation here.", -2.5}, {"Awesome- *cough* *cough*.", 2}}

local escapeDictionary = {{"Hold on, I see light!", 2}, {"Oh, lovely light... *Cough*", 6},
                          {"My hands, I can see my hands!", 2}, {"Oh... they look...", 1.5},
                          {"Different.... *Cough*", 3}, {"N-no matter, I'll just... continue...", 4}, {"Hey...", 3},
                          {"Thanks for helping me out there.", 3}}

local function speakFrom(speakDictionary)
    for _, tbl in ipairs(speakDictionary) do
        local msg = tbl[1]
        local sleepDuration = tbl[2]

        if sleepDuration >= 0 and not msg:find("{append} ") then
            print(msg)
            sleep(sleepDuration)
        elseif tbl[2] < 0 then
            io.write(msg .. " ")
            local input = io.read() -- wait for input
            sleep(math.abs(sleepDuration))
        elseif msg:find("{append} ") then
            local realString = msg:gsub("{append} ", '')
            io.write(realString)
            sleep(tbl[2])
        end
    end
end

local function setupMap()
    local mapTxt = io.open("map.txt", 'r')
    assert(mapTxt, "No map text file to read from!")

    local lines = {}
    while true do
        local line = mapTxt:read("*l")
        if not line then
            break
        end

        table.insert(lines, line)
    end
    -- print(table.concat(lines, '\n'))

    -- cheatsheet: col: x; row: y
    local collumns = #lines[1]:gsub("%s", '')
    local rows = #lines
    -- printf("%d collumns and %d rows\n\n", collumns, rows)

    local mapArray = Array2D.new(collumns, rows, 1)
    for row, line in ipairs(lines) do
        local collumn = 0

        for character in line:gmatch("[^%s]") do
            collumn = collumn + 1
            mapArray:Set(row, collumn, character == 'X' and 1 or 0)
        end
    end

    -- Setup win collumns and rows (scans edges)
    local function scanEdge(mode, getX, getY)
        local forEnd = (mode == "collumn" and mapArray.Width) or (mode == "row" and mapArray.Height)

        for i = 1, forEnd do
            local x = (mode == "collumn" and i) or (getX or 1)
            local y = (mode == "row" and i) or (getY or 1)

            if mapArray:Get(y, x) == 0 then
                winCollumn = y
                winRow = x
            end
        end
    end

    -- Scan first collumn
    scanEdge("collumn", nil, 1)

    --[[ This is equivalent to:
    for i = 1, mapArray.Width do
        if mapArray:Get(i, 1) == 0 then
            winCollumn = i
            winRow = 1
        end
    end]]

    scanEdge("collumn", nil, mapArray.Height) -- Scan last collumn
    scanEdge("row", 1) -- Scan first row
    scanEdge("row", mapArray.Width) -- Scan last row

    -- mapArray:Print()
    -- printf("Win collumn is %d, win row is %d.", winCollumn, winRow)

    return mapArray
end

local function setupCharacter(map2dArray)
    local validPosition = false

    while not validPosition do
        local col = math.random(map2dArray.Width)
        local row = math.random(map2dArray.Height)

        validPosition = map2dArray:Get(row, col) == 0 and col ~= winCollumn and row ~= winRow

        if validPosition then
            characterCollumn = col
            characterRow = row
            characterOrientation = orientationArray[math.random(#orientationArray)]
            return
        end
    end
end

local function informPosition(map2dArray)
    -- Count walls around
    local wallsAround = 0
    local wallInFront = false

    -- printf("character x: %d, y: %d", characterCollumn, characterRow)
    for i, offset in ipairs(directionOffsets) do
        -- printf("%d: offset[1]: %s | offset[2]: %d | offset[3]: %d", i, offset[1], offset[2], offset[3])

        local x = math.clamp(characterCollumn + offset[2], 1, map2dArray.Width)
        local y = math.clamp(characterRow + offset[3], 1, map2dArray.Height)
        -- printf("checking x: %d, y: %d. got: %s", x, y, tostring(map2dArray:Get(x, y)))

        if map2dArray:Get(x, y) == 1 then
            wallsAround = wallsAround + 1
            -- print("wall around check succeeded")

            if offset[1] == characterOrientation then
                -- printf("! wall in front check succeeded", offset[1])
                wallInFront = true
            end
        end
    end
    map2dArray:RawPrint()

    if wallsAround == 4 then
        local secret = {{"I'm trapped.", 2.5}, {"Oh no...", 1.65}}

        for i = 1, 35 do
            table.insert(secret, {"NO", 1/10})
        end

        table.insert(secret, {"{append} LET ME OUT!", 0})
        table.insert(secret, {"{append} !", 0.5})
        table.insert(secret, {"{append} !", 4})
        table.insert(secret, {"{append} \n", 0})

        for i = 1, 30 do
            table.insert(secret, {"...", 1 / 4})
        end
        table.insert(secret, {"...", 4})

        table.insert(secret, {"I must've fallen asleep again...", 2.5})
        table.insert(secret, {"Where were we?", 1.75})

        os.execute("cls")
        speakFrom(secret)

        secret = nil
        setupCharacter(map2dArray) -- Respawn somewhere else to avoid softlocks

        return
    end

    if wallsAround == 0 then
        print("There are no walls around me.")
    elseif wallsAround == 1 then
        if not wallInFront then
            print("There is 1 wall around me.")
        else
            print("There is 1 wall around me,")
            print("and it's in front of me.")
        end
    elseif wallsAround > 1 then
        if not wallInFront then
            printf("There are %d walls around me.", wallsAround)
        else
            printf("There are %d walls around me,", wallsAround)
            print("and one of them is in front of me.")
        end
    end
end

local function rotateCharacter(input)
    characterOrientation = orientationTable[characterOrientation][input]
end

local function moveCharacter(map2dArray, input)
    local direction
    for _, nested in ipairs(directionOffsets) do
        for _, value in ipairs(nested) do
            if characterOrientation == value then
                direction = nested
                break
            end
        end
    end

    local newX = math.clamp(characterCollumn + direction[2], 1, map2dArray.Width)
    local newY = math.clamp(characterRow + direction[3], 1, map2dArray.Height)

    if map2dArray:Get(newX, newY) == 1 then
        nextMessage = ouchieArray[math.random(#ouchieArray)]
    else
        characterCollumn = newX;
        characterRow = newY
    end
end

local function main(args)
    os.execute("cls")

    local skipIntro = table.find(args, "skipintro")
    local debug = table.find(args, "debug")

    if not skipIntro then
        speakFrom(introDictionary)
    end

    local map2dArray = setupMap()
    setupCharacter(map2dArray)

    local escaped = false
    local firstMessage = true

    while not escaped do
        os.execute("cls")
        -- Update escaped flag
        escaped = characterCollumn == winCollumn and characterRow == winRow

        if escaped then
            speakFrom(escapeDictionary)
            os.exit()
        end

        if nextMessage then
            print(nextMessage)
            nextMessage = nil
        end

        map2dArray:PrintMap(debug)

        if firstMessage then
            printf("As far as I know, I think I'm facing %s.", characterOrientation)
            firstMessage = nil
        end

        informPosition(map2dArray)

        local input = io.read():lower()
        if input == "left" or input == "right" then
            rotateCharacter(input)
        elseif input == "forward" or input:find("backward") then
            moveCharacter(map2dArray, input)
        elseif input == "quit" or input == "q" or input == "bye" or input == "end" then
            print("Oh well, guess I'll have to figure it out myself then.")
            os.exit()
        else
            nextMessage = misunderstoodArray[math.random(#misunderstoodArray)]
        end
    end
end

main(arg)

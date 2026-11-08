-- hardcore misery for paparazzi
local set = {
    name = "hunters_glee_paparazzi_west", -- unique name
}

local function setWeaponOverride( hunter, wepClass )
hunter.DefaultWeapon = wepClass

end

local function give357( _, hunter )
setWeaponOverride( hunter, "weapon_357" ) --revolver
end

local function giveAnnabelle( _, hunter )
setWeaponOverride( hunter, "termhunt_annabelle" )
end

local function giveCrapvidcam( _, hunter )
setWeaponOverride( hunter, "weapon_glee_crapvidcam" )
end


if SERVER then
    local postSpawnedOvercharge = GAMEMODE.setHelpers.postSpawnedOvercharge

    local setSv = {
        prettyName = "A Western Movie",
        description = "BASED ON REAL EVENTS.\nThe shop is CLOSED to the living.",
        difficultyPerMin = 0.05, -- very little difficulty per minute, let wave clears primarily bump difficulty
        waveInterval = "default", -- time between spawn waves
        diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
        startingBudget = "default", -- so budget isnt 0
        spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
        startingSpawnCount = 5,
        maxSpawnCount = 50, -- hard cap on count
        maxSpawnDist = "default",
        roundEndSound = "default",
        roundStartSound = "default",
        roundEarlyStartSound = "default", -- plays 10s before round start
        genericSpawnerRate = "default", -- speeds up or slows down the crate/beartrap/etc spawner
        chanceToBeVotable = 40,
        spawns = {
            {
                hardRandomChance = nil,
                name = "paparazzi_cowboy", -- unique name
                prettyName = "A Cowboy",
                class = "terminator_nextbot_fakeply", -- class spawned
                spawnType = "hunter",
                difficultyCost = { 10 },
                countClass = "terminator_nextbot_fakeply*", -- class COUNTED, uses findbyclass
                minCount = { 2 }, -- will ALWAYS maintain this count
                postSpawnedFuncs = { give357 }, -- this can be nil
            },
            {
                hardRandomChance = { 0, 2 },
                name = "paparazzi_operator",
                prettyName = "A Camera Operator",
                class = "terminator_nextbot_fakeply",
                spawnType = "hunter",
                difficultyCost = { 15},
                countClass = "terminator_nextbot_fakeply*",
                minutesNeeded = { 1 },
                postSpawnedFuncs = { giveCrapvidcam },
            },
            {
                hardRandomChance = nil,
                name = "paparazzi_gunslinger",
                prettyName = "A Gunslinger",
                class = "terminator_nextbot_fakeply",
                spawnType = "hunter",
                difficultyCost = { 40 },
                countClass = "terminator_nextbot_fakeply*",
                minutesNeeded = { 2 },
                postSpawnedFuncs = { giveAnnabelle },
            }
        }
    }
    table.Merge( set, setSv )

end

local gunslingerShare = 0.25

function set:Activate()
    local setHelpers = GAMEMODE.setHelpers
    setHelpers.makeHardcore( self )

    if CLIENT then return end

    -- picked once, and kept for as long as this misery is
    -- by SteamID64, so rejoining doesn't reroll it
    local gunslingerById = {}

    -- everyone without a pick yet is picked together, least persistent guilt first
    -- ties go in a random order, so whoever spawns first isn't always the gunslinger
    local function pickGunslingers()
        local unpicked = {}
        local guilts = {}
        local tieBreaks = {}
        local gunslingerCount = 0
        for _, ply in player.Iterator() do
            local isGunslinger = gunslingerById[ply:SteamID64()]
            if isGunslinger == nil then
                table.insert( unpicked, ply )
                guilts[ply] = GAMEMODE:GetPersistentGuilt( ply )
                tieBreaks[ply] = math.random()

            elseif isGunslinger then
                gunslingerCount = gunslingerCount + 1

            end
        end

        table.sort( unpicked, function( a, b )
            if guilts[a] ~= guilts[b] then
                return guilts[a] < guilts[b]

            end
            return tieBreaks[a] < tieBreaks[b]

        end )

        -- alone, there's nobody to heal or revive, so they're a plain cowboy for good
        local wantedGunslinger = 0
        if player.GetCount() >= 2 then
            wantedGunslinger = math.ceil( player.GetCount() * gunslingerShare )

        end
        for _, ply in ipairs( unpicked ) do
            local isGunslinger = gunslingerCount < wantedGunslinger
            gunslingerById[ply:SteamID64()] = isGunslinger
            if isGunslinger then
                gunslingerCount = gunslingerCount + 1

            end
        end
    end

    local function isGunslinger( ply )
        if gunslingerById[ply:SteamID64()] == nil then
            pickGunslingers()

        end
        return gunslingerById[ply:SteamID64()]

    end

    setHelpers.addStartWeapon( self, {
        class = "weapon_357",
        ammoType = "357",

    } )
    setHelpers.addStartWeapon( self, "termhunt_annabelle", isGunslinger )
    setHelpers.addStartWeapon( self, "termhunt_reviver", isGunslinger )

end

-- put the spawnset IN the global table to be gobbled
table.insert( GLEE_SPAWNSETS, set )

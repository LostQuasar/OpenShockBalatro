local mod_path = "" .. SMODS.current_mod.path
os_config = SMODS.current_mod.config
local openshock = SMODS.current_mod

function openshock.save_config(self)
    SMODS.save_mod_config(self)
end

local function get_coordinates(position, width)
    if width == nil then width = 10 end -- 10 is default for Jokers
    return { x = (position) % width, y = math.floor((position) / width) }
end

function say(message)
    sendDebugMessage('[OpenShock] - ' .. (message or '???'))
end

local reset = true

if openshock.config.punish then
    G.E_MANAGER:add_event(Event({
        func = function()
            if reset == true and G.STATE == G.STATES.GAME_OVER then
                love.thread.getChannel("send_shock"):push("true")
                reset = false
            end
            if reset == false and G.STATE == G.STATES.NEW_ROUND then
                reset = true
            end
            return false
        end,
        blocking = false,
        no_delete = true
    }))

    G.E_MANAGER:add_event(Event({
        func = function()
            local txt = love.thread.getChannel("shock_response"):pop()
            if txt then
                say(txt)
                return false
            end
            return false
        end,
        blocking = false
    }))
end

if not GLOBAL_send_shock_update_thread then
    local file_data = assert(NFS.newFileData(mod_path .. "https/thread.lua"))
    GLOBAL_send_shock_update_thread = love.thread.newThread(file_data)
    GLOBAL_send_shock_update_thread:start()
end

SMODS.current_mod.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = {
            emboss = 0.05,
            minh = 6,
            r = 0.1,
            minw = 10,
            align = "cm",
            padding = 0.2,
            colour = G.C.BLACK
        },
        nodes = {
            {
                n = G.UIT.C,
                config = { align = "cl" },
                nodes = {
                    create_toggle({
                        label = localize("os_config_end_shock"),
                        ref_table = openshock.config,
                        ref_value =
                        'punish',
                        callback = function() openshock:save_config() end
                    }),
                    create_toggle({
                        label = localize("os_config_joker"),
                        ref_table = openshock.config,
                        ref_value =
                        'jokers',
                        callback = function() openshock:save_config() end
                    }),
                }
            },
        }

    }
end

SMODS.Atlas {
    -- Key for code to find it with
    key = "modicon",
    -- The name of the file, for the code to pull the atlas from
    path = "modicon.png",
    -- Width of each sprite in 1x size
    px = 32,
    -- Height of each sprite in 1x size
    py = 32
}

SMODS.Atlas {
    -- Key for code to find it with
    key = "os_joker_atlas",
    -- The name of the file, for the code to pull the atlas from
    path = "jokers.png",
    -- Width of each sprite in 1x size
    px = 71,
    -- Height of each sprite in 1x size
    py = 95
}


function create_joker(joker)
    --Check Joker's keyword tag, if the setting is turned off then don't add anything
    local isAdded = true
    if joker.gameplay_tag and type(joker.gameplay_tag) == 'table' then
        for _, v in ipairs(joker.gameplay_tag) do
            isAdded = check_enable_taglist(joker.gameplay_tag)
        end
    end
    if not isAdded then return end

    -- Sprite position

    local width = 2 -- Width of the spritesheet (in Jokers)

    joker.position = get_coordinates(joker.pos)

    -- Sprite atlas

    if joker.type == nil then
        joker.atlas = 'os_joker_atlas'

        -- Key generation from name

        local key = string.gsub(string.lower(joker.name), '%s', '_') -- Removes spaces and uppercase letters

        -- Rarity conversion

        if joker.rarity == 'Common' then
            joker.rarity = 1
        elseif joker.rarity == 'Uncommon' then
            joker.rarity = 2
        elseif joker.rarity == 'Rare' then
            joker.rarity = 3
        elseif joker.rarity == 'Legendary' then
            joker.rarity = 4
        end

        -- Config values

        if joker.vars == nil then joker.vars = {} end

        joker.config = { extra = {} }

        for _, kv_pair in ipairs(joker.vars) do
            -- kv_pair is {a = 1}
            local k, v = next(kv_pair)
            joker.config.extra[k] = v
        end

        -- Joker creation
        SMODS.Joker {
            name = joker.name,
            key = key,

            atlas = joker.atlas,
            pos = joker.position,
            soul_pos = joker.soul,

            rarity = joker.rarity,
            cost = joker.cost,

            unlocked = true,
            --check_for_unlock = joker.check_for_unlock,
            --unlock_condition = joker.unlock_condition,
            --discovered = true, --false,

            blueprint_compat = joker.blueprint or false,

            eternal_compat = (joker.eternal == nil) or joker.eternal,

            perishable_compat = (joker.perishable == nil) or joker.perishable,


            process_loc_text = joker.process_loc_text,

            config = joker.custom_config or joker.config,
            loc_vars = joker.custom_vars or function(self, info_queue, card)
                -- Localization values

                local vars = {}

                for _, kv_pair in ipairs(joker.vars) do
                    -- kv_pair is {a = 1}
                    local k, v = next(kv_pair)
                    -- k is `a`, v is `1`
                    table.insert(vars, card.ability.extra[k])
                end

                return { vars = vars }
            end,

            calculate = joker.calculate,
            update = joker.update,
            remove_from_deck = joker.remove_from_deck,
            add_to_deck = joker.add_to_deck,

            set_ability = joker.set_ability,
            set_sprites = joker.set_sprites,
            load = joker.load,

            calc_dollar_bonus = joker.calc_dollar_bonus,

            in_pool = joker.custom_in_pool,

            effect = joker.effect
        }
    end
end

if openshock.config.jokers then
    create_joker(
        {
            name = 'High Voltage',
            pos = 0,
            vars = { { xmult = 5 }, { odds = 5 } },
            custom_vars = function(self, info_queue, card)
                return { vars = { card.ability.extra.xmult, G.GAME and G.GAME.probabilities.normal or 1, card.ability.extra.odds } }
            end,
            rarity = 'Uncommon',
            cost = 5,
            blueprint = true,
            eternal = true,
            unlocked = true,
            calculate = function(self, card, context)
                if context.joker_main and context.scoring_hand then
                    local isActivated = pseudorandom('highvoltage' .. G.SEED) <
                        G.GAME.probabilities.normal / card.ability.extra.odds
                    if isActivated then
                        love.thread.getChannel("send_shock"):push("true")
                        return {
                            card = card,
                            message = localize("k_os_zap"),
                        }

                    else
                        return {
                            Xmult_mod = card.ability.extra.xmult,
                            card = card,
                            message = localize {
                                type = 'variable',
                                key = 'a_xmult',
                                vars = { card.ability.extra.xmult }
                            },
                        }
                    end
                end
            end
        }
    )
end

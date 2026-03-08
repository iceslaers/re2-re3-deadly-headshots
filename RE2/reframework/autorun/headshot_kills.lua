if _G.__hs_damage_installed then return end
_G.__hs_damage_installed = true



local api = require("REFrameworkAPI")
local Set = require('helpers.set')
local sdk = api.sdk
local log = api.log

local HEAD_PART = 0
local KILL_DAMAGE = 999999
-- zombies kindId 0,1,2,24,21
-- licker 3
-- dogs 4
-- grass 7
-- regenerator 23
-- water monsters 8
-- tyrant stalker 10
-- tyrant bossfight 11
-- birkin in ending 17
local ALLOWED_KIND_ID_SET = Set:new({ 0, 1, 2, 21, 24 })
local ALLOWED_WEAPON_TYPE = Set:new({
    1,   -- Matilda
    2,   -- M19
    3,   -- JMB Hp3
    4,   -- Quickdraw Army
    7,   -- MUP
    8,   -- Broom Hc
    9,   -- SLS 60
    11,  -- W-870
    21,  -- MQ 11
    23,  -- LE 5
    31,  -- Lightning Hawk
    50,  -- Minigun
    82,  -- Samurai Edge - Original
    83,  -- Samurai Edge - Chris
    84,  -- Samurai Edge - Jill
    85,  -- Samurai Edge - Albert
    252, -- Minigun - Unlimited
})


local function to_managed(x)
    local ok, obj = pcall(function() return sdk.to_managed_object(x) end)
    if ok and obj then return obj end
    return nil
end



do
    local equipment_define_type = sdk.find_type_definition('app.ropeway.EquipmentDefine')
    local hit_manager_type = sdk.find_type_definition('app.Collision.HitManager')
    local calc_damage_method = hit_manager_type and hit_manager_type:get_method('calcDamage')
    if not calc_damage_method then
        log.info('[HS] calcDamage not found')
        return
    end


    sdk.hook(calc_damage_method,
        function(args)
            local em_controller = to_managed(args[4]) -- app.ropeway.EnemyController
            if not em_controller then return end

            local is_ok, kind_id = pcall(function() return em_controller:call('get_KindID()') end)


            if not is_ok then return end
            log.debug("kindId= " .. tostring(kind_id))

            if ALLOWED_KIND_ID_SET:has(kind_id) then
                local equipment_manager = sdk.get_managed_singleton('app.ropeway.EquipmentManager')
                if not equipment_manager then return end

                local equipment = to_managed(equipment_manager:call('getPlayerEquipment()'))

                if not equipment then return end

                local weapon_type = equipment:get_field('<EquipType>k__BackingField')

                if ALLOWED_WEAPON_TYPE:has(weapon_type) then
                    local damage_info = to_managed(args[3]) -- app.Collision.HitController.DamageInfo
                    if not damage_info then return end
                    local damage_user_data = to_managed(damage_info:get_field('<DamageUserData>k__BackingField'))

                    if damage_user_data == nil then
                        log.info('[HS] dmg user data not found')
                    end

                    local parts = damage_user_data:get_field('Parts')

                    if parts == HEAD_PART then
                        damage_info:set_field("<Damage>k__BackingField", KILL_DAMAGE)
                        damage_info:set_field("<OriginalDamage>k__BackingField", KILL_DAMAGE)
                        damage_info:set_field("<DamageRatio>k__BackingField", 1.0)
                    end
                end
            end
        end,
        function(retval) return retval end
    )
end

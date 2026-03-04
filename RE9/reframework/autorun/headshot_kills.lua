local api = require('REFrameworkAPI')
local Set = require('helpers.set')

local sdk = api.sdk
local log = api.log

local head_body_parts_set = Set:new({
    0,
    1
})

local zombie_prefix_name = 'cp_B0'

local excluded_zombie_types = Set:new({
    'cp_B002'
})

local excluded_zombie_types_table = excluded_zombie_types:toTable()

local headshot_context = nil

-- Zombies
-- cp_B070
-- cp_B001
-- cp_B000

-- cp_D100 Mr Gideon

local moprh_postfix = 'morphed'

do
    local zm_updater_type = sdk.find_type_definition('app.Cp_B000Updater')

    if zm_updater_type == nil then
        log.debug('NOT ZM_UPDATER')
    end

    local request_morhp_pop_head_method = zm_updater_type:get_method('requestPopMorphHead')

    if request_morhp_pop_head_method == nil then
        log.debug('morph head method not finded')
        return
    end

    local hit_manager_singleton = sdk.get_managed_singleton('app.HitManager')
    if hit_manager_singleton == nil then
        log.debug('HitManager not exists')
        return
    end

    local hit_manager_type = hit_manager_singleton:get_type_definition()
    local update_damage_method = hit_manager_type:get_method('updateDamage')
    local calc_damage_dir_method = hit_manager_type:get_method('calcDamageDir')

    if update_damage_method == nil then
        log.debug('update_damage not exists')
        return
    end

    sdk.hook(
        request_morhp_pop_head_method,
        function(args)
            local zm_updater = sdk.to_managed_object(args[2])


            local hit_controller = sdk.to_managed_object(zm_updater:get_field('<HitController>k__BackingField'))


            if hit_controller == nil then
                log.debug('no hit controller')
                return
            end

            local game_object = zm_updater:call('get_GameObject()')

            if game_object == nil then
                log.debug('no game object')
                return
            end

            local enemy_name = game_object:call('get_Name()')

            game_object:call('set_Name(System.String)', enemy_name .. '_' .. moprh_postfix)
        end,
        function(retval) return retval end
    )

    sdk.hook(
        update_damage_method,
        function(args)
            local hit_info = sdk.to_managed_object(args[3])
            local damage_user_data = sdk.to_managed_object(hit_info:get_field('<DamageUserData>k__BackingField'))
            local attack_data = sdk.to_managed_object(hit_info:get_field('<AttackData>k__BackingField'))

            if args[4] == nil then
                log.debug('args4 is null')
            end

            if damage_user_data == nil or attack_data == nil then
                log.debug('damaga user data nil')
                return
            end

            local damage_hit_controller = sdk.to_managed_object(hit_info:get_field(
                '<DamageHitController>k__BackingField'))

            if damage_hit_controller == nil then
                log.debug('NO DAMAGE HIT CONTROLLER')
            end

            local attack_owner = sdk.to_managed_object(damage_hit_controller:call('get_AttackOwner()'))

            if attack_owner == nil then
                log.debug('Attack Owner not exists')
                return
            end


            local body_parts = damage_user_data:get_field('_BodyParts')
            ---@type string
            local enemy_name = attack_owner:call('get_Name()')

            local is_enemy_basic_zombie = enemy_name:match(zombie_prefix_name)
            local is_not_morphed = not enemy_name:find(moprh_postfix, 1)

            local is_excluded = false

            for zombie_type in pairs(excluded_zombie_types_table)
            do
                if enemy_name:find(zombie_type, 1)
                then
                    is_excluded = true
                end
            end

            if head_body_parts_set:has(body_parts)
                and is_enemy_basic_zombie
                and is_not_morphed
                and not excluded_zombie_types:has()
                and not is_excluded
            then
                headshot_context = sdk.get_thread_context()
            end
        end,
        function(retval)
            return retval
        end
    )

    sdk.hook(calc_damage_dir_method,
        function(args)
            local damage_info = sdk.to_managed_object(args[3])
            local thread_context = sdk:get_thread_context()

            if headshot_context == thread_context then
                log.debug('HEADSHOT CONTEXT ' .. tostring(headshot_context))
                log.debug('CURRENT CONTEXT ' .. tostring(thread_context))
                damage_info:set_field('<Damage>k__BackingField', 999999)
            end
        end,
        function(retval)
            return retval
        end
    )
end

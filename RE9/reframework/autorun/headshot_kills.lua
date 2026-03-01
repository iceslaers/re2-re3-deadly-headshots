local api = require('REFrameworkAPI')
local Set = require('helpers.set')

local sdk = api.sdk
local log = api.log

local head_body_parts_set = Set:new({
    0,
    1
})

local zombie_prefix_name = 'cp_B0'

local is_headshot_in_context = false

-- Zombies
-- cp_B070
-- cp_B001
-- cp_B000

-- cp_D100 Mr Gideon

do
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

            if head_body_parts_set:has(body_parts) and is_enemy_basic_zombie then
                is_headshot_in_context = true
            end
        end,
        function(retval)
            return retval
        end
    )

    sdk.hook(calc_damage_dir_method,
        function(args)
            local damage_info = sdk.to_managed_object(args[3])

            if is_headshot_in_context then
                damage_info:set_field('<Damage>k__BackingField', 999999)
            end
            is_headshot_in_context = false
        end,
        function(retval)
            return retval
        end
    )
end

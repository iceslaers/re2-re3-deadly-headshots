local api = require('REFrameworkAPI')
local Set = require('helpers.set')

local sdk = api.sdk
local log = api.log

local head_body_parts_set = Set:new({
    0,
    1
})

local is_headshot_in_context = false


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

            if damage_user_data == nil or attack_data == nil then
                log.debug('damaga user data nil')
                return
            end

            local body_parts = damage_user_data:get_field('_BodyParts')

            if head_body_parts_set:has(body_parts) then
                log.debug('ITS HEAD')
                log.debug('BodyParts= ' .. tostring(damage_user_data:get_field('_BodyParts')))
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

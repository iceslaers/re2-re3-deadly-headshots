local api = require('REFrameworkAPI')
local sdk = api.sdk
local log = api.log
local Set = require('helpers.set')


local HEAD_BODY_PART = 0
local ATTACK_TYPE_SHOT = 1

local ALLOWD_KIND_ID_SET = Set:new({
    4,  -- base zombies
    5,  -- base zombies
    6,  -- base zombies
    17, --insectoids
})
-- zombies 4,5
-- nemesis 23
-- canalisation monsters 16
-- dogs 18


local hit_manager_type = sdk.find_type_definition('offline.Collision.HitManager')
local calc_damage_method = hit_manager_type:get_method('calcDamage')


if calc_damage_method
then
    sdk.hook(
        calc_damage_method,
        function(args)
            local damage_info = sdk.to_managed_object(args[3])
            local enemy_controller = sdk.to_managed_object(args[4])

            if not enemy_controller then
                log.debug('NO EMENY CONTROLLER')
                return
            end

            local damage_user_data = sdk.to_managed_object(damage_info:get_field('<DamageUserData>k__BackingField'))
            local attack_user_data = sdk.to_managed_object(damage_info:get_field('<AttackUserData>k__BackingField'))
            local parts = damage_user_data:get_field('Parts')
            local attack_type = attack_user_data:get_field('AttackType')
            local kind_id = enemy_controller:call('get_KindID()')

            if parts == HEAD_BODY_PART
                and attack_type == ATTACK_TYPE_SHOT
                and ALLOWD_KIND_ID_SET:has(kind_id)
            then
                damage_info:set_field('<Damage>k__BackingField', 99999)
            end
        end,
        function(retval)
            return retval
        end
    )
end

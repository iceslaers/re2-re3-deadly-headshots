local api = require('REFrameworkAPI')
local Set = require('helpers.set')
local sdk = api.sdk

local HEAD_BODY_PART = 1

local enemy_types = Set:new({
    'cp_B000',
    'cp_B001',
    'cp_B003',
    'cp_B004',
    'cp_B005',
    'cp_B006',
    'cp_B007',
    'cp_B030',
    'cp_B032',
    'cp_B050',
    'cp_B051',
    'cp_B052',
    'cp_B053',
    'cp_B054',
    'cp_B060',
    'cp_B070'
})





local enemy_attack_driver_type = sdk.find_type_definition('app.EnemyAttackDamageDriver')
local update_damage_method = enemy_attack_driver_type:get_method('updateDamage')

sdk.hook(
    update_damage_method,
    function(args)
        --blister zombie flag
        local is_morphed = nil
        local enemy_attack_damage_driver = sdk.to_managed_object(args[2])
        local enemy_context = sdk.to_managed_object(enemy_attack_damage_driver:call('get_Context()'))

        local damage_info = sdk.to_managed_object(args[3])
        local damage_user_data = sdk.to_managed_object(damage_info:get_field('<DamageUserData>k__BackingField'))
        local body_part = damage_user_data:get_field('_BodyParts')
        ---@type REManagedObject
        local character_kind_id = enemy_context:call('get_KindID()')

        local morph_status_data = sdk.to_managed_object(enemy_context:get_field('<MorphStatusData>k__BackingField'))

        if morph_status_data then
            is_morphed = morph_status_data:get_field('_IsMorphed')
        end

        local character_kind_name = character_kind_id:get_field('_Name')

        if not is_morphed
            and body_part == HEAD_BODY_PART
            and enemy_types:has(character_kind_name)
        then
            damage_info:set_field('<Damage>k__BackingField', 99999)
        end
    end,
    function(retval)
        return retval
    end
)

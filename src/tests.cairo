#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use debug::PrintTrait;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use pixelaw::core::models::registry::{app, app_name, core_actions_address};

    use pixelaw::core::models::pixel::{Pixel, PixelUpdate};
    use pixelaw::core::models::pixel::{pixel};
    use pixelaw::core::models::permissions::{permissions};
    use pixelaw::core::utils::{get_core_actions, Direction, Position, DefaultParameters};
    use pixelaw::core::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    use dojo::test_utils::{spawn_test_world, deploy_contract};

    use myapp::app::{
        minesweeper_actions, IMinesweeperActionsDispatcher, IMinesweeperActionsDispatcherTrait
    };

    use zeroable::Zeroable;

    // Helper function: deploys world and actions
    fn deploy_world() -> (IWorldDispatcher, IActionsDispatcher, IMinesweeperActionsDispatcher) {
        // Deploy World and models
        let world = spawn_test_world(
            array![
                pixel::TEST_CLASS_HASH,
                app::TEST_CLASS_HASH,
                app_name::TEST_CLASS_HASH,
                core_actions_address::TEST_CLASS_HASH,
                permissions::TEST_CLASS_HASH,
            ]
        );

        // Deploy Core actions
        let core_actions_address = world
            .deploy_contract('salt1', actions::TEST_CLASS_HASH.try_into().unwrap());
        let core_actions = IActionsDispatcher { contract_address: core_actions_address };

        // Deploy MyApp actions
        let minesweeper_actions_address = world
            .deploy_contract('salt2', minesweeper_actions::TEST_CLASS_HASH.try_into().unwrap());
        let minesweeper_actions = IMinesweeperActionsDispatcher { contract_address: minesweeper_actions_address };

        // Setup dojo auth
        world.grant_writer('Pixel', core_actions_address);
        world.grant_writer('App', core_actions_address);
        world.grant_writer('AppName', core_actions_address);
        world.grant_writer('CoreActionsAddress', core_actions_address);
        world.grant_writer('Permissions', core_actions_address);

        world.grant_writer('Game',minesweeper_actions_address);

        (world, core_actions, minesweeper_actions)
    }

    #[test]
    #[available_gas(3000000000)]
    fn test_minesweeper_actions() {
        // Deploy everything
        let (world, core_actions, minesweeper_actions) = deploy_world();

        core_actions.init();
        minesweeper_actions.init();

        let player1 = starknet::contract_address_const::<0x1337>();
        starknet::testing::set_account_contract_address(player1);

        let color = encode_color(1, 1, 1);

        minesweeper_actions
            .interact(
                DefaultParameters {
                    for_player: Zeroable::zero(),
                    for_system: Zeroable::zero(),
                    position: Position { x: 1, y: 1 },
                    color: color
                },
                size: 5,
                mines_amount: 10
            );

        let pixel_1_1 = get!(world, (1, 1), (Pixel));
        assert(pixel_1_1.color == color, 'should be the color');

        'Passed test'.print();
    }

    fn encode_color(r: u8, g: u8, b: u8) -> u32 {
        (r.into() * 0x10000) + (g.into() * 0x100) + b.into()
    }

    fn decode_color(color: u32) -> (u8, u8, u8) {
        let r = (color / 0x10000);
        let g = (color / 0x100) & 0xff;
        let b = color & 0xff;

        (r.try_into().unwrap(), g.try_into().unwrap(), b.try_into().unwrap())
    }

    #[test]
    #[available_gas(3000000000)]
    fn test_create_minefield() {
        // Deploy everything
        let (world, core_actions, minesweeper_actions) = deploy_world();

        core_actions.init();
        minesweeper_actions.init();

        // Impersonate player
        let player = starknet::contract_address_const::<0x1337>();
        starknet::testing::set_account_contract_address(player);

        //computer variables
        let size: u64 = 5;
        let mines_amount: u64 = 10;

        // Player creates minefield
        minesweeper_actions
            .interact(
                DefaultParameters {
                    for_player: Zeroable::zero(),
                    for_system: Zeroable::zero(),
                    position: Position { x: 1, y: 1 },
                    color: 0
                },
                size,
                mines_amount
            );
    }
}

module staking::staking_tests {
    use sui::test_scenario;
    use staking::simple_staking::{self, StakingPool};
    use sui::coin;
    use sui::clock;

    #[test]
    fun test_stake_and_view() {
        let admin = @0xAD;
        let alice = @0xA;
        let mut scenario = test_scenario::begin(admin);

        // Initialize pool
        { simple_staking::init(test_scenario::ctx(&mut scenario)); };

        // Alice stakes 1000 SUI
        test_scenario::next_tx(&mut scenario, alice);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            let clk = clock::create_for_testing(test_scenario::ctx(&mut scenario));
            let stake_coin = coin::mint_for_testing<sui::sui::SUI>(1000, test_scenario::ctx(&mut scenario));
            simple_staking::stake(&mut pool, stake_coin, &clk, test_scenario::ctx(&mut scenario));
            assert!(simple_staking::get_stake_amount(&pool, alice) == 1000, 0);
            clock::destroy_for_testing(clk);
            test_scenario::return_shared(pool);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_full_stake_unstake_cycle() {
        let admin = @0xAD;
        let alice = @0xA;
        let mut scenario = test_scenario::begin(admin);

        // Initialize pool
        { simple_staking::init(test_scenario::ctx(&mut scenario)); };

        // Add rewards to pool (admin)
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            let reward_coin = coin::mint_for_testing<sui::sui::SUI>(1000, test_scenario::ctx(&mut scenario));
            simple_staking::add_rewards(&mut pool, reward_coin, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(pool);
        };

        // Alice stakes
        test_scenario::next_tx(&mut scenario, alice);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            let clk = clock::create_for_testing(test_scenario::ctx(&mut scenario));
            let stake_coin = coin::mint_for_testing<sui::sui::SUI>(1000, test_scenario::ctx(&mut scenario));
            simple_staking::stake(&mut pool, stake_coin, &clk, test_scenario::ctx(&mut scenario));
            clock::destroy_for_testing(clk);
            test_scenario::return_shared(pool);
        };

        // Fast forward 30 days and unstake
        test_scenario::next_tx(&mut scenario, alice);
        {
            let mut pool = test_scenario::take_shared<StakingPool>(&scenario);
            let mut clk = clock::create_for_testing(test_scenario::ctx(&mut scenario));
            clock::increment_for_testing(&mut clk, simple_staking::LOCK_PERIOD_MS());
            simple_staking::unstake(&mut pool, &clk, test_scenario::ctx(&mut scenario));
            clock::destroy_for_testing(clk);
            test_scenario::return_shared(pool);
        };

        test_scenario::end(scenario);
    }
}

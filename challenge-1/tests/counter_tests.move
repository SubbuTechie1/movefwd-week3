module counter::counter_tests {
    use sui::test_scenario;
    use counter::counter::{self, Counter, AdminCap};

    #[test]
    fun test_create_and_increment() {
        let owner = @0xA;
        let mut scenario = test_scenario::begin(owner);

        // Create counter by owner
        { counter::create_counter(test_scenario::ctx(&mut scenario)); };

        // Another user increments
        test_scenario::next_tx(&mut scenario, @0xB);
        {
            let mut counter_obj = test_scenario::take_shared<Counter>(&scenario);
            counter::increment(&mut counter_obj, test_scenario::ctx(&mut scenario));
            assert!(counter::get_value(&counter_obj) == 1, 0);
            test_scenario::return_shared(counter_obj);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_admin_reset_and_reset_to() {
        let owner = @0xA;
        let mut scenario = test_scenario::begin(owner);

        // Create counter
        { counter::create_counter(test_scenario::ctx(&mut scenario)); };

        // Owner increments
        test_scenario::next_tx(&mut scenario, owner);
        {
            let mut counter_obj = test_scenario::take_shared<Counter>(&scenario);
            counter::increment_by(&mut counter_obj, 5, test_scenario::ctx(&mut scenario));
            assert!(counter::get_value(&counter_obj) == 5, 0);
            test_scenario::return_shared(counter_obj);
        };

        // Reset with admin cap
        test_scenario::next_tx(&mut scenario, owner);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            let mut counter_obj = test_scenario::take_shared<Counter>(&scenario);
            counter::reset(&admin_cap, &mut counter_obj, test_scenario::ctx(&mut scenario));
            assert!(counter::get_value(&counter_obj) == 0, 0);
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(counter_obj);
        };

        // Reset_to example: set to 42
        test_scenario::next_tx(&mut scenario, owner);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            let mut counter_obj = test_scenario::take_shared<Counter>(&scenario);
            counter::reset_to(&admin_cap, &mut counter_obj, 42, test_scenario::ctx(&mut scenario));
            assert!(counter::get_value(&counter_obj) == 42, 0);
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(counter_obj);
        };

        test_scenario::end(scenario);
    }
}

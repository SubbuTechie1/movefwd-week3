module counter::counter {
    use sui::object;
    use sui::tx_context;
    use sui::transfer;
    use sui::event;
    use std::vector;

    // Errors
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_INVALID_AMOUNT: u64 = 2;

    /// Admin capability: proves who can perform admin actions on a counter
    public struct AdminCap has key, store {
        id: UID,
        counter_id: ID,
    }

    /// Shared counter object
    public struct Counter has key {
        id: UID,
        owner: address,
        value: u64,
    }

    /// Events
    public struct CounterCreated has copy, drop {
        counter_id: ID,
        owner: address,
    }

    public struct CounterIncremented has copy, drop {
        counter_id: ID,
        old_value: u64,
        new_value: u64,
        incrementer: address,
    }

    public struct CounterReset has copy, drop {
        counter_id: ID,
        old_value: u64,
        new_value: u64,
        reset_by: address,
    }

    // Create counter and give the creator an AdminCap; share the counter so anyone can read/increment
    public entry fun create_counter(ctx: &mut TxContext) {
        let counter_uid = object::new(ctx);
        let counter_id = object::uid_to_inner(&counter_uid);
        let owner = tx_context::sender(ctx);

        let counter = Counter {
            id: counter_uid,
            owner,
            value: 0,
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
            counter_id,
        };

        event::emit(CounterCreated { counter_id, owner });

        transfer::share_object(counter);
        transfer::public_transfer(admin_cap, owner);
    }

    // Anyone can increment by 1
    public entry fun increment(counter: &mut Counter, ctx: &TxContext) {
        let old = counter.value;
        counter.value = counter.value + 1;
        event::emit(CounterIncremented {
            counter_id: object::id(counter),
            old_value: old,
            new_value: counter.value,
            incrementer: tx_context::sender(ctx),
        });
    }

    // Increment by a positive amount
    public entry fun increment_by(counter: &mut Counter, amount: u64, ctx: &TxContext) {
        assert!(amount > 0, E_INVALID_AMOUNT);
        let old = counter.value;
        counter.value = counter.value + amount;
        event::emit(CounterIncremented {
            counter_id: object::id(counter),
            old_value: old,
            new_value: counter.value,
            incrementer: tx_context::sender(ctx),
        });
    }

    // Read-only getter
    public fun get_value(counter: &Counter): u64 {
        counter.value
    }

    // Reset to 0 (admin only)
    public entry fun reset(admin_cap: &AdminCap, counter: &mut Counter, ctx: &TxContext) {
        // verify capability is for this counter
        assert!(admin_cap.counter_id == object::id(counter), E_NOT_AUTHORIZED);
        let old = counter.value;
        counter.value = 0;
        event::emit(CounterReset {
            counter_id: object::id(counter),
            old_value: old,
            new_value: 0,
            reset_by: tx_context::sender(ctx),
        });
    }

    // Reset to specific value (admin only)
    public entry fun reset_to(admin_cap: &AdminCap, counter: &mut Counter, new_value: u64, ctx: &TxContext) {
        assert!(admin_cap.counter_id == object::id(counter), E_NOT_AUTHORIZED);
        let old = counter.value;
        counter.value = new_value;
        event::emit(CounterReset {
            counter_id: object::id(counter),
            old_value: old,
            new_value,
            reset_by: tx_context::sender(ctx),
        });
    }
}


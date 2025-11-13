module staking::simple_staking {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use sui::event;
    use sui::transfer;
    use sui::object;
    use sui::tx_context;

    // Parameters
    const LOCK_PERIOD_MS: u64 = 30 * 24 * 60 * 60 * 1000; // 30 days
    const ANNUAL_REWARD_RATE: u64 = 10; // 10% APY
    const DAYS_IN_YEAR: u64 = 365;
    const MS_IN_DAY: u64 = 24 * 60 * 60 * 1000;

    // Errors
    const E_STAKE_LOCKED: u64 = 1;
    const E_NO_STAKE: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_ZERO_AMOUNT: u64 = 4;
    const E_ALREADY_STAKED: u64 = 5;

    // Per-user stake info (stored in table)
    public struct StakeInfo has store {
        amount: u64,
        stake_timestamp: u64,
    }

    // Shared staking pool (shared object)
    public struct StakingPool has key {
        id: UID,
        balance: Balance<SUI>,
        stakes: Table<address, StakeInfo>,
        total_staked: u64,
    }

    // Events
    public struct PoolCreated has copy, drop { pool_id: ID }
    public struct StakedEvent has copy, drop { staker: address, amount: u64, timestamp: u64 }
    public struct UnstakedEvent has copy, drop { staker: address, amount: u64, reward: u64, timestamp: u64 }

    // Initialize and share the pool
    public entry fun init(ctx: &mut TxContext) {
        let pool_uid = object::new(ctx);
        let pool_id = object::uid_to_inner(&pool_uid);

        let pool = StakingPool {
            id: pool_uid,
            balance: balance::zero(),
            stakes: table::new(ctx),
            total_staked: 0,
        };

        event::emit(PoolCreated { pool_id });
        transfer::share_object(pool);
    }

    // Stake SUI into the pool (one active stake per address in this simple version)
    public entry fun stake(pool: &mut StakingPool, stake_coin: Coin<SUI>, clock: &Clock, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let amount = coin::value(&stake_coin);
        assert!(amount > 0, E_ZERO_AMOUNT);
        assert!(!table::contains(&pool.stakes, sender), E_ALREADY_STAKED);

        let current_time = clock::timestamp_ms(clock);

        let stake_balance = coin::into_balance(stake_coin);
        balance::join(&mut pool.balance, stake_balance);

        let stake_info = StakeInfo { amount, stake_timestamp: current_time };
        table::add(&mut pool.stakes, sender, stake_info);
        pool.total_staked = pool.total_staked + amount;

        event::emit(StakedEvent { staker: sender, amount, timestamp: current_time });
    }

    // Unstake and claim rewards (only after lock period)
    public entry fun unstake(pool: &mut StakingPool, clock: &Clock, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(table::contains(&pool.stakes, sender), E_NO_STAKE);

        let stake_info = table::remove(&mut pool.stakes, sender);
        let current_time = clock::timestamp_ms(clock);

        assert!(is_unlocked(stake_info.stake_timestamp, current_time), E_STAKE_LOCKED);

        let reward = calculate_reward(stake_info.amount, stake_info.stake_timestamp, current_time);
        let total_payout = stake_info.amount + reward;

        assert!(balance::value(&pool.balance) >= total_payout, E_INSUFFICIENT_BALANCE);

        let payout_balance = balance::split(&mut pool.balance, total_payout);
        let payout_coin = coin::from_balance(payout_balance, ctx);

        pool.total_staked = pool.total_staked - stake_info.amount;

        event::emit(UnstakedEvent { staker: sender, amount: stake_info.amount, reward, timestamp: current_time });

        transfer::public_transfer(payout_coin, sender);
    }

    // Admin can add reward coins to pool
    public entry fun add_rewards(pool: &mut StakingPool, reward_coin: Coin<SUI>, _ctx: &mut TxContext) {
        let reward_balance = coin::into_balance(reward_coin);
        balance::join(&mut pool.balance, reward_balance);
    }

    // Reward calculation (integer math)
    public fun calculate_reward(amount: u64, stake_timestamp: u64, current_timestamp: u64): u64 {
        let time_elapsed = current_timestamp - stake_timestamp;
        let days_staked = time_elapsed / MS_IN_DAY;
        let effective_days = if (days_staked > DAYS_IN_YEAR) { DAYS_IN_YEAR } else { days_staked };
        // reward = amount * rate * days / (365 * 100)
        let reward = (amount * ANNUAL_REWARD_RATE * effective_days) / (DAYS_IN_YEAR * 100);
        reward
    }

    // Check lock
    public fun is_unlocked(stake_timestamp: u64, current_timestamp: u64): bool {
        current_timestamp >= stake_timestamp + LOCK_PERIOD_MS
    }

    // Read helpers
    public fun has_stake(pool: &StakingPool, user: address): bool {
        table::contains(&pool.stakes, user)
    }

    public fun get_stake_amount(pool: &StakingPool, user: address): u64 {
        if (!table::contains(&pool.stakes, user)) { return 0 };
        let s = table::borrow(&pool.stakes, user);
        s.amount
    }

    public fun get_pending_rewards(pool: &StakingPool, user: address, clock: &Clock): u64 {
        if (!table::contains(&pool.stakes, user)) { return 0 };
        let s = table::borrow(&pool.stakes, user);
        let current_time = clock::timestamp_ms(clock);
        calculate_reward(s.amount, s.stake_timestamp, current_time)
    }
}


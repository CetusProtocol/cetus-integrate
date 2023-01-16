module cetus_integrate::liquidity {
    use cetus_clmm::clmm_router::remove_liquidity;
    use cetus_integrate::rewarder::{
        collect_rewarder_for_two,
        collect_rewarder_for_three,
        collect_rewarder_for_one
    };

    public entry fun remove_all_liquidity<CoinA, CoinB, CoinC>(
        owner: &signer,
        pool_address: address,
        delta_liquidity: u128,
        min_amount_a: u64,
        min_amount_b: u64,
        pos_index: u64,
        is_close: bool,
    ) {
        remove_liquidity<CoinA, CoinB>(
            owner,
            pool_address,
            delta_liquidity,
            min_amount_a,
            min_amount_b,
            pos_index,
            is_close
        );
        collect_rewarder_for_one<CoinA, CoinB, CoinC>(owner, pool_address, pos_index);
    }

    public entry fun remove_all_liquidity_for_two<CoinA, CoinB, CoinC, CoinD>(
        owner: &signer,
        pool_address: address,
        delta_liquidity: u128,
        min_amount_a: u64,
        min_amount_b: u64,
        pos_index: u64,
        is_close: bool,
    ) {
        remove_liquidity<CoinA, CoinB>(
            owner,
            pool_address,
            delta_liquidity,
            min_amount_a,
            min_amount_b,
            pos_index,
            is_close
        );
        collect_rewarder_for_two<CoinA, CoinB, CoinC, CoinD>(owner, pool_address, pos_index);
    }

    public entry fun remove_all_liquidity_for_three<CoinA, CoinB, CoinC, CoinD, CoinE>(
        owner: &signer,
        pool_address: address,
        delta_liquidity: u128,
        min_amount_a: u64,
        min_amount_b: u64,
        pos_index: u64,
        is_close: bool,
    ) {
        remove_liquidity<CoinA, CoinB>(
            owner,
            pool_address,
            delta_liquidity,
            min_amount_a,
            min_amount_b,
            pos_index,
            is_close
        );
        collect_rewarder_for_three<CoinA, CoinB, CoinC, CoinD, CoinE>(owner, pool_address, pos_index);
    }
}
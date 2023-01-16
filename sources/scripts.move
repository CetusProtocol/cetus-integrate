module cetus_integrate::scripts {
    use std::string::String;
    use cetus_integrate::swap_router;
    use cetus_integrate::rewarder;
    use cetus_integrate::fetcher;
    use cetus_integrate::calculator;
    use cetus_integrate::liquidity;

    public entry fun extact_input_for_router_one<CoinA, CoinB>(
        account: signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_min_out: u64,
        partner: String
    ) {
        swap_router::exact_input_for_router_one<CoinA, CoinB>(
            &account,
            swap_directs,
            pool_addresses,
            amount,
            amount_min_out,
            partner
        );
    }

    public entry fun extact_output_for_router_one<CoinA, CoinB>(
        account: signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_min_out: u64,
        partner: String
    ) {
        swap_router::exact_output_for_router_one<CoinA, CoinB>(
            &account,
            swap_directs,
            pool_addresses,
            amount,
            amount_min_out,
            partner
        );
    }

    public entry fun exact_input_for_router_two<CoinA, CoinX, CoinB>(
        account: signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_min_out: u64,
        partner: String
    ) {
        swap_router::exact_input_for_router_two<CoinA, CoinX, CoinB>(
            &account,
            swap_directs,
            pool_addresses,
            amount,
            amount_min_out,
            partner
        );
    }

    public entry fun exact_output_for_router_two<CoinA, CoinX, CoinB>(
        account: signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_max_in: u64,
        partner: String
    ) {
        swap_router::exact_output_for_router_two<CoinA, CoinX, CoinB>(
            &account,
            swap_directs,
            pool_addresses,
            amount,
            amount_max_in,
            partner
        );
    }

    public entry fun exact_input_for_router_three<CoinA, CoinX, CoinY, CoinB>(
        account: signer,
        swap_directs: vector<bool>,
        pool_addersses: vector<address>,
        amount: u64,
        amount_min_out: u64,
        partner: String
    ) {
        swap_router::exact_input_for_router_three<CoinA, CoinX, CoinY, CoinB>(
            &account,
            swap_directs,
            pool_addersses,
            amount,
            amount_min_out,
            partner
        );
    }

    public entry fun exact_output_for_router_three<CoinA, CoinX, CoinY, CoinB>(
        account: signer,
        swap_direcets: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_max_in: u64,
        partner: String
    ) {
        swap_router::exact_output_for_router_three<CoinA, CoinX, CoinY, CoinB>(
            &account,
            swap_direcets,
            pool_addresses,
            amount,
            amount_max_in,
            partner
        );
    }

    public entry fun collect_rewarder_for_two<CoinA, CoinB, CoinC, CoinD>(
        owner: &signer,
        pool_address: address,
        pos_index: u64
    ) {
        rewarder::collect_rewarder_for_two<CoinA, CoinB, CoinC, CoinD>(
            owner,
            pool_address,
            pos_index
        );
    }

    public entry fun collect_rewarder_for_three<CoinA, CoinB, CoinC, CoinD, CoinE>(
        owner: &signer,
        pool_address: address,
        pos_index: u64
    ) {
        rewarder::collect_rewarder_for_three<CoinA, CoinB, CoinC, CoinD, CoinE>(
            owner,
            pool_address,
            pos_index
        );
    }

    public entry fun fetch_ticks<CoinA, CoinB>(
        account: &signer,
        pool_address: address,
        index: u64,
        offset: u64,
        limit: u64
    ) {
        fetcher::fetch_ticks<CoinA, CoinB>(
            account,
            pool_address,
            index,
            offset,
            limit
        );
    }

    public entry fun fetch_positions<CoinA, CoinB>(
        account: &signer,
        pool_address: address,
        index: u64,
        limit: u64
    ) {
        fetcher::fetche_positions<CoinA, CoinB>(
            account,
            pool_address,
            index,
            limit
        );
    }

    public entry fun calculate_swap_result<CoinA, CoinB>(
        account: &signer,
        pool_address: address,
        a2b: bool,
        by_amount_in: bool,
        amount: u64
    ) {
        calculator::calculate_swap_result<CoinA, CoinB>(
            account,
            pool_address,
            a2b,
            by_amount_in,
            amount
        )
    }
    public entry fun remove_all_liquidity<CoinA, CoinB, CoinC>(
        owner: &signer,
        pool_address: address,
        delta_liquidity: u128,
        min_amount_a: u64,
        min_amount_b: u64,
        pos_index: u64,
        is_close: bool,
    ) {
        liquidity::remove_all_liquidity<CoinA, CoinB, CoinC>(
            owner,
            pool_address,
            delta_liquidity,
            min_amount_a,
            min_amount_b,
            pos_index,
            is_close
        );
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
        liquidity::remove_all_liquidity_for_two<CoinA, CoinB, CoinC, CoinD>(
            owner,
            pool_address,
            delta_liquidity,
            min_amount_a,
            min_amount_b,
            pos_index,
            is_close
        );
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
        liquidity::remove_all_liquidity_for_three<CoinA, CoinB, CoinC, CoinD, CoinE>(
            owner,
            pool_address,
            delta_liquidity,
            min_amount_a,
            min_amount_b,
            pos_index,
            is_close
        );
    }
}

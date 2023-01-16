module cetus_integrate::calculator {
    use cetus_clmm::pool;

    struct CalculatedSwapResult has key {
        data: pool::CalculatedSwapResult
    }

    public fun calculate_swap_result<CoinTypeA, CoinTypeB>(
        account: &signer,
        pool_address: address,
        a2b: bool,
        by_amount_in: bool,
        amount: u64
    ) {
        let result = pool::calculate_swap_result<CoinTypeA, CoinTypeB>(
            pool_address,
            a2b,
            by_amount_in,
            amount
        );
        move_to(account, CalculatedSwapResult{
            data: result
        })
    }
}

module cetus_integrate::rewarder {
    use cetus_clmm::clmm_router::collect_rewarder;

    public fun collect_rewarder_for_one<CoinA, CoinB, CoinC>(
        owner: &signer,
        pool_address: address,
        pos_index: u64
    ) {
        collect_rewarder<CoinA, CoinB, CoinC>(owner, pool_address, 0, pos_index);
    }

    public fun collect_rewarder_for_two<CoinA, CoinB, CoinC, CoinD>(
        owner: &signer,
        pool_address: address,
        pos_index: u64
    ) {
        collect_rewarder<CoinA, CoinB, CoinC>(owner, pool_address, 0, pos_index);
        collect_rewarder<CoinA, CoinB, CoinD>(owner, pool_address, 1, pos_index);
    }

    public fun collect_rewarder_for_three<CoinA, CoinB, CoinC, CoinD, CoinE>(
        owner: &signer,
        pool_address: address,
        pos_index: u64
    ) {
        collect_rewarder<CoinA, CoinB, CoinC>(owner, pool_address, 0, pos_index);
        collect_rewarder<CoinA, CoinB, CoinD>(owner, pool_address, 1, pos_index);
        collect_rewarder<CoinA, CoinB, CoinE>(owner, pool_address, 2, pos_index);
    }
}

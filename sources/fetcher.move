module cetus_integrate::fetcher {
    use cetus_clmm::pool;

    struct FetchTicksResult has key {
        index: u64,
        offset: u64,
        ticks: vector<pool::Tick>
    }

    struct FetchPositionsResult has key {
        index: u64,
        positions: vector<pool::Position>
    }

    public fun fetch_ticks<CoinTypeA, CoinTypeB>(
        account: &signer,
        pool_address: address,
        index: u64,
        offset: u64,
        limit: u64
    ) {
        let (index, offset, ticks) =
            pool::fetch_ticks<CoinTypeA, CoinTypeB>(pool_address, index, offset, limit);
        move_to(account, FetchTicksResult{
            index,
            offset,
            ticks
        })
    }

    public fun fetche_positions<CoinTypeA, CoinTypeB>(
        account: &signer,
        pool_address: address,
        index: u64,
        limit: u64
    ) {
        let (index, positions) =
            pool::fetch_positions<CoinTypeA, CoinTypeB>(pool_address, index, limit);
        move_to(account, FetchPositionsResult {
            index,
            positions
        })
    }
}

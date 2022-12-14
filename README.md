# cetus-integrate
Integrate following this doc to easily swap with the concentrated liquidity pools of Cetus.

## How to integrate the Cetus Protocol swap api

The Cetus Protocol offers two ways to trade the coins, the normal swap and the flash_loan way.
### Swap

#### Signature
```
public entry fun swap<CoinTypeA, CoinTypeB>(
        account: &signer,
        pool_address: address,
        a_to_b: bool,
        by_amount_in: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_limit: u128,
        partner: String,
    ) 
```
#### Params

1. pool_address: address of the pool want to trade; pool is a resource account.
2. a_to_b: the `Pool` struct has coin_a and coin_b, so if swap from coin_a to coin_b then the `a_to_b` if true, vice versa.
3. by_amount_in: indicate the `amount` parameter is swap in coin amount to be consumed or output amount returned. 
4. amount: the coin amount want to swap, which is work together with `by_amount_in`.
5. amount_limit: this param is also work with `by_amount_in` and `a_to_b`. 
6. sqrt_price_limit: the sqrt_price limit. when `a_to_b` is true, the price of the pool will down and when `a_to_b` is false, the price of the pool will up. In general, you can provide the max and min sqrt_price in normal trade request; the protocol max_sqrt_price is 79226673515401279992447579055 and min_sqrt_prices is 4295048016.
7. partner: the partner can be empty string or the partner name provided by the protocol. When the partner is not empty and is a valid partner, and the partner can receier part of the protocol_fee the pool owned. The partner is a resource account, and anytime the partner authority can claim the partner fee received.


Exp, if `by_amount_in` and `a_to_b` are both true so the `amount` is coin_a amount the user want to trade exactly, and the `amount_limit` is the minimum coin_b amount to receive the user can accpet; 

if `by_amount_in` is false and `a_to_b` is true so the `amount` is coin_b amount the user want to get and the coin_a is variable, `amount_limit` is the maximum coin_a amount the user want to be consumed by the pool.

### Flash_Swap

The flash-swap split the swap process into two entry function, providing the function that the user can get the ouput coin first in the `flash_swap` method and then return the input coin in the `repay_flash_swap` method. In the two method gap you can do what you want.
Since the "hot potato" struct `FlashSwapReceipt` doesn’t have a drop, key, or store capability, it’s guaranteed that its "destroy" function `repay_flash_swap` must be called in order to consume it. The `FlashSwapReceipt` struct fields store some swap detail the `repay_flash_swap` needed and will be check in this method.

#### Signature
```
public entry fun flash_swap<CoinTypeA, CoinTypeB>(
        account: &signer,
        pool_address: address,
        a_to_b: bool,
        by_amount_in: bool,
        amount: u64,
        sqrt_price_limit: u128,
    ): (Coin<CoinTypeA>, Coin<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>)


public entry fun repay_flash_swap<CoinTypeA, CoinTypeB>(
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        receipt: FlashSwapReceipt<CoinTypeA, CoinTypeB>
    )
```
#### Params

1. pool_address: address of the pool want to trade; pool is a resource account.
2. a_to_b: the `Pool` struct has coin_a and coin_b, so if swap from coin_a to coin_b then the `a_to_b` if true, vice versa.
3. by_amount_in: indicate the `amount` parameter is swap in coin amount to be consumed or output amount returned. 
4. amount: the coin amount want to swap, which is work together with `by_amount_in`.
5. sqrt_price_limit: the sqrt_price limit. when `a_to_b` is true, the price of the pool will down and when `a_to_b` is false, the price of the pool will up. In general, you can provide the max and min sqrt_price in normal trade request; the protocol max_sqrt_price is 79226673515401279992447579055 and min_sqrt_prices is 4295048016.
6. coin_a: the coin_a resource return to the pool. when `a_to_b` is true then coin_a is the input coin and coin_b amount is zero.
7. coin_b: the coin_b resource return to the pool. when `a_to_b` is false then coin_b is the input coin and coin_a amount is zero.

#### Returns

If `a_to_b` is true, the first return value is coin_a and the amount is zero, and second return value is the coin_b the user will get.
If `a_to_b` is false, the coin_b amount is zero, and coin_a is coin resource the user will get.
`FlashSwapReceipt` is the "hot potato" which make the falsh-swap works.

### Mainnet Module Address

> 0xf03607bec13972d4768441ed8eb30a50e88804808f61e4f1c355e525f851277c

### Get the pool list

The swap pair list is store in the `data` field of the `Pools` struct.

1. retrieve the `{module_address}::factory::Pools` resource.

2. Parse the resource, the `data` field is SimpleMap type and value is the pool address.

```

struct PoolId has store, copy, drop {
        coin_type_a: TypeInfo,
        coin_type_b: TypeInfo,
        tick_spacing: u64
    }

struct Pools has key {
    data: SimpleMap<PoolId, address>,
    create_pool_events: EventHandle<CreatePoolEvent>,
    index: u64,
}
```

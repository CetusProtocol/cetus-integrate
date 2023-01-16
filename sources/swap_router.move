module cetus_integrate::swap_router {
    use std::signer;
    use std::string::String;
    use std::vector;
    use cetus_clmm::tick_math::{min_sqrt_price, max_sqrt_price};
    use cetus_clmm::pool::{flash_swap, repay_flash_swap, FlashSwapReceipt, swap_pay_amount};
    use aptos_framework::coin::{Self, Coin};
    use std::error;
    use std::option::{Self, Option};

    // Errors codes.

    // Parameter invalied
    const ERR_PARAMETER_INVALIED: u64 = 1;
    // Swap amount incorrect
    const ERR_SWAP_AMOUNT_INCORRECT: u64 = 2;
    /// Insufficient amount in
    const ERR_INSUFFICIENT_IN_AMOUNT: u64 = 3;
    /// Insufficient amount out
    const ERR_INSUFFICIENT_OUT_AMOUNT: u64 = 4;

    public fun exact_input<CoinA, CoinB>(
        coin_in_a: Coin<CoinA>,
        coin_in_b: Coin<CoinB>,
        swap_from: address,
        pool_address: address,
        a_to_b: bool,
        amount: u64,
        partner: String
    ): Coin<CoinB> {
        let (coin_swaped_a, coin_swaped_b);
        if (a_to_b) {
            (coin_swaped_a, coin_swaped_b) = exact_input_internal<CoinA, CoinB>(
                coin_in_a,
                coin_in_b,
                swap_from,
                pool_address,
                true,
                amount,
                partner);
        } else {
            (coin_swaped_b, coin_swaped_a) = exact_input_internal<CoinB, CoinA>(
                coin_in_b,
                coin_in_a,
                swap_from,
                pool_address,
                false,
                amount,
                partner);
        };
        coin::destroy_zero(coin_swaped_a);
        coin_swaped_b
    }

    public fun exact_input_internal<CoinA, CoinB>(
        coin_in_a: Coin<CoinA>,
        coin_in_b: Coin<CoinB>,
        swap_from: address,
        pool_address: address,
        a_to_b: bool,
        amount: u64,
        partner: String
    ): (Coin<CoinA>, Coin<CoinB>) {
        let sqrt_price_limit = if (a_to_b) {
            min_sqrt_price()
        } else {
            max_sqrt_price()
        };
        let (coin_swaped_a, coin_swaped_b, receipt);
        (coin_swaped_a, coin_swaped_b, receipt) = flash_swap<CoinA, CoinB>(
            pool_address,
            swap_from,
            partner,
            a_to_b,
            true,
            amount,
            sqrt_price_limit
        );

        let pay_amount = swap_pay_amount(&receipt);
        assert!(pay_amount == amount, error::aborted(ERR_SWAP_AMOUNT_INCORRECT));
        if (a_to_b) {
            coin::destroy_zero(coin_in_b);
            repay_flash_swap<CoinA, CoinB>(coin_in_a, coin::zero<CoinB>(), receipt);
        } else {
            coin::destroy_zero(coin_in_a);
            repay_flash_swap<CoinA, CoinB>(coin::zero<CoinA>(), coin_in_b, receipt);
        };
        (coin_swaped_a, coin_swaped_b)
    }

    public fun exact_output_internal<CoinA, CoinB>(
        swap_from: address,
        pool_address: address,
        a_to_b: bool,
        amount: u64,
        partner: String
    ): (Coin<CoinA>, Coin<CoinB>, FlashSwapReceipt<CoinA, CoinB>) {
        let sqrt_price_limit = if (a_to_b) {
            min_sqrt_price()
        } else {
            max_sqrt_price()
        };

        flash_swap<CoinA, CoinB>(
            pool_address,
            swap_from,
            partner,
            a_to_b,
            false,
            amount,
            sqrt_price_limit
        )
    }

    public fun exact_output<CoinA, CoinB>(
        swap_from: address,
        pool_address: address,
        a_to_b: bool,
        amount: u64,
        partner: String
    ): (Coin<CoinA>, Coin<CoinB>, Option<FlashSwapReceipt<CoinA, CoinB>>, Option<FlashSwapReceipt<CoinB, CoinA>>) {
        // TODO: destroy first returned coin
        if (a_to_b) {
            let (coin_swaped_a, coin_swaped_b, receipt) = exact_output_internal<CoinA, CoinB>(
                swap_from,
                pool_address,
                true,
                amount,
                partner);
            (coin_swaped_a, coin_swaped_b, option::some(receipt), option::none<FlashSwapReceipt<CoinB, CoinA>>())
        } else {
            let (coin_swaped_b, coin_swaped_a, receipt) = exact_output_internal<CoinB, CoinA>(
                swap_from,
                pool_address,
                false,
                amount,
                partner);
            (coin_swaped_a, coin_swaped_b, option::none<FlashSwapReceipt<CoinA, CoinB>>(), option::some(receipt))
        }
    }

    public fun exact_input_for_router_one<CoinA, CoinB>(
        account: &signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_min_out: u64,
        partner: String
    ) {
        assert!(
            vector::length(&swap_directs) == 1 &&
                vector::length(&pool_addresses) == 1,
            error::aborted(ERR_PARAMETER_INVALIED)
        );

        let coin_in_a= coin::withdraw<CoinA>(account, amount);
        let sender_address = signer::address_of(account);
        let swap_direct = *vector::borrow(&swap_directs, 0);
        let pool_address = *vector::borrow(&pool_addresses, 0);
        let coin_swaped_b = exact_input<CoinA, CoinB>(
            coin_in_a,
            coin::zero(),
            sender_address,
            pool_address,
            swap_direct,
            amount,
            partner
        );
        let amount = coin::value(&coin_swaped_b);
        assert!(amount >= amount_min_out, error::aborted(ERR_INSUFFICIENT_OUT_AMOUNT));

        coin_register<CoinB>(account);
        coin::deposit(sender_address, coin_swaped_b)
    }

    public fun exact_output_for_router_one<CoinA, CoinB>(
        account: &signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_max_in: u64,
        partner: String
    ) {
        assert!(
            vector::length(&swap_directs) == 1 &&
                vector::length(&pool_addresses) == 1,
            error::aborted(ERR_PARAMETER_INVALIED)
        );

        let sender_address = signer::address_of(account);
        let pool_address = *vector::borrow(&pool_addresses, 0);
        let swap_direct_for_a_to_b= *vector::borrow(&swap_directs, 0);
        let (coin_swaped_a,
            coin_swaped_b,
            maybe_receipt_a_b,
            maybe_receipt_b_a
        ) = exact_output<CoinA, CoinB>(
            sender_address,
            pool_address,
            swap_direct_for_a_to_b,
            amount,
            partner
        );
        coin::destroy_zero(coin_swaped_a);

        let amount = if (swap_direct_for_a_to_b) {
            swap_pay_amount(option::borrow(&maybe_receipt_a_b))
        } else {
            swap_pay_amount(option::borrow(&maybe_receipt_b_a))
        };
        assert!(amount <= amount_max_in, error::aborted(ERR_INSUFFICIENT_IN_AMOUNT));

        let coin_input = coin::withdraw<CoinA>(account, amount);
        if (swap_direct_for_a_to_b) {
            option::destroy_none(maybe_receipt_b_a);
            repay_flash_swap(coin_input, coin::zero<CoinB>(), option::destroy_some(maybe_receipt_a_b));
        } else {
            option::destroy_none(maybe_receipt_a_b);
            repay_flash_swap(coin::zero<CoinB>(), coin_input, option::destroy_some(maybe_receipt_b_a));
        };

        coin_register<CoinB>(account);
        coin::deposit(sender_address, coin_swaped_b)
    }

    public fun exact_input_for_router_two<CoinA, CoinX, CoinB>(
        account: &signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_min_out: u64,
        partner: String
    ) {
        assert!(
            vector::length(&swap_directs) == 2 &&
                vector::length(&pool_addresses) == 2,
            error::aborted(ERR_PARAMETER_INVALIED)
        );

        let coin_in_a = coin::withdraw<CoinA>(account, amount);
        let sender_address = signer::address_of(account);
        let pool_address = *vector::borrow(&pool_addresses, 0);
        let swap_direct = *vector::borrow(&swap_directs, 0);
        let coin_swaped_x = exact_input<CoinA, CoinX>(
            coin_in_a,
            coin::zero(),
            sender_address,
            pool_address,
            swap_direct,
            amount,
            partner
        );

        let coin_in_x = coin_swaped_x;
        let amount = coin::value(&coin_in_x);
        let pool_address = *vector::borrow(&pool_addresses, 1);
        let swap_direct = *vector::borrow(&swap_directs, 1);
        let coin_swaped_b = exact_input<CoinX, CoinB>(
            coin_in_x,
            coin::zero(),
            sender_address,
            pool_address,
            swap_direct,
            amount,
            partner
        );

        let amount = coin::value(&coin_swaped_b);
        assert!(amount >= amount_min_out, error::aborted(ERR_INSUFFICIENT_OUT_AMOUNT));

        coin_register<CoinB>(account);
        coin::deposit(sender_address, coin_swaped_b);
    }

    public fun exact_output_for_router_two<CoinA, CoinX, CoinB>(
        account: &signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_max_in: u64,
        partner: String
    ) {
        assert!(
            vector::length(&swap_directs) == 2 &&
                vector::length(&pool_addresses) == 2,
            error::aborted(ERR_PARAMETER_INVALIED)
        );

        let sender_address = signer::address_of(account);
        let pool_address = *vector::borrow(&pool_addresses, 1);
        let swap_direct_for_x_to_b = *vector::borrow(&swap_directs, 1);
        let (coin_swaped_x,
            coin_swaped_b,
            maybe_receipt_x_b,
            maybe_receipt_b_x
        ) = exact_output<CoinX, CoinB>(
            sender_address,
            pool_address,
            swap_direct_for_x_to_b,
            amount,
            partner
        );


        let amount = if (swap_direct_for_x_to_b) {
            swap_pay_amount(option::borrow(&maybe_receipt_x_b))
        } else {
            swap_pay_amount(option::borrow(&maybe_receipt_b_x))
        };

        coin::destroy_zero(coin_swaped_x);

        let pool_address = *vector::borrow(&pool_addresses, 0);
        let swap_direct_for_a_to_x = *vector::borrow(&swap_directs, 0);
        let (coin_swaped_a,
            coin_swaped_x,
            maybe_receipt_for_a_x,
            maybe_receipt_for_x_a
        ) = exact_output<CoinA, CoinX>(
            sender_address,
            pool_address,
            swap_direct_for_a_to_x,
            amount,
            partner
        );

        coin::destroy_zero(coin_swaped_a);

        if (swap_direct_for_x_to_b) {
            repay_flash_swap<CoinX, CoinB>(coin_swaped_x, coin::zero<CoinB>(), option::destroy_some(maybe_receipt_x_b));
            option::destroy_none(maybe_receipt_b_x);
        } else {
            repay_flash_swap<CoinB, CoinX>(coin::zero<CoinB>(), coin_swaped_x, option::destroy_some(maybe_receipt_b_x));
            option::destroy_none(maybe_receipt_x_b);
        };

        let amount = if (swap_direct_for_a_to_x) {
            swap_pay_amount(option::borrow(&maybe_receipt_for_a_x))
        } else {
            swap_pay_amount(option::borrow(&maybe_receipt_for_x_a))
        };

        let coin_a = coin::withdraw<CoinA>(account, amount);
        if (swap_direct_for_a_to_x) {
            repay_flash_swap<CoinA, CoinX>(coin_a, coin::zero<CoinX>(), option::destroy_some(maybe_receipt_for_a_x));
            option::destroy_none(maybe_receipt_for_x_a);
        } else {
            repay_flash_swap<CoinX, CoinA>(coin::zero<CoinX>(), coin_a, option::destroy_some(maybe_receipt_for_x_a));
            option::destroy_none(maybe_receipt_for_a_x);
        };

        assert!(amount <= amount_max_in, error::aborted(ERR_INSUFFICIENT_IN_AMOUNT));

        coin_register<CoinB>(account);
        coin::deposit(sender_address, coin_swaped_b);
    }

    public fun exact_input_for_router_three<CoinA, CoinX, CoinY, CoinB>(
        account: &signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_min_out: u64,
        partner: String
    ) {
        assert!(
            vector::length(&swap_directs) == 3 &&
                vector::length(&pool_addresses) == 3,
            error::aborted(ERR_PARAMETER_INVALIED)
        );
        let coin_in_a = coin::withdraw<CoinA>(account, amount);
        let sender_address = signer::address_of(account);
        let pool_address = *vector::borrow(&pool_addresses, 0);
        let swap_direct = *vector::borrow(&swap_directs, 0);
        let coin_swaped_x = exact_input<CoinA, CoinX>(
            coin_in_a,
            coin::zero(),
            sender_address,
            pool_address,
            swap_direct,
            amount,
            partner
        );

        let coin_in_x = coin_swaped_x;
        let amount = coin::value(&coin_in_x);
        let pool_address = *vector::borrow(&pool_addresses, 1);
        let swap_direct = *vector::borrow(&swap_directs, 1);
        let coin_swaped_y = exact_input<CoinX, CoinY>(
            coin_in_x,
            coin::zero(),
            sender_address,
            pool_address,
            swap_direct,
            amount,
            partner
        );

        let coin_in_y = coin_swaped_y;
        let amount = coin::value(&coin_in_y);
        let pool_address = *vector::borrow(&pool_addresses, 2);
        let swap_direct = *vector::borrow(&swap_directs, 2);
        let coin_swaped_b = exact_input<CoinY, CoinB>(
            coin_in_y,
            coin::zero(),
            sender_address,
            pool_address,
            swap_direct,
            amount,
            partner
        );

        let amount = coin::value(&coin_swaped_b);
        assert!(amount >= amount_min_out, error::aborted(ERR_INSUFFICIENT_OUT_AMOUNT));

        coin_register<CoinB>(account);
        coin::deposit(sender_address, coin_swaped_b);
    }

    public fun exact_output_for_router_three<CoinA, CoinX, CoinY, CoinB>(
        account: &signer,
        swap_directs: vector<bool>,
        pool_addresses: vector<address>,
        amount: u64,
        amount_max_in: u64,
        partner: String
    ) {
        assert!(
            vector::length(&swap_directs) == 3 &&
                vector::length(&pool_addresses) == 3,
            error::aborted(ERR_PARAMETER_INVALIED)
        );

        let sender_address = signer::address_of(account);
        let pool_address = *vector::borrow(&pool_addresses, 2);
        let swap_direct_for_y_to_b = *vector::borrow(&swap_directs, 2);
        let (coin_swaped_y,
            coin_swaped_b,
            maybe_receipt_for_y_b,
            maybe_receipt_for_b_y
        ) = exact_output<CoinY, CoinB>(
            sender_address,
            pool_address,
            swap_direct_for_y_to_b,
            amount,
            partner
        );

        let amount = if (swap_direct_for_y_to_b) {
            swap_pay_amount(option::borrow(&maybe_receipt_for_y_b))
        } else {
            swap_pay_amount(option::borrow(&maybe_receipt_for_b_y))
        };

        coin::destroy_zero(coin_swaped_y);

        let pool_address = *vector::borrow(&pool_addresses, 1);
        let swap_direct_for_x_to_y = *vector::borrow(&swap_directs, 1);
        let (coin_swaped_x,
            coin_swaped_y,
            maybe_receipt_for_x_y,
            maybe_receipt_for_y_x
        ) = exact_output<CoinX, CoinY>(
            sender_address,
            pool_address,
            swap_direct_for_x_to_y,
            amount,
            partner
        );

        let amount = if (swap_direct_for_x_to_y) {
            swap_pay_amount(option::borrow(&maybe_receipt_for_x_y))
        } else {
            swap_pay_amount(option::borrow(&maybe_receipt_for_y_x))
        };
        coin::destroy_zero(coin_swaped_x);

        if (swap_direct_for_y_to_b) {
            repay_flash_swap<CoinY, CoinB>(coin_swaped_y, coin::zero<CoinB>(), option::destroy_some(maybe_receipt_for_y_b));
            option::destroy_none(maybe_receipt_for_b_y);
        } else {
            repay_flash_swap<CoinB, CoinY>(coin::zero<CoinB>(), coin_swaped_y, option::destroy_some(maybe_receipt_for_b_y));
            option::destroy_none(maybe_receipt_for_y_b);
        };

        let pool_address = *vector::borrow(&pool_addresses, 0);
        let swap_direct_for_a_to_x = *vector::borrow(&swap_directs, 0);
        let (coin_swaped_a,
            coin_swaped_x,
            maybe_receipt_for_a_x,
            maybe_receipt_for_x_a
        ) = exact_output<CoinA, CoinX>(
            sender_address,
            pool_address,
            swap_direct_for_a_to_x,
            amount,
            partner
        );

        if (swap_direct_for_x_to_y) {
            repay_flash_swap<CoinX, CoinY>(coin_swaped_x, coin::zero<CoinY>(), option::destroy_some(maybe_receipt_for_x_y));
            option::destroy_none(maybe_receipt_for_y_x);
        } else {
            repay_flash_swap<CoinY, CoinX>(coin::zero<CoinY>(), coin_swaped_x, option::destroy_some(maybe_receipt_for_y_x));
            option::destroy_none(maybe_receipt_for_x_y);
        };

        let amount = if (swap_direct_for_a_to_x) {
            swap_pay_amount(option::borrow(&maybe_receipt_for_a_x))
        } else {
            swap_pay_amount(option::borrow(&maybe_receipt_for_x_a))
        };
        coin::destroy_zero(coin_swaped_a);

        let coin_a = coin::withdraw<CoinA>(account, amount);
        if (swap_direct_for_a_to_x) {
            repay_flash_swap<CoinA, CoinX>(coin_a, coin::zero<CoinX>(), option::destroy_some(maybe_receipt_for_a_x));
            option::destroy_none(maybe_receipt_for_x_a);
        } else {
            repay_flash_swap<CoinX, CoinA>(coin::zero<CoinX>(), coin_a, option::destroy_some(maybe_receipt_for_x_a));
            option::destroy_none(maybe_receipt_for_a_x);
        };

        assert!(amount <= amount_max_in, error::aborted(ERR_INSUFFICIENT_IN_AMOUNT));

        coin_register<CoinB>(account);
        coin::deposit(sender_address, coin_swaped_b);
    }

    fun coin_register<CoinType>(
        account: &signer
    ) {
        if (!coin::is_account_registered<CoinType>(signer::address_of(account))) {
            coin::register<CoinType>(account);
        };
    }
}

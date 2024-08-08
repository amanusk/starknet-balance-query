use starknet::{
    get_caller_address, contract_address_const, ContractAddress, get_contract_address, Into
};
use array::{ArrayTrait, SpanTrait};

use zeroable::Zeroable;
use debug::PrintTrait;

use balance_query::erc20::erc20::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};

#[derive(Drop, Serde, Copy)]
struct TokenBalance {
    account_address: ContractAddress,
    token_address: ContractAddress,
    amount: u256,
}

#[starknet::interface]
trait IBalanceQuery<TContractState> {
    fn query_balance(
        self: @TContractState,
        token_addresses: Array<ContractAddress>,
        account_addresses: Array<ContractAddress>
    ) -> Array<TokenBalance>;
}

#[starknet::contract]
mod BalanceQuery {
    use starknet::{
        get_caller_address, contract_address_const, ContractAddress, get_contract_address, Into
    };

    use zeroable::Zeroable;
    use array::{ArrayTrait, SpanTrait};

    use balance_query::erc20::erc20::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};

    use debug::PrintTrait;

    use super::TokenBalance;


    #[constructor]
    fn constructor(ref self: ContractState,) {}

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl BalanceQuery of super::IBalanceQuery<ContractState> {
        fn query_balance(
            self: @ContractState,
            token_addresses: Array<ContractAddress>,
            account_addresses: Array<ContractAddress>
        ) -> Array<TokenBalance> {
            let mut balances: Array<TokenBalance> = ArrayTrait::new();
            let mut counter = 0;

            for _token_address in token_addresses
                .span() {
                    for _account_address in account_addresses.span() {
                        counter = counter + 1;
                    }
                };

            return balances;
        }
    }
}

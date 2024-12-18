use starknet::{ContractAddress};

#[derive(Drop, Serde, Copy, Debug)]
pub struct TokenBalance {
    account_address: ContractAddress,
    token_address: ContractAddress,
    amount: u256,
}

#[starknet::interface]
pub trait IBalanceQuery<TContractState> {
    fn query_balance_struct(
        self: @TContractState,
        token_addresses: Array<ContractAddress>,
        account_addresses: Array<ContractAddress>,
    ) -> Array<TokenBalance>;

    fn query_balance_lists(
        self: @TContractState,
        token_addresses: Array<ContractAddress>,
        account_addresses: Array<ContractAddress>,
    ) -> Array<Array<u256>>;
}

#[starknet::contract]
pub mod BalanceQuery {
    use starknet::{ContractAddress};

    use balance_query::erc20::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};

    use super::TokenBalance;


    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl BalanceQuery of super::IBalanceQuery<ContractState> {
        fn query_balance_struct(
            self: @ContractState,
            token_addresses: Array<ContractAddress>,
            account_addresses: Array<ContractAddress>,
        ) -> Array<TokenBalance> {
            let mut balances: Array<TokenBalance> = ArrayTrait::new();

            for token_address in token_addresses.span() {
                let erc20 = IERC20Dispatcher { contract_address: *token_address };
                for account_address in account_addresses.span() {
                    let amount = erc20.balance_of(*account_address);
                    let token_balance = TokenBalance {
                        account_address: *account_address,
                        token_address: *token_address,
                        amount: amount,
                    };
                    balances.append(token_balance);
                }
            };

            return balances;
        }

        fn query_balance_lists(
            self: @ContractState,
            token_addresses: Array<ContractAddress>,
            account_addresses: Array<ContractAddress>,
        ) -> Array<Array<u256>> {
            let mut result: Array<Array<u256>> = ArrayTrait::new();

            for token_address in token_addresses.span() {
                let mut token_balances: Array<u256> = ArrayTrait::new();
                let erc20 = IERC20Dispatcher { contract_address: *token_address };
                for account_address in account_addresses.span() {
                    let amount = erc20.balance_of(*account_address);
                    token_balances.append(amount);
                };
                result.append(token_balances);
            };

            return result;
        }
    }
}

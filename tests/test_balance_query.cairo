use snforge_std::{declare, cheat_caller_address, ContractClassTrait, CheatSpan};

use snforge_std::{spy_events, EventSpyAssertionsTrait};

use starknet::{
    contract_address_const, get_block_info, ContractAddress, Felt252TryIntoContractAddress, TryInto,
    Into, OptionTrait, class_hash::Felt252TryIntoClassHash, get_caller_address,
    get_contract_address,
};


use starknet::storage_read_syscall;

// use token_sender::tests::test_utils::{assert_eq};

use array::{ArrayTrait, SpanTrait, ArrayTCloneImpl};
use result::ResultTrait;
use serde::Serde;

use box::BoxTrait;
use integer::u256;

use balance_query::erc20::mock_erc20::MockERC20;
use balance_query::erc20::mock_erc20::MockERC20::{Event::ERC20Event};
use balance_query::erc20::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};

use balance_query::balance_query::{IBalanceQueryDispatcher, IBalanceQueryDispatcherTrait};
use balance_query::balance_query::TokenBalance;


const INITIAL_SUPPLY: u256 = 1000000000;

fn setup() -> (ContractAddress, ContractAddress, ContractAddress) {
    let erc20_class_hash = declare("MockERC20").unwrap();

    let account: ContractAddress = contract_address_const::<1>();

    let mut calldata = ArrayTrait::new();
    INITIAL_SUPPLY.serialize(ref calldata);
    account.serialize(ref calldata);

    let (erc20_address_1, _) = erc20_class_hash.deploy(@calldata).unwrap();
    let (erc20_address_2, _) = erc20_class_hash.deploy(@calldata).unwrap();

    let balance_query_class_hash = declare("BalanceQuery").unwrap();

    let mut calldata = ArrayTrait::new();

    let (balance_query_address, _) = balance_query_class_hash.deploy(@calldata).unwrap();

    (erc20_address_1, erc20_address_2, balance_query_address)
}

#[test]
fn test_single_send() {
    let (erc20_address_1, erc20_address_2, balance_query_address) = setup();
    let erc20_1 = IERC20Dispatcher { contract_address: erc20_address_1 };
    let erc20_2 = IERC20Dispatcher { contract_address: erc20_address_2 };

    let account: ContractAddress = contract_address_const::<1>();

    assert(erc20_1.balance_of(account) == INITIAL_SUPPLY, 'Balance should be > 0');
    let account2: ContractAddress = contract_address_const::<2>();
    let account3: ContractAddress = contract_address_const::<3>();
    let account4: ContractAddress = contract_address_const::<4>();

    let transfer_value: u256 = 100;

    cheat_caller_address(erc20_address_1, account, CheatSpan::TargetCalls(3));
    erc20_1.transfer(account2, transfer_value);
    erc20_1.transfer(account3, transfer_value * 2);
    erc20_1.transfer(account4, transfer_value * 3);

    cheat_caller_address(erc20_address_2, account, CheatSpan::TargetCalls(3));
    erc20_2.transfer(account2, transfer_value);
    erc20_2.transfer(account3, transfer_value * 2);
    erc20_2.transfer(account4, transfer_value * 3);

    let token_list = array![erc20_address_1, erc20_address_2];
    let account_list = array![account2, account3, account4];

    let balance_query = IBalanceQueryDispatcher { contract_address: balance_query_address };
    let query_result = balance_query.query_balance(token_list, account_list);

    assert!(query_result.len() == 6, "Result should have 6 elements");
    print!("Result: {:?}", query_result);
}


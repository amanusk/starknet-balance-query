use bigdecimal::BigDecimal;
use num_bigint::{BigUint, ToBigInt};
use reqwest::Error;
use serde::Deserialize;
use starknet::{
    core::types::{BlockId, BlockTag, Felt, FunctionCall},
    macros::selector,
    providers::{
        jsonrpc::{HttpTransport, JsonRpcClient},
        Provider, Url,
    },
};
use std::collections::HashMap;
use std::{env, process};
use tokio;

#[derive(Deserialize)]
struct Addresses {
    accounts: Vec<Felt>,
    tokens: Vec<Felt>,
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    // Load environment variables from .env file
    dotenv::dotenv().ok();

    // Read rpc url
    let rpc_url = env::var("STARKNET_RPC_URL").expect("STARKNET_RPC_URL not set");
    println!("RPC URL: {}", rpc_url);

    let provider = JsonRpcClient::new(HttpTransport::new(Url::parse(&rpc_url).unwrap()));

    // Read query contract address
    let balance_query_address_string =
        env::var("BALANCE_QUERY_ADDRESS").expect("BALANCE_QUERY_ADDRESS not set");
    let balance_query_address = Felt::from_hex(&balance_query_address_string)
        .expect("Failed to parse balance query address");
    println!("balance query address: {}", balance_query_address);

    let input_file = env::var("INPUT_FILE").expect("INPUT_FILE not set");

    // Read and parse the JSON file
    let file_content = std::fs::read_to_string(input_file).expect("Failed to read JSON file");
    let addresses: Addresses =
        serde_json::from_str(&file_content).expect("Failed to parse JSON file");

    // Use the arrays from the JSON file
    println!("accounts: {:?}", addresses.accounts);
    println!("tokens: {:?}", addresses.tokens);

    // Go over all tokens and make sure the are deployed
    for token_address in addresses.tokens.iter() {
        let token_class = provider
            .get_class_hash_at(BlockId::Tag(BlockTag::Latest), token_address)
            .await;
        match token_class {
            Ok(class_hash) => {
                println!("Token class hash: {:#064x}", class_hash);
            }
            Err(e) => {
                println!(
                    "Failed to get token class of: {:#064x}, {}",
                    token_address, e
                );
                process::exit(1);
            }
        }
    }
    // Create calldata
    let mut calldata: Vec<Felt> = vec![addresses.tokens.len().into()];
    calldata.extend(addresses.tokens.clone());
    calldata.push(addresses.accounts.len().into());
    calldata.extend(addresses.accounts.clone());

    // From here we assume all tokens are deployed
    let call_result = provider
        .call(
            FunctionCall {
                contract_address: balance_query_address,
                entry_point_selector: selector!("query_balance_lists"),
                calldata,
            },
            BlockId::Tag(BlockTag::Latest),
        )
        .await
        .expect("failed to call balance_query_lists");

    let token_length = addresses.tokens.len();

    // parse result
    let mut balance_map: HashMap<Felt, HashMap<Felt, BigUint>> = HashMap::new();
    for (i, account) in addresses.accounts.iter().enumerate() {
        let mut token_balance_map: HashMap<Felt, BigUint> = HashMap::new();
        for (j, token) in addresses.tokens.iter().enumerate() {
            // The result structur is as follows:
            // [2, account_len, a0_t0_low, a0_t0_high, a0_t1_low, a0_t1_high, ..., account_len,
            // a1_t0_low, a1_t0_high, ...]
            let index = 1 + i * (token_length * 2 + 1) + 1 + j * 2;
            let low_felt = call_result[index]; // Borrow the low_felt
            let high_felt = call_result[index + 1]; // Borrow the high_felt
            let low: BigUint = low_felt.to_biguint();
            let high: BigUint = high_felt.to_biguint();
            let raw_balance: BigUint = (high << 128) + low;
            token_balance_map.insert(*token, raw_balance);
        }
        balance_map.insert(*account, token_balance_map);
    }

    for (account, token_balance_map) in balance_map.iter() {
        println!("Account: {:#064x}", account);
        for (token, balance) in token_balance_map.iter() {
            let balance_dec = BigDecimal::new(balance.to_bigint().unwrap(), 18);
            println!("\t{:#064x}:{}", token, balance_dec);
        }
    }

    Ok(())
}

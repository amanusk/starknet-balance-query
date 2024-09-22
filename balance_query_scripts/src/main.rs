use reqwest::Error;
use serde::Deserialize;
use starknet::{
    core::types::{BlockId, BlockTag, Felt},
    providers::{
        jsonrpc::{HttpTransport, JsonRpcClient},
        Provider, Url,
    },
};
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

    // Read and parse the JSON file
    let file_content = std::fs::read_to_string("addresses.json").expect("Failed to read JSON file");
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
    // From here we assume all tokens are deployed

    Ok(())
}

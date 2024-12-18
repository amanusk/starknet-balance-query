# Starknet Balance Query

![PRs Welcome](https://img.shields.io/badge/PRs-welcome-green.svg) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/amanusk/starknet-foundry-template/blob/main/LICENSE) ![example workflow](https://github.com/amanusk/starknet-foundry-template/actions/workflows/scarb.yml/badge.svg)


Contract to query bulk addresses and token balances. Provided with rust scripts to read and display balances.

Currently the contract is deployed on following address on starknet-sepolia and starknet-mainnet

```
0x062d5ecf6e3683128583247913bf5b65cf4da2e22c681c2db339d3a726fec757
```

## Instructions

- Go to `./balance_query_scripts` and build with `cargo build --release`
- Copy the `addresses.example.json` file to `addresses.json` and add the addresses and tokens you would like to query
- Copy the .env.example file to .env and add your RPC provider
- Run with `cargo run --release`

## Example output
```
Account: 0x03337386debb62e257d9afaad930c0df8343e4f686caef2fd538260e755e3158
	0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7:0.075335331842830930
	0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d:0E-18
Account: 0x051705f024bdd49fd7e5336f408bce777546c7954803ab46ac11a77e385b995a
	0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d:0E-18
	0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7:827.540111492939970283
```




## Building

```
scarb build
```

## Testing

```
snforge test
```

If you like it then you shoulda put a ⭐ on it

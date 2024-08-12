## Burner

## General Overview

Collateral is a concept introduced by Symbiotic that brings capital efficiency and scale by enabling assets used to secure Symbiotic networks to be held outside of the Symbiotic protocol itself - e.g., in DeFi positions on networks other than Ethereum itself.

Symbiotic achieves this by separating the ability to slash assets from the underlying asset itself, similar to how liquid staking tokens create tokenized representations of underlying staked positions. Technically, collateral positions in Symbiotic are ERC-20 tokens with extended functionality to handle slashing incidents if applicable. In other words, if the collateral token aims to support slashing, it should be possible to create a `Burner` responsible for proper burning of the asset.

For example, if asset is ETH LST it can be used as a collateral if it's possible to create `Burner` contract that withdraw ETH from beaconchain and burn it, if asset is native e.g. governance token it also can be used as collateral since burner might be implemented as "black-hole" contract or address.

## Default Burners

We've implemented default Burners for the assets restaked at Symbiotic, which need "unwrapping" (and allow it in a permissionless way):

### wstETH Burner

An asset transfered to the [Burner](../src/contracts/burners/wstETH_Burner.sol) - wstETH

#### Unwrap flow

1. Trigger withdrawal

   - Unwrap wstETH into stETH via wstETH contract
   - Create requests with acceptable by the Lido Withdrawal Queue amounts
   - Send withdrawal requests to the Lido Withdrawal Queue

2. Trigger burn

   - Claim withdrawal request by its ID
   - Burn ETH by `selfdestruct()`

### rETH Burner

An asset transfered to the [Burner](../src/contracts/burners/rETH_Burner.sol) - rETH

#### Unwrap flow

1. Trigger burn

   - Unwrap rETH into ETH via rETH contract
   - Burn ETH by `selfdestruct()`

### mETH Burner

An asset transfered to the [Burner](../src/contracts/burners/mETH_Burner.sol) - mETH

#### Unwrap flow

1. Trigger withdrawal

   - Send a withdrawal request to the Mantle Staking contract

2. Trigger burn

   - Claim withdrawal request by its ID
   - Burn ETH by `selfdestruct()`

### swETH Burner

An asset transfered to the [Burner](../src/contracts/burners/swETH_Burner.sol) - swETH

#### Unwrap flow

1. Trigger withdrawal

   - Create requests with acceptable by the Swell Exit contract amounts
   - Send withdrawal requests to the Swell Exit contract

2. Trigger burn

   - Claim withdrawal request by its ID
   - Burn ETH by `selfdestruct()`

### sfrxETH Burner

An asset transfered to the [Burner](../src/contracts/burners/sfrxETH_Burner.sol) - sfrxETH

#### Unwrap flow

1. Trigger withdrawal

   - Send a withdrawal request to the frxETH Redemption Queue

2. Trigger burn

   - Claim withdrawal request by its ID
   - Burn ETH by `selfdestruct()`

### ETHx Burner

An asset transfered to the [Burner](../src/contracts/burners/ETHx_Burner.sol) - ETHx

#### Unwrap flow

1. Trigger withdrawal

   - Create requests with acceptable by the User Withdraw Manager contract amounts
   - Send withdrawal requests to the User Withdraw Manager contract

2. Trigger burn

   - Claim withdrawal request by its ID
   - Burn ETH by `selfdestruct()`

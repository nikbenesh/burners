## Burner Router

[See the code here](../src/contracts/router/)

The Burner Router allows redirecting the slashed collateral tokens to different addresses, which may be represented by Burners, Treasury contracts, LP lockers, etc.

### Full Flow

1. Setup

   - Before the Vault's creation, deploy a new Burner Router via `BurnerRouterFactory` with the same collateral address as the Vault will use
   - Deploy the Vault inputting the received `BurnerRouter` address and `IBaseSlasher.BaseParams.isBurnerHook` set to `true`

2. Slashing

   - The router is called via `onSlash()` function
   - It determines the needed address for redirection and saves the redirection amount for it

3. Trigger transfer

   - Transfers a given account's whole balance from the router to this account

### Deploy

```shell
source .env
```

#### Deploy factory

Deployment script: [click](../script/deploy/BurnerRouterFactory.s.sol)

```shell
forge script script/deploy/BurnerRouterFactory.s.sol:BurnerRouterFactoryScript --broadcast --rpc-url=$ETH_RPC_URL
```

#### Deploy entity

Deployment script: [click](../script/deploy/BurnerRouter.s.sol)

```shell
forge script script/deploy/BurnerRouter.s.sol:BurnerRouterScript 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 0 0x0000000000000000000000000000000000000000 [\(0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000\),\(0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000\)] [\(0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000\),\(0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000\)] --sig "run(address,address,address,uint48,address,(address,address)[],(address,address,address)[])" --broadcast --rpc-url=$ETH_RPC_URL
```

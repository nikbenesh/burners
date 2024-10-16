// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";

import {VaultFactory} from "@symbioticfi/core/src/contracts/VaultFactory.sol";
import {DelegatorFactory} from "@symbioticfi/core/src/contracts/DelegatorFactory.sol";
import {SlasherFactory} from "@symbioticfi/core/src/contracts/SlasherFactory.sol";
import {NetworkRegistry} from "@symbioticfi/core/src/contracts/NetworkRegistry.sol";
import {OperatorRegistry} from "@symbioticfi/core/src/contracts/OperatorRegistry.sol";
import {MetadataService} from "@symbioticfi/core/src/contracts/service/MetadataService.sol";
import {NetworkMiddlewareService} from "@symbioticfi/core/src/contracts/service/NetworkMiddlewareService.sol";
import {OptInService} from "@symbioticfi/core/src/contracts/service/OptInService.sol";

import {Vault} from "@symbioticfi/core/src/contracts/vault/Vault.sol";
import {NetworkRestakeDelegator} from "@symbioticfi/core/src/contracts/delegator/NetworkRestakeDelegator.sol";
import {FullRestakeDelegator} from "@symbioticfi/core/src/contracts/delegator/FullRestakeDelegator.sol";
import {OperatorSpecificDelegator} from "@symbioticfi/core/src/contracts/delegator/OperatorSpecificDelegator.sol";
import {Slasher} from "@symbioticfi/core/src/contracts/slasher/Slasher.sol";
import {VetoSlasher} from "@symbioticfi/core/src/contracts/slasher/VetoSlasher.sol";

import {Token} from "@symbioticfi/core/test/mocks/Token.sol";
import {VaultConfigurator, IVaultConfigurator} from "@symbioticfi/core/src/contracts/VaultConfigurator.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {INetworkRestakeDelegator} from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IBaseDelegator} from "@symbioticfi/core/src/interfaces/delegator/IBaseDelegator.sol";
import {IBaseSlasher} from "@symbioticfi/core/src/interfaces/slasher/IBaseSlasher.sol";
import {ISlasher} from "@symbioticfi/core/src/interfaces/slasher/ISlasher.sol";

import {BurnerRouterFactory} from "../../src/contracts/router/BurnerRouterFactory.sol";
import {BurnerRouter} from "../../src/contracts/router/BurnerRouter.sol";
import {IBurnerRouter} from "../../src/interfaces/router/IBurnerRouter.sol";

contract BurnerRouterFactoryTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    VaultFactory vaultFactory;
    DelegatorFactory delegatorFactory;
    SlasherFactory slasherFactory;
    NetworkRegistry networkRegistry;
    OperatorRegistry operatorRegistry;
    MetadataService operatorMetadataService;
    MetadataService networkMetadataService;
    NetworkMiddlewareService networkMiddlewareService;
    OptInService networkVaultOptInService;
    OptInService operatorVaultOptInService;
    OptInService operatorNetworkOptInService;

    Token collateral;
    VaultConfigurator vaultConfigurator;

    Vault vault;
    FullRestakeDelegator delegator;
    Slasher slasher;

    BurnerRouterFactory burnerRouterFactory;
    BurnerRouter burnerRouter;

    function setUp() public {
        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vaultFactory = new VaultFactory(owner);
        delegatorFactory = new DelegatorFactory(owner);
        slasherFactory = new SlasherFactory(owner);
        networkRegistry = new NetworkRegistry();
        operatorRegistry = new OperatorRegistry();
        operatorMetadataService = new MetadataService(address(operatorRegistry));
        networkMetadataService = new MetadataService(address(networkRegistry));
        networkMiddlewareService = new NetworkMiddlewareService(address(networkRegistry));
        operatorVaultOptInService =
            new OptInService(address(operatorRegistry), address(vaultFactory), "OperatorVaultOptInService");
        operatorNetworkOptInService =
            new OptInService(address(operatorRegistry), address(networkRegistry), "OperatorNetworkOptInService");

        address vaultImpl =
            address(new Vault(address(delegatorFactory), address(slasherFactory), address(vaultFactory)));
        vaultFactory.whitelist(vaultImpl);

        address networkRestakeDelegatorImpl = address(
            new NetworkRestakeDelegator(
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(networkRestakeDelegatorImpl);

        address fullRestakeDelegatorImpl = address(
            new FullRestakeDelegator(
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(fullRestakeDelegatorImpl);

        address operatorSpecificDelegatorImpl = address(
            new OperatorSpecificDelegator(
                address(operatorRegistry),
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(operatorSpecificDelegatorImpl);

        address slasherImpl = address(
            new Slasher(
                address(vaultFactory),
                address(networkMiddlewareService),
                address(slasherFactory),
                slasherFactory.totalTypes()
            )
        );
        slasherFactory.whitelist(slasherImpl);

        address vetoSlasherImpl = address(
            new VetoSlasher(
                address(vaultFactory),
                address(networkMiddlewareService),
                address(networkRegistry),
                address(slasherFactory),
                slasherFactory.totalTypes()
            )
        );
        slasherFactory.whitelist(vetoSlasherImpl);

        collateral = new Token("Token");

        vaultConfigurator =
            new VaultConfigurator(address(vaultFactory), address(delegatorFactory), address(slasherFactory));
    }

    function test_Create(uint48 delay, address globalReceiver) public {
        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        uint160 N1 = 10;
        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](N1);
        uint160 N2 = 20;
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](N2);

        for (uint160 i; i < N1; ++i) {
            networkReceivers[i] =
                IBurnerRouter.NetworkReceiver({network: address(i * 2 + 3), receiver: address(i * 2 + 1)});
        }

        for (uint160 i; i < N2; ++i) {
            operatorNetworkReceivers[i] = IBurnerRouter.OperatorNetworkReceiver({
                network: address(i * 2 + 3),
                operator: address(i * 2 + 1),
                receiver: address(i * 2 + 2)
            });
        }

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: owner,
            collateral: address(collateral),
            delay: delay,
            globalReceiver: globalReceiver,
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        assertTrue(burnerRouterFactory.isEntity(burnerRouterAddress));

        assertEq(burnerRouter.owner(), owner);
        assertEq(burnerRouter.collateral(), address(collateral));
        assertEq(burnerRouter.delay(), delay);
        assertEq(burnerRouter.lastBalance(), 0);
        assertEq(burnerRouter.globalReceiver(), globalReceiver);
        (address pendingAddress, uint48 pendingTimestamp) = burnerRouter.pendingGlobalReceiver();
        assertEq(pendingAddress, address(0));
        assertEq(pendingTimestamp, 0);
        for (uint160 i; i < N1 + 1; ++i) {
            assertEq(burnerRouter.networkReceiver(address(i * 2 + 3)), i < N1 ? address(i * 2 + 1) : address(0));
        }
        (pendingAddress, pendingTimestamp) = burnerRouter.pendingNetworkReceiver(address(0));
        assertEq(pendingAddress, address(0));
        assertEq(pendingTimestamp, 0);
        for (uint160 i; i < N2 + 1; ++i) {
            assertEq(
                burnerRouter.operatorNetworkReceiver(address(i * 2 + 3), address(i * 2 + 1)),
                i < N2 ? address(i * 2 + 2) : address(0)
            );
        }
        (pendingAddress, pendingTimestamp) = burnerRouter.pendingOperatorNetworkReceiver(address(0), address(0));
        assertEq(pendingAddress, address(0));
        assertEq(pendingTimestamp, 0);
        assertEq(burnerRouter.balanceOf(address(0)), 0);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));
    }

    function test_CreateRevertInvalidCollateral(uint48 delay, address globalReceiver) public {
        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        uint160 N1 = 10;
        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](N1);
        uint160 N2 = 20;
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](N2);

        for (uint160 i; i < N1; ++i) {
            networkReceivers[i] =
                IBurnerRouter.NetworkReceiver({network: address(i * 2 + 3), receiver: address(i * 2 + 1)});
        }

        for (uint160 i; i < N2; ++i) {
            operatorNetworkReceivers[i] = IBurnerRouter.OperatorNetworkReceiver({
                network: address(i * 2 + 3),
                operator: address(i * 2 + 1),
                receiver: address(i * 2 + 2)
            });
        }

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: owner,
            collateral: address(0),
            delay: delay,
            globalReceiver: globalReceiver,
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        vm.expectRevert(IBurnerRouter.InvalidCollateral.selector);
        address burnerRouterAddress = burnerRouterFactory.create(initParams);
    }

    function test_CreateRevertInvalidReceiver1(uint48 delay, address globalReceiver) public {
        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        uint160 N1 = 10;
        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](N1);
        uint160 N2 = 20;
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](N2);

        for (uint160 i; i < N1; ++i) {
            networkReceivers[i] = IBurnerRouter.NetworkReceiver({network: address(i * 2 + 3), receiver: address(0)});
        }

        for (uint160 i; i < N2; ++i) {
            operatorNetworkReceivers[i] = IBurnerRouter.OperatorNetworkReceiver({
                network: address(i * 2 + 3),
                operator: address(i * 2 + 1),
                receiver: address(i * 2 + 2)
            });
        }

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: owner,
            collateral: address(collateral),
            delay: delay,
            globalReceiver: globalReceiver,
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        vm.expectRevert(IBurnerRouter.InvalidReceiver.selector);
        address burnerRouterAddress = burnerRouterFactory.create(initParams);
    }

    function test_CreateRevertInvalidReceiver2(uint48 delay, address globalReceiver) public {
        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        uint160 N1 = 10;
        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](N1);
        uint160 N2 = 20;
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](N2);

        for (uint160 i; i < N1; ++i) {
            networkReceivers[i] =
                IBurnerRouter.NetworkReceiver({network: address(i * 2 + 3), receiver: address(i * 2 + 1)});
        }

        for (uint160 i; i < N2; ++i) {
            operatorNetworkReceivers[i] = IBurnerRouter.OperatorNetworkReceiver({
                network: address(i * 2 + 3),
                operator: address(i * 2 + 1),
                receiver: address(0)
            });
        }

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: owner,
            collateral: address(collateral),
            delay: delay,
            globalReceiver: globalReceiver,
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        vm.expectRevert(IBurnerRouter.InvalidReceiver.selector);
        address burnerRouterAddress = burnerRouterFactory.create(initParams);
    }

    function test_CreateRevertDuplicateNetworkReceiver(uint48 delay, address globalReceiver) public {
        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        uint160 N1 = 10;
        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](N1);
        uint160 N2 = 20;
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](N2);

        for (uint160 i; i < N1; ++i) {
            networkReceivers[i] = IBurnerRouter.NetworkReceiver({network: address(1), receiver: address(i * 2 + 1)});
        }

        for (uint160 i; i < N2; ++i) {
            operatorNetworkReceivers[i] = IBurnerRouter.OperatorNetworkReceiver({
                network: address(i * 2 + 3),
                operator: address(i * 2 + 1),
                receiver: address(i * 2 + 2)
            });
        }

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: owner,
            collateral: address(collateral),
            delay: delay,
            globalReceiver: globalReceiver,
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        vm.expectRevert(IBurnerRouter.DuplicateNetworkReceiver.selector);
        address burnerRouterAddress = burnerRouterFactory.create(initParams);
    }

    function test_CreateRevertDuplicateOperatorNetworkReceiver(uint48 delay, address globalReceiver) public {
        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        uint160 N1 = 10;
        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](N1);
        uint160 N2 = 20;
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](N2);

        for (uint160 i; i < N1; ++i) {
            networkReceivers[i] =
                IBurnerRouter.NetworkReceiver({network: address(i * 2 + 3), receiver: address(i * 2 + 1)});
        }

        for (uint160 i; i < N2; ++i) {
            operatorNetworkReceivers[i] = IBurnerRouter.OperatorNetworkReceiver({
                network: address(1),
                operator: address(1),
                receiver: address(i * 2 + 2)
            });
        }

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: owner,
            collateral: address(collateral),
            delay: delay,
            globalReceiver: globalReceiver,
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        vm.expectRevert(IBurnerRouter.DuplicateOperatorNetworkReceiver.selector);
        address burnerRouterAddress = burnerRouterFactory.create(initParams);
    }

    function _getVaultWithDelegatorWithSlasher(
        address burner
    ) internal returns (Vault, FullRestakeDelegator, Slasher) {
        address[] memory networkLimitSetRoleHolders = new address[](1);
        networkLimitSetRoleHolders[0] = alice;
        address[] memory operatorNetworkSharesSetRoleHolders = new address[](1);
        operatorNetworkSharesSetRoleHolders[0] = alice;
        (address vault_, address delegator_, address slasher_) = vaultConfigurator.create(
            IVaultConfigurator.InitParams({
                version: vaultFactory.lastVersion(),
                owner: alice,
                vaultParams: abi.encode(
                    IVault.InitParams({
                        collateral: address(collateral),
                        burner: burner,
                        epochDuration: 7 days,
                        depositWhitelist: false,
                        isDepositLimit: false,
                        depositLimit: 0,
                        defaultAdminRoleHolder: alice,
                        depositWhitelistSetRoleHolder: alice,
                        depositorWhitelistRoleHolder: alice,
                        isDepositLimitSetRoleHolder: alice,
                        depositLimitSetRoleHolder: alice
                    })
                ),
                delegatorIndex: 0,
                delegatorParams: abi.encode(
                    INetworkRestakeDelegator.InitParams({
                        baseParams: IBaseDelegator.BaseParams({
                            defaultAdminRoleHolder: alice,
                            hook: address(0),
                            hookSetRoleHolder: alice
                        }),
                        networkLimitSetRoleHolders: networkLimitSetRoleHolders,
                        operatorNetworkSharesSetRoleHolders: operatorNetworkSharesSetRoleHolders
                    })
                ),
                withSlasher: true,
                slasherIndex: 0,
                slasherParams: abi.encode(ISlasher.InitParams({baseParams: IBaseSlasher.BaseParams({isBurnerHook: true})}))
            })
        );

        return (Vault(vault_), FullRestakeDelegator(delegator_), Slasher(slasher_));
    }
}

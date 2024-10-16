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
import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";

import {BurnerRouterFactory} from "../../src/contracts/router/BurnerRouterFactory.sol";
import {BurnerRouter} from "../../src/contracts/router/BurnerRouter.sol";
import {IBurnerRouter} from "../../src/interfaces/router/IBurnerRouter.sol";

contract BurnerRouterTest is Test {
    using Subnetwork for bytes32;
    using Subnetwork for address;

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

    function test_SetGlobalReceiver() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(alice),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setGlobalReceiver(bob);
        vm.stopPrank();

        assertEq(burnerRouter.globalReceiver(), alice);

        (address pendingGlobalReceiver, uint48 pendingTimestamp) = burnerRouter.pendingGlobalReceiver();
        assertEq(pendingGlobalReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        blockTimestamp = blockTimestamp + 1;
        vm.warp(blockTimestamp);

        (pendingGlobalReceiver, pendingTimestamp) = burnerRouter.pendingGlobalReceiver();
        assertEq(pendingGlobalReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days - 1);

        vm.startPrank(alice);
        burnerRouter.setGlobalReceiver(address(this));
        vm.stopPrank();

        assertEq(burnerRouter.globalReceiver(), alice);

        (pendingGlobalReceiver, pendingTimestamp) = burnerRouter.pendingGlobalReceiver();
        assertEq(pendingGlobalReceiver, address(this));
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        vm.startPrank(alice);
        burnerRouter.setGlobalReceiver(alice);
        vm.stopPrank();

        assertEq(burnerRouter.globalReceiver(), alice);

        (pendingGlobalReceiver, pendingTimestamp) = burnerRouter.pendingGlobalReceiver();
        assertEq(pendingGlobalReceiver, address(0));
        assertEq(pendingTimestamp, 0);

        vm.startPrank(alice);
        burnerRouter.setGlobalReceiver(bob);
        vm.stopPrank();

        assertEq(burnerRouter.globalReceiver(), alice);

        (pendingGlobalReceiver, pendingTimestamp) = burnerRouter.pendingGlobalReceiver();
        assertEq(pendingGlobalReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        blockTimestamp = blockTimestamp + 30 days;
        vm.warp(blockTimestamp);

        vm.startPrank(alice);
        burnerRouter.setGlobalReceiver(alice);
        vm.stopPrank();

        assertEq(burnerRouter.globalReceiver(), bob);

        (pendingGlobalReceiver, pendingTimestamp) = burnerRouter.pendingGlobalReceiver();
        assertEq(pendingGlobalReceiver, alice);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);
    }

    function test_SetGlobalReceiverRevertAlreadySet() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(alice),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        vm.expectRevert(IBurnerRouter.AlreadySet.selector);
        burnerRouter.setGlobalReceiver(alice);
        vm.stopPrank();
    }

    function test_AcceptGlobalReceiver() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(alice),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setGlobalReceiver(bob);
        vm.stopPrank();

        blockTimestamp = blockTimestamp + 21 days;
        vm.warp(blockTimestamp);

        vm.startPrank(bob);
        burnerRouter.acceptGlobalReceiver();
        vm.stopPrank();

        assertEq(burnerRouter.globalReceiver(), bob);

        (address pendingGlobalReceiver, uint48 pendingTimestamp) = burnerRouter.pendingGlobalReceiver();
        assertEq(pendingGlobalReceiver, address(0));
        assertEq(pendingTimestamp, 0);
    }

    function test_AcceptGlobalReceiverRevertNotReady() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(alice),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setGlobalReceiver(bob);
        vm.stopPrank();

        blockTimestamp = blockTimestamp + 20 days;
        vm.warp(blockTimestamp);

        vm.startPrank(bob);
        vm.expectRevert(IBurnerRouter.NotReady.selector);
        burnerRouter.acceptGlobalReceiver();
        vm.stopPrank();
    }

    function test_SetNetworkReceiver() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](1);
        networkReceivers[0] = IBurnerRouter.NetworkReceiver({network: address(0x1), receiver: alice});
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(0),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setNetworkReceiver(address(0x1), bob);
        vm.stopPrank();

        assertEq(burnerRouter.networkReceiver(address(0x1)), alice);

        (address pendingReceiver, uint48 pendingTimestamp) = burnerRouter.pendingNetworkReceiver(address(0x1));
        assertEq(pendingReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        blockTimestamp = blockTimestamp + 1;
        vm.warp(blockTimestamp);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingNetworkReceiver(address(0x1));
        assertEq(pendingReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days - 1);

        vm.startPrank(alice);
        burnerRouter.setNetworkReceiver(address(0x1), address(this));
        vm.stopPrank();

        assertEq(burnerRouter.networkReceiver(address(0x1)), alice);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingNetworkReceiver(address(0x1));
        assertEq(pendingReceiver, address(this));
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        vm.startPrank(alice);
        burnerRouter.setNetworkReceiver(address(0x1), alice);
        vm.stopPrank();

        assertEq(burnerRouter.networkReceiver(address(0x1)), alice);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingNetworkReceiver(address(0x1));
        assertEq(pendingReceiver, address(0));
        assertEq(pendingTimestamp, 0);

        vm.startPrank(alice);
        burnerRouter.setNetworkReceiver(address(0x1), bob);
        vm.stopPrank();

        assertEq(burnerRouter.networkReceiver(address(0x1)), alice);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingNetworkReceiver(address(0x1));
        assertEq(pendingReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        blockTimestamp = blockTimestamp + 30 days;
        vm.warp(blockTimestamp);

        vm.startPrank(alice);
        burnerRouter.setNetworkReceiver(address(0x1), alice);
        vm.stopPrank();

        assertEq(burnerRouter.networkReceiver(address(0x1)), bob);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingNetworkReceiver(address(0x1));
        assertEq(pendingReceiver, alice);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);
    }

    function test_SetNetworkReceiverRevertAlreadySet() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](1);
        networkReceivers[0] = IBurnerRouter.NetworkReceiver({network: address(0x1), receiver: alice});
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(0),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        vm.expectRevert(IBurnerRouter.AlreadySet.selector);
        burnerRouter.setNetworkReceiver(address(0x1), alice);
        vm.stopPrank();
    }

    function test_AcceptNetworkReceiver() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](1);
        networkReceivers[0] = IBurnerRouter.NetworkReceiver({network: address(0x1), receiver: alice});
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(0),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setNetworkReceiver(address(0x1), bob);
        vm.stopPrank();

        blockTimestamp = blockTimestamp + 21 days;
        vm.warp(blockTimestamp);

        vm.startPrank(bob);
        burnerRouter.acceptNetworkReceiver(address(0x1));
        vm.stopPrank();

        assertEq(burnerRouter.networkReceiver(address(0x1)), bob);

        (address pendingReceiver, uint48 pendingTimestamp) = burnerRouter.pendingNetworkReceiver(address(0x1));
        assertEq(pendingReceiver, address(0));
        assertEq(pendingTimestamp, 0);
    }

    function test_AcceptNetworkReceiverRevertNotReady() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](1);
        networkReceivers[0] = IBurnerRouter.NetworkReceiver({network: address(0x1), receiver: alice});
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(0),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setNetworkReceiver(address(0x1), bob);
        vm.stopPrank();

        blockTimestamp = blockTimestamp + 20 days;
        vm.warp(blockTimestamp);

        vm.startPrank(bob);
        vm.expectRevert(IBurnerRouter.NotReady.selector);
        burnerRouter.acceptNetworkReceiver(address(0x1));
        vm.stopPrank();
    }

    function test_SetOperatorNetworkReceiver() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](1);
        operatorNetworkReceivers[0] =
            IBurnerRouter.OperatorNetworkReceiver({network: address(0x1), operator: address(0x2), receiver: alice});

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(0),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setOperatorNetworkReceiver(address(0x1), address(0x2), bob);
        vm.stopPrank();

        assertEq(burnerRouter.operatorNetworkReceiver(address(0x1), address(0x2)), alice);

        (address pendingReceiver, uint48 pendingTimestamp) =
            burnerRouter.pendingOperatorNetworkReceiver(address(0x1), address(0x2));
        assertEq(pendingReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        blockTimestamp = blockTimestamp + 1;
        vm.warp(blockTimestamp);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingOperatorNetworkReceiver(address(0x1), address(0x2));
        assertEq(pendingReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days - 1);

        vm.startPrank(alice);
        burnerRouter.setOperatorNetworkReceiver(address(0x1), address(0x2), address(this));
        vm.stopPrank();

        assertEq(burnerRouter.operatorNetworkReceiver(address(0x1), address(0x2)), alice);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingOperatorNetworkReceiver(address(0x1), address(0x2));
        assertEq(pendingReceiver, address(this));
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        vm.startPrank(alice);
        burnerRouter.setOperatorNetworkReceiver(address(0x1), address(0x2), alice);
        vm.stopPrank();

        assertEq(burnerRouter.operatorNetworkReceiver(address(0x1), address(0x2)), alice);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingOperatorNetworkReceiver(address(0x1), address(0x2));
        assertEq(pendingReceiver, address(0));
        assertEq(pendingTimestamp, 0);

        vm.startPrank(alice);
        burnerRouter.setOperatorNetworkReceiver(address(0x1), address(0x2), bob);
        vm.stopPrank();

        assertEq(burnerRouter.operatorNetworkReceiver(address(0x1), address(0x2)), alice);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingOperatorNetworkReceiver(address(0x1), address(0x2));
        assertEq(pendingReceiver, bob);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        blockTimestamp = blockTimestamp + 30 days;
        vm.warp(blockTimestamp);

        vm.startPrank(alice);
        burnerRouter.setOperatorNetworkReceiver(address(0x1), address(0x2), alice);
        vm.stopPrank();

        assertEq(burnerRouter.operatorNetworkReceiver(address(0x1), address(0x2)), bob);

        (pendingReceiver, pendingTimestamp) = burnerRouter.pendingOperatorNetworkReceiver(address(0x1), address(0x2));
        assertEq(pendingReceiver, alice);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);
    }

    function test_SetOperatorNetworkReceiverRevertAlreadySet() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](1);
        operatorNetworkReceivers[0] =
            IBurnerRouter.OperatorNetworkReceiver({network: address(0x1), operator: address(0x2), receiver: alice});

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(0),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        vm.expectRevert(IBurnerRouter.AlreadySet.selector);
        burnerRouter.setOperatorNetworkReceiver(address(0x1), address(0x2), alice);
        vm.stopPrank();
    }

    function test_AcceptOperatorNetworkReceiver() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](1);
        operatorNetworkReceivers[0] =
            IBurnerRouter.OperatorNetworkReceiver({network: address(0x1), operator: address(0x2), receiver: alice});

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(0),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setOperatorNetworkReceiver(address(0x1), address(0x2), bob);
        vm.stopPrank();

        blockTimestamp = blockTimestamp + 21 days;
        vm.warp(blockTimestamp);

        vm.startPrank(bob);
        burnerRouter.acceptOperatorNetworkReceiver(address(0x1), address(0x2));
        vm.stopPrank();

        assertEq(burnerRouter.operatorNetworkReceiver(address(0x1), address(0x2)), bob);

        (address pendingReceiver, uint48 pendingTimestamp) =
            burnerRouter.pendingOperatorNetworkReceiver(address(0x1), address(0x2));
        assertEq(pendingReceiver, address(0));
        assertEq(pendingTimestamp, 0);
    }

    function test_AcceptOperatorNetworkReceiverRevertNotReady() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](1);
        operatorNetworkReceivers[0] =
            IBurnerRouter.OperatorNetworkReceiver({network: address(0x1), operator: address(0x2), receiver: alice});

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(0),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setOperatorNetworkReceiver(address(0x1), address(0x2), bob);
        vm.stopPrank();

        blockTimestamp = blockTimestamp + 20 days;
        vm.warp(blockTimestamp);

        vm.startPrank(bob);
        vm.expectRevert(IBurnerRouter.NotReady.selector);
        burnerRouter.acceptOperatorNetworkReceiver(address(0x1), address(0x2));
        vm.stopPrank();
    }

    function test_SetDelay() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(alice),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setDelay(7 days);
        vm.stopPrank();

        assertEq(burnerRouter.delay(), 21 days);

        (uint48 pendingDelay, uint48 pendingTimestamp) = burnerRouter.pendingDelay();
        assertEq(pendingDelay, 7 days);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        blockTimestamp = blockTimestamp + 1;
        vm.warp(blockTimestamp);

        (pendingDelay, pendingTimestamp) = burnerRouter.pendingDelay();
        assertEq(pendingDelay, 7 days);
        assertEq(pendingTimestamp, blockTimestamp + 21 days - 1);

        vm.startPrank(alice);
        burnerRouter.setDelay(8 days);
        vm.stopPrank();

        assertEq(burnerRouter.delay(), 21 days);

        (pendingDelay, pendingTimestamp) = burnerRouter.pendingDelay();
        assertEq(pendingDelay, 8 days);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        vm.startPrank(alice);
        burnerRouter.setDelay(21 days);
        vm.stopPrank();

        assertEq(burnerRouter.delay(), 21 days);

        (pendingDelay, pendingTimestamp) = burnerRouter.pendingDelay();
        assertEq(pendingDelay, 0);
        assertEq(pendingTimestamp, 0);

        vm.startPrank(alice);
        burnerRouter.setDelay(7 days);
        vm.stopPrank();

        assertEq(burnerRouter.delay(), 21 days);

        (pendingDelay, pendingTimestamp) = burnerRouter.pendingDelay();
        assertEq(pendingDelay, 7 days);
        assertEq(pendingTimestamp, blockTimestamp + 21 days);

        blockTimestamp = blockTimestamp + 30 days;
        vm.warp(blockTimestamp);

        vm.startPrank(alice);
        burnerRouter.setDelay(21 days);
        vm.stopPrank();

        assertEq(burnerRouter.delay(), 7 days);

        (pendingDelay, pendingTimestamp) = burnerRouter.pendingDelay();
        assertEq(pendingDelay, 21 days);
        assertEq(pendingTimestamp, blockTimestamp + 7 days);
    }

    function test_SetDelayRevertAlreadySet() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(alice),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        vm.expectRevert(IBurnerRouter.AlreadySet.selector);
        burnerRouter.setDelay(21 days);
        vm.stopPrank();
    }

    function test_AcceptDelay() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(alice),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setDelay(7 days);
        vm.stopPrank();

        blockTimestamp = blockTimestamp + 21 days;
        vm.warp(blockTimestamp);

        vm.startPrank(bob);
        burnerRouter.acceptDelay();
        vm.stopPrank();

        assertEq(burnerRouter.delay(), 7 days);

        (uint48 pendingDelay, uint48 pendingTimestamp) = burnerRouter.pendingDelay();
        assertEq(pendingDelay, 0);
        assertEq(pendingTimestamp, 0);
    }

    function test_AcceptDelayRevertNotReady() external {
        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](0);
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](0);

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(alice),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault, delegator, slasher) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        vm.startPrank(alice);
        burnerRouter.setDelay(7 days);
        vm.stopPrank();

        blockTimestamp = blockTimestamp + 20 days;
        vm.warp(blockTimestamp);

        vm.startPrank(bob);
        vm.expectRevert(IBurnerRouter.NotReady.selector);
        burnerRouter.acceptDelay();
        vm.stopPrank();
    }

    function test_OnSlash(uint256 amount1, uint256 amount2, uint256 amount3) external {
        amount1 = bound(amount1, 1, 1000 * 1e18);
        amount2 = bound(amount2, 1, 1000 * 1e18);
        amount3 = bound(amount3, 1, 1000 * 1e18);

        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](1);
        networkReceivers[0] = IBurnerRouter.NetworkReceiver({network: address(9876), receiver: address(2_345_665_432)});
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](1);
        operatorNetworkReceivers[0] = IBurnerRouter.OperatorNetworkReceiver({
            network: address(9876),
            operator: address(98_765),
            receiver: address(3_456_776_543)
        });

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(1_234_554_321),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        collateral.transfer(address(burnerRouter), amount1);

        burnerRouter.onSlash(address(9876).subnetwork(111), address(98_765), 0, 0);

        assertEq(burnerRouter.balanceOf(address(3_456_776_543)), amount1);

        collateral.transfer(address(burnerRouter), amount2);

        burnerRouter.onSlash(address(9876).subnetwork(111), address(9876), 0, 0);

        assertEq(burnerRouter.balanceOf(address(2_345_665_432)), amount2);

        collateral.transfer(address(burnerRouter), amount1);

        burnerRouter.onSlash(address(9876).subnetwork(111), address(98_765), 0, 0);

        assertEq(burnerRouter.balanceOf(address(3_456_776_543)), 2 * amount1);

        collateral.transfer(address(burnerRouter), amount3);

        burnerRouter.onSlash(address(987).subnetwork(111), address(98_765), 0, 0);

        assertEq(burnerRouter.balanceOf(address(1_234_554_321)), amount3);
    }

    function test_TriggerTransfer(
        uint256 amount
    ) external {
        amount = bound(amount, 1, 1000 * 1e18);

        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](1);
        networkReceivers[0] = IBurnerRouter.NetworkReceiver({network: address(9876), receiver: address(2_345_665_432)});
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](1);
        operatorNetworkReceivers[0] = IBurnerRouter.OperatorNetworkReceiver({
            network: address(9876),
            operator: address(98_765),
            receiver: address(3_456_776_543)
        });

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(1_234_554_321),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        collateral.transfer(address(burnerRouter), amount);

        burnerRouter.onSlash(address(9876).subnetwork(111), address(98_765), 0, 0);

        uint256 balanceBefore = collateral.balanceOf(address(3_456_776_543));
        assertEq(burnerRouter.triggerTransfer(address(3_456_776_543)), amount);
        assertEq(collateral.balanceOf(address(3_456_776_543)) - balanceBefore, amount);
    }

    function test_TriggerTransferRevertInsufficientBalance(
        uint256 amount
    ) external {
        amount = bound(amount, 1, 1000 * 1e18);

        uint256 blockTimestamp = block.timestamp * block.timestamp / block.timestamp * block.timestamp / block.timestamp;
        blockTimestamp = blockTimestamp + 1_720_700_948;
        vm.warp(blockTimestamp);

        address burnerRouterImplementation = address(new BurnerRouter());
        burnerRouterFactory = new BurnerRouterFactory(burnerRouterImplementation);

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](1);
        networkReceivers[0] = IBurnerRouter.NetworkReceiver({network: address(9876), receiver: address(2_345_665_432)});
        IBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers =
            new IBurnerRouter.OperatorNetworkReceiver[](1);
        operatorNetworkReceivers[0] = IBurnerRouter.OperatorNetworkReceiver({
            network: address(9876),
            operator: address(98_765),
            receiver: address(3_456_776_543)
        });

        IBurnerRouter.InitParams memory initParams = IBurnerRouter.InitParams({
            owner: alice,
            collateral: address(collateral),
            delay: 21 days,
            globalReceiver: address(1_234_554_321),
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });

        address burnerRouterAddress = burnerRouterFactory.create(initParams);
        burnerRouter = BurnerRouter(burnerRouterAddress);

        (vault,,) = _getVaultWithDelegatorWithSlasher(address(burnerRouter));

        collateral.transfer(address(burnerRouter), amount);

        vm.expectRevert(IBurnerRouter.InsufficientBalance.selector);
        burnerRouter.triggerTransfer(address(3_456_776_543));
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

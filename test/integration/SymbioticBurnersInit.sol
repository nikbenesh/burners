// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@symbioticfi/core/test/integration/SymbioticCoreInit.sol";

import "./SymbioticBurnersImports.sol";

import {SymbioticBurnersConstants} from "./SymbioticBurnersConstants.sol";
import {SymbioticBurnersBindings} from "./SymbioticBurnersBindings.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SymbioticBurnersInit is SymbioticCoreInit, SymbioticBurnersBindings {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // General config

    string public SYMBIOTIC_BURNERS_PROJECT_ROOT = "";
    bool public SYMBIOTIC_BURNERS_USE_EXISTING_DEPLOYMENT = false;
    bool public SYMBIOTIC_BURNERS_NEED_BURNERS = true;
    bool public SYMBIOTIC_BURNERS_NEED_BURNER_ROUTER = true;

    // Burner Router config

    uint48 public SYMBIOTIC_BURNERS_MIN_DELAY = 0;
    uint48 public SYMBIOTIC_BURNERS_MAX_DELAY = 60 days;

    SymbioticBurnersConstants.Burners public symbioticBurners;
    ISymbioticBurnerRouterFactory public symbioticBurnerRouterFactory;

    function setUp() public virtual override {
        super.setUp();

        if (SYMBIOTIC_BURNERS_NEED_BURNERS) {
            _initBurners_SymbioticBurners(SYMBIOTIC_BURNERS_USE_EXISTING_DEPLOYMENT);
        }
        if (SYMBIOTIC_BURNERS_NEED_BURNER_ROUTER) {
            _initBurnerRouter_SymbioticBurners(SYMBIOTIC_BURNERS_USE_EXISTING_DEPLOYMENT);
        }
    }

    // ------------------------------------------------------------ GENERAL HELPERS ------------------------------------------------------------ //

    function _initBurners_SymbioticBurners() internal virtual {
        symbioticBurners = SymbioticBurnersConstants.burners();
    }

    function _initBurners_SymbioticBurners(
        bool useExisting
    ) internal virtual {
        if (useExisting) {
            _initBurners_SymbioticBurners();
        } else {
            ISymbioticETHx_Burner ETHx_Burner;
            if (SymbioticBurnersConstants.burnerSupported("ETHx_Burner")) {
                ETHx_Burner = ISymbioticETHx_Burner(
                    deployCode(
                        string.concat(SYMBIOTIC_BURNERS_PROJECT_ROOT, "out/ETHx_Burner.sol/ETHx_Burner.json"),
                        abi.encode(SymbioticCoreConstants.token("ETHx"), SymbioticBurnersConstants.staderConfig())
                    )
                );
            }
            ISymbioticmETH_Burner mETH_Burner;
            if (SymbioticBurnersConstants.burnerSupported("mETH_Burner")) {
                mETH_Burner = ISymbioticmETH_Burner(
                    deployCode(
                        string.concat(SYMBIOTIC_BURNERS_PROJECT_ROOT, "out/mETH_Burner.sol/mETH_Burner.json"),
                        abi.encode(SymbioticCoreConstants.token("mETH"))
                    )
                );
            }
            ISymbioticrETH_Burner rETH_Burner;
            if (SymbioticBurnersConstants.burnerSupported("rETH_Burner")) {
                rETH_Burner = ISymbioticrETH_Burner(
                    deployCode(
                        string.concat(SYMBIOTIC_BURNERS_PROJECT_ROOT, "out/rETH_Burner.sol/rETH_Burner.json"),
                        abi.encode(SymbioticCoreConstants.token("rETH"))
                    )
                );
            }
            ISymbioticsfrxETH_Burner sfrxETH_Burner;
            if (SymbioticBurnersConstants.burnerSupported("sfrxETH_Burner")) {
                sfrxETH_Burner = ISymbioticsfrxETH_Burner(
                    deployCode(
                        string.concat(SYMBIOTIC_BURNERS_PROJECT_ROOT, "out/sfrxETH_Burner.sol/sfrxETH_Burner.json"),
                        abi.encode(
                            SymbioticCoreConstants.token("sfrxETH"),
                            SymbioticBurnersConstants.fraxEtherRedemptionQueue()
                        )
                    )
                );
            }
            ISymbioticswETH_Burner swETH_Burner;
            if (SymbioticBurnersConstants.burnerSupported("swETH_Burner")) {
                swETH_Burner = ISymbioticswETH_Burner(
                    deployCode(
                        string.concat(SYMBIOTIC_BURNERS_PROJECT_ROOT, "out/swETH_Burner.sol/swETH_Burner.json"),
                        abi.encode(SymbioticCoreConstants.token("swETH"), SymbioticBurnersConstants.swEXIT())
                    )
                );
            }
            ISymbioticwstETH_Burner wstETH_Burner;
            if (SymbioticBurnersConstants.burnerSupported("wstETH_Burner")) {
                wstETH_Burner = ISymbioticwstETH_Burner(
                    deployCode(
                        string.concat(SYMBIOTIC_BURNERS_PROJECT_ROOT, "out/wstETH_Burner.sol/wstETH_Burner.json"),
                        abi.encode(
                            SymbioticCoreConstants.token("wstETH"), SymbioticBurnersConstants.lidoWithdrawalQueue()
                        )
                    )
                );
            }

            symbioticBurners = SymbioticBurnersConstants.Burners({
                ETHx_Burner: ETHx_Burner,
                mETH_Burner: mETH_Burner,
                rETH_Burner: rETH_Burner,
                sfrxETH_Burner: sfrxETH_Burner,
                swETH_Burner: swETH_Burner,
                wstETH_Burner: wstETH_Burner
            });
        }
    }

    function _initBurnerRouter_SymbioticBurners() internal virtual {
        symbioticBurnerRouterFactory = SymbioticBurnersConstants.burnerRouterFactory();
    }

    function _initBurnerRouter_SymbioticBurners(
        bool useExisting
    ) internal virtual {
        if (useExisting) {
            _initBurnerRouter_SymbioticBurners();
        } else {
            address burnerRouterImplementation =
                deployCode(string.concat(SYMBIOTIC_BURNERS_PROJECT_ROOT, "out/BurnerRouter.sol/BurnerRouter.json"));
            symbioticBurnerRouterFactory = ISymbioticBurnerRouterFactory(
                deployCode(
                    string.concat(
                        SYMBIOTIC_BURNERS_PROJECT_ROOT, "out/BurnerRouterFactory.sol/BurnerRouterFactory.json"
                    ),
                    abi.encode(burnerRouterImplementation)
                )
            );
        }
    }

    // ------------------------------------------------------------ BURNER-ROUTER-RELATED HELPERS ------------------------------------------------------------ //

    function _getBurnerRouter_SymbioticBurners(
        address collateral,
        address globalReceiver
    ) internal virtual returns (address) {
        return _createBurnerRouter_SymbioticBurners({
            symbioticBurnerRouterFactory: symbioticBurnerRouterFactory,
            who: address(this),
            owner: address(this),
            collateral: collateral,
            delay: 0,
            globalReceiver: globalReceiver,
            networkReceivers: new ISymbioticBurnerRouter.NetworkReceiver[](0),
            operatorNetworkReceivers: new ISymbioticBurnerRouter.OperatorNetworkReceiver[](0)
        });
    }

    function _getBurnerRouter_SymbioticBurners(
        address owner,
        address collateral,
        uint48 delay,
        address globalReceiver,
        ISymbioticBurnerRouter.NetworkReceiver[] memory networkReceivers,
        ISymbioticBurnerRouter.OperatorNetworkReceiver[] memory operatorNetworkReceivers
    ) internal virtual returns (address) {
        return _createBurnerRouter_SymbioticBurners({
            symbioticBurnerRouterFactory: symbioticBurnerRouterFactory,
            who: address(this),
            owner: owner,
            collateral: collateral,
            delay: delay,
            globalReceiver: globalReceiver,
            networkReceivers: networkReceivers,
            operatorNetworkReceivers: operatorNetworkReceivers
        });
    }

    function _getBurnerRouterRandom_SymbioticBurners(
        address collateral,
        address globalReceiver
    ) internal virtual returns (address) {
        return _getBurnerRouter_SymbioticBurners({
            owner: address(this),
            collateral: collateral,
            delay: uint48(_randomWithBounds_Symbiotic(SYMBIOTIC_BURNERS_MIN_DELAY, SYMBIOTIC_BURNERS_MAX_DELAY)),
            globalReceiver: globalReceiver,
            networkReceivers: new ISymbioticBurnerRouter.NetworkReceiver[](0),
            operatorNetworkReceivers: new ISymbioticBurnerRouter.OperatorNetworkReceiver[](0)
        });
    }

    // ------------------------------------------------------------ ANYONE-RELATED HELPERS ------------------------------------------------------------ //

    // function _anyoneTriggerAction_SymbioticBurners(
    //     address anyone,
    //     address burner
    // ) internal virtual returns (bool lastStep) {
    //     // address collateral = ISymbioticETHx_Burner(burner).COLLATERAL();
    //     // address collateral = ISymbioticmETH_Burner(burner).COLLATERAL();
    //     // address collateral = ISymbioticrETH_Burner(burner).COLLATERAL();
    //     // address collateral = ISymbioticsfrxETH_Burner(burner).COLLATERAL();
    //     // address collateral = ISymbioticswETH_Burner(burner).COLLATERAL();
    //     address collateral = ISymbioticwstETH_Burner(burner).COLLATERAL();

    //     if (collateral == SymbioticCoreConstants.token("ETHx")) {
    //         ;
    //         return false;
    //     } else if (collateral == SymbioticCoreConstants.token("mETH")) {
    //         ;
    //         return false;
    //     } else if (collateral == SymbioticCoreConstants.token("rETH")) {
    //         ;
    //         return true;
    //     } else if (collateral == SymbioticCoreConstants.token("sfrxETH")) {
    //         ;
    //         return false;
    //     } else if (collateral == SymbioticCoreConstants.token("swETH")) {
    //         ;
    //         return false;
    //     } else if (collateral == SymbioticCoreConstants.token("wstETH")) {
    //         ;
    //         return false;
    //     } else {
    //         revert("Unsupported collateral");
    //     }
    // }

    function _anyoneTriggerTransfer_SymbioticBurners(
        address anyone,
        address burnerRouter,
        address receiver
    ) internal virtual {
        _triggerTransfer_SymbioticBurners(anyone, burnerRouter, receiver);
    }

    function _anyoneAcceptGlobalReceiver_SymbioticBurners(address anyone, address burnerRouter) internal virtual {
        _acceptGlobalReceiver_SymbioticBurners(anyone, burnerRouter);
    }

    function _anyoneAcceptNetworkReceiver_SymbioticBurners(
        address anyone,
        address burnerRouter,
        address network
    ) internal virtual {
        _acceptNetworkReceiver_SymbioticBurners(anyone, burnerRouter, network);
    }

    function _anyoneAcceptOperatorNetworkReceiver_SymbioticBurners(
        address anyone,
        address burnerRouter,
        address network,
        address operator
    ) internal virtual {
        _acceptOperatorNetworkReceiver_SymbioticBurners(anyone, burnerRouter, network, operator);
    }

    function _anyoneAcceptDelay_SymbioticBurners(address anyone, address burnerRouter) internal virtual {
        _acceptDelay_SymbioticBurners(anyone, burnerRouter);
    }

    // ------------------------------------------------------------ CURATOR-RELATED HELPERS ------------------------------------------------------------ //

    function _curatorSetGlobalReceiver_SymbioticBurners(
        address curator,
        address burnerRouter,
        address receiver
    ) internal virtual {
        _setGlobalReceiver_SymbioticBurners(curator, burnerRouter, receiver);
    }

    function _curatorSetNetworkReceiver_SymbioticBurners(
        address curator,
        address burnerRouter,
        address network,
        address receiver
    ) internal virtual {
        _setNetworkReceiver_SymbioticBurners(curator, burnerRouter, network, receiver);
    }

    function _curatorSetOperatorNetworkReceiver_SymbioticBurners(
        address curator,
        address burnerRouter,
        address network,
        address operator,
        address receiver
    ) internal virtual {
        _setOperatorNetworkReceiver_SymbioticBurners(curator, burnerRouter, network, operator, receiver);
    }

    function _curatorSetDelay_SymbioticBurners(address curator, address burnerRouter, uint48 delay) internal virtual {
        _setDelay_SymbioticBurners(curator, burnerRouter, delay);
    }
}

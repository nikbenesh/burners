// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SymbioticBurnersImports.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {SymbioticCoreConstants} from "@symbioticfi/core/test/integration/SymbioticCoreConstants.sol";

library SymbioticBurnersConstants {
    using Strings for string;

    struct Burners {
        ISymbioticETHx_Burner ETHx_Burner;
        ISymbioticmETH_Burner mETH_Burner;
        ISymbioticrETH_Burner rETH_Burner;
        ISymbioticsfrxETH_Burner sfrxETH_Burner;
        ISymbioticswETH_Burner swETH_Burner;
        ISymbioticwstETH_Burner wstETH_Burner;
    }

    function burners() internal view returns (Burners memory) {
        if (block.chainid == 1) {
            // mainnet
            revert("SymbioticCoreConstants.burners(): mainnet not supported yet");
        } else if (block.chainid == 17_000) {
            // holesky
            return Burners({
                ETHx_Burner: ISymbioticETHx_Burner(0xE7845Dd89F8b93924A279e58E448c5a8e7aCE675),
                mETH_Burner: ISymbioticmETH_Burner(0x58D347334A5E6bDE7279696abE59a11873294FA4),
                rETH_Burner: ISymbioticrETH_Burner(0x1d39cB4382DFF536DC2Be4EEf9D99d5f9Cd76697),
                sfrxETH_Burner: ISymbioticsfrxETH_Burner(address(0)),
                swETH_Burner: ISymbioticswETH_Burner(address(0)),
                wstETH_Burner: ISymbioticwstETH_Burner(0x25133c2c49A343F8312bb6e896C1ea0Ad8CD0EBd)
            });
        } else if (block.chainid == 11_155_111) {
            // sepolia
            return Burners({
                ETHx_Burner: ISymbioticETHx_Burner(address(0)),
                mETH_Burner: ISymbioticmETH_Burner(0xE7845Dd89F8b93924A279e58E448c5a8e7aCE675),
                rETH_Burner: ISymbioticrETH_Burner(address(0)),
                sfrxETH_Burner: ISymbioticsfrxETH_Burner(address(0)),
                swETH_Burner: ISymbioticswETH_Burner(address(0)),
                wstETH_Burner: ISymbioticwstETH_Burner(0x58D347334A5E6bDE7279696abE59a11873294FA4)
            });
        } else {
            revert("SymbioticBurnersConstants.burners(): chainid not supported");
        }
    }

    function burnerRouterFactory() internal view returns (ISymbioticBurnerRouterFactory) {
        if (block.chainid == 1) {
            // mainnet
            revert("SymbioticBurnersConstants.burnerRouterFactory(): mainnet not supported yet");
        } else if (block.chainid == 17_000) {
            // holesky
            return ISymbioticBurnerRouterFactory(0x32e2AfbdAffB1e675898ABA75868d92eE1E68f3b);
        } else if (block.chainid == 11_155_111) {
            // sepolia
            return ISymbioticBurnerRouterFactory(0x32e2AfbdAffB1e675898ABA75868d92eE1E68f3b);
        } else {
            revert("SymbioticBurnersConstants.burnerRouterFactory(): chainid not supported");
        }
    }

    function ETHx_BurnerSupported() internal view returns (bool) {
        return block.chainid == 17_000;
    }

    function mETH_BurnerSupported() internal view returns (bool) {
        return block.chainid == 17_000 || block.chainid == 11_155_111;
    }

    function rETH_BurnerSupported() internal view returns (bool) {
        return block.chainid == 17_000;
    }

    function sfrxETH_BurnerSupported() internal view returns (bool) {
        return false;
    }

    function swETH_BurnerSupported() internal view returns (bool) {
        return false;
    }

    function wstETH_BurnerSupported() internal view returns (bool) {
        return block.chainid == 17_000 || block.chainid == 11_155_111;
    }

    function burner(
        string memory name
    ) internal view returns (address) {
        if (name.equal("ETHx_Burner")) {
            return address(burners().ETHx_Burner);
        } else if (name.equal("mETH_Burner")) {
            return address(burners().mETH_Burner);
        } else if (name.equal("rETH_Burner")) {
            return address(burners().rETH_Burner);
        } else if (name.equal("sfrxETH_Burner")) {
            return address(burners().sfrxETH_Burner);
        } else if (name.equal("swETH_Burner")) {
            return address(burners().swETH_Burner);
        } else if (name.equal("wstETH_Burner")) {
            return address(burners().wstETH_Burner);
        } else {
            revert("SymbioticBurnersConstants.burner(): burner not found");
        }
    }

    function burnerSupported(
        string memory name
    ) internal view returns (bool) {
        if (name.equal("ETHx_Burner")) {
            return ETHx_BurnerSupported();
        } else if (name.equal("mETH_Burner")) {
            return mETH_BurnerSupported();
        } else if (name.equal("rETH_Burner")) {
            return rETH_BurnerSupported();
        } else if (name.equal("sfrxETH_Burner")) {
            return sfrxETH_BurnerSupported();
        } else if (name.equal("swETH_Burner")) {
            return swETH_BurnerSupported();
        } else if (name.equal("wstETH_Burner")) {
            return wstETH_BurnerSupported();
        } else {
            return false;
        }
    }

    function allBurners() internal view returns (string[] memory result) {
        result = new string[](6);
        result[0] = "ETHx_Burner";
        result[1] = "mETH_Burner";
        result[2] = "rETH_Burner";
        result[3] = "sfrxETH_Burner";
        result[4] = "swETH_Burner";
        result[5] = "wstETH_Burner";
    }

    function tokenAddressToBurner(
        address token
    ) internal view returns (address) {
        string[] memory allTokens = SymbioticCoreConstants.allTokens();
        for (uint256 i; i < allTokens.length; ++i) {
            if (token == SymbioticCoreConstants.token(allTokens[i])) {
                return burner(string.concat(allTokens[i], "_Burner"));
            }
        }
        revert("SymbioticBurnersConstants.tokenAddressToBurner(): token not found");
    }

    function tokenAddressToBurnerSupported(
        address token
    ) internal view returns (bool) {
        string[] memory allTokens = SymbioticCoreConstants.allTokens();
        for (uint256 i; i < allTokens.length; ++i) {
            if (!SymbioticCoreConstants.tokenSupported(allTokens[i])) {
                continue;
            }
            if (token == SymbioticCoreConstants.token(allTokens[i])) {
                return burnerSupported(string.concat(allTokens[i], "_Burner"));
            }
        }
        return false;
    }

    function lidoWithdrawalQueue() internal view returns (address) {
        if (block.chainid == 1) {
            // mainnet
            return 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1;
        } else if (block.chainid == 17_000) {
            // holesky
            return 0xc7cc160b58F8Bb0baC94b80847E2CF2800565C50;
        } else if (block.chainid == 11_155_111) {
            // sepolia
            return 0x1583C7b3f4C3B008720E6BcE5726336b0aB25fdd;
        } else {
            revert("SymbioticBurnersConstants.lidoWithdrawalQueue(): chainid not supported");
        }
    }

    function swEXIT() internal view returns (address) {
        if (block.chainid == 1) {
            // mainnet
            return 0x48C11b86807627AF70a34662D4865cF854251663;
        } else {
            revert("SymbioticBurnersConstants.swEXIT(): chainid not supported");
        }
    }

    function fraxEtherRedemptionQueue() internal view returns (address) {
        if (block.chainid == 1) {
            // mainnet
            return 0x82bA8da44Cd5261762e629dd5c605b17715727bd;
        } else {
            revert("SymbioticBurnersConstants.fraxEtherRedemptionQueue(): chainid not supported");
        }
    }

    function staderConfig() internal view returns (address) {
        if (block.chainid == 1) {
            // mainnet
            return 0x4ABEF2263d5A5ED582FC9A9789a41D85b68d69DB;
        } else if (block.chainid == 17_000) {
            // holesky
            return 0x50FD3384783EE49011E7b57d7A3430a762b3f3F2;
        } else {
            revert("SymbioticBurnersConstants.staderConfig(): chainid not supported");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IEthenaMinting {
    enum Role {
        Minter,
        Redeemer
    }

    enum OrderType {
        MINT,
        REDEEM
    }

    enum TokenType {
        STABLE,
        ASSET
    }

    enum SignatureType {
        EIP712,
        EIP1271
    }

    enum DelegatedSignerStatus {
        REJECTED,
        PENDING,
        ACCEPTED
    }

    struct Signature {
        SignatureType signature_type;
        bytes signature_bytes;
    }

    struct Route {
        address[] addresses;
        uint128[] ratios;
    }

    struct Order {
        string order_id;
        OrderType order_type;
        uint120 expiry;
        uint128 nonce;
        address benefactor;
        address beneficiary;
        address collateral_asset;
        uint128 collateral_amount;
        uint128 usde_amount;
    }

    struct TokenConfig {
        /// @notice tracks asset type (STABLE or ASSET)
        TokenType tokenType;
        /// @notice tracks if the asset is active
        bool isActive;
        /// @notice max mint per block this given asset
        uint128 maxMintPerBlock;
        /// @notice max redeem per block this given asset
        uint128 maxRedeemPerBlock;
    }

    struct BlockTotals {
        /// @notice USDe minted per block / per asset per block
        uint128 mintedPerBlock;
        /// @notice USDe redeemed per block / per asset per block
        uint128 redeemedPerBlock;
    }

    struct GlobalConfig {
        /// @notice max USDe that can be minted across all assets within a single block.
        uint128 globalMaxMintPerBlock;
        /// @notice max USDe that can be redeemed across all assets within a single block.
        uint128 globalMaxRedeemPerBlock;
    }

    /// @notice hash an Order struct
    function hashOrder(
        Order calldata order
    ) external view returns (bytes32);

    /// @notice total USDe that can be minted/redeemed across all assets per single block.
    function totalPerBlockPerAsset(uint256 blockNumber, address asset) external view returns (BlockTotals memory);

    function totalPerBlock(
        uint256 blockNumber
    ) external view returns (BlockTotals memory);

    /// @notice global single block totals
    function globalConfig() external view returns (GlobalConfig memory);

    function tokenConfig(
        address asset
    ) external view returns (TokenConfig memory);

    /// @notice Adds a benefactor address to the benefactor whitelist
    function addWhitelistedBenefactor(
        address benefactor
    ) external;

    /**
     * @notice Redeem stablecoins for assets
     * @param order struct containing order details and confirmation from server
     * @param signature signature of the taker
     */
    function redeem(Order calldata order, Signature calldata signature) external;
}

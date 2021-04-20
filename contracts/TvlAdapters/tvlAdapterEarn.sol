/**
 *Submitted for verification at Etherscan.io on 2021-04-15
 */

/**
 *Submitted for verification at Etherscan.io on 2021-04-14
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*******************************************************
 *                       Interfaces                    *
 *******************************************************/
interface IEarnToken {
    function token() external view returns (address);

    function calcPoolValueInToken() external view returns (uint256);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IOracle {
    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256);

    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) external view returns (uint256);

    function getPriceUsdcRecommended(address tokenAddress)
        external
        view
        returns (uint256);
}

interface IDelegationMapping {
    function assetBalanceIsDelegated(address) external view returns (bool);
}

interface IAddressesGenerator {
    function assetsAddresses() external view returns (address[] memory);

    function assetsLength() external view returns (uint256);
}

/*******************************************************
 *                     Adapter Logic                   *
 *******************************************************/
contract TvlAdapterEarn {
    /*******************************************************
     *           Common code shared by all adapters        *
     *******************************************************/

    IOracle public oracle; // The oracle is used to fetch USDC normalized pricing data
    IAddressesGenerator public addressesGenerator; // A utility for fetching assets addresses and length
    IDelegationMapping public delegationMapping;

    /**
     * TVL breakdown for an asset
     */
    struct AssetTvlBreakdown {
        address assetId; // Asset address
        address tokenId; // Token address
        uint256 tokenPriceUsdc; // Token price in USDC
        uint256 underlyingTokenBalance; // Amount of underlying token in asset
        uint256 delegatedBalance; // Amount of underlying token balance that is delegated
        uint256 adjustedBalance; // underlyingTokenBalance - delegatedBalance
        uint256 adjustedBalanceUsdc; // TVL
    }

    /**
     * Information about the adapter
     */
    struct AdapterInfo {
        address id; // Adapter address
        string typeId; // Adapter typeId (for example "VAULT_V2" or "IRON_BANK_MARKET")
        string categoryId; // Adapter categoryId (for example "VAULT")
    }

    /**
     * Configure adapter
     */
    constructor(
        address _oracleAddress,
        address _addressesGeneratorAddress,
        address _delegationMappingAddress
    ) {
        oracle = IOracle(_oracleAddress);
        addressesGenerator = IAddressesGenerator(_addressesGeneratorAddress);
        delegationMapping = IDelegationMapping(_delegationMappingAddress);
    }

    /**
     * Fetch the total number of assets for this adapter
     */
    function assetsLength() public view returns (uint256) {
        return 10;
    }

    /**
     * Fetch all asset addresses for this adapter
     */
    function assetsAddresses() public view returns (address[] memory) {
        address[] memory overrideAddresses = new address[](10);
        overrideAddresses[0] = 0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01;
        overrideAddresses[1] = 0xd6aD7a6750A7593E092a9B218d66C0A814a3436e;
        overrideAddresses[2] = 0x83f798e925BcD4017Eb265844FDDAbb448f1707D;
        overrideAddresses[3] = 0xF61718057901F84C4eEC4339EF8f0D86D2B45600;
        overrideAddresses[4] = 0x73a052500105205d34Daf004eAb301916DA8190f;
        overrideAddresses[5] = 0x04Aa51bbcB46541455cCF1B8bef2ebc5d3787EC9;
        overrideAddresses[6] = 0xC2cB1040220768554cf699b0d863A3cd4324ce32;
        overrideAddresses[7] = 0x26EA744E5B887E5205727f55dFBE8685e3b21951;
        overrideAddresses[8] = 0xE6354ed5bC4b393a5Aad09f21c46E101e692d447;
        overrideAddresses[9] = 0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE;
        return overrideAddresses;
    }

    // Fetch TVL breakdown for adapter given an array of addresses
    function assetsTvlBreakdown(address[] memory _assetsAddresses)
        public
        view
        returns (AssetTvlBreakdown[] memory)
    {
        uint256 numberOfAssets = _assetsAddresses.length;

        AssetTvlBreakdown[] memory tvlData =
            new AssetTvlBreakdown[](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            tvlData[assetIdx] = assetTvlBreakdown(assetAddress);
        }
        return tvlData;
    }

    /**
     * Fetch TVL breakdown for adapter
     */
    function assetsTvlBreakdown()
        external
        view
        returns (AssetTvlBreakdown[] memory)
    {
        address[] memory _assetsAddresses = assetsAddresses();
        return assetsTvlBreakdown(_assetsAddresses);
    }

    /**
     * Fetch TVL breakdown of an asset
     */
    function assetTvlBreakdown(address assetAddress)
        public
        view
        returns (AssetTvlBreakdown memory)
    {
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 underlyingBalanceAmount = assetBalance(assetAddress);
        uint256 delegatedBalanceAmount = assetDelegatedBalance(assetAddress);
        uint256 adjustedBalance =
            underlyingBalanceAmount - delegatedBalanceAmount;
        uint256 tokenPriceUsdc =
            IOracle(0x190c2CFC69E68A8e8D5e2b9e2B9Cc3332CafF77B)
                .getPriceUsdcRecommended(tokenAddress);
        return
            AssetTvlBreakdown({
                assetId: assetAddress,
                tokenId: tokenAddress,
                tokenPriceUsdc: tokenPriceUsdc,
                underlyingTokenBalance: underlyingBalanceAmount,
                delegatedBalance: delegatedBalanceAmount,
                adjustedBalance: adjustedBalance,
                adjustedBalanceUsdc: IOracle(
                    0x190c2CFC69E68A8e8D5e2b9e2B9Cc3332CafF77B
                )
                    .getNormalizedValueUsdc(
                    tokenAddress,
                    adjustedBalance,
                    tokenPriceUsdc
                )
            });
    }

    /**
     * Fetch TVL for adapter in USDC
     */
    function assetsTvlUsdc(address[] memory _assetsAddresses)
        public
        view
        returns (uint256)
    {
        uint256 tvl;
        uint256 numberOfAssets = assetsLength();
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            uint256 _assetTvl = assetTvlUsdc(assetAddress);
            tvl += _assetTvl;
        }
        return tvl;
    }

    /**
     * Fetch TVL for adapter in USDC given an array of addresses
     */
    function assetsTvlUsdc() external view returns (uint256) {
        address[] memory _assetsAddresses = assetsAddresses();
        return assetsTvlUsdc(_assetsAddresses);
    }

    /**
     * Fetch TVL of an asset in USDC
     */
    function assetTvlUsdc(address assetAddress) public view returns (uint256) {
        address tokenAddress = underlyingTokenAddress(assetAddress);
        uint256 underlyingBalanceAmount = assetBalance(assetAddress);
        uint256 delegatedBalanceAmount = assetDelegatedBalance(assetAddress);
        uint256 adjustedBalanceAmount =
            underlyingBalanceAmount - delegatedBalanceAmount;
        uint256 adjustedBalanceUsdc =
            IOracle(0x190c2CFC69E68A8e8D5e2b9e2B9Cc3332CafF77B)
                .getNormalizedValueUsdc(tokenAddress, adjustedBalanceAmount);
        return adjustedBalanceUsdc;
    }

    /*******************************************************
     *                   Asset-specific Logic              *
     *******************************************************/

    /**
     * Fetch adapter info
     */
    function adapterInfo() public view returns (AdapterInfo memory) {
        return
            AdapterInfo({
                id: address(this),
                typeId: "EARN",
                categoryId: "SAFE"
            });
    }

    /**
     * Fetch the underlying token address of an asset
     */
    function underlyingTokenAddress(address assetAddress)
        public
        view
        returns (address)
    {
        IEarnToken earnToken = IEarnToken(assetAddress);
        address tokenAddress = earnToken.token();
        return tokenAddress;
    }

    /**
     * Fetch asset balance in underlying tokens
     */
    function assetBalance(address assetAddress) public view returns (uint256) {
        IEarnToken earnToken = IEarnToken(assetAddress);
        return earnToken.calcPoolValueInToken();
    }

    /**
     * Fetch delegated balance of an asset
     */
    function assetDelegatedBalance(address assetAddress)
        public
        view
        returns (uint256)
    {
        return 0;
    }
}

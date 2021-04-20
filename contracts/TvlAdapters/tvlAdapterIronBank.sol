/**
 *Submitted for verification at Etherscan.io on 2021-04-14
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*******************************************************
 *                       Interfaces                    *
 *******************************************************/
interface CyToken {
    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function balanceOf() external view returns (uint256);

    function borrowBalanceStored() external view returns (uint256);

    function decimals() external view returns (uint8);
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
contract TvlAdapterIronBank {
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
        return addressesGenerator.assetsLength();
    }

    /**
     * Fetch all asset addresses for this adapter
     */
    function assetsAddresses() public view returns (address[] memory) {
        address[] memory overrideAddresses = new address[](20);
        overrideAddresses[0] = 0x41c84c0e2EE0b740Cf0d31F63f3B6F627DC6b393;
        overrideAddresses[1] = 0x8e595470Ed749b85C6F7669de83EAe304C2ec68F;
        overrideAddresses[2] = 0x7589C9E17BCFcE1Ccaa1f921196FDa177F0207Fc;
        overrideAddresses[3] = 0xE7BFf2Da8A2f619c2586FB83938Fa56CE803aA16;
        overrideAddresses[4] = 0xFa3472f7319477c9bFEcdD66E4B948569E7621b9;
        overrideAddresses[5] = 0x12A9cC33A980DAa74E00cc2d1A0E74C57A93d12C;
        overrideAddresses[6] = 0x8Fc8BFD80d6A9F17Fb98A373023d72531792B431;
        overrideAddresses[7] = 0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a;
        overrideAddresses[8] = 0x76Eb2FE28b36B3ee97F3Adae0C69606eeDB2A37c;
        overrideAddresses[9] = 0xBE86e8918DFc7d3Cb10d295fc220F941A1470C5c;
        overrideAddresses[10] = 0x297d4Da727fbC629252845E96538FC46167e453A;
        overrideAddresses[11] = 0xA8caeA564811af0e92b1E044f3eDd18Fa9a73E4F;
        overrideAddresses[12] = 0xCA55F9C4E77f7B8524178583b0f7c798De17fD54;
        overrideAddresses[13] = 0x7736Ffb07104c0C400Bb0CC9A7C228452A732992;
        overrideAddresses[14] = 0x09bDCCe2593f0BEF0991188c25Fb744897B6572d;
        overrideAddresses[15] = 0xa0E5A19E091BBe241E655997E50da82DA676b083;
        overrideAddresses[16] = 0x4F12c9DABB5319A252463E6028CA833f1164d045;
        overrideAddresses[17] = 0xBB4B067cc612494914A902217CB6078aB4728E36;
        overrideAddresses[18] = 0x950027632FbD6aDAdFe82644BfB64647642B6C09;
        overrideAddresses[19] = 0xa7c4054AFD3DbBbF5bFe80f41862b89ea05c9806;
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
                typeId: "IRON_BANK_MARKET",
                categoryId: "LENDING"
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
        CyToken cyToken = CyToken(assetAddress);
        address tokenAddress = cyToken.underlying();
        return tokenAddress;
    }

    /**
     * Fetch asset balance in underlying tokens
     */
    function assetBalance(address assetAddress) public view returns (uint256) {
        CyToken cyToken = CyToken(assetAddress);
        uint256 cash = cyToken.getCash();
        uint256 totalBorrows = cyToken.totalBorrows();
        uint256 totalReserves = cyToken.totalReserves();
        uint256 totalSupplied = (cash + totalBorrows - totalReserves);
        return totalSupplied;
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

    function assetDelegatedBalance(address assetAddress)
        public
        view
        returns (uint256)
    {
        return 0;
    }
}

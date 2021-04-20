/**
 *Submitted for verification at Etherscan.io on 2021-04-14
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*******************************************************
 *                       Interfaces                    *
 *******************************************************/
interface IV1Vault {
    function token() external view returns (address);

    function balance() external view returns (uint256);
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
contract TvlAdapterV1Vaults {
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
        address[] memory overrideAddresses = new address[](34);
        overrideAddresses[0] = 0x29E240CFD7946BA20895a7a02eDb25C210f9f324;
        overrideAddresses[1] = 0x881b06da56BB5675c54E4Ed311c21E54C5025298;
        overrideAddresses[2] = 0x597aD1e0c13Bfe8025993D9e79C69E1c0233522e;
        overrideAddresses[3] = 0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c;
        overrideAddresses[4] = 0x37d19d1c4E1fa9DC47bD1eA12f742a0887eDa74a;
        overrideAddresses[5] = 0xACd43E627e64355f1861cEC6d3a6688B31a6F952;
        overrideAddresses[6] = 0x2f08119C6f07c006695E079AAFc638b8789FAf18;
        overrideAddresses[7] = 0xBA2E7Fed597fd0E3e70f5130BcDbbFE06bB94fe1;
        overrideAddresses[8] = 0x2994529C0652D127b7842094103715ec5299bBed;
        overrideAddresses[9] = 0x7Ff566E1d69DEfF32a7b244aE7276b9f90e9D0f6;
        overrideAddresses[10] = 0xe1237aA7f535b0CC33Fd973D66cBf830354D16c7;
        overrideAddresses[11] = 0x9cA85572E6A3EbF24dEDd195623F188735A5179f;
        overrideAddresses[12] = 0xec0d8D3ED5477106c6D4ea27D90a60e594693C90;
        overrideAddresses[13] = 0x629c759D1E83eFbF63d84eb3868B564d9521C129;
        overrideAddresses[14] = 0x0FCDAeDFb8A7DfDa2e9838564c5A1665d856AFDF;
        overrideAddresses[15] = 0xcC7E70A958917cCe67B4B87a8C30E6297451aE98;
        overrideAddresses[16] = 0x98B058b2CBacF5E99bC7012DF757ea7CFEbd35BC;
        overrideAddresses[17] = 0xE0db48B4F71752C4bEf16De1DBD042B82976b8C7;
        overrideAddresses[18] = 0x5334e150B938dd2b6bd040D9c4a03Cff0cED3765;
        overrideAddresses[19] = 0xFe39Ce91437C76178665D64d7a2694B0f6f17fE3;
        overrideAddresses[20] = 0xF6C9E9AF314982A4b38366f4AbfAa00595C5A6fC;
        overrideAddresses[21] = 0xA8B1Cb4ed612ee179BDeA16CCa6Ba596321AE52D;
        overrideAddresses[22] = 0x07FB4756f67bD46B748b16119E802F1f880fb2CC;
        overrideAddresses[23] = 0x7F83935EcFe4729c4Ea592Ab2bC1A32588409797;
        overrideAddresses[24] = 0x123964EbE096A920dae00Fb795FFBfA0c9Ff4675;
        overrideAddresses[25] = 0x46AFc2dfBd1ea0c0760CAD8262A5838e803A37e5;
        overrideAddresses[26] = 0x5533ed0a3b83F70c3c4a1f69Ef5546D3D4713E44;
        overrideAddresses[27] = 0x39546945695DCb1c037C836925B355262f551f55;
        overrideAddresses[28] = 0x8e6741b456a074F0Bc45B8b82A755d4aF7E965dF;
        overrideAddresses[29] = 0x03403154afc09Ce8e44C3B185C82C6aD5f86b9ab;
        overrideAddresses[30] = 0xE625F5923303f1CE7A43ACFEFd11fd12f30DbcA4;
        overrideAddresses[31] = 0xBacB69571323575C6a5A3b4F9EEde1DC7D31FBc1;
        overrideAddresses[32] = 0x1B5eb1173D2Bf770e50F10410C9a96F7a8eB6e75;
        overrideAddresses[33] = 0x96Ea6AF74Af09522fCB4c28C269C26F59a31ced6;
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
        uint256 delegatedBalanceAmount = 0;
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
        uint256 delegatedBalanceAmount = 0;
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
                typeId: "VAULT_V1",
                categoryId: "VAULT"
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
        IV1Vault vault = IV1Vault(assetAddress);
        address tokenAddress = vault.token();
        return tokenAddress;
    }

    /**
     * Fetch asset balance in underlying tokens
     */
    function assetBalance(address assetAddress) public view returns (uint256) {
        IV1Vault vault = IV1Vault(assetAddress);
        return vault.balance();
    }

    /**
     * Fetch delegated balance of an asset
     */
    function assetDelegatedBalance(address assetAddress)
        public
        view
        returns (uint256)
    {
        bool balanceIsDelegated =
            delegationMapping.assetBalanceIsDelegated(assetAddress);
        if (balanceIsDelegated) {
            return assetBalance(assetAddress);
        }
        return 0;
    }
}

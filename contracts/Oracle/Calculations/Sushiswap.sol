// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface PriceRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function WETH() external view returns (address);
}

interface Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);
}

contract CalculationsSushiswap {
    address public primaryRouterAddress;
    address public primaryFactoryAddress;
    address public secondaryRouterAddress;
    address public secondaryFactoryAddress;
    address public wethAddress;
    address public usdcAddress;
    PriceRouter primaryRouter;
    PriceRouter secondaryRouter;

    address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address zeroAddress = 0x0000000000000000000000000000000000000000;

    constructor(
        address _primaryRouterAddress,
        address _primaryFactoryAddress,
        address _secondaryRouterAddress,
        address _secondaryFactoryAddress,
        address _usdcAddress
    ) {
        primaryRouterAddress = _primaryRouterAddress;
        primaryFactoryAddress = _primaryFactoryAddress;
        secondaryRouterAddress = _secondaryRouterAddress;
        secondaryFactoryAddress = _secondaryFactoryAddress;
        usdcAddress = _usdcAddress;
        primaryRouter = PriceRouter(primaryRouterAddress);
        secondaryRouter = PriceRouter(secondaryRouterAddress);
        wethAddress = primaryRouter.WETH();
    }

    // Uniswap/Sushiswap
    function getPriceUsdc(address tokenAddress) public view returns (uint256) {
        if (isLpToken(tokenAddress)) {
            return getLpTokenPriceUsdc(tokenAddress);
        }
        return getPriceFromRouterUsdc(tokenAddress);
    }

    function getPriceFromRouter(address token0Address, address token1Address)
        public
        view
        returns (uint256)
    {
        // Convert ETH address (0xEeee...) to WETH
        if (token0Address == ethAddress) {
            token0Address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        }
        if (token1Address == ethAddress) {
            token1Address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        }

        address[] memory path;
        uint8 numberOfJumps;
        bool inputTokenIsWeth =
            token0Address == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 ||
                token1Address == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        if (inputTokenIsWeth) {
            // path = [token0, weth] or [weth, token1]
            numberOfJumps = 1;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = token1Address;
        } else {
            // path = [token0, weth, token1]
            numberOfJumps = 2;
            path = new address[](numberOfJumps + 1);
            path[0] = token0Address;
            path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            path[2] = token1Address;
        }

        IERC20 token0 = IERC20(token0Address);
        uint256 amountIn = 10**uint256(token0.decimals());
        uint256[] memory amountsOut;

        bool fallbackRouterExists =
            0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F != zeroAddress;
        if (fallbackRouterExists) {
            try
                PriceRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
                    .getAmountsOut(amountIn, path)
            returns (uint256[] memory _amountsOut) {
                amountsOut = _amountsOut;
            } catch {
                amountsOut = PriceRouter(
                    0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
                )
                    .getAmountsOut(amountIn, path);
            }
        } else {
            amountsOut = PriceRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
                .getAmountsOut(amountIn, path);
        }

        // Return raw price (without fees)
        uint256 amountOut = amountsOut[amountsOut.length - 1];
        uint256 feeBips = 30; // .3% per swap
        amountOut = (amountOut * 10000) / (10000 - (feeBips * numberOfJumps));
        return amountOut;
    }

    function getPriceFromRouterUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return
            getPriceFromRouter(
                tokenAddress,
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
            );
    }

    function isLpToken(address tokenAddress) public view returns (bool) {
        Pair lpToken = Pair(tokenAddress);
        try lpToken.factory() {
            return true;
        } catch {
            return false;
        }
    }

    function getRouterForLpToken(address tokenAddress)
        public
        view
        returns (PriceRouter)
    {
        Pair lpToken = Pair(tokenAddress);
        address factoryAddress = lpToken.factory();
        if (factoryAddress == 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f) {
            return PriceRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else if (
            factoryAddress == 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
        ) {
            return PriceRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
        }
        revert();
    }

    function getLpTokenTotalLiquidityUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        Pair pair = Pair(tokenAddress);
        address token0Address = pair.token0();
        address token1Address = pair.token1();
        IERC20 token0 = IERC20(token0Address);
        IERC20 token1 = IERC20(token1Address);
        uint8 token0Decimals = token0.decimals();
        uint8 token1Decimals = token1.decimals();
        uint256 token0Price = getPriceUsdc(token0Address);
        uint256 token1Price = getPriceUsdc(token1Address);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint256 totalLiquidity =
            ((reserve0 / 10**token0Decimals) * token0Price) +
                ((reserve1 / 10**token1Decimals) * token1Price);
        return totalLiquidity;
    }

    function getLpTokenPriceUsdc(address tokenAddress)
        public
        view
        returns (uint256)
    {
        Pair pair = Pair(tokenAddress);
        uint256 totalLiquidity = getLpTokenTotalLiquidityUsdc(tokenAddress);
        uint256 totalSupply = pair.totalSupply();
        uint8 pairDecimals = pair.decimals();
        uint256 pricePerLpTokenUsdc =
            (totalLiquidity * 10**pairDecimals) / totalSupply;
        return pricePerLpTokenUsdc;
    }
}

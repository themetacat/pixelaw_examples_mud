// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;
struct SwapParams {
    address tokenIn;
    address tokenOut;
    uint256 amountSpecified;
}

struct Pool {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address pool;
    bool version;
}

struct Quote {
    Pool[] path;
    uint256 amountIn;
    uint256 amountOut;
}

interface IQuote {
    
  function routeExactInput(SwapParams memory params) external view returns (Quote memory bestQuote);

  function routeExactOutput(SwapParams memory params) external view returns (Quote memory bestQuote);

}
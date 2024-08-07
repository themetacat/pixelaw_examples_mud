// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint8);
    // function transferFrom(address from, address to, uint256 value) external returns (bool);
}
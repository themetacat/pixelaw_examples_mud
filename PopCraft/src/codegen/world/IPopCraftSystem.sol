// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

import { DefaultParameters } from "./../../core_codegen/index.sol";

/**
 * @title IPopCraftSystem
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IPopCraftSystem {
  error InsufficientBalance(address);
  error Inventory_shortage(address shortageToken);
  error GetQuoteError();
  error GameContinues();
  error ExceededPurchaseLimit(uint256 limit);

  function popCraft_PopCraftSystem_init() external;

  function popCraft_PopCraftSystem_interact(DefaultParameters memory default_parameters) external;

  function popCraft_PopCraftSystem_pop(DefaultParameters memory default_parameters) external;

  function popCraft_PopCraftSystem_buyToken(address[] memory token_addr, uint256[] memory amount) external payable;

  function popCraft_PopCraftSystem_withDrawToken(address[] memory token_addr, uint256[] memory amount) external;

  function popCraft_PopCraftSystem_quoteOutput(
    address[] memory tokenOut,
    uint256[] memory amount
  ) external view returns (uint256 res);

  function popCraft_PopCraftSystem_reIssuanceRewards(address[] memory owner) external;
}

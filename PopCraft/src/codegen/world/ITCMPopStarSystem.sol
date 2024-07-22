// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

import { DefaultParameters } from "./../../core_codegen/index.sol";

/**
 * @title ITCMPopStarSystem
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITCMPopStarSystem {
  error InsufficientBalance(address);
  error Inventory_shortage(address shortageToken);
  error GetQuoteError();
  error GameContinues();

  function tcmPopStar_TCMPopStarSystem_init() external;

  function tcmPopStar_TCMPopStarSystem_interact(DefaultParameters memory default_parameters) external;

  function tcmPopStar_TCMPopStarSystem_pop(DefaultParameters memory default_parameters) external;

  function tcmPopStar_TCMPopStarSystem_buyToken(address[] memory token_addr, uint256[] memory amount) external payable;

  function tcmPopStar_TCMPopStarSystem_withDrawToken(address[] memory token_addr, uint256[] memory amount) external;

  function tcmPopStar_TCMPopStarSystem_quoteOutput(
    address[] memory tokenOut,
    uint256[] memory amount
  ) external view returns (uint256 res);

  function tcmPopStar_TCMPopStarSystem_reissuanceRewards(address[] memory owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

import { Permissions, PermissionsData, PermissionsTableId } from "./tables/Permissions.sol";
import { Pixel, PixelData, PixelTableId } from "./tables/Pixel.sol";
import { PixelUpdate, PixelUpdateData, PixelUpdateTableId } from "./tables/PixelUpdate.sol";
import { QueueItem, QueueItemTableId } from "./tables/QueueItem.sol";
import { App, AppData, AppTableId } from "./tables/App.sol";
import { AppUser, AppUserTableId } from "./tables/AppUser.sol";
import { AppName, AppNameTableId } from "./tables/AppName.sol";
import { CoreActionAddress, CoreActionAddressTableId } from "./tables/CoreActionAddress.sol";
import { Instruction, InstructionData, InstructionTableId } from "./tables/Instruction.sol";
import { QueueScheduled, QueueScheduledData, QueueScheduledTableId } from "./tables/QueueScheduled.sol";
import { QueueProcessed, QueueProcessedTableId } from "./tables/QueueProcessed.sol";
import { Alert, AlertData, AlertTableId } from "./tables/Alert.sol";
import { ERC20TokenBalance, ERC20TokenBalanceTableId } from "./tables/ERC20TokenBalance.sol";


struct DefaultParameters{
    address for_player;
    string for_app;
    Position position;
    string color;
}


struct Position{
    uint32 x;
    uint32 y; 
}

struct TokenInfo{
  address token_addr;
  uint256 amount; 
}

struct UniversalRouterParams{
  bytes call_data;
  uint256 value; 
  TokenInfo token_info;
}

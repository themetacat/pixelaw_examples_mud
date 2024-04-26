// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;
 
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IBaseWorld } from "@latticexyz/world-modules/src/interfaces/IBaseWorld.sol";
 
import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/core/implementations/WorldRegistrationSystem.sol";
 
// Create resource identifiers (for the namespace and system)
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
 
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { DefaultParameters } from "../src/core_codegen/index.sol";
import { Puzzle } from "../src/codegen/index.sol";
// For deploying MessageSystem
import { PuzzleSystem } from "../src/systems/PuzzleSystem.sol";
 
contract PuzzleExtension is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    console.log("world Address: ", worldAddress);
 
    WorldRegistrationSystem world = WorldRegistrationSystem(worldAddress);
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(bytes14("puzzle"));
    ResourceId systemResource = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "puzzle", "PuzzleSystem");
    console.log("Namespace ID: %x", uint256(ResourceId.unwrap(namespaceResource)));
    console.log("System ID:    %x", uint256(ResourceId.unwrap(systemResource)));
 
    vm.startBroadcast(deployerPrivateKey);
    world.registerNamespace(namespaceResource);

    StoreSwitch.setStoreAddress(worldAddress);
    Puzzle.register();
  
    PuzzleSystem puzzleSystem = new PuzzleSystem();
    console.log("SYSTEM_ADDRESS: ", address(puzzleSystem));
    
    world.registerSystem(systemResource, puzzleSystem, true);
    world.registerFunctionSelector(systemResource, "init()");
    world.registerFunctionSelector(systemResource, "interact((address,string,(uint32,uint32),string))");
    world.registerFunctionSelector(systemResource, "move((address,string,(uint32,uint32),string))");

    vm.stopBroadcast();
  }

}
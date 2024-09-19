// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;
 
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { IBaseWorld } from "@latticexyz/world-modules/src/interfaces/IBaseWorld.sol";
 
import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/core/implementations/WorldRegistrationSystem.sol";
 import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
// Create resource identifiers (for the namespace and system)
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
 
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { DefaultParameters } from "../src/core_codegen/index.sol";
import { TCMPopStar, GameRecord, TokenSold, TokenBalance } from "../src/codegen/index.sol";
// import { TokenSold } from "../src/codegen/index.sol";
// import { TokenBalance } from "../src/codegen/index.sol";
import { PopCraftSystem } from "../src/systems/PopCraftSystem.sol";
import { Puppet } from "@latticexyz/world-modules/src/modules/puppet/Puppet.sol";

contract PopCraftExtension is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    console.log("world Address: ", worldAddress);
 
    WorldRegistrationSystem world = WorldRegistrationSystem(worldAddress);
    ResourceId namespaceResource = WorldResourceIdLib.encodeNamespace(bytes14("popCraft"));
    ResourceId systemResource = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "popCraft", "PopCraftSystem");
    console.log("Namespace ID: %x", uint256(ResourceId.unwrap(namespaceResource)));
    console.log("System ID:    %x", uint256(ResourceId.unwrap(systemResource)));

    vm.startBroadcast(deployerPrivateKey);
    world.registerNamespace(namespaceResource);

    StoreSwitch.setStoreAddress(worldAddress);

    TCMPopStar.register();
    TokenSold.register();
    TokenBalance.register();
    GameRecord.register();

    PopCraftSystem popCraftSystem = new PopCraftSystem();
    console.log("SYSTEM_ADDRESS: ", address(popCraftSystem));
    
    world.registerSystem(systemResource, popCraftSystem, true);
    world.registerFunctionSelector(systemResource, "init()");
    world.registerFunctionSelector(systemResource, "interact((address,string,(uint32,uint32),string))");
    world.registerFunctionSelector(systemResource, "pop((address,string,(uint32,uint32),string))");
    world.registerFunctionSelector(systemResource, "buyToken((bytes,uint256,(address,uint256))[])");
    // world.registerFunctionSelector(systemResource, "withDrawToken(address,uint256)");
    world.registerFunctionSelector(systemResource, "reIssuanceRewards(address[])");
    vm.stopBroadcast();
  }

}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { ICoreSystem } from "../core_codegen/world/ICoreSystem.sol";
import { PermissionsData, DefaultParameters, Position, PixelUpdateData, Pixel, PixelData, TestParameters } from "../core_codegen/index.sol";


contract MyAppSystem is System {

  // Core only supports unicode icons for now
  string constant APP_ICON = 'U+1F58B';

  // The NAMESPACE and SYSTEM_NAME of the current contract in mudConfig
  string constant NAMESPACE = 'myapp';
  string constant SYSTEM_NAME = 'MyAppSystem';

  // APP_NAME must be unique across the entire platform
  string constant APP_NAME = 'myapp';

  // prefixing with BASE means using the server's default abi.json handler, the following is consistent with the current contract name.
  string constant APP_MANIFEST = 'BASE/MyAppSystem';
  
  function init() public {
    
    // init my app
    ICoreSystem(_world()).update_app(APP_NAME, APP_ICON, APP_MANIFEST, NAMESPACE, SYSTEM_NAME);

    // Set app instruction
    // bytes4 INTERACT_SELECTOR =  bytes4(keccak256("interact(DefaultParameters)"));
    // string memory INTERACT_INSTRUCTION = 'select for myapp';
    // ICoreSystem(_world()).set_instruction(INTERACT_SELECTOR, INTERACT_INSTRUCTION);

    // Grant permission to the snake App
    ICoreSystem(_world()).update_permission("snake", 
    PermissionsData({
      app: true, color: true, owner: true, text: true, timestamp: false, action: false
      })); 
  }

  //Put color on a certain position
  // Arguments
  //`position` - Position of the pixel.
  //`new_color` - Color to set the pixel to.
  function interact(DefaultParameters memory default_parameters) public {
    // Load important variables
    Position memory position = default_parameters.position;
    address player = default_parameters.for_player;
    string memory app = default_parameters.for_app;

    // Load the Pixel
    PixelData memory pixel = Pixel.get(position.x, position.y);

    // TODO: Load MyApp App Settings like the fade steptime
    // For example for the Cooldown feature
    uint256 COOLDOWN_SECS = 5;

    // Check if 5 seconds have passed or if the sender is the owner
    require(pixel.owner == address(0) || pixel.owner == player || block.timestamp - pixel.timestamp < COOLDOWN_SECS, 'Cooldown not over');

    // We can now update color of the pixel

    // If you don't want to assign a value of type address(like owner), you should pass in address(1)
    // If you don't want to assign a value of type string(like app、color、text...), you should pass in "_Null"
    ICoreSystem(_world()).update_pixel(
      PixelUpdateData({
        x: position.x,
        y: position.y,
        color: default_parameters.color,
        timestamp: 0,
        text: "_Null",
        app: app,
        owner: player,
        action: "_Null"
      }));
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { ICoreSystem } from "../core_codegen/world/ICoreSystem.sol";
import { PermissionsData, DefaultParameters, Position, PixelUpdateData, Pixel, PixelData, TestParameters } from "../core_codegen/index.sol";
import { TestEnum, TestEnumTwo } from "../codegen/common.sol";

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

    // bytes4 INTERACT_SELECTOR =  bytes4(keccak256("interact(DefaultParameters, Direction)"));
    // string memory INTERACT_INSTRUCTION = 'select for myapp';
    // ICoreSystem(_world()).set_instruction(INTERACT_SELECTOR, INTERACT_INSTRUCTION);

    //Grant permission to the snake App
    ICoreSystem(_world()).update_permission("snake", 
    PermissionsData({
      app: false, color: true, owner: false, text: true, timestamp: false, action: false
      })); 
  }

  //Put color on a certain position
  // Arguments
  //`position` - Position of the pixel.
  //`new_color` - Color to set the pixel to.
  function interact(DefaultParameters memory default_parameters, TestEnum testEnum, Position memory po, TestEnumTwo testEnumTwo, TestParameters memory testParameters) public {
    // Load important variables
    Position memory position = default_parameters.position;
    address player = default_parameters.for_player;
    string memory app = default_parameters.for_app;
    /////////////
    require(testParameters.test_uint == 1, "testParameters.test_uint not 1");
    string memory color = default_parameters.color;
    if(testEnum == TestEnum.Q){
      color = "#FFFFFF";
    }
    if(testEnumTwo == TestEnumTwo.S){
      app = "testapp";
    }
    /////////////

    // Load the Pixel
    PixelData memory pixel = Pixel.get(position.x, position.y);

    // TODO: Load MyApp App Settings like the fade steptime
    // For example for the Cooldown feature
    uint256 COOLDOWN_SECS = 5;

    // Check if 5 seconds have passed or if the sender is the owner
    require(pixel.owner == address(0) || pixel.owner == player || block.timestamp - pixel.timestamp < COOLDOWN_SECS, 'Cooldown not over');

    // We can now update color of the pixel
    ICoreSystem(_world()).update_pixel(
      PixelUpdateData({
        x: po.x,
        y: po.y,
        color: color,
        timestamp: 0,
        text: "",
        app: app,
        owner: player,
        action: "test_interact"
      }));

  }

  function test_interact(TestEnumTwo testEnumTwo, TestParameters memory testParameters) public {
    // Load important variables
    require(testParameters.test_uint == 1, "testParameters.test_uint not 1");
    string memory app = testParameters.app;
    if(testEnumTwo == TestEnumTwo.S){
      app = "testapp";
    }

    // require(app == "test", "app not testapp");

  }

}

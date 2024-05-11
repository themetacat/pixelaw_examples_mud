// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { ICoreSystem } from "../core_codegen/world/ICoreSystem.sol";
import { PermissionsData, DefaultParameters, Position, PixelUpdateData, Pixel, PixelData } from "../core_codegen/index.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { PopStar, PopStarData } from "../codegen/index.sol";


contract PopStarSystem is System {

  string constant APP_ICON = 'U+2B50';

  string constant NAMESPACE = 'popStar';
  string constant SYSTEM_NAME = 'PopStarSystem';

  string constant APP_NAME = 'PopStar';

  string constant APP_MANIFEST = 'BASE/PopStarSystem';

  bytes32 bytes_name = converToBytes32("PopStar");

  function init() public {
    ICoreSystem(_world()).update_app(APP_NAME, APP_ICON, APP_MANIFEST, NAMESPACE, SYSTEM_NAME);
  }

  function interact(DefaultParameters memory default_parameters) public {
    Position memory position = default_parameters.position;
    address player = default_parameters.for_player;
    require(ownerlessSpace(position), "Pixel not enough");

    uint256 timestamp = block.timestamp;

    uint256[] memory matrix = shuffle();
    bool game_finished = check_game_finished(matrix);

    string memory text;
    string memory color;
    uint256 arr_index;
    for(uint32 i; i < 10; ){
      for(uint32 j; j < 10; ){
        arr_index = 10*i+j;
        (text, color) = getColorText(matrix[arr_index]);
        ICoreSystem(_world()).update_pixel(
          PixelUpdateData({
            x: position.x + j,
            y: position.y + i,
            color: color,
            timestamp: timestamp,
            text: text,
            app: "PopStar",
            owner: player,
            action: "pop"
          })
        );
        unchecked{
          j++;
        }
      }
      unchecked{
        i++;
      }
    }
    PopStar.set(timestamp, player, bytes_name, position.x, position.y, game_finished, matrix);
    
  }

  function shuffle() private view returns(uint256[] memory) {
    uint256[] memory matrix = new uint256[](100);
    for (uint256 i = 0; i < 100; ) {
        uint256 random_num = uint256(keccak256(abi.encodePacked(block.prevrandao, block.number+i))) % 5 + 1;
        // (matrix, empty_index) = moveInternal(dir, matrix, empty_index);
        matrix[i] = random_num;
        unchecked{
          i++;
        }
    }
    return matrix;
  }

  function ownerlessSpace(Position memory position) private view returns (bool){
    PixelData memory pixel;
    for(uint8 i; i<10; i++){
      for(uint8 j; j<10; j++){
        pixel = Pixel.get(position.x+j, position.y+i);
        if(bytes(pixel.color).length != 0){
          return false;
        }else if(bytes(pixel.text).length != 0){
          return false;
        }else if(bytes(pixel.app).length != 0 || pixel.owner != address(0)){
          return false;
        }
      }
    }
    return true;
  }

  function pop(DefaultParameters memory default_parameters) public {
    Position memory position = default_parameters.position;
    PixelData memory pixel = Pixel.get(position.x, position.y);

    // require(pixel.owner == address(_msgSender()), "Not owner");
    // require(keccak256(abi.encodePacked(pixel.app)) == keccak256(abi.encodePacked("PopStar")), "Not PopStar app");
    
    PopStarData memory popStarData = PopStar.get(pixel.timestamp, pixel.owner, bytes_name);
    require(keccak256(abi.encodePacked(pixel.app)) == keccak256(abi.encodePacked("PopStar")) || popStarData.matrixArray.length == 100, "Not PopStar app");
    require(!popStarData.gameFinished, "Game is finished");
    uint32 x = popStarData.x;
    uint32 y = popStarData.y;

    uint256[] memory matrix_array = popStarData.matrixArray;
    // click num index in matrix
    uint256 matrix_index = (position.x - popStarData.x) + (position.y - popStarData.y)*10;
    // click num value
    uint256 click_value = matrix_array[matrix_index];
    require(click_value != 0, "Please click on the star");
    require(check_pop_access(matrix_index, click_value, matrix_array), "Need to connect two or more identical stars");
    matrix_array = dfs(matrix_index, click_value, matrix_array);
    matrix_array = move(matrix_array);
    bool game_finished = check_game_finished(matrix_array);

    uint256[] memory origin_matrix = PopStar.getMatrixArray(pixel.timestamp, pixel.owner, bytes_name);
    string memory text;
    string memory color;
    for(uint32 i; i < 100; ){
      if(origin_matrix[i] != matrix_array[i]){
        (text, color) = getColorText(matrix_array[i]);
        ICoreSystem(_world()).update_pixel(
          PixelUpdateData({
            x: x + i % 10,
            y: y + i / 10,
            color: color,
            timestamp: pixel.timestamp,
            text: text,
            app: "PopStar",
            owner: pixel.owner,
            action: "pop"
          })
        );
      }
      unchecked{
        i++;
      }
    }

    PopStar.set(pixel.timestamp, pixel.owner, bytes_name, popStarData.x, popStarData.y, game_finished, matrix_array);

  }
  
  function dfs(uint256 matrix_index, uint256 target_value, uint256[] memory matrix_array) private returns (uint256[] memory) {
    uint256 x = matrix_index % 10;
    uint256 y = matrix_index / 10;
    
    uint256 index;
    if(x > 0){
      index = matrix_index-1;
      if(matrix_array[index] == target_value){
        matrix_array[index] = 0;
        matrix_array = dfs(index, target_value, matrix_array);
      }
    } 

    if(x < 9){
      index = matrix_index+1;
      if(matrix_array[index] == target_value){
        matrix_array[index] = 0;
        matrix_array = dfs(index, target_value, matrix_array);
      }
    } 

    if(y > 0){
      index = matrix_index-10;
      if(matrix_array[index] == target_value){
        matrix_array[index] = 0;
        matrix_array = dfs(index, target_value, matrix_array);
      }
    } 

    if(y < 9){
      index = matrix_index+10;
      if(matrix_array[index] == target_value){
        matrix_array[index] = 0;
        matrix_array = dfs(index, target_value, matrix_array);
      }
    }

    return matrix_array;
  }

  function move(uint256[] memory matrix_array) private pure returns(uint256[] memory){
    uint256 index;
    uint256 zero_index_row;
    uint256 zero_index_col = 89;
    for(uint256 i; i < 10; ){
      zero_index_row = 90 + i;
      for(uint256 j=10; j > 0; ){
         unchecked{
          j--;
          index = i+j*10;
          if(matrix_array[index] != 0){
            if(index != zero_index_row){
              matrix_array[zero_index_row] = matrix_array[index];
              matrix_array[index] = 0;
            }
            zero_index_row -= 10;
          }
        }
      }

      if(i>0 && matrix_array[zero_index_col] == 0){
        if(matrix_array[90+i] != 0){
          for(uint256 x=0; x < 10; ){
            index = i+x*10;
            if(matrix_array[index] != 0){
              matrix_array[index-1] = matrix_array[index];
              matrix_array[index] = 0;
            }
            unchecked{
              x++;
            }
          }
          zero_index_col += 1;
        }
        
      }else{
        zero_index_col += 1;
      }
      unchecked{
        i++;
      }
    }
    // for(uint256 i; i < 10; ){
      

    // }
    return matrix_array;
  }

  function check_pop_access(uint256 matrix_index, uint256 target_value, uint256[] memory matrix_array) private pure returns (bool) {
    uint256 x = matrix_index % 10;
    uint256 y = matrix_index / 10;
    
    uint256 index;
    if(x > 0){
      index = matrix_index-1;
      if(matrix_array[index] == target_value){
        return true;
      }
    } 

    if(x < 9){
      index = matrix_index+1;
      if(matrix_array[index] == target_value){
        return true;
      }
    } 

    if(y > 0){
      index = matrix_index-10;
      if(matrix_array[index] == target_value){
        return true;
      }
    } 

    if(y < 9){
      index = matrix_index+10;
      if(matrix_array[index] == target_value){
        return true;
      }
    }

    return false;
  }

  function check_game_finished(uint256[] memory matrix_array) private pure returns(bool){
    for(uint256 i; i < 99; ){
      if(matrix_array[i] != 0){
        if(i>89){
          if(matrix_array[i] == matrix_array[i+1]){
            return false;
          }
        }else if(i%10 == 9){
          if(matrix_array[i] == matrix_array[i+10]){
            return false;
          }
        }else if(matrix_array[i] == matrix_array[i+1] || matrix_array[i] == matrix_array[i+10]){
          return false;
        }
      }
      unchecked{
        i++;
      }
    }
    return true;
  }

  function converToBytes32(string memory input) private pure returns (bytes32) {
    bytes memory stringBytes = bytes(input);
    if (stringBytes.length == 0) {
        return 0x0;
    }
    bytes32 result;
    assembly {
        result := mload(add(stringBytes, 32))
    }
    return result;
  }

  function getColorText(uint256 num) private pure returns (string memory text, string memory color){
    text = "U+2606";
    if(num == 1){
      // text = "U+2605";
      color = "#FFFF00"; //黄色
    }else if(num == 2){
      // text = "U+2606";
      color = "#0000FF"; //蓝色
    }else if(num == 3){
      // text = "U+2726";
      color = "#de88f6"; //紫色
    }else if(num == 4){
      // text = "U+272C";
      color = "#FF0000"; //红色
    }else if(num == 5){
      // text = "U+272A";
      color = "#f98690"; //粉色
    }else{
      text = "";
      color = "#000000"; //黑色
    }
    
  }

}

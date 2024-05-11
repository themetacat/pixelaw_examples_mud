// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { ICoreSystem } from "../core_codegen/world/ICoreSystem.sol";
import { PermissionsData, DefaultParameters, Position, PixelUpdateData, Pixel, PixelData } from "../core_codegen/index.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Puzzle, PuzzleData } from "../codegen/index.sol";


contract PuzzleSystem is System {

  string constant APP_ICON = 'U+1F9E9';

  string constant NAMESPACE = 'puzzle';
  string constant SYSTEM_NAME = 'PuzzleSystem';

  string constant APP_NAME = '15puzzle';

  string constant APP_MANIFEST = 'BASE/PuzzleSystem';

  uint256[] private new_matrix;
  bytes32 bytes_name = converToBytes32("15puzzle");

  constructor(){
    for(uint256 i=1; i<16; ){
      new_matrix.push(i);
      unchecked{
        i++;
      }
    }
    new_matrix.push(0);
  }

  function init() public {

    ICoreSystem(_world()).update_app(APP_NAME, APP_ICON, APP_MANIFEST, NAMESPACE, SYSTEM_NAME);
  
  }

  function interact(DefaultParameters memory default_parameters) public {
    Position memory position = default_parameters.position;
    address player = default_parameters.for_player;
    require(ownerlessSpace(position), "Pixel not enough");

    uint256 timestamp = block.timestamp;
    uint256[] memory matrix = new_matrix;
    uint256 empty_index = 15;

    matrix = shuffle(matrix, empty_index);
    require(!checkGameFinished(matrix), "Game is finished");

    string memory text;
    string memory color;
    for(uint32 i; i < 16; ){
      if(matrix[i] == 0){
        text = "";
        color = "#603d30";
      }else{
        text = Strings.toString(matrix[i]);
        color = "#b7a091";
      }
      ICoreSystem(_world()).update_pixel(
        PixelUpdateData({
          x: position.x + i % 4,
          y: position.y + i / 4,
          color: color,
          timestamp: timestamp,
          text: text,
          app: "15puzzle",
          owner: player,
          action: "move"
        })
      );
      unchecked{
        i++;
      }
    }
    Puzzle.set(timestamp, player, bytes_name, position.x, position.y, false, matrix);

  }

  function shuffle(uint256[] memory matrix, uint256 empty_index) private view returns(uint256[] memory) {
    for (uint256 i = 0; i < 100; ) {
        uint256 dir = uint256(keccak256(abi.encodePacked(block.prevrandao, block.number+i))) % 4;
        (matrix, empty_index) = moveInternal(dir, matrix, empty_index);
        unchecked{
          i++;
        }

    }
    return matrix;
  }

  function moveInternal(uint256 dir, uint256[] memory matrix, uint256 empty_index) private pure returns(uint256[] memory, uint256) {
    uint256 new_index = empty_index;
    // uint256[] memory random_matrix = matrix;
    if (dir == 1) { // up
      new_index = (new_index > 3) ? (new_index - 4) : (new_index + 4);
    } else if (dir == 2) { // down
        new_index = (new_index < 12) ? (new_index + 4) : (new_index - 4);
    } else if (dir == 3) { // left
        new_index = (new_index % 4 > 0) ? (new_index - 1) : (new_index + 1);
    } else{ // right
        new_index = (new_index % 4 < 3) ? (new_index + 1) : (new_index - 1);
    }
    matrix[empty_index] = matrix[new_index];
    matrix[new_index] = 0;
    empty_index = new_index;
    return (matrix, empty_index);
  }

  function checkGameFinished(uint256[] memory matrix) private pure returns(bool) {
    for (uint256 i = 0; i < 15; ) {
      if (matrix[i] != i+1) {
        return false;
      }
      unchecked{
        i++;
      }
    }
    return true;
  }

   function ownerlessSpace(Position memory position) private view returns (bool){
    PixelData memory pixel;
    for(uint8 i; i<4; i++){
      for(uint8 j; j<4; j++){
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

  function move(DefaultParameters memory default_parameters) public {
    Position memory position = default_parameters.position;
    PixelData memory pixel = Pixel.get(position.x, position.y);
    uint256 text_value = getNumValue(pixel.text);

    require(text_value != 0, "No movement allowed");
    // require(pixel.owner == address(_msgSender()), "Not owner");
    require(keccak256(abi.encodePacked(pixel.app)) == keccak256(abi.encodePacked("15puzzle")), "Not 15Puzzle app");
    
    PuzzleData memory puzzleData = Puzzle.get(pixel.timestamp, pixel.owner, bytes_name);
    require(!puzzleData.gameFinished, "Game is finished");

    uint256[] memory matrix = puzzleData.matrixArray;
    Position memory zero_po;
    (zero_po, matrix) = getZeroPixel(position, matrix, text_value);
    require(zero_po.x != position.x || zero_po.y != position.y, "No movement allowed");

    ICoreSystem(_world()).update_pixel(
      PixelUpdateData({
        x: zero_po.x,
        y: zero_po.y,
        color: "#b7a091",
        timestamp: pixel.timestamp,
        text: pixel.text,
        app: "15puzzle",
        owner: pixel.owner,
        action: "move"
      })
    );

    ICoreSystem(_world()).update_pixel(
      PixelUpdateData({
        x: position.x,
        y: position.y,
        color: "#603d30",
        timestamp: pixel.timestamp,
        text: "",
        app: "15puzzle",
        owner: pixel.owner,
        action: "move"
      })
    );
    bool game_state = checkGameFinished(matrix);
    Puzzle.set(pixel.timestamp, pixel.owner, bytes_name, puzzleData.x, puzzleData.y, game_state, matrix);

  }

  function getZeroPixel(Position memory position, uint256[] memory matrix, uint256 text_value) pure private returns(Position memory, uint256[] memory){
    
    uint256 index = getNumIndex(matrix, text_value);
    // up
    if(index > 3 && matrix[index-4] == 0){
      matrix[index-4] = text_value;
      matrix[index] = 0;
      return (Position({x: position.x, y: position.y-1}), matrix);
    }

    // down
    if(index < 12 && matrix[index+4] == 0){
      matrix[index+4] = text_value;
      matrix[index] = 0;
      return (Position({x: position.x, y: position.y+1}), matrix);
    }
    
    // left
    if(index > 0 && matrix[index-1] == 0){
      matrix[index-1] = text_value;
      matrix[index] = 0;
      return (Position({x: position.x-1, y: position.y}), matrix);
    }

    // right
    if(index < 15 && matrix[index+1] == 0){
      matrix[index+1] = text_value;
      matrix[index] = 0;
      return (Position({x: position.x+1, y: position.y}), matrix);
    }

    return (Position({x: position.x, y: position.y}), matrix);
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

  function getNumValue(string memory value) private pure returns(uint256 res){
    
    if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("1"))){
      res = 1;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("2"))){
      res = 2;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("3"))){
      res = 3;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("4"))){
      res = 4;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("5"))){
      res = 5;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("6"))){
      res = 6;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("7"))){
      res = 7;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("8"))){
      res = 8;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("9"))){
      res = 9;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("10"))){
      res = 10;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("11"))){
      res = 11;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("12"))){
      res = 12;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("13"))){
      res = 13;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("14"))){
      res = 14;
    }else if(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked("15"))){
      res = 15;
    }else{
      res = 0;
    }
  }

  function stringToUint(string memory value) private pure returns(uint256 res) {
    bytes memory bytesValue = bytes(value);
    uint256 i;
    res = 0;
    for (i = 0; i < bytesValue.length; i++) {
        uint256 c = uint256(uint8(bytesValue[i]));
        if (c >= 48 && c <= 57) {
            res = res * 10 + (c - 48);
        } else {
            revert("Invalid character found in the string.");
        }
    }
  }

  function getNumIndex(uint256[] memory matrix, uint256 num) private pure returns(uint256){
    for(uint256 i; i < 16; ){
      if(matrix[i] == num){
        return i;
      }
      unchecked{
        i++;
      }
    }
    return 16;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { System } from "@latticexyz/world/src/System.sol";
import { ICoreSystem } from "../core_codegen/world/ICoreSystem.sol";
import { IWorld } from "../core_codegen/world/IWorld.sol";
import { PermissionsData, DefaultParameters, Position, PixelUpdateData, Pixel, PixelData, ERC20TokenBalance, UniversalRouterParams, TokenInfo } from "../core_codegen/index.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { TCMPopStar, TCMPopStarData, TokenBalance, TokenSold, TokenSoldData, GameRecord, GameRecordData } from "../codegen/index.sol";
import { IERC20 } from "@latticexyz/world-modules/src/modules/erc20-puppet/IERC20.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { Puppet } from "@latticexyz/world-modules/src/modules/puppet/Puppet.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
// import { IERC20 } from "../interfaces/IERC20.sol";
import { IQuote, SwapParams, Quote } from "../interfaces/IQuote.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

contract PopCraftSystem is System {

  string constant APP_ICON = 'U+1F48E';
  string constant NAMESPACE = 'popCraft';
  string constant SYSTEM_NAME = 'PopCraftSystem';
  string constant APP_NAME = 'PopCraft';
  string constant APP_MANIFEST = 'BASE/PopCraftSystem';
  bytes14 constant BYTESNAMESPACE = bytes14(bytes(NAMESPACE));

  bytes32 bytes_name = converToBytes32("PopCraft");
  uint256 overtime = 4 minutes + 3 seconds;
  uint256 constant bonus = 150 * 10 ** 18;
  address constant BUGS = 0x9c0153C56b460656DF4533246302d42Bd2b49947;
  address constant quoterAddr = 0xA15BB66138824a1c7167f5E85b957d04Dd34E468;
  uint256 constant limit_amount = 20 * 10 ** 18;

  address[] private TCMTokens;
  ICoreSystem internal coreSystem;

  error InsufficientBalance(address);

  constructor() {
    TCMTokens = [
      0xC750a84ECE60aFE3CBf4154958d18036D3f15786,
      0x65638Aa354d2dEC431aa851F52eC0528cc6D84f3,
      0xD64f7863d030Ae7090Fe0D8109E48B6f17f53145,
      0x160F5016Bb027695968df938aa04A95B575939f7,
      0x1ca53886132119F99eE4994cA9D0a9BcCD2bB96f,
      0x7Ea470137215BDD77370fC3b049bd1d009e409f9,
      0xca7f09561D1d80C5b31b390c8182A0554CF09F21,
      0xdCc7Bd0964B467554C9b64d3eD610Dff12AF794e,
      0x54b31D72a658A5145704E8fC2cAf5f87855cc1Cd,
      0xF66D7aB71764feae0e15E75BAB89Bd0081a7180d
    ];
    coreSystem = ICoreSystem(0x784844480280Ca865Ac8eF89bB554283DDDFF737);
  }
  receive() external payable {}

  function init() public {
    ICoreSystem(_world()).update_app(APP_NAME, APP_ICON, APP_MANIFEST, NAMESPACE, SYSTEM_NAME);
  }

  function interact(DefaultParameters memory default_parameters) public {
    Position memory position = default_parameters.position;

    TCMPopStarData memory tcmPopStarData = TCMPopStar.get(_msgSender());

    if(tcmPopStarData.startTime > 0){
      position = Position({x: tcmPopStarData.x, y: tcmPopStarData.y});
    }else{
      require(ownerlessSpace(position), "Pixel not enough");
    }

    {
      uint256 timestamp = block.timestamp;
      PixelUpdateData[] memory pixelUpdateData = new PixelUpdateData[](100);
      uint256[] memory matrix = shuffle();
      address[] memory tokenAddressArr = randomTCMToken();
      string memory text;
      string memory color;
      uint256 arr_index;
      unchecked {
        for(uint32 i; i < 10; i++){
          for(uint32 j; j < 10; j++){
            arr_index = 10*i+j;

            (text, color) = getColorText(matrix[arr_index]);
            pixelUpdateData[arr_index] = PixelUpdateData({
                x: position.x + j,
                y: position.y + i,
                color: color,
                timestamp: timestamp,
                text: text,
                app: "PopCraft",
                owner: _msgSender(),
                action: "pop"
              });
          }
        }
      }
      IWorld(_world()).update_pixel_batch(pixelUpdateData);
      
      TCMPopStar.set(_msgSender(), position.x, position.y, timestamp, false, matrix, tokenAddressArr);
      uint256 gameTimes = GameRecord.getTimes(_msgSender());
      GameRecord.setTimes(_msgSender(), gameTimes+=1);
    }
  }

  function shuffle() private view returns(uint256[] memory) {
    uint256[] memory matrix = new uint256[](100);
    address sender = _msgSender();
    for (uint256 i = 0; i < 100; ) {
        uint256 random_num = uint256(keccak256(abi.encodePacked(sender, block.timestamp, block.number, i))) % 5 + 1;
        matrix[i] = random_num;
        unchecked{
          i++;
        }
    }
    return matrix;
  }

  function randomTCMToken() private view returns(address[] memory) {

    address[] memory address_arr = new address[](5);
  
    address[] memory tempValues = TCMTokens;
    uint256 n = tempValues.length;

    // Fisher-Yates shuffle 算法
    for (uint256 i = 0; i < 5; i++) {
        uint256 randIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, i))) % n;
        address_arr[i] = tempValues[randIndex];
        // address_arr[i] = tempValues[i];
        tempValues[randIndex] = tempValues[n - 1];
        n--;
    }
    return address_arr;
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
    require(pixel.owner == address(_msgSender()), "Not owner");

    TCMPopStarData memory tcmPopStarData = TCMPopStar.get(_msgSender());
    require(keccak256(abi.encodePacked(pixel.app)) == keccak256(abi.encodePacked("PopCraft")) && tcmPopStarData.matrixArray.length == 100, "Not PopCraft app");

    require(!tcmPopStarData.gameFinished, "Game Over");
    if(block.timestamp > (tcmPopStarData.startTime + overtime)){
      TCMPopStar.set(_msgSender(), tcmPopStarData.x, tcmPopStarData.y, tcmPopStarData.startTime, true, tcmPopStarData.matrixArray, tcmPopStarData.tokenAddressArr);
      return;
    }
    
    // require(!tcmPopStarData.gameFinished || block.timestamp > (tcmPopStarData.startTime + overtime), "Game Over");

    uint256[] memory matrix_array = tcmPopStarData.matrixArray;
    // click num index in matrix
    uint256 matrix_index = (position.x - tcmPopStarData.x) + (position.y - tcmPopStarData.y)*10;
    // click num value
    uint256 click_value = matrix_array[matrix_index];
    // require(click_value != 0, "Please click on the star");
    if(click_value == 0) revert('Please click on the star');
    
    bool pop_access = check_pop_access(matrix_index, click_value, matrix_array);
    if(!pop_access){
      {
        address token_addr = tcmPopStarData.tokenAddressArr[click_value-1];
        uint256 token_balance = TokenBalance.get(_msgSender() ,token_addr);
        uint8 token_decimals = IERC20(token_addr).decimals();
        uint256 deduct_token_num = 10 ** uint256(token_decimals);
        
        if(token_balance < deduct_token_num) revert InsufficientBalance(token_addr);

        uint256 token_sold_now = TokenSold.getSoldNow(token_addr);
        TokenSold.setSoldNow(token_addr, token_sold_now - deduct_token_num);
        
        TokenBalance.set(_msgSender() ,token_addr, token_balance - deduct_token_num);
        
        matrix_array[matrix_index] = 0;
      }
    }else{
      matrix_array = dfs(matrix_index, click_value, matrix_array);
    }

    matrix_array = move(matrix_array);

    // uint256[] memory matrix_array = new uint256[](100);
    
    {
      bool game_finished = check_game_finished(matrix_array);
      // if(game_finished){
      //   delete_board(tcmPopStarData.x, tcmPopStarData.y);
      //   uint256[] memory init_arr;
      //   TCMPopStar.set(pixel.owner, tcmPopStarData.x, tcmPopStarData.y, tcmPopStarData.startTime, game_finished, init_arr, tcmPopStarData.tokenAddressArr);

      // }else{
      uint256[] memory origin_matrix = TCMPopStar.getMatrixArray(_msgSender());
      string memory text;
      string memory color;
      for(uint32 i; i < 100; ){
        if(origin_matrix[i] != matrix_array[i]){
          (text, color) = getColorText(matrix_array[i]);
          coreSystem.update_pixel(
            PixelUpdateData({
              x: tcmPopStarData.x + i % 10,
              y: tcmPopStarData.y + i / 10,
              color: color,
              timestamp: pixel.timestamp,
              text: text,
              app: "PopCraft",
              owner: _msgSender(),
              action: "pop"
            })
          );
        }
        unchecked{
          i++;
        }
      }
      TCMPopStar.set(_msgSender(), tcmPopStarData.x, tcmPopStarData.y, tcmPopStarData.startTime, game_finished, matrix_array, tcmPopStarData.tokenAddressArr);
      if(game_finished){
        GameRecordData memory gameRecordData = GameRecord.get(_msgSender());
        uint256 total_supply = ERC20TokenBalance.get(BUGS, WorldResourceIdLib.encodeNamespace(BYTESNAMESPACE));
         if(total_supply >= bonus){
            IWorld(_world()).transferERC20TokenToAddress(WorldResourceIdLib.encodeNamespace(BYTESNAMESPACE), BUGS, _msgSender(), bonus);
         }else{
            gameRecordData.unissuedRewards += 1;
         }
         GameRecord.set(_msgSender(), gameRecordData.times, gameRecordData.successTimes += 1 ,gameRecordData.unissuedRewards);
      }
    }
  }

  function delete_board(uint32 x, uint32 y) private{
    for(uint32 i; i < 100; i++){
      ICoreSystem(_world()).update_pixel(
        PixelUpdateData({
          x: x + i % 10,
          y: y + i / 10,
          color: "",
          timestamp: 0,
          text: "",
          app: "",
          owner: address(0),
          action: ""
        })
      );
    }
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
    uint256 zero_index_col_bot = 89;
    uint256 zero_index_col;

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

      if(i>0 && matrix_array[zero_index_col_bot] == 0){
        if(matrix_array[90+i] != 0){
          zero_index_col = zero_index_col_bot - 90;
          for(uint256 x=0; x < 10; ){
            index = i+x*10;
            if(matrix_array[index] != 0){
              matrix_array[x*10+zero_index_col] = matrix_array[index];
              matrix_array[index] = 0;
            }
            unchecked{
              x++;
            }
          }
          zero_index_col_bot += 1;
        }
        
      }else{
        zero_index_col_bot += 1;
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
    unchecked{
      for(uint256 i; i < 99; ){
        if(matrix_array[i] != 0){
          return false;
        }
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
    text = "";
    if(num == 1){
      text = "1";
      color = "#FFFF00"; //黄色
    }else if(num == 2){
      text = "2";
      color = "#0000FF"; //蓝色
    }else if(num == 3){
      text = "3";
      color = "#de88f6"; //紫色
    }else if(num == 4){
      text = "4";
      color = "#FF0000"; //红色
    }else if(num == 5){
      text = "5";
      color = "#f98690"; //粉色
    }else{
      text = "";
      color = "#000000"; //黑色
    }
    
  }

  function getTCMToken(uint256 num) private pure returns (address tokenAddress){
    if(num == 0){
      // UREA
      tokenAddress = address(0xC750a84ECE60aFE3CBf4154958d18036D3f15786); 
    }else if(num == 1){
      // FERTILIZER
      tokenAddress = address(0x65638Aa354d2dEC431aa851F52eC0528cc6D84f3);
    }else if(num == 2){
      // ANTIFREEZE
      tokenAddress = address(0xD64f7863d030Ae7090Fe0D8109E48B6f17f53145);
    }else if(num == 3){
      // LUBRICANT
      tokenAddress = address(0x160F5016Bb027695968df938aa04A95B575939f7);
    }else if(num == 4){
      // CORN
      tokenAddress = address(0x1ca53886132119F99eE4994cA9D0a9BcCD2bB96f);
    }else if(num == 5){
      // TOBACCO
      tokenAddress = address(0x7Ea470137215BDD77370fC3b049bd1d009e409f9);
    }else if(num == 6){
      // PETROLEUM
      tokenAddress = address(0xca7f09561D1d80C5b31b390c8182A0554CF09F21);
    }else if(num == 7){
      // SAND
      tokenAddress = address(0xdCc7Bd0964B467554C9b64d3eD610Dff12AF794e);
    }else if(num == 8){
      // YEAST
      tokenAddress = address(0x54b31D72a658A5145704E8fC2cAf5f87855cc1Cd);
    }else{
      // RATS
      tokenAddress = address(0xF66D7aB71764feae0e15E75BAB89Bd0081a7180d);
    }
    
  }

  function buyToken(UniversalRouterParams[] calldata universalRouterParams) public payable {
    uint256 router_params_length = universalRouterParams.length;

    require(_msgValue() > 0, "msgValue < 0");

    uint256 balance_last = address(this).balance;
    IWorld(_world()).transferBalanceToAddress(WorldResourceIdLib.encodeNamespace(BYTESNAMESPACE), address(this), _msgValue());
    uint256 balance_after = address(this).balance;
    require(balance_after-balance_last == _msgValue(), "Incorrect balance");

    IWorld(_world()).universalRouterExecuteBatch{value:_msgValue()}(universalRouterParams, WorldResourceIdLib.encodeNamespace(BYTESNAMESPACE));

    for(uint256 i; i < router_params_length; i++){
      address token_addr = universalRouterParams[i].token_info.token_addr;
      uint256 amount = universalRouterParams[i].token_info.amount;
   
        TokenSoldData memory tokenSoldData = TokenSold.get(token_addr);
        TokenSold.set(token_addr, tokenSoldData.soldNow + amount, tokenSoldData.soldAll + amount);

        uint256 balance = TokenBalance.get(_msgSender() ,token_addr);
        TokenBalance.set(_msgSender() ,token_addr, balance + amount);
    }
  }

  // function withDrawToken(address[] memory token_addr, uint256[] memory amount) public pure {
    // uint256 token_addr_length = token_addr.length;
    // require(token_addr_length == amount.length, 'Length mismatch');
    // for(uint256 i; i < token_addr_length; i++){
    //   uint256 token_balance = TokenBalance.get(_msgSender(), token_addr[i]);
    //   if(token_balance < amount[i]) revert InsufficientBalance(token_addr[i]);

    //   uint256 token_sold_now = TokenSold.getSoldNow(token_addr[i]);
    //   TokenSold.setSoldNow(token_addr[i], token_sold_now - amount[i]);
    //   TokenBalance.set(_msgSender(), token_addr[i], token_balance - amount[i]);

    //   IWorld(_world()).transferERC20TokenToAddress(WorldResourceIdLib.encodeNamespace(BYTESNAMESPACE), token_addr[i], _msgSender(), amount[i]);
    // }
  // }
  

  function reIssuanceRewards(address[] memory owner) external {
    AccessControl.requireOwner(WorldResourceIdLib.encodeNamespace(BYTESNAMESPACE), _msgSender());
    uint256 owner_length = owner.length;
    for(uint256 i; i < owner_length; ){
      GameRecordData memory gameRecordData = GameRecord.get(owner[i]);
      uint256 total_supply = ERC20TokenBalance.get(BUGS, WorldResourceIdLib.encodeNamespace(BYTESNAMESPACE));
      if(total_supply < bonus){
        i = owner_length;
      }else{
        uint256 totalBonus = bonus * gameRecordData.unissuedRewards;
        if(total_supply >= totalBonus){
          IWorld(_world()).transferERC20TokenToAddress(WorldResourceIdLib.encodeNamespace(BYTESNAMESPACE), BUGS, owner[i], totalBonus);
          GameRecord.setUnissuedRewards(owner[i], 0);
        }
        i++;
      }
    }
  }

}

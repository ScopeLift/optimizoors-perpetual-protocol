// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {Create2} from "src/lib/Create2.sol";
import {IOpenPosition} from "src/interface/IOpenPosition.sol";

abstract contract PerpetualBaseRouter {
  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;
  bool public immutable IS_BASE_TO_QUOTE;
  bool public immutable IS_EXACT_INPUT;
  address public immutable TOKEN;

  bytes32 internal constant REFERRAL_CODE =
    0x0000000000000000000000000000000000000000000000000000000000000000;

  constructor(IClearingHouse clearingHouse, address asset, bool isBaseToQuote, bool isExactInput) {
    PERPETUAL_CLEARING_HOUSE = clearingHouse;
    IS_BASE_TO_QUOTE = isBaseToQuote;
    IS_EXACT_INPUT = isExactInput;
    TOKEN = asset;
  }
}

// TODO: Add a router for each combindation of long/short and exact input/output.
contract PerpetualLongInput is PerpetualBaseRouter, IOpenPosition {
  constructor(IClearingHouse perpetual, address asset)
    PerpetualBaseRouter(perpetual, asset, false, true)
  {}

  // TODO: Greater optimization is possible but it will
  //   add more complexity. In order to avoid going
  //   down the wrong path we will wait until we can
  //   talk to the projects.
  //
  //
  // We may be able to leverage a fallback function here.
  //
  // Going to push on the integer optimization as we figure out the pros and cons
  //
  // 1. What us a reasonable amount of precision to reducethe function?
  // 2. What are reasonable time periods for deadlines
  function openPosition(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    external
    payable
    returns (uint256 base, uint256 quote, uint256 fee)
  {
    return PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: IS_BASE_TO_QUOTE,
        isExactInput: IS_EXACT_INPUT,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: block.timestamp,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }
}

contract PerpetualRouterFactory {
  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;

  event RouterDeployed(string indexed routerType, address indexed asset);

  constructor(IClearingHouse clearingHouse) {
    PERPETUAL_CLEARING_HOUSE = clearingHouse;
  }

  // TODO: Modify to support multiple router types
  //     or rename and have a deploy function per
  //     router.
  function deploy(address asset) external returns (address) {
    bytes32 salt = _salt(asset);
    address openPositionLongInput =
      address(new PerpetualLongInput{salt: salt}(PERPETUAL_CLEARING_HOUSE, asset));
    emit RouterDeployed("longInput", asset);
    return openPositionLongInput;
  }

  function computeAddress(address asset) external view returns (address) {
    return Create2.computeCreate2Address(
      _salt(asset),
      address(this),
      type(PerpetualLongInput).creationCode,
      abi.encode(PERPETUAL_CLEARING_HOUSE, asset)
    );
  }

  function _salt(address asset) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(asset)));
  }
}

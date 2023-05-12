// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SignedMath} from "openzeppelin-contracts/contracts/utils/math/SignedMath.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";

/// @notice A router to manage a perpetual position by opening and closing it.
contract PerpetualPositionRouter {
  using SignedMath for int256;

  error FunctionDoesNotExist();
  error NoExistingPosition();

  /// @notice The contract used to manage positions in perpetual
  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;

  /// @notice The token used for the router's positions
  address public immutable TOKEN;

  /// @notice The perpetual contract that manages a users account balance
  IAccountBalance public immutable ACCOUNT_BALANCE;

  /// @dev A null value for a referral code
  bytes32 internal constant REFERRAL_CODE =
    0x0000000000000000000000000000000000000000000000000000000000000000;

  constructor(IClearingHouse clearingHouse, IAccountBalance accountBalance, address asset) {
    PERPETUAL_CLEARING_HOUSE = clearingHouse;
    ACCOUNT_BALANCE = accountBalance;
    TOKEN = asset;
  }

  // TODO: Should we deposit eth into the perpetual vault?
  receive() external payable {}

  function combineArgs(uint8 funcName, uint160 sqrtPriceLimitX96) external pure returns (uint168) {
    return (uint168(funcName) << 160) | uint168(sqrtPriceLimitX96);
  }

  function _extractSqrtPriceLimitX96(uint168 args) internal pure returns (uint160) {
    uint168 mask = (1 << 160) - 1;

    return uint160(args & mask);
  }

  function _openLongInput(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    internal
  {
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: false,
        isExactInput: true,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: type(uint256).max,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  function _openLongOutput(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    internal
  {
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: false,
        isExactInput: false,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: type(uint256).max,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  function _openShortInput(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    internal
  {
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: true,
        isExactInput: true,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: type(uint256).max,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  function _openShortOutput(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    internal
  {
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: true,
        isExactInput: false,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: type(uint256).max, // TODO: verify this is market order behavior, and do we need a
        // separate limit router
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  function _closePosition(uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96) internal {
    int256 takerPositionSize = ACCOUNT_BALANCE.getTakerPositionSize(msg.sender, TOKEN);
    if (takerPositionSize == 0) revert NoExistingPosition();
    bool shortPosition = takerPositionSize > 0 ? true : false;
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: shortPosition,
        isExactInput: shortPosition,
        amount: takerPositionSize.abs(),
        oppositeAmountBound: oppositeAmountBound,
        deadline: type(uint256).max,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  // TODO: Greater optimization is possible but it will
  //   add more complexity. In order to avoid going
  //   down the wrong path we will wait until we can
  //   talk to the projects.
  //
  //
  //
  // Going to push on the integer optimization as we figure out the pros and cons
  //
  // 1. What us a reasonable amount of precision to reduce the function?
  // 2. What are reasonable time periods for deadlines
  fallback() external payable {
    // The first 11 bytes are padding.
    // The 12th byte will contain the function name
    // which we will use to pick the correct decoding
    // strategy
    uint8 funcName = uint8(bytes1(msg.data[11:12]));
    uint168 combinedArgs;
    uint256 amount;
    uint256 oppositeAmountBound;
    if (funcName != 5) {
      (combinedArgs, amount, oppositeAmountBound) =
        abi.decode(msg.data, (uint168, uint256, uint256));
    } else {
      (combinedArgs, oppositeAmountBound) = abi.decode(msg.data, (uint168, uint256));
    }
    uint160 sqrtPriceLimitX96 = _extractSqrtPriceLimitX96(combinedArgs);

    if (funcName == 1) _openShortOutput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcName == 2) _openShortInput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcName == 3) _openLongOutput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcName == 4) _openLongInput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcName == 5) _closePosition(oppositeAmountBound, sqrtPriceLimitX96);
    else revert FunctionDoesNotExist();
  }
}

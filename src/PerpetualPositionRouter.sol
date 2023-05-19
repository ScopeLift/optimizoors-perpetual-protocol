// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SignedMath} from "openzeppelin-contracts/contracts/utils/math/SignedMath.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";

/// @notice A router to manage a Perpetual position by opening and closing it.
contract PerpetualPositionRouter {
  using SignedMath for int256;

  /// @dev Thrown when calldata provides a function ID that does not exist.
  error FunctionDoesNotExist();

  /// @dev Thrown when a user tries to take an action on a position that does not exist.
  error NoExistingPosition();

  /// @notice The contract used to manage positions in Perpetual.
  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;

  /// @notice The token used for the router's positions.
  address public immutable TOKEN;

  /// @notice The Perpetual contract that manages a users account balance.
  IAccountBalance public immutable ACCOUNT_BALANCE;

  /// @dev The default value for a referral code used when opening a position.
  bytes32 internal constant REFERRAL_CODE =
    0x0000000000000000000000000000000000000000000000000000000000000000;

  /// @param clearingHouse Address of the Perpetual clearing house contract.
  /// @param accountBalance Address of the Perpetual account balance contract.
  /// @param asset Address of the token used for the Perpetual position.
  constructor(IClearingHouse clearingHouse, IAccountBalance accountBalance, address asset) {
    PERPETUAL_CLEARING_HOUSE = clearingHouse;
    ACCOUNT_BALANCE = accountBalance;
    TOKEN = asset;
  }

  // TODO: Should we deposit eth into the Perpetual vault?
  receive() external payable {}

  /// @dev Returns the `sqrtPriceLimitX96` from a `uint168`.
  /// @param args A `uint168` that contains both the `funcId` and the `sqrtPriceLimitX96` needed to
  /// open or close a position.
  function _extractSqrtPriceLimitX96(uint168 args) internal pure returns (uint160) {
    uint168 mask = (1 << 160) - 1;
    return uint160(args & mask);
  }

  /// @dev Used to open a long position that takes in the exact amount of input tokens.
  /// @param amount The input amount of the position.
  /// @param oppositeAmountBound The lower bound of the router token.
  /// @param sqrtPriceLimitX96 The restriction on the ending price after the swap.
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

  /// @dev Used to open a long position specifying the output amount of the position.
  /// @param amount The output amount of the position.
  /// @param oppositeAmountBound The upper bound on the input quote token (vUSDC).
  /// @param sqrtPriceLimitX96 The restriction on the ending price after the swap.
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

  /// @dev Used to open a short position specifying the input amount of the position.
  /// @param amount The input amount of the position.
  /// @param oppositeAmountBound The lower bound on the output quote token (vUSDC).
  /// @param sqrtPriceLimitX96 The restriction on the ending price after the swap.
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

  /// @dev Used to open a short position specifying the output amount of the position.
  /// @param amount The output amount of the position.
  /// @param oppositeAmountBound The upper bound of the router token.
  /// @param sqrtPriceLimitX96 The restriction on the ending price after the swap.
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
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  /// @dev Closes an open position for the router's token.
  /// @param oppositeAmountBound If the position being closed in a long position then this will be
  /// the upper bound on the input quote token (vUSDC). If the position is a short position then
  /// this will be the lower bound on the output quote token (vUSDC).
  /// @param sqrtPriceLimitX96 The restriction on the ending price after the swap.
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

  /// @notice Creates or closes a position depending on the provided `funcId`. Calldata is
  /// conditionally decoded based on the `funcId`.
  fallback() external payable {
    // The first 11 bytes are padding. The 12th byte will contain the function name which we will
    // use to pick the correct decoding strategy
    uint8 funcId = uint8(bytes1(msg.data[11:12]));
    uint168 combinedArgs;
    uint256 amount;
    uint256 oppositeAmountBound;
    if (funcId != 5) {
      (combinedArgs, amount, oppositeAmountBound) =
        abi.decode(msg.data, (uint168, uint256, uint256));
    } else {
      (combinedArgs, oppositeAmountBound) = abi.decode(msg.data, (uint168, uint256));
    }
    uint160 sqrtPriceLimitX96 = _extractSqrtPriceLimitX96(combinedArgs);

    if (funcId == 1) _openShortOutput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcId == 2) _openShortInput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcId == 3) _openLongOutput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcId == 4) _openLongInput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcId == 5) _closePosition(oppositeAmountBound, sqrtPriceLimitX96);
    else revert FunctionDoesNotExist();
  }
}

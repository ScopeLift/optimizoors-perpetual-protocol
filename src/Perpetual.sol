// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {Create2} from "src/lib/Create2.sol";

import {SignedMath} from "openzeppelin-contracts/contracts/utils/math/SignedMath.sol";
import "forge-std/console.sol";

abstract contract PerpetualBaseRouter {
  // @notice The contract used to manage positions in perpetual
  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;
  // @notice If true the position being created is a long position
  // @notice If false the created position is a short position
  bool public immutable IS_BASE_TO_QUOTE;
  // @notice If true the position is a an exact input. Similar to how it is done in uniswap
  // @notice If false the created position is an exact output.
  bool public immutable IS_EXACT_INPUT;
  // @notice The token used for the router's positions
  address public immutable TOKEN;
  IAccountBalance public immutable ACCOUNT_BALANCE;

  // @notice A null value for a referral code
  bytes32 internal constant REFERRAL_CODE =
    0x0000000000000000000000000000000000000000000000000000000000000000;

  constructor(
    IClearingHouse clearingHouse,
    address asset,
    bool isBaseToQuote,
    bool isExactInput,
    IAccountBalance accountBalance
  ) {
    PERPETUAL_CLEARING_HOUSE = clearingHouse;
    IS_BASE_TO_QUOTE = isBaseToQuote;
    IS_EXACT_INPUT = isExactInput;
    TOKEN = asset;
    ACCOUNT_BALANCE = accountBalance;
  }
}

// TODO: Add a router for each combination of long/short and exact input/output.
contract PerpetualLongInput is PerpetualBaseRouter {
  using SignedMath for int256;

  error FunctionDoesNotExist();
  error NoExistingPosition();

  constructor(IClearingHouse perpetual, IAccountBalance accountBalance, address asset)
    PerpetualBaseRouter(perpetual, asset, false, true, accountBalance)
  {}

  function _openLongInput(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    private
  {
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: false,
        isExactInput: true,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: block.timestamp,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  function _openLongOutput(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    private
  {
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: false,
        isExactInput: false,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: block.timestamp,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  function _openShortInput(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    private
  {
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: true,
        isExactInput: true,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: block.timestamp,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  function _openShortOutput(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    private
  {
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: true,
        isExactInput: false,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: block.timestamp,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  // return IAccountBalance(_accountBalance).getTakerPositionSize(trader, baseToken);
  // check position size is not equal 0
  function _closePosition(uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96) private {
    console.logString("Here");
    console.logAddress(msg.sender);
    console.logAddress(TOKEN);
    int256 takerPositionSize = ACCOUNT_BALANCE.getTakerPositionSize(msg.sender, TOKEN);
    console.logInt(takerPositionSize);
    if (takerPositionSize == 0) {
      console.logString("Reverting");
      revert NoExistingPosition();
    }
    console.logString("X");
    bool shortPosition = takerPositionSize > 0 ? true : false;
    console.logString("X2");
    console.logBool(shortPosition);
    console.logInt(takerPositionSize);
    PERPETUAL_CLEARING_HOUSE.openPositionFor(
      msg.sender,
      IClearingHouse.OpenPositionParams({
        baseToken: TOKEN,
        isBaseToQuote: shortPosition,
        isExactInput: shortPosition,
        amount: takerPositionSize.abs(),
        oppositeAmountBound: oppositeAmountBound,
        deadline: block.timestamp,
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
  //
  // closePosition is not using the amount value and maybe we could optimize by splitting it out
  // into a separate contract
  fallback() external payable {
    (uint8 funcName, uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96) =
      abi.decode(msg.data, (uint8, uint256, uint256, uint160));
    if (funcName == 1) _openShortOutput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcName == 2) _openShortInput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcName == 3) _openLongOutput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcName == 4) _openLongInput(amount, oppositeAmountBound, sqrtPriceLimitX96);
    else if (funcName == 5) _closePosition(oppositeAmountBound, sqrtPriceLimitX96);
    else revert FunctionDoesNotExist();
  }
}

contract PerpetualRouterFactory {
  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;
  IAccountBalance public immutable PERPETUAL_ACCOUNT_BALANCE;

  event RouterDeployed(string indexed routerType, address indexed asset);

  constructor(IClearingHouse clearingHouse, IAccountBalance accountBalance) {
    PERPETUAL_CLEARING_HOUSE = clearingHouse;
    PERPETUAL_ACCOUNT_BALANCE = accountBalance;
  }

  // TODO: Modify to support multiple router types
  //     or rename and have a deploy function per
  //     router.
  function deploy(address asset) external returns (address) {
    bytes32 salt = _salt(asset);
    address openPositionLongInput = address(
      new PerpetualLongInput{salt: salt}(
                PERPETUAL_CLEARING_HOUSE,
                PERPETUAL_ACCOUNT_BALANCE,
                asset
            )
    );
    emit RouterDeployed("longInput", asset);
    return openPositionLongInput;
  }

  function computeAddress(address asset) external view returns (address) {
    return Create2.computeCreate2Address(
      _salt(asset),
      address(this),
      type(PerpetualLongInput).creationCode,
      abi.encode(PERPETUAL_CLEARING_HOUSE, PERPETUAL_ACCOUNT_BALANCE, asset)
    );
  }

  function _salt(address asset) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(asset)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SignedMath} from "openzeppelin-contracts/contracts/utils/math/SignedMath.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {IVault} from "src/interface/IVault.sol";
import {DepositRouter} from "src/DepositRouter.sol";
import {Create2} from "src/lib/Create2.sol";

/// @notice A router to manage a perpetual position by opening and closing it.
contract PerpetualPositionRouter {
  using SignedMath for int256;

  error FunctionDoesNotExist();
  error NoExistingPosition();

  /// @notice The contract used to manage positions in perpetual
  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;
  /// @notice The token used for the router's positions
  address public immutable TOKEN;

  /// @notice
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
        deadline: type(uint256).max,
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
        deadline: type(uint256).max,
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
        deadline: type(uint256).max,
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
        deadline: type(uint256).max, // TODO: verify this is market order behavior, and do we need a
        // separate limit router
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: REFERRAL_CODE
      })
    );
  }

  function _closePosition(uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96) private {
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
  //
  // closePosition is not using the amount value and maybe we could optimize by splitting it into a
  // separate contract
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
  error RouterTypeDoesNotExist();

  enum RouterTypes {
    PositionRouterType,
    DepositRouterType
  }

  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;
  IAccountBalance public immutable PERPETUAL_ACCOUNT_BALANCE;
  IVault public immutable PERPETUAL_VAULT;

  event RouterDeployed(RouterTypes indexed routerType, address indexed asset);

  constructor(IClearingHouse clearingHouse, IAccountBalance accountBalance, IVault vault) {
    PERPETUAL_CLEARING_HOUSE = clearingHouse;
    PERPETUAL_ACCOUNT_BALANCE = accountBalance;
    PERPETUAL_VAULT = vault;
  }

  // TODO: Modify to support multiple router types
  //     or rename and have a deploy function per
  //     router.
  function deploy(RouterTypes type_, address asset) external returns (address) {
    bytes32 salt = _salt(asset);
    address router;
    if (type_ == RouterTypes.PositionRouterType) {
      router = address(
        new PerpetualPositionRouter{salt: salt}(
                    PERPETUAL_CLEARING_HOUSE,
                    PERPETUAL_ACCOUNT_BALANCE,
                    asset
                )
      );
    } else if (type_ == RouterTypes.DepositRouterType) {
      router = address(new DepositRouter{salt: salt}(asset, PERPETUAL_VAULT));
    } else {
      revert RouterTypeDoesNotExist();
    }
    emit RouterDeployed(RouterTypes.PositionRouterType, asset);
    return router;
  }

  function computeAddress(RouterTypes type_, address asset) external view returns (address) {
    if (type_ == RouterTypes.PositionRouterType) return _computePositionAddress(asset);
    else if (type_ == RouterTypes.DepositRouterType) return _computeDepositAddress(asset);
    else revert RouterTypeDoesNotExist();
  }

  function _computePositionAddress(address asset) internal view returns (address) {
    return Create2.computeCreate2Address(
      _salt(asset),
      address(this),
      type(PerpetualPositionRouter).creationCode,
      abi.encode(PERPETUAL_CLEARING_HOUSE, PERPETUAL_ACCOUNT_BALANCE, asset)
    );
  }

  function _computeDepositAddress(address asset) internal view returns (address) {
    return Create2.computeCreate2Address(
      _salt(asset),
      address(this),
      type(DepositRouter).creationCode,
      abi.encode(asset, PERPETUAL_VAULT)
    );
  }

  function _salt(address asset) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(asset)));
  }
}

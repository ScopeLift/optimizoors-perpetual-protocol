// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Create2} from "src/lib/Create2.sol";
import {DepositRouter} from "src/DepositRouter.sol";
import {PerpetualPositionRouter} from "src/PerpetualPositionRouter.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IVault} from "src/interface/IVault.sol";

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

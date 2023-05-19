// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Create2} from "src/lib/Create2.sol";
import {DepositRouter} from "src/DepositRouter.sol";
import {PerpetualPositionRouter} from "src/PerpetualPositionRouter.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IVault} from "src/interface/IVault.sol";

/// @notice A factory for deploying an optimized router for Perpetual protocol. A
/// router will require an asset and wrap some piece of functionality of Perpetual
/// protocol.
contract PerpetualRouterFactory {
  /// @dev Thrown when a function tries to use a router that does not exist.
  /// This error should not be thrown in production as we use an enum to ensure
  /// that a valid router is passed into a function.
  error RouterTypeDoesNotExist();

  /// @dev different types of routers that can be deployed by the factory.
  enum RouterTypes {
    PositionRouterType,
    DepositRouterType
  }

  /// @notice The contract used to manage positions in Perpetual.
  IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;

  /// @notice The Perpetual contract that manages a users account balance.
  IAccountBalance public immutable PERPETUAL_ACCOUNT_BALANCE;

  /// @notice The contract for the Perpetual vault where the deposits are sent.
  IVault public immutable PERPETUAL_VAULT;

  /// @dev Emitted on a successfully deployed router.
  event RouterDeployed(RouterTypes indexed routerType, address indexed asset);

  /// @param clearingHouse Address of the Perpetual clearing house contract.
  /// @param accountBalance Address of the Perpetual account balance contract.
  /// @param vault Address of the Perpetual vault contract.
  constructor(IClearingHouse clearingHouse, IAccountBalance accountBalance, IVault vault) {
    PERPETUAL_CLEARING_HOUSE = clearingHouse;
    PERPETUAL_ACCOUNT_BALANCE = accountBalance;
    PERPETUAL_VAULT = vault;
  }

  /// @notice Creates a contract for a given asset and router type, and
  /// returns the address for the deployed contract.
  /// @dev This function will only revert with `RouterTypeDoesNotExist` if a new
  /// router is added and the case has not been handled yet. It should never
  /// revert in production.
  /// @param type_ The type of router to deploy.
  /// @param asset The token the router uses to manage deposits and positions.
  function deploy(RouterTypes type_, address asset) external returns (address) {
    bytes32 salt = _salt(asset);
    address router;
    if (type_ == RouterTypes.PositionRouterType) {
      router = address(
        new PerpetualPositionRouter{salt: salt}(
          PERPETUAL_CLEARING_HOUSE, PERPETUAL_ACCOUNT_BALANCE, asset
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

  /// @notice Returns the address for a router of a given asset and router type.
  /// This function will still return an address even if the router has not
  /// been deployed.
  /// @dev This function will only revert with `RouterTypeDoesNotExist` if a new
  /// router is added and the case has not been handled yet. It should never
  /// revert in production.
  function computeAddress(RouterTypes type_, address asset) external view returns (address) {
    if (type_ == RouterTypes.PositionRouterType) return _computePositionAddress(asset);
    else if (type_ == RouterTypes.DepositRouterType) return _computeDepositAddress(asset);
    else revert RouterTypeDoesNotExist();
  }

  /// @dev Computes the address for a position router of a given asset.
  /// @param asset The token the router uses to open and close positions.
  function _computePositionAddress(address asset) internal view returns (address) {
    return Create2.computeCreate2Address(
      _salt(asset),
      address(this),
      type(PerpetualPositionRouter).creationCode,
      abi.encode(PERPETUAL_CLEARING_HOUSE, PERPETUAL_ACCOUNT_BALANCE, asset)
    );
  }

  /// @dev Computes the address for a deposit router of a given asset.
  /// @param asset The token the router uses to manage deposits.
  function _computeDepositAddress(address asset) internal view returns (address) {
    return Create2.computeCreate2Address(
      _salt(asset),
      address(this),
      type(DepositRouter).creationCode,
      abi.encode(asset, PERPETUAL_VAULT)
    );
  }

  /// @dev Creates salt value used when creating a contract using `CREATE2`.
  function _salt(address asset) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(asset)));
  }
}

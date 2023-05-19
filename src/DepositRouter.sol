// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IVault} from "src/interface/IVault.sol";

/// @notice A router for depositing funds into the Perpetual vault. A
/// router will support a single ERC20 token and Ether.
contract DepositRouter {
  /// @notice The token that is being deposited into the router.
  address public immutable TOKEN;

  /// @notice The contract for the perpetual vault where the deposits are sent.
  IVault public immutable PERPETUAL_VAULT;

  /// @param token The token that is being deposited into the router.
  /// @param vault The contract for the Perpetual vault where the deposits are sent.
  constructor(address token, IVault vault) {
    TOKEN = token;
    PERPETUAL_VAULT = vault;
  }


  /// @dev Deposits the router's token into the Perpetual vault.
  fallback() external payable {
    uint256 amount = abi.decode(msg.data, (uint256));
    SafeTransferLib.safeTransferFrom(ERC20(TOKEN), msg.sender, address(this), amount);
    ERC20(TOKEN).approve(address(PERPETUAL_VAULT), amount);
    PERPETUAL_VAULT.depositFor(msg.sender, TOKEN, amount);
  }

  /// @dev Deposits Ether into the Perpetual vault.
  receive() external payable {
    PERPETUAL_VAULT.depositEtherFor{value: msg.value}(msg.sender);
  }
}

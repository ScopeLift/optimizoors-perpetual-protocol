// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IVault} from "src/interface/IVault.sol";

/// @notice A router for depositing funds into the perpetual vault
contract DepositRouter {
  /// @notice The token used for the router's deposits
  address public immutable TOKEN;

  /// @notice The contract for the perpetual vault to accept deposits
  IVault public immutable PERPETUAL_VAULT;

  constructor(address token, IVault vault) {
    TOKEN = token;
    PERPETUAL_VAULT = vault;
  }

  function _deposit(uint256 amount) private {
    SafeTransferLib.safeTransferFrom(ERC20(TOKEN), msg.sender, address(this), amount);
    ERC20(TOKEN).approve(address(PERPETUAL_VAULT), amount);
    PERPETUAL_VAULT.depositFor(msg.sender, TOKEN, amount);
  }

  // TODO: integer optimization after talking to the protocol
  fallback() external payable {
    uint256 amount = abi.decode(msg.data, (uint256));
    _deposit(amount);
  }

  receive() external payable {
    PERPETUAL_VAULT.depositEtherFor{value: msg.value}(msg.sender);
  }
}

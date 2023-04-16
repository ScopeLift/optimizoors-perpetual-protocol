// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IVault} from "src/interface/IVault.sol";

contract DepositRouter {
  // @notice The token used for the router's deposits
  address public immutable TOKEN;

  // @notice The contract for the perpetual vault to accept deposits
  IVault public immutable PERPETUAL_VAULT;

  constructor(address token, IVault vault) {
    TOKEN = token;
    PERPETUAL_VAULT = vault;
  }

  function deposit(uint256 amount) external {
    SafeTransferLib.safeTransferFrom(ERC20(TOKEN), msg.sender, address(this), amount);
    PERPETUAL_VAULT.depositFor(msg.sender, TOKEN, amount);
  }
}

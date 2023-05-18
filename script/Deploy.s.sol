// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {IVault} from "src/interface/IVault.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";
import {PerpetualContracts} from "test/PerpetualContracts.sol";

contract Deploy is Script, PerpetualContracts {
  function run() public {
    require(block.chainid == 10, "script can only be run on optimism");
    vm.broadcast();
    PerpetualRouterFactory factory =
      new PerpetualRouterFactory(clearingHouse, accountBalance, vault);

    vm.broadcast();
    factory.deploy(PerpetualRouterFactory.RouterTypes.DepositRouterType, USDC);

    vm.broadcast();
    factory.deploy(PerpetualRouterFactory.RouterTypes.PositionRouterType, VETH);
  }
}

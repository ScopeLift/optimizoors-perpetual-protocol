// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {IVault} from "src/interface/IVault.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";

contract Deploy is Script {
  IClearingHouse clearingHouse = IClearingHouse(0x82ac2CE43e33683c58BE4cDc40975E73aA50f459);
  IVault vault = IVault(0xAD7b4C162707E0B2b5f6fdDbD3f8538A5fbA0d60);
  IAccountBalance accountBalance = IAccountBalance(0xA7f3FC32043757039d5e13d790EE43edBcBa8b7c);

  address public immutable USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
  address public immutable VETH = 0x8C835DFaA34e2AE61775e80EE29E2c724c6AE2BB;

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

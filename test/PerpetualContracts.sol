// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IVault} from "src/interface/IVault.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {IDelegateApproval} from "test/interface/IDelegateApproval.sol";

contract PerpetualContracts {
  // Optimism addresses

  IClearingHouse clearingHouse = IClearingHouse(0x82ac2CE43e33683c58BE4cDc40975E73aA50f459);
  IVault vault = IVault(0xAD7b4C162707E0B2b5f6fdDbD3f8538A5fbA0d60);
  IAccountBalance accountBalance = IAccountBalance(0xA7f3FC32043757039d5e13d790EE43edBcBa8b7c);
  IDelegateApproval delegateApproval = IDelegateApproval(0xfd7bB5F6844a43c5469c972640Eddfa99597a547);
  address public immutable VETH = 0x8C835DFaA34e2AE61775e80EE29E2c724c6AE2BB;
  address public immutable USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
  address public immutable WETH = 0x4200000000000000000000000000000000000006;
}

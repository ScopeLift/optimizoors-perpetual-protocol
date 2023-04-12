// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IVault} from "src/interface/IVault.sol";
import {PerpetualRouterFactory, PerpetualLongInput} from "src/Perpetual.sol";
import {IOpenPosition} from "src/interface/IOpenPosition.sol";
import {IDelegateApproval} from "test/interface/IDelegateApproval.sol";

contract RouterForkTestBase is Test {
  IClearingHouse clearingHouse = IClearingHouse(0x82ac2CE43e33683c58BE4cDc40975E73aA50f459);
  IVault vault = IVault(0xAD7b4C162707E0B2b5f6fdDbD3f8538A5fbA0d60);
  IDelegateApproval delegateApproval = IDelegateApproval(0xfd7bB5F6844a43c5469c972640Eddfa99597a547);
  address public immutable VWETH = 0x8C835DFaA34e2AE61775e80EE29E2c724c6AE2BB;

  PerpetualRouterFactory factory;
  uint256 optimismForkId;

  function setUp() public {
    optimismForkId = vm.createSelectFork(vm.rpcUrl("optimism"), 87_407_144);
    factory = new PerpetualRouterFactory(clearingHouse);
    factory.deploy(VWETH);
    deal(address(this), 100 ether);
    vault.depositEther{value: 10 ether}();
  }
}

contract OpenPositionLongInputFork is RouterForkTestBase {
  function testOpenPosition() public {
    delegateApproval.approve(address(factory.computeAddress(VWETH)), 1); //
    (uint256 base, uint256 quote,) =
      IOpenPosition(factory.computeAddress(VWETH)).openPosition(1 ether, 0, 0);
    assertEq(quote, 1 ether);
    assertEq(base, 538_599_759_293_451);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IVault} from "src/interface/IVault.sol";
import {PerpetualRouterFactory, PerpetualLongInput} from "src/Perpetual.sol";
import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {AccountMarket} from "src/lib/AccountMarket.sol";
import {IDelegateApproval} from "test/interface/IDelegateApproval.sol";

contract RouterFactoryTest is Test {
  function test_deployRouter() public {
    // Opitimism addresses

    address VETH = 0x8C835DFaA34e2AE61775e80EE29E2c724c6AE2BB;
    IClearingHouse clearingHouse = IClearingHouse(0x82ac2CE43e33683c58BE4cDc40975E73aA50f459);
    IAccountBalance accountBalance = IAccountBalance(0xA7f3FC32043757039d5e13d790EE43edBcBa8b7c);
    PerpetualRouterFactory factory = new PerpetualRouterFactory(
            clearingHouse,
            accountBalance
        );

    address VETHLongInputRouter = factory.deploy(VETH);
    assertEq(VETHLongInputRouter, factory.computeAddress(VETH));
  }
}

contract RouterForkTestBase is Test {
  // Optimism addresses

  IClearingHouse clearingHouse = IClearingHouse(0x82ac2CE43e33683c58BE4cDc40975E73aA50f459);
  IVault vault = IVault(0xAD7b4C162707E0B2b5f6fdDbD3f8538A5fbA0d60);
  IAccountBalance accountBalance = IAccountBalance(0xA7f3FC32043757039d5e13d790EE43edBcBa8b7c);
  IDelegateApproval delegateApproval = IDelegateApproval(0xfd7bB5F6844a43c5469c972640Eddfa99597a547);
  address public immutable VETH = 0x8C835DFaA34e2AE61775e80EE29E2c724c6AE2BB;

  PerpetualRouterFactory factory;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl("optimism"), 87_407_144);
    factory = new PerpetualRouterFactory(clearingHouse, accountBalance);
    factory.deploy(VETH);
    deal(address(this), 100 ether);
    vault.depositEther{value: 10 ether}();
  }
}

contract OpenPositionLongInputFork is RouterForkTestBase {
  function test_FallbackLongInput() public {
    delegateApproval.approve(address(factory.computeAddress(VETH)), 1); //
    (bool ok,) = payable(factory.computeAddress(VETH)).call(abi.encode(4, 1 ether, 0, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    assertEq(info.takerOpenNotional, -1 ether);
    assertEq(info.takerPositionSize, 538_599_759_293_451);
  }

  function test_FallbackLongOutput() public {
    delegateApproval.approve(address(factory.computeAddress(VETH)), 1); //
    (bool ok,) = payable(factory.computeAddress(VETH)).call(abi.encode(3, 1 ether, 0, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    console.logInt(info.takerOpenNotional);
    console.logInt(info.takerPositionSize);
    // assertTrue(ok);
    assertEq(info.takerOpenNotional, -1_856_697_038_719_929_142_024);
    assertEq(info.takerPositionSize, 1 ether);
  }

  function test_FallbackShortInput() public {
    delegateApproval.approve(address(factory.computeAddress(VETH)), 1); //
    (bool ok,) = payable(factory.computeAddress(VETH)).call(abi.encode(2, 1 ether, 0, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    console.logInt(info.takerOpenNotional);
    console.logInt(info.takerPositionSize);
    // assertTrue(ok);
    assertEq(info.takerOpenNotional, 1_852_924_032_181_202_909_050);
    assertEq(info.takerPositionSize, -1 ether);
  }

  function test_FallbackShortOutput() public {
    delegateApproval.approve(address(factory.computeAddress(VETH)), 1); //
    (bool ok,) = payable(factory.computeAddress(VETH)).call(abi.encode(1, 1 ether, 0, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    console.logInt(info.takerOpenNotional);
    console.logInt(info.takerPositionSize);
    // assertTrue(ok);
    assertEq(info.takerOpenNotional, 1 ether);
    assertEq(info.takerPositionSize, -539_678_586_420_661);
  }

  function test_FallbackClosePositionLong() public {
    delegateApproval.approve(address(factory.computeAddress(VETH)), 1); //
    (bool ok,) = payable(factory.computeAddress(VETH)).call(abi.encode(4, 1 ether, 0, 0));
    (bool okTwo, bytes memory msg) =
      payable(factory.computeAddress(VETH)).call(abi.encode(5, 1 ether, 0, 0));
    console.logBytes(msg);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function test_FallbackClosePositionShortInput() public {
    delegateApproval.approve(address(factory.computeAddress(VETH)), 1); //
    (bool ok,) = payable(factory.computeAddress(VETH)).call(abi.encode(2, 1 ether, 0, 0));
    (bool okTwo, bytes memory msg) =
      payable(factory.computeAddress(VETH)).call(abi.encode(5, 1 ether, 0, 0));
    console.logBytes(msg);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function test_FallbackClosePositionShortOutput() public {
    delegateApproval.approve(address(factory.computeAddress(VETH)), 1); //
    (bool ok,) = payable(factory.computeAddress(VETH)).call(abi.encode(1, 1 ether, 0, 0));
    (bool okTwo, bytes memory msg) =
      payable(factory.computeAddress(VETH)).call(abi.encode(5, 1 ether, 0, 0));
    console.logBytes(msg);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function test_FallbackClosePositionLongOutput() public {
    delegateApproval.approve(address(factory.computeAddress(VETH)), 1); //
    (bool ok,) = payable(factory.computeAddress(VETH)).call(abi.encode(3, 1 ether, 0, 0));
    (bool okTwo, bytes memory msg) =
      payable(factory.computeAddress(VETH)).call(abi.encode(5, 1 ether, 0, 0));
    console.logBytes(msg);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }
}

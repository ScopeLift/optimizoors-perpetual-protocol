// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";

import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";
import {AccountMarket} from "src/lib/AccountMarket.sol";
import {PerpetualContracts} from "test/PerpetualContracts.sol";

contract PositionRouterForkTestBase is Test, PerpetualContracts {
  PerpetualRouterFactory factory;
  address vethPositionRouterAddr;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl("optimism"), 87_407_144);
    factory = new PerpetualRouterFactory(
            clearingHouse,
            accountBalance,
            vault
        );
    factory.deploy(PerpetualRouterFactory.RouterTypes.PositionRouterType, VETH);
    deal(address(this), 100 ether);
    vault.depositEther{value: 10 ether}();
    vethPositionRouterAddr =
      address(factory.computeAddress(PerpetualRouterFactory.RouterTypes.PositionRouterType, VETH));
  }

  function _closePositionHelper(
    uint8 openFunc,
    uint256 amount,
    uint256 oppositeAmountBound,
    uint256 sqrtPriceLimitX96
  ) internal {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encode(openFunc, amount, oppositeAmountBound, sqrtPriceLimitX96)
    );
    (bool okTwo,) =
      payable(vethPositionRouterAddr).call(abi.encode(5, 0, oppositeAmountBound, sqrtPriceLimitX96));
    assertTrue(ok);
    assertTrue(okTwo);
  }
}

contract OpenPositionLongInputFork is PositionRouterForkTestBase {
  function test_FallbackLongInput() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(4, 1 ether, 0, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    assertEq(info.takerOpenNotional, -1 ether);
    assertEq(info.takerPositionSize, 538_599_759_293_451);
  }

  function test_FallbackLongOutput() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(3, 1 ether, 0, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);

    assertTrue(ok);
    assertEq(info.takerOpenNotional, -1_856_697_038_719_929_142_024);
    assertEq(info.takerPositionSize, 1 ether);
  }

  function test_FallbackShortInput() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(2, 1 ether, 0, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    assertEq(info.takerOpenNotional, 1_852_924_032_181_202_909_050);
    assertEq(info.takerPositionSize, -1 ether);
  }

  function test_FallbackShortOutput() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(1, 1 ether, 0, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    assertEq(info.takerOpenNotional, 1 ether);
    assertEq(info.takerPositionSize, -539_678_586_420_661);
  }

  function test_FallbackClosePositionLong() public {
    _closePositionHelper(4, 1 ether, 0, 0);
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function test_FallbackClosePositionShortInput() public {
    _closePositionHelper(2, 5 ether, 0, 0);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function test_FallbackClosePositionShortOutput() public {
    _closePositionHelper(1, 1 ether, 0, 0);
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function test_FallbackClosePositionLongOutput() public {
    _closePositionHelper(3, 1 ether, 0, 0);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }
}
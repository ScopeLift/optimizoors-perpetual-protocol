// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";

import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";
import {AccountMarket} from "src/lib/AccountMarket.sol";
import {PerpetualContracts} from "test/PerpetualContracts.sol";

interface IPositionRouter {
  function encodeArgs(uint8, uint160) external pure returns (uint168);
}

contract PositionRouterForkTestBase is Test, PerpetualContracts {
  PerpetualRouterFactory factory;
  address vethPositionRouterAddr;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl("optimism"), 87_407_144);
    factory = new PerpetualRouterFactory(clearingHouse, accountBalance, vault);
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
    uint160 sqrtPriceLimitX96
  ) internal {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 openCombinedArgs =
      IPositionRouter(vethPositionRouterAddr).encodeArgs(openFunc, sqrtPriceLimitX96);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encode(openCombinedArgs, amount, oppositeAmountBound)
    );
    uint168 closeCombinedArgs =
      IPositionRouter(vethPositionRouterAddr).encodeArgs(5, sqrtPriceLimitX96);
    (bool okTwo,) =
      payable(vethPositionRouterAddr).call(abi.encode(closeCombinedArgs, 0, oppositeAmountBound));
    assertTrue(ok);
    assertTrue(okTwo);
  }
}

contract OpenPositionLongInputFork is PositionRouterForkTestBase {
  function test_FallbackLongInput() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 combinedArgs = IPositionRouter(vethPositionRouterAddr).encodeArgs(4, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    // Long position is represented as a negative number
    assertEq(info.takerOpenNotional, -1 ether);
    // Meant to prevent regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerPositionSize, 538_599_759_293_451);
  }

  function test_FallbackLongOutput() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 combinedArgs = IPositionRouter(vethPositionRouterAddr).encodeArgs(3, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);

    assertTrue(ok);

    // Long position is represented as a negative number
    assertEq(info.takerOpenNotional, -1_856_697_038_719_929_142_024);
    // Meant to prevent a regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerPositionSize, 1 ether);
  }

  function test_FallbackShortInput() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 combinedArgs = IPositionRouter(vethPositionRouterAddr).encodeArgs(2, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    // Short position is represented as a positive number
    // Meant to prevent a regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerOpenNotional, 1_852_924_032_181_202_909_050);
    assertEq(info.takerPositionSize, -1 ether);
  }

  function test_FallbackShortOutput() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 combinedArgs = IPositionRouter(vethPositionRouterAddr).encodeArgs(1, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    // Short position is represented as a positive number
    assertEq(info.takerOpenNotional, 1 ether);
    // Meant to prevent regression number was sourced
    // from running test in a working state.
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

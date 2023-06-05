// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";
import {PerpetualPositionRouter} from "src/PerpetualPositionRouter.sol";
import {AccountMarket} from "src/lib/AccountMarket.sol";
import {PerpetualContracts} from "test/PerpetualContracts.sol";

contract PositionRouterTest is Test, PerpetualContracts {
  address vethPositionRouterAddr;

  function setUp() public virtual {
    PerpetualRouterFactory factory =
      new PerpetualRouterFactory(clearingHouse, accountBalance, vault);
    vethPositionRouterAddr =
      address(factory.computeAddress(PerpetualRouterFactory.RouterType.PositionRouterType, VETH));
  }

  function closePositionHelper(
    uint8 openFunc,
    uint256 amount,
    uint256 oppositeAmountBound,
    uint160 sqrtPriceLimitX96
  ) internal {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(
        uint8(openFunc),
        uint160(sqrtPriceLimitX96),
        uint32(type(uint32).max),
        uint96(amount),
        uint96(oppositeAmountBound)
      )
    );
    (bool okTwo,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(
        uint8(5),
        uint160(sqrtPriceLimitX96),
        uint32(type(uint32).max),
        uint96(0),
        uint96(oppositeAmountBound)
      )
    );
    assertTrue(ok);
    assertTrue(okTwo);
  }
}

contract Constructor is PositionRouterTest {
  function test_CorrectlySetsAllConstructorArgs() public {
    PerpetualPositionRouter router = new PerpetualPositionRouter(
        clearingHouse,
        accountBalance,
        VETH
    );
    assertEq(
      address(router.PERPETUAL_CLEARING_HOUSE()),
      address(clearingHouse),
      "PERPETUAL_CLEARING_HOUSE not set correctly"
    );
    assertEq(
      address(router.ACCOUNT_BALANCE()),
      address(accountBalance),
      "ACCOUNT_BALANCE not set correctly"
    );
    assertEq(router.TOKEN(), VETH, "TOKEN not set correctly");
  }
}

contract Receive is PositionRouterTest {
  function test_RevertIf_Called(uint256 amount) public {
    PerpetualPositionRouter router = new PerpetualPositionRouter(
        clearingHouse,
        accountBalance,
        VETH
    );
    vm.deal(address(this), amount);

    vm.expectRevert(bytes(""));
    (bool ok,) = payable(address(router)).call{value: amount}("");

    assertTrue(!ok, "Call did not revert");
    assertEq(address(this).balance, amount, "Router did not return all funds");
    assertEq(address(router).balance, 0, "Router kept some funds");
  }
}

contract Fallback is PositionRouterTest {
  PerpetualRouterFactory factory;

  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl("optimism"), 87_407_144);
    factory = new PerpetualRouterFactory(clearingHouse, accountBalance, vault);
    factory.deploy(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);
    deal(address(this), 100 ether);
    vault.depositEther{value: 10 ether}();
    vethPositionRouterAddr =
      address(factory.computeAddress(PerpetualRouterFactory.RouterType.PositionRouterType, VETH));
  }

  function testFork_OpenLongExactInputPosition() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(4), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    // Long position is represented as a negative number
    assertEq(info.takerOpenNotional, -1 ether);
    // Meant to prevent regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerPositionSize, 538_599_759_293_451);
  }

  function testFork_OpenLongExactOutputPosition() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(3), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);

    assertTrue(ok);

    // Long position is represented as a negative number
    assertEq(info.takerOpenNotional, -1_856_697_038_719_929_142_024);
    // Meant to prevent a regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerPositionSize, 1 ether);
  }

  function testFork_OpenShortExactInputPosition() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(2), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    // Short position is represented as a positive number
    // Meant to prevent a regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerOpenNotional, 1_852_924_032_181_202_909_050);
    assertEq(info.takerPositionSize, -1 ether);
  }

  function testFork_OpenShortExactOutputPosition() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(1), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    // Short position is represented as a positive number
    assertEq(info.takerOpenNotional, 1 ether);
    // Meant to prevent regression number was sourced
    // from running test in a working state.
    assertEq(info.takerPositionSize, -539_678_586_420_661);
  }

  function testFork_CloseLongExactInputPosition() public {
    closePositionHelper(4, 1 ether, 0, 0);
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function testFork_CloseLongExactOutputPosition() public {
    closePositionHelper(3, 1 ether, 0, 0);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function testFork_CloseShortExactInputPosition() public {
    closePositionHelper(2, 5 ether, 0, 0);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function testFork_CloseShortExactOutputPosition() public {
    closePositionHelper(1, 1 ether, 0, 0);
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function testFork_FailedCallWhenExtraCalldataArgument() public {
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(4), uint160(0), uint32(type(uint32).max), uint96(0), uint96(100))
    );
    assertTrue(!ok);
  }

  function testFork_FailedClosePositionCallWithWrongArguments() public {
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(5), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    assertTrue(!ok);
  }

  function testFork_FailedFallbackWithZeroFuncId() public {
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(0), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    assertTrue(!ok);
  }
}

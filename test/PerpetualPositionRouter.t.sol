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

  function openClearingHousePosition(
    address token,
    bool isBaseToQuote,
    bool isExactInput,
    uint256 amount,
    uint256 oppositeAmountBound,
    uint256 deadline,
    uint160 sqrtPriceLimitX96
  ) internal {
    clearingHouse.openPosition(
      IClearingHouse.OpenPositionParams({
        baseToken: token,
        isBaseToQuote: isBaseToQuote,
        isExactInput: isExactInput,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: deadline,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: bytes32("")
      })
    );
  }

  function testFork_OpenLongExactInputPosition() public {
    uint256 snapshotId = vm.snapshot();
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(4), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    vm.revertTo(snapshotId);
    openClearingHousePosition(VETH, false, true, uint256(1 ether), 0, type(uint32).max, 0);
    AccountMarket.Info memory nativeInfo = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, nativeInfo.takerOpenNotional);
    assertEq(info.takerPositionSize, nativeInfo.takerPositionSize);
  }

  function testFork_OpenLongExactOutputPosition() public {
    uint256 snapshotId = vm.snapshot();
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(3), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);

    assertTrue(ok);

    vm.revertTo(snapshotId);
    openClearingHousePosition(VETH, false, false, uint256(1 ether), 0, type(uint32).max, 0);
    AccountMarket.Info memory nativeInfo = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, nativeInfo.takerOpenNotional);
    assertEq(info.takerPositionSize, nativeInfo.takerPositionSize);
  }

  function testFork_OpenShortExactInputPosition() public {
    uint256 snapshotId = vm.snapshot();
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(2), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    vm.revertTo(snapshotId);
    openClearingHousePosition(VETH, true, true, uint256(1 ether), 0, type(uint32).max, 0);
    AccountMarket.Info memory nativeInfo = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, nativeInfo.takerOpenNotional);
    assertEq(info.takerPositionSize, nativeInfo.takerPositionSize);
  }

  function testFork_OpenShortExactOutputPosition() public {
    uint256 snapshotId = vm.snapshot();
    delegateApproval.approve(vethPositionRouterAddr, 1);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encodePacked(uint8(1), uint160(0), uint32(type(uint32).max), uint96(1 ether), uint96(0))
    );
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    vm.revertTo(snapshotId);
    openClearingHousePosition(VETH, true, false, uint256(1 ether), 0, type(uint32).max, 0);
    AccountMarket.Info memory nativeInfo = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, nativeInfo.takerOpenNotional);
    assertEq(info.takerPositionSize, nativeInfo.takerPositionSize);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";
import {PerpetualPositionRouter} from "src/PerpetualPositionRouter.sol";
import {PerpetualContracts} from "test/PerpetualContracts.sol";

interface IBadRouterFactory {
  enum BadRouterType {
    PositionRouterType,
    DepositRouterType,
    MadeUpRouter
  }

  function deploy(BadRouterType type_, address asset) external returns (address);

  function computeAddress(BadRouterType type_, address asset) external returns (address);
}

contract RouterFactoryTest is Test, PerpetualContracts {
  PerpetualRouterFactory factory;

  event RouterDeployed(PerpetualRouterFactory.RouterType indexed type_, address indexed asset);
}

contract Constructor is RouterFactoryTest {
  function test_CorrectlySetsAllConstructorArgs() public {
    PerpetualRouterFactory factory = new PerpetualRouterFactory(
      clearingHouse,
      accountBalance,
      vault
    );
    assertEq(
      address(factory.PERPETUAL_CLEARING_HOUSE()),
      address(clearingHouse),
      "PERPETUAL_CLEARING_HOUSE was not set correctly"
    );
    assertEq(
      address(factory.PERPETUAL_ACCOUNT_BALANCE()),
      address(accountBalance),
      "PERPETUAL_ACCOUNT_BALANCE was not set correctly"
    );
    assertEq(
      address(factory.PERPETUAL_VAULT()), address(vault), "PERPETUAL_VAULT was not set correctly"
    );
  }
}

contract Deploy is RouterFactoryTest {
  function setUp() public {
    factory = new PerpetualRouterFactory(
        clearingHouse,
        accountBalance,
        vault
    );
  }

  function test_EmitPositionRouterDeployedEvent() public {
    vm.expectEmit();
    emit RouterDeployed(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);

    factory.deploy(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);
  }

  function test_EmitDepositRouterDeployedEvent() public {
    vm.expectEmit();
    emit RouterDeployed(PerpetualRouterFactory.RouterType.DepositRouterType, VETH);

    factory.deploy(PerpetualRouterFactory.RouterType.DepositRouterType, VETH);
  }

  function test_ReturnsPositionRouterAddress() public {
    address positionRouter =
      factory.deploy(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);
    assertEq(
      positionRouter,
      factory.computeAddress(PerpetualRouterFactory.RouterType.PositionRouterType, VETH),
      "Address not equal to the computed position router address"
    );
  }

  function test_CorrectlyDeploysPositionRouter() public {
    address positionRouter =
      factory.deploy(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);
    assertGt(positionRouter.code.length, 0, "no code");
  }

  function test_ReturnsDepositRouterAddress() public {
    address USDCDepositRouter =
      factory.deploy(PerpetualRouterFactory.RouterType.DepositRouterType, USDC);
    assertEq(
      USDCDepositRouter,
      factory.computeAddress(PerpetualRouterFactory.RouterType.DepositRouterType, USDC),
      "Address not equal to the computed deposit router address"
    );
  }

  function test_CorrectlyDeploysDepositRouter() public {
    address depositRouter =
      factory.deploy(PerpetualRouterFactory.RouterType.DepositRouterType, VETH);
    assertGt(depositRouter.code.length, 0, "no code");
  }

  function test_RevertIf_DepositRouterIsAlreadyDeployed() public {
    factory.deploy(PerpetualRouterFactory.RouterType.DepositRouterType, USDC);

    vm.expectRevert(bytes(""));
    factory.deploy(PerpetualRouterFactory.RouterType.DepositRouterType, USDC);
  }

  function test_RevertIf_PositionRouterIsAlreadyDeployed() public {
    factory.deploy(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);

    vm.expectRevert(bytes(""));
    factory.deploy(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);
  }
}

contract ComputeAddress is RouterFactoryTest {
  function setUp() public {
    factory = new PerpetualRouterFactory(
        clearingHouse,
        accountBalance,
        vault
    );
  }

  function test_ComputeDepositRouterAddress() public {
    address computedAddress =
      factory.computeAddress(PerpetualRouterFactory.RouterType.DepositRouterType, USDC);
    assertEq(computedAddress.code.length, 0, "There is code at the computed address");

    factory.deploy(PerpetualRouterFactory.RouterType.DepositRouterType, USDC);
    assertGt(computedAddress.code.length, 0, "There should be code at the computed address");
  }

  function test_ComputePositionRouterAddress() public {
    address computedAddress =
      factory.computeAddress(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);
    assertEq(computedAddress.code.length, 0, "There is code at the computed address");

    factory.deploy(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);
    assertGt(computedAddress.code.length, 0, "There should be code at the computed address");
  }

  function test_RevertIf_InvalidRouterTypeIsProvided() public {
    vm.expectRevert(bytes(""));
    IBadRouterFactory(address(factory)).computeAddress(
      IBadRouterFactory.BadRouterType.MadeUpRouter, USDC
    );
  }
}

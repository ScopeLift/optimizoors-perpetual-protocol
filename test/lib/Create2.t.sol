// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Create2} from "src/lib/Create2.sol";

contract ComputeCreate2Address is Test {
  function test_GenerateCreate2Address() external {
    bytes32 salt = bytes32(uint256(31_415));
    bytes memory initcodeHash = abi.encode(0x6080);
    address deployer = 0x6C9FC64A53c1b71FB3f9Af64d1ae3A4931A5f4E9;
    address create2Address = Create2.computeCreate2Address(salt, deployer, initcodeHash, "");
    assertEq(create2Address, 0xB147a5d25748fda14b463EB04B111027C290f4d3);
  }
}

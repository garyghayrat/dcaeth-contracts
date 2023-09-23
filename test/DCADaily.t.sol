// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {DCADaily} from "../src/DCADaily.sol";
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/interfaces/IERC20.sol";

contract CounterTest is Test {
    DCADaily dcaDaily;
    IERC20 mockToken;
    address public user = address(0xaceface);

    function setUp() public {
        mockToken = new ERC20Mock();
        dcaDaily = new DCADaily(address(mockToken));
        deal(address(mockToken), user, 1000 ether);
    }

    function testSignUp() public {
        vm.startPrank(user);
        uint256 _recurringAmount = 100 ether;
        uint256 _initialMockTokenBalanceOfUser = mockToken.balanceOf(address(user));
        mockToken.approve(address(dcaDaily), type(uint256).max);
        dcaDaily.signUp(_recurringAmount);
        dcaDaily.buy();
        assertEq(mockToken.balanceOf(address(user)), _initialMockTokenBalanceOfUser - _recurringAmount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {DCADaily} from "../src/DCADaily.sol";
import {ERC20Mock} from "openzeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "openzeppelin/interfaces/IERC20.sol";

import {IPermit2} from "../src/interfaces/IPermit2.sol";
import {IUniversalRouter} from "universal-router/interfaces/IUniversalRouter.sol";

contract CounterTest is Test {
    DCADaily dcaDaily;
    address public universalRouter = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD; // Sepolia
    IERC20 mockToken;
    IERC20 UNI = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984); // Sepolia UNI
    address public user = address(0x637C1Ec1d205a4E7a79c9CE4Bd100CD1d19E6080);
    IPermit2 constant PERMIT2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IUniversalRouter router = IUniversalRouter(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD); // Sepolia
    address public constant tokenAddress = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // Sepolia

    // Fee tiers
    // see: https://docs.uniswap.org/sdk/v3/reference/enums/FeeAmount
    bytes3 constant HIGH_FEE_TIER = bytes3(uint24(10_000));
    bytes3 constant MEDIUM_FEE_TIER = bytes3(uint24(3000));
    bytes3 constant LOW_FEE_TIER = bytes3(uint24(500));
    bytes3 constant LOWEST_FEE_TIER = bytes3(uint24(100));

    function setUp() public {
        mockToken = new ERC20Mock();
        dcaDaily = new DCADaily(address(UNI), WETH);
        deal(address(UNI), user, 1000 ether);

        vm.label(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD, "universalRouter");
        vm.label(0x637C1Ec1d205a4E7a79c9CE4Bd100CD1d19E6080, "user");

        vm.startPrank(user);
        UNI.approve(address(0x000000000022D473030F116dDEE9F6B43aC78BA3), type(uint256).max);
        PERMIT2.approve(address(UNI), address(dcaDaily), type(uint160).max, type(uint48).max);
        vm.stopPrank();
    }

    function testIsUser() public {
        vm.startPrank(user);
        dcaDaily.signUp(100 ether);
        assertTrue(dcaDaily.isUser(user));
        assertTrue(!dcaDaily.isUser(address(0x0)));
        vm.stopPrank();
    }

    function testRecurringBuyAmount() public {
        assertEq(dcaDaily.recurringBuyAmount(address(0)), 0);
    }

    // function testSignUp() public {
    //     vm.startPrank(user);
    //     uint256 _recurringAmount = 100 ether;
    //     uint256 _initialMockTokenBalanceOfUser = mockToken.balanceOf(address(user));
    //     mockToken.approve(address(dcaDaily), type(uint256).max);
    //     dcaDaily.signUp(_recurringAmount);
    //     dcaDaily.transferInTokens(user);
    //     assertEq(mockToken.balanceOf(address(user)), _initialMockTokenBalanceOfUser - _recurringAmount);
    // }

    function testSwap() public {
        vm.startPrank(user);
        uint256 _recurringAmount = 1 ether;
        deal(address(UNI), user, 1000 ether);
        uint256 _initialUNITokenBalanceOfUser = UNI.balanceOf(address(user));
        uint256 _initialETHBalanceOfUser = (address(user)).balance;

        dcaDaily.signUp(_recurringAmount);
        UNI.approve(address(dcaDaily), type(uint256).max);
        dcaDaily.buy();

        assertEq(UNI.balanceOf(address(user)), _initialUNITokenBalanceOfUser - _recurringAmount);
        assertTrue(address(user).balance > _initialETHBalanceOfUser);
        vm.stopPrank();
    }

    function testUniversalRouter() public {
        vm.startPrank(user);

        UNI.approve(address(dcaDaily), type(uint256).max);
        UNI.approve(address(0x000000000022D473030F116dDEE9F6B43aC78BA3), type(uint256).max);
        // Enable the following line to test permit2
        // PERMIT2.approve(address(UNI), address(router), type(uint160).max, type(uint48).max);

        uint256 _recurringAmount = 1 ether;
        uint256 _initialWETHBalanceOfUser = IERC20(WETH).balanceOf(address(user));
        uint256 _initialUNIBalanceOfUser = IERC20(UNI).balanceOf(address(user));

        // Command for V3_SWAP_EXACT_IN
        bytes memory commands = abi.encodePacked(bytes1(uint8(0x00)));
        // Encoded path for V3_SWAP_EXACT_IN
        // bytes memory encodedPath =
        //     abi.encode(bytes32(uint256(uint160(address(UNI)))), bytes3(uint24(10_000)), bytes32(uint256(uint160(WETH))));
        // bytes memory path = bytes.concat(bytes20(address(UNI)), bytes20(address(WETH)));
        bytes memory path = bytes.concat(bytes20(address(UNI)), LOW_FEE_TIER, bytes20(address(WETH)));
        // https://docs.uniswap.org/contracts/universal-router/technical-reference#v3_swap_exact_in
        // Make the following line true to test permit2
        bool _inputTokenComesFromMsgSender = false;
        // IERC20(tokenAddress).approve(address(universalRouter), type(uint256).max);
        // IERC20(tokenAddress).transfer(address(universalRouter), _tokenAmount);

        // // Encoding the inputs for V3_SWAP_EXACT_IN
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(user, _recurringAmount, 0, path, _inputTokenComesFromMsgSender);
        bytes.concat("hello", "hello");

        console2.log(msg.sender);
        // // Execute on the UniversalRouter
        // Disable the following line to test permit2
        IERC20(UNI).transfer(address(router), _recurringAmount);
        router.execute(commands, inputs, uint256(block.timestamp + 10000000));
        assertEq(IERC20(UNI).balanceOf(address(user)), _initialUNIBalanceOfUser - _recurringAmount);
        assertTrue(_initialWETHBalanceOfUser < IERC20(WETH).balanceOf(address(user)));
    }

    function testUniversalRouterWithUnwrapEth() public {
        vm.startPrank(user);

        UNI.approve(address(dcaDaily), type(uint256).max);
        UNI.approve(address(0x000000000022D473030F116dDEE9F6B43aC78BA3), type(uint256).max);
        // Enable the following line to test permit2
        // PERMIT2.approve(address(UNI), address(router), type(uint160).max, type(uint48).max);

        uint256 _recurringAmount = 1 ether;
        uint256 _initialWETHBalanceOfUser = IERC20(WETH).balanceOf(address(user));
        uint256 _initialUNIBalanceOfUser = IERC20(UNI).balanceOf(address(user));
        uint256 _initialETHBalanceOfUser = address(user).balance;

        // Command for V3_SWAP_EXACT_IN
        bytes memory commands = abi.encodePacked(bytes1(uint8(0x00)), bytes1(uint8(0x0c)));
        // Encoded path for V3_SWAP_EXACT_IN
        // bytes memory encodedPath =
        //     abi.encode(bytes32(uint256(uint160(address(UNI)))), bytes3(uint24(10_000)), bytes32(uint256(uint160(WETH))));
        // bytes memory path = bytes.concat(bytes20(address(UNI)), bytes20(address(WETH)));
        bytes memory path = bytes.concat(bytes20(address(UNI)), LOW_FEE_TIER, bytes20(address(WETH)));
        // https://docs.uniswap.org/contracts/universal-router/technical-reference#v3_swap_exact_in
        // Make the following line true to test permit2
        bool _inputTokenComesFromMsgSender = false;
        // IERC20(tokenAddress).approve(address(universalRouter), type(uint256).max);
        // IERC20(tokenAddress).transfer(address(universalRouter), _tokenAmount);

        // // Encoding the inputs for V3_SWAP_EXACT_IN
        bytes[] memory inputs = new bytes[](2);
        inputs[0] = abi.encode(router, _recurringAmount, 0, path, _inputTokenComesFromMsgSender);
        inputs[1] = abi.encode(user, 0);
        bytes.concat("hello", "hello");

        console2.log(msg.sender);
        // // Execute on the UniversalRouter
        // Disable the following line to test permit2
        IERC20(UNI).transfer(address(router), _recurringAmount);
        router.execute(commands, inputs, uint256(block.timestamp + 10000000));
        assertEq(IERC20(UNI).balanceOf(address(user)), _initialUNIBalanceOfUser - _recurringAmount);
        assertTrue(_initialETHBalanceOfUser < address(user).balance);
        console2.log(_initialWETHBalanceOfUser, IERC20(WETH).balanceOf(address(user)));
        console2.log(_initialETHBalanceOfUser, address(user).balance);
    }
}

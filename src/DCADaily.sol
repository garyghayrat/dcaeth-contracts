// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IUniversalRouter} from "universal-router/interfaces/IUniversalRouter.sol";

// Sepolia contract address: 0xBea915d8A99B0b532E4075B36C89d4Ef4bf4f8Ec
// Latest: 0x090E06627F797797E020F8A9Af054873Ba7Ad590
contract DCADaily {
    address[] public users;
    mapping(address => uint256) public recurringBuyAmount;
    address public tokenAddress;
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // Sepolia
    IUniversalRouter public constant universalRouter = IUniversalRouter(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD); // Sepolia

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        // universalRouter = IUniversalRouter(_universalRouter);
    }

    function signUp(uint256 _amount) public {
        users.push(msg.sender);
        recurringBuyAmount[msg.sender] = _amount;
        // TODO: Need to make recurringBuyAmount x length of time they want to sign
        // up for / 24hours to get the total amount to approve
    }

    // Chainlink will call this function
    function buy() external {
        for (uint256 i = 0; i < users.length; i++) {
            transferInTokens(users[i]);
            swapTokensForEth(users[i], recurringBuyAmount[users[i]]);
            // transferOutTokens(users[i]);
        }
    }

    function updateRecurringAmount(uint256 _amount) public {
        recurringBuyAmount[msg.sender] = _amount;
    }

    // TODO: Change to internal
    function transferInTokens(address _user) public {
        IERC20(tokenAddress).transferFrom(_user, address(this), recurringBuyAmount[_user]);
    }

    // TODO: change to internal
    function swapTokensForEth(address _recepient, uint256 _tokenAmount) public {
        // Command for V3_SWAP_EXACT_IN
        bytes memory commands = abi.encodePacked(bytes1(uint8(0x00)));

        // Path for V3_SWAP_EXACT_IN
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WETH;

        // https://docs.uniswap.org/contracts/universal-router/technical-reference#v3_swap_exact_in
        bool _inputTokenComesFromMsgSender = false;
        // IERC20(tokenAddress).approve(address(universalRouter), type(uint256).max);
        // IERC20(tokenAddress).transfer(address(universalRouter), _tokenAmount);

        // // Encoding the inputs for V3_SWAP_EXACT_IN
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(_recepient, _tokenAmount, 0, path, _inputTokenComesFromMsgSender);

        // // Execute on the UniversalRouter
        universalRouter.execute(commands, inputs, block.timestamp + 10000000);
        // bytes memory data =
        //     "0x3593564c000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000650f257800000000000000000000000000000000000000000000000000000000000000020b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000002386f26fc1000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000fe067e9d7cbaf00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002bfff9976782d46cc05630d1f6ebab18b2324d6b140027101f9840a85d5af5bf1d1762f925bdaddc4201f984000000000000000000000000000000000000000000";
        // address(universalRouter).call(data);
    }

    // function transferOutTokens(address _user) internal {}
}

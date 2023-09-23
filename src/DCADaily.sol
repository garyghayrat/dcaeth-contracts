// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

// Sepolia contract address: 0xBea915d8A99B0b532E4075B36C89d4Ef4bf4f8Ec
contract DCADaily {
    address[] public users;
    mapping(address => uint256) public recurringBuyAmount;
    address public tokenAddress;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function signUp(uint256 _amount) public {
        users.push(msg.sender);
        recurringBuyAmount[msg.sender] = _amount;
        // TODO: Need make this _amount x length of time they want to sign
        // up for / 24hours to get the total amount to approve
        approveRecurringAmount(_amount);
    }

    // Chainlink will call this function
    function buy() external {
        for (uint256 i = 0; i < users.length; i++) {
            transferInTokens(users[i]);
            swapTokensForEth(recurringBuyAmount[users[i]]);
            transferOutTokens(users[i]);
        }
    }

    function approveRecurringAmount(uint256 _amount) internal {
        IERC20(tokenAddress).approve(address(this), _amount);
    }

    function transferInTokens(address _user) internal {
        IERC20(tokenAddress).transferFrom(_user, address(this), recurringBuyAmount[_user]);
    }

    // function swapTokensForEth(uint256 _tokenAmount) internal {
    //     // Command for V3_SWAP_EXACT_IN
    //     bytes memory command = "\x00";

    //     // Encoding the inputs for V3_SWAP_EXACT_IN
    //     bytes memory inputs = abi.encode(recipient, daiAmount, minETHReceived, encodedPath, true);

    //     // Execute on the UniversalRouter
    //     universalRouter.execute(command, [inputs], block.timestamp + 15);
    // }

    function transferOutTokens(address _user) internal {}
}

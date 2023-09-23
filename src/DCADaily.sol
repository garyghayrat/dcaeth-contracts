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

    // Uniswap params
    bytes commands = abi.encodePacked(bytes1(uint8(0x00)), bytes1(uint8(0x0c))); // Command for V3_SWAP_EXACT_IN and UNWRAP_ETH
    bytes path;
    bytes3 constant LOW_FEE_TIER = bytes3(uint24(500));

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        // universalRouter = IUniversalRouter(_universalRouter);
        path = bytes.concat(bytes20(address(tokenAddress)), LOW_FEE_TIER, bytes20(address(WETH)));
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
        // // Encoding the inputs for V3_SWAP_EXACT_IN
        bytes[] memory inputs = new bytes[](2);
        inputs[0] = abi.encode(universalRouter, _tokenAmount, 0, path, false);
        inputs[1] = abi.encode(_recepient, 0);

        IERC20(tokenAddress).transfer(address(universalRouter), _tokenAmount);
        // // Execute on the UniversalRouter
        universalRouter.execute(commands, inputs, block.timestamp + 15);
    }
}

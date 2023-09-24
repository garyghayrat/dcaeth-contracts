// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IUniversalRouter} from "universal-router/interfaces/IUniversalRouter.sol";

contract DCADaily {
    address[] public users;
    mapping(address => bool) public isUser;
    mapping(address => uint256) public recurringBuyAmount;
    address public tokenAddress;
    address private immutable WETH;
    IUniversalRouter private constant universalRouter = IUniversalRouter(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD); // Sepolia

    // Uniswap params
    bytes private path;
    bytes private constant commands = abi.encodePacked(bytes1(uint8(0x00)), bytes1(uint8(0x0c))); // Command for V3_SWAP_EXACT_IN and UNWRAP_ETH
    bytes3 private constant LOW_FEE_TIER = bytes3(uint24(500));

    constructor(address _tokenAddress, address _weth) {
        tokenAddress = _tokenAddress;
        WETH = _weth;
        // universalRouter = IUniversalRouter(_universalRouter);
        path = bytes.concat(bytes20(address(tokenAddress)), LOW_FEE_TIER, bytes20(address(WETH)));
    }

    function signUp(uint256 _amount) external {
        if (!isUser[msg.sender]) {
            users.push(msg.sender);
            isUser[msg.sender] = true;
        }
        recurringBuyAmount[msg.sender] = _amount;
    }

    // Chainlink will call this function
    // Right now, anyone can call this, but we should change it to only be called by Chainlink
    function buy() external {
        for (uint256 _i = 0; _i < users.length; _i++) {
            address _user = users[_i];
            if (_checkUserAllowanceAndBalance(_user)) {
                _transferInTokens(_user);
                _swapTokensForEth(_user, recurringBuyAmount[_user]);
            }
        }
    }

    function updateRecurringAmount(uint256 _amount) external {
        recurringBuyAmount[msg.sender] = _amount;
    }

    // TODO: Change to internal
    function _transferInTokens(address _user) private {
        IERC20(tokenAddress).transferFrom(_user, address(this), recurringBuyAmount[_user]);
    }

    // TODO: change to internal
    function _swapTokensForEth(address _recepient, uint256 _tokenAmount) private {
        // // Encoding the inputs for V3_SWAP_EXACT_IN
        bytes[] memory inputs = new bytes[](2);
        inputs[0] = abi.encode(universalRouter, _tokenAmount, 0, path, false);
        inputs[1] = abi.encode(_recepient, 0);

        IERC20(tokenAddress).transfer(address(universalRouter), _tokenAmount);
        // // Execute on the UniversalRouter
        universalRouter.execute(commands, inputs, block.timestamp + 15);
    }

    function _checkUserAllowanceAndBalance(address _user) private view returns (bool) {
        bool hasAllowance = IERC20(tokenAddress).allowance(_user, address(this)) >= recurringBuyAmount[_user];
        bool hasBalance = IERC20(tokenAddress).balanceOf(_user) >= recurringBuyAmount[_user];
        if (hasAllowance && hasBalance) return true;
        else return false;
    }
}

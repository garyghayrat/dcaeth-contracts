// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract DCADaily {
    address[] public users;
    mapping(address => uint256) public recurringBuyAmount;

    function signUp(uint256 _amount) public {
        users.push(msg.sender);
        recurringBuyAmount[msg.sender] = _amount;
    }

    // Chainlink will call this function
    function buy() external {
        for (uint256 i = 0; i < users.length; i++) {
            transferInTokens(users[i]);
            swapTokensForEth(recurringBuyAmount[users[i]]);
            transferOutTokens(users[i]);
        }
    }

    function approveRecurringAmount(uint256 _amount) internal {}

    function transferInTokens(address _user) internal {}

    function swapTokensForEth(uint256 _tokenAmount) internal {}

    function transferOutTokens(address _user) internal {}
}

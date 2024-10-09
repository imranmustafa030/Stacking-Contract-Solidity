// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Staking__TransferFailed();
error Withdraw__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking is ReentrancyGuard {
    IERC20 public s_stakingToken;


    mapping(address => uint256) public s_balances;

    mapping(address => uint256) public s_unstackTime;

    mapping(address => uint256) public s_minStackTime;

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken) {
        s_stakingToken = IERC20(stakingToken);
    }

    function stake(uint256 amount, uint16 stakeTime) external moreThanZero(amount) returns (string memory) {

        require(amount >= 300, "You must provide atleast 300 tokens");
        require(stakeTime == 3 || stakeTime == 6 || stakeTime == 12, "The provided time is not valid. it must be 3, 6 or 12");

        uint256 currentTime = block.timestamp;
        uint256 extraTime;
        
        if(stakeTime == 3){
            extraTime =  3 * 30 days;
            currentTime = currentTime + extraTime;
        }
        else if(stakeTime == 6){
            extraTime =  6 * 30 days;
            currentTime = currentTime + extraTime;
        }
        else if(stakeTime == 12){
            extraTime =  12 * 30 days;
            currentTime = currentTime + extraTime;
        }
        else{
            return "The provided time is not valid.";
        }

        s_balances[msg.sender] += amount;
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert Staking__TransferFailed();
        }
        
        s_unstackTime [msg.sender] = currentTime; 
        s_minStackTime [msg.sender] = stakeTime;
        return "successfull";
        
    }

    function withdraw() external payable returns (string memory) {

        uint256 balance = s_balances[msg.sender];

        require(balance >= 300, "You have not enough balance");
        require(s_unstackTime[msg.sender] <= block.timestamp, "Your staking time is not completed");

        uint256 bonusTime = block.timestamp - s_unstackTime[msg.sender];

        // Staking Time bonus...
        
        if(s_minStackTime[msg.sender] == 3){
            balance = balance + ( (balance * 30) / 100 );
        }
        else if(s_minStackTime[msg.sender] == 6){
            balance = balance + ( (balance * 60) / 100 );
        }
        else if(s_minStackTime[msg.sender] == 12){
            balance = balance * 2;
        }

        // Extra holding bonus..

        if(bonusTime >= (block.timestamp + (3* 30 days)) - block.timestamp){
            balance = balance + ( (balance * 30) / 100 );
        }
        else if(bonusTime >= (block.timestamp + (3* 30 days)) - block.timestamp){
            balance = balance + ( (balance * 60) / 100 );
        }
        else if(bonusTime >= (block.timestamp + (3* 30 days)) - block.timestamp){
            balance = balance * 2;
        }
        

        // emit event
        bool success = s_stakingToken.transfer(msg.sender, balance);
        if (!success) {
            revert Withdraw__TransferFailed();
        }
        
        s_balances[msg.sender] = 0;
        s_unstackTime[msg.sender] = 0;
        s_minStackTime[msg.sender] = 0;


        return "Success";
    }

    function getStaked(address account) public view returns (uint256) {
        return s_balances[account];
    }

    function checkBalance (address account) public view returns (uint256) {
        return s_stakingToken.balanceOf(account);
    }
}
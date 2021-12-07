// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./DualOwnable.sol";
import "./SafeMath.sol";

contract ERC20TimeLock is ERC20, DualOwnable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint)) public initialAllowance;
    mapping(address => bool) public percentageIdentifierMembers;

    mapping(address => uint) public futureTime_10PERCENT;
    mapping(address => uint) public timelock_10PERCENT;
    mapping(address => uint) public futureTime_20PERCENT;
    mapping(address => uint) public timelock_20PERCENT;

    constructor() ERC20("MyToken", "TKN") {}

    function setServiceManager(address _serviceManager) public onlyOwner {
        _setServiceManager(_serviceManager);
    }

    function mint(uint _amount) public onlyOwner {
        _mint(msg.sender, _amount);
        transfer(address(this), _amount);
    }

    function approve(address _spender, uint256 _amount) public onlyOwnerOrServiceManager virtual override returns (bool) {
        _approve(address(this), _spender, _amount);
        return true;
    }

    function approveWithPeriod(address _spender, uint _amount, uint _lockPeriod, uint _percentageIdentifier) public onlyOwnerOrServiceManager {
        
        if(_percentageIdentifier == 10) {
            futureTime_10PERCENT[_spender] = block.timestamp.add(_lockPeriod);
            timelock_10PERCENT[_spender] = _lockPeriod;
            percentageIdentifierMembers[_spender] = true;
        }

        else if(_percentageIdentifier == 20) {
            futureTime_20PERCENT[_spender] = block.timestamp.add(_lockPeriod);
            timelock_20PERCENT[_spender] = _lockPeriod;
            percentageIdentifierMembers[_spender] = true;
        }

        initialAllowance[address(this)][_spender] = _amount;

        _approve(address(this), _spender, _amount);
    }

    function claimTokens() public {
        if(percentageIdentifierMembers[msg.sender]) {
            if(futureTime_10PERCENT[msg.sender] > 0) {
                claim_10PERCENT();
            }
            else if(futureTime_20PERCENT[msg.sender] > 0) {
                claim_20PERCENT();
            }
        }
        else {
            // Transfer tokens directly to _spender
            uint allowanceAmount = allowance(address(this), msg.sender);
            if(allowanceAmount > 0) {
                transferFrom(address(this), msg.sender, allowanceAmount);
            }
            else {
                revert("allowance amount is 0");
            }
        }
    }

    function claim_10PERCENT() private {
        require(futureTime_10PERCENT[msg.sender] > 0, "You are not in 10% allowance list");
        require(block.timestamp >= futureTime_10PERCENT[msg.sender], "Your Time has not elapsed for transaction!");
        require(initialAllowance[address(this)][msg.sender] > 0, "You are not a approved memeber");

        uint elapsedTime = block.timestamp - futureTime_10PERCENT[msg.sender];
        uint timeMultiplier = elapsedTime / timelock_10PERCENT[msg.sender];
        uint percentageIdentifier = 10;
        timeMultiplier++; // Because it has already elapsed base time(eg. 30sec) in require above

        uint initialAllowanceValue = initialAllowance[address(this)][msg.sender];

        // timeMultiplier * (20 * initialAllowanceValue)/100;
        uint releaseAmount = timeMultiplier.mul(percentageIdentifier.mul(initialAllowanceValue).div(100)); // 10%

        uint allowanceAmount = allowance(address(this), msg.sender);
        if(allowanceAmount > 0) {
            transferFrom(address(this), msg.sender, releaseAmount);
        }
        else {
            revert("allowance amount is 0");
        }
        // update time
        futureTime_10PERCENT[msg.sender] = block.timestamp + timelock_10PERCENT[msg.sender];

    }
        

    function claim_20PERCENT() private {
        require(futureTime_20PERCENT[msg.sender] > 0, "You are not in 20% allowance list");
        require(block.timestamp >= futureTime_20PERCENT[msg.sender], "Your Time has not elapsed for transaction!");
        require(initialAllowance[address(this)][msg.sender] > 0, "You are not a approved memeber");

        uint elapsedTime = block.timestamp - futureTime_20PERCENT[msg.sender];
        uint timeMultiplier = elapsedTime / timelock_20PERCENT[msg.sender];
        uint percentageIdentifier = 20;
        timeMultiplier++; // Because it has already elapsed base time(eg. 30sec) in require above

        uint initialAllowanceValue = initialAllowance[address(this)][msg.sender];
         uint releaseAmount = timeMultiplier.mul(percentageIdentifier.mul(initialAllowanceValue).div(100)); // 20%

         uint allowanceAmount = allowance(address(this), msg.sender);
        if(allowanceAmount > 0) {
            transferFrom(address(this), msg.sender, releaseAmount);
        }
        else {
            revert("allowance amount is 0");
        }
        // update time
        futureTime_20PERCENT[msg.sender] = block.timestamp + timelock_20PERCENT[msg.sender];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SaadToken is Ownable{

    uint public totalSupply;
    string public constant name = "Saad Token";
    string public constant symbol = "SQR";
    uint public constant decimals = 2;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => mapping(address => uint)) public initialAllowance;

    
    uint public deployedTime;
    mapping(address => uint) public allowance10percent;
    mapping(address => uint) public allowance20percent;
    mapping(address => uint) public timeLock10;
    mapping(address => uint) public timeLock20;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );

    constructor(uint _initialSupply) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        deployedTime = block.timestamp;
    }

    function transfer(address _to, uint _value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value; 
        balanceOf[_to] += _value; 

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value, uint _time, uint _percentageIdentifier) public onlyOwner returns(bool success) {
        
        if(_percentageIdentifier == 10) {
            allowance10percent[_spender] = block.timestamp + _time;
            timeLock10[_spender] = _time;
        }

        else if(_percentageIdentifier == 20) {
             allowance20percent[_spender] = block.timestamp + _time;
             timeLock20[_spender] = _time;
        }

        initialAllowance[msg.sender][_spender] = _value;
        allowance[msg.sender][_spender] = _value;
        

        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint _value) internal  returns(bool success) {
        require(balanceOf[_from] >= _value, "From has insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance is insufficient");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function withDraw(address _from, address _to, uint _value) public {
        require(allowance10percent[msg.sender] == 0, "You are  in 10% allowance list");
        require(allowance20percent[msg.sender] == 0, "You are  in 20% allowance list");

        transferFrom(_from, _to, _value);
    }

    function withDraw10Percent(address _from, address _to, uint _value) public  {
        require(allowance10percent[msg.sender] > 0, "You are not in 10% allowance list");
        require(block.timestamp >= allowance10percent[msg.sender], "Your Time has not elapsed for transaction!");
        require(initialAllowance[_from][msg.sender] > 0, "You are not a approved memeber");

        // Modulus
        uint elapsedTime = block.timestamp - allowance10percent[msg.sender];
        uint parts = elapsedTime / timeLock10[msg.sender];
        uint identifer = 10;

        parts++;
        

        if(initialAllowance[_from][msg.sender] > 0 ) {
            uint initialAllowanceValue = initialAllowance[_from][msg.sender];
            uint allowedValue = parts * (1 * initialAllowanceValue)/10; // 10%



            if(_value <= allowedValue) {
            transferFrom(_from, _to, _value);
            // update time
            allowance10percent[msg.sender] = block.timestamp + timeLock10[msg.sender];

            
        }
            else {

                 revert(string(abi.encodePacked("You are allowed only ",Strings.toString(parts * identifer), " percent. Because Elaspsed Time is ",
                 Strings.toString(elapsedTime + timeLock10[msg.sender]))));
            }
        }
       
        
        
    }

    function withDraw20Percent(address _from, address _to, uint _value) public {
        require(allowance20percent[msg.sender] > 0, "You are not in 20% allowance list");
        require (block.timestamp >= allowance20percent[msg.sender], "Your Time has not elapsed for transaction!");
        require(initialAllowance[_from][msg.sender] > 0, "You are not a approved memeber");

        // Modulus
        uint elapsedTime = block.timestamp - allowance20percent[msg.sender];
        uint parts = elapsedTime / timeLock20[msg.sender];
        uint identifer = 20;

        parts++;
        

        if(initialAllowance[_from][msg.sender] > 0 ) {
            uint initialAllowanceValue = initialAllowance[_from][msg.sender];
            uint allowedValue = parts * (20 * initialAllowanceValue)/100; // 20%

            if(_value <= allowedValue) {
            transferFrom(_from, _to, _value);
            // update time
            allowance20percent[msg.sender] = block.timestamp + timeLock20[msg.sender];
        }
            else {

                 revert(string(abi.encodePacked("You are allowed only ",Strings.toString(parts * identifer), " percent. Because Elaspsed Time is ",
                 Strings.toString(elapsedTime + timeLock20[msg.sender]))));
            }
        } 
    }
}

 
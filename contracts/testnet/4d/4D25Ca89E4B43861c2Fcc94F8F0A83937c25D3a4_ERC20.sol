/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-30
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

// SPDX-License-Identifier:MIT

pragma solidity 0.8.17;

contract ERC20{
    string public name = "Reward Token";
    string public symbol = "RWD";
    uint256 public totalSupply = 1000000000000000* 10**6; //1 billion tokens ;
    uint8 public decimals = 6;
    address public Owner;

    event moved(
        address from,address to, uint value
    );
    event approval(
        address from,address to,uint value
    );

    mapping(address=>uint256) public balanceOf;
    mapping(address =>mapping(address=>uint256)) public allowance;



    constructor(){
        Owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        

    }
    function _decimals() public view returns(uint){
        return decimals;
    }

    function transfer(address _to, uint _value) public returns(bool success) {

        require(balanceOf[msg.sender] >= _value,"Insufficuent Token");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit moved(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender, uint _value) public {
        allowance[msg.sender][_spender] = _value;
        emit approval(msg.sender,_spender,_value);
    }
    
    function transferFrom(address _owner ,address _anotherOwner, uint _value) public returns(bool success){
            require(_value <= balanceOf[_owner],"Insufficent Amount");
            require(_value <= allowance[_owner][msg.sender],"Insufficent Allowance");

            balanceOf[_owner] -= _value;
            balanceOf[_anotherOwner] += _value;
            allowance[_owner][msg.sender] -= _value;

            emit moved(_owner,_anotherOwner,_value);
            return true;

     
    }



}
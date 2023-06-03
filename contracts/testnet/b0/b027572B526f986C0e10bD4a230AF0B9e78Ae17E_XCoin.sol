/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
}

contract XCoin is ERC20Interface {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;
    address public owner;
    bool public activeStatus = true;
    address payable withdrawAddr;
    uint256 constant tokenPrice = 0.000000000017 ether;

    event Active(address msgSender);
    event Reset(address msgSender);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    mapping(address => uint256) public balances;
    mapping(address => uint256) public freezeOf;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor() public {
        symbol = "MSTNG";
        name = "MUSTANG";
        decimals = 18;
        _totalSupply = 420000000000000 * 10**uint(decimals);
        owner = msg.sender;
        withdrawAddr = msg.sender;
    }

    function isOwner(address add) public view returns (bool) {
      if (add == owner) {
        return true;
      } else return false;
    }

    modifier onlyOwner {
    if (!isOwner(msg.sender)) {
            revert();
         }
    _;
    }

    modifier onlyActive {
     if (!activeStatus) {
            revert();
        }
    _;
    }

    function activeMode() public onlyOwner {
        activeStatus = true;
        emit Active(msg.sender);
    }

    function resetMode() public onlyOwner {
        activeStatus = false;
        emit Reset(msg.sender);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     function getWtAddress() public view returns (address) {
        return withdrawAddr;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function Withdraw() onlyOwner public returns(bool success)  {
        uint256 amount = address(this).balance;
        withdrawAddr.transfer(amount);
        return true;
    }

    function buyToken(uint256 tokenAmount) public payable {
        require(msg.value >= tokenAmount * tokenPrice, "Not enough bnb sent");
        uint256 aToken = tokenAmount * 10**uint256(decimals);
        balances[msg.sender] = balanceOf(msg.sender) + aToken;
        emit Transfer(address(0), msg.sender, aToken);
    }

    function coinPaymentsBuy(uint256 tokenAmount, address receiver) public onlyOwner {
        uint256 aToken = tokenAmount * 10**uint256(decimals);
        balances[receiver] = balanceOf(receiver) + aToken;
        emit Transfer(address(0), receiver, aToken);
    }

    function transfer(address to, uint256 value) public onlyActive returns (bool success) {
        if (to == address(0)) {
            revert();
        }
    	if (value <= 0) {
    		revert();
        }
        if (balances[msg.sender] < value) {
            revert();
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public onlyActive returns (bool success) {
        if (value <= 0) {
            revert();
        }
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public onlyActive returns (bool success) {
        if (to == address(0)) {
            revert();
        }
        if (value <= 0) {
            revert();
        }
        if (balances[from] < value) {
            revert();
        }
        if (value > allowed[from][msg.sender]) {
            revert();
        }
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public onlyActive returns (bool success) {
        if (balances[msg.sender] < value) {
            revert();
        }
		if (value <= 0) {
		    revert();
		}
        balances[msg.sender] = balances[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Burn(msg.sender, value);
        return true;
    }

	function freeze(uint256 value) public onlyActive returns (bool success) {
        if (balances[msg.sender] < value) {
            revert();
        }
		if (value <= 0){
		    revert();
		}
        balances[msg.sender] = balances[msg.sender].sub(value);
        freezeOf[msg.sender] = freezeOf[msg.sender].add(value);
        emit Freeze(msg.sender, value);
        return true;
    }

	function unfreeze(uint256 value) public onlyActive returns (bool success) {
        if (freezeOf[msg.sender] < value) {
            revert();
        }
		if (value <= 0) {
		    revert();
		}
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(value);
		balances[msg.sender] = balances[msg.sender].add(value);
        emit Unfreeze(msg.sender, value);
        return true;
    }

    function () external payable {
        revert();
    }
}
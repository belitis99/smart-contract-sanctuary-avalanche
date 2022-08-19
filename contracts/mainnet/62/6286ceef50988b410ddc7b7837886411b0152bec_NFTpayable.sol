/**
 *Submitted for verification at snowtrace.io on 2022-08-19
*/

//sol
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.13;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

abstract contract NebulaNFT is Context {
    function setURI(uint256 k) external view virtual;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external virtual;
    function checkTots() external virtual view  returns(uint256[3] memory);

}
/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract NFTpayable {
    // Payable address can receive Ether
    using SafeMath for uint256;
    address payable public owner;
    struct Recieved {
	    uint256 amountrecieved;
	    uint256 amountverified;
	    bool full;
    
    }
    struct Sent{
	    uint256 tok1;
	    uint256 tok2;
	    uint256 tok3;
    }
    mapping(address => Recieved) public recieved;
    mapping(address => Sent) public sent;
    address[] public accounts;
    uint256 public Zero = 0;
    uint256 public limit1 = 10;
    uint256 public limit2 = 10;
    uint256 public limit3 = 10;
    uint256 public cost1 = 300;
    uint256 public cost2 = 750;
    uint256 public cost3 = 1500;
    uint256 public gas = 1*(10**17);
    uint256[3] public maxSupplies = [3000,2000,1000];
    uint256[3] public nft_cost = [cost1,cost2,cost3];
    NebulaNFT public nft;
    address public nftAddress = 0x9B446019860D3e1543af793c20Fe371B85BA3EDE;
    address public treasury = 0x6EF53D5FD1B15B0f6c38E1Ea72F72eb33134E75D;
    address public feeToken = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    IERC20 _feeToken = IERC20(feeToken);
 
    // Payable constructor can receive Ether
    constructor() payable {
        nft = NebulaNFT(nftAddress);
        owner = payable(msg.sender);
    }
   function queryERC20Balance(address _account) internal view returns (uint) {
        return IERC20(_feeToken).balanceOf(_account);
    }
    function checkMint(address _account,uint256 _id) internal {
    	Recieved storage _rec = recieved[_account];
    	Sent storage _sent = sent[_account];
    	if (nft_cost[_id-1] <= (_rec.amountrecieved - _rec.amountverified)){
    		nft.setURI(_id);
    		uint256[3] memory ls = [Zero,Zero,Zero];
    		for(uint i=0;i<nft_cost.length;i++){
    			if (i == (_id-1)){
    				ls[i] = 1;
    			}
    		}
    		if (ls[0] != Zero){
	    		_sent.tok1 += ls[0];
	    		nft.mint(_account,1,1,"0x0");
    		}else if (ls[1] != Zero){
	    		_sent.tok2 += ls[1];
	    		nft.mint(_account,2,1,"0x0");
    		}else if (ls[2] != Zero){
	    		_sent.tok3 += ls[2];
	    		nft.mint(_account,3,1,"0x0");
    		}
    		
    	}
    }
    

    function checkFull(uint256 _id) internal {
    	
    	uint256[3] memory ls = nft.checkTots();
    	for(uint i=0;i<nft_cost.length;i++){
    		if (i == (_id-1)){
    			require(ls[i] < maxSupplies[i],"you already retain the maximum amount of this NFT");
    		}
    		
    	}
    }
    function isInList(address _account, address[] memory list) internal returns(bool){
    	for(uint i=0;i<list.length;i++){
    		if(_account == list[i]){
    			return true;
    		}
    	}
    	return false;
    }
    function deposit(address _account,uint256 _id) public payable {
    	Sent storage _sent = sent[_account];
    	require((_sent.tok1).add(_sent.tok2).add(_sent.tok3) < 10,"sorry, you already have too many NFT's");
    	require(msg.sender == _account, "you cannot transfer OPP");
    	require(_account.balance >= gas, "you dont have enough AVAX to cover gas");
    	transfer(payable(nftAddress),gas);
    	require(queryERC20Balance(_account) >= nft_cost[_id-1], "you do not have enough to cover the transfer");
    	require(_feeToken.transferFrom(msg.sender,treasury, nft_cost[_id-1]), "you dont have enough tokens to pay for the NFT");
    	if (isInList(_account,accounts) == false){
    		accounts.push(_account);
    		}
	Recieved storage _rec = recieved[_account];

    	_rec.amountrecieved += nft_cost[_id-1];
    	checkFull(_id);
    	checkMint(_account,_id);
    	_rec.amountverified += nft_cost[_id-1];
    	}
    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }



}
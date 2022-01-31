/**
 *Submitted for verification at snowtrace.io on 2021-12-28
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



// File: contracts/RTSTBT.sol


pragma solidity >=0.4.22 <0.9.0;





contract TestReflect is Ownable {		
	string public name = "The Test Reflection Utility";
	address public racexowner;
    // Mapping owner address to Reflect amount for NFCars
    mapping(address => uint256) private _carReflectionBalance;
    // Mapping owner address to Reflect amount for NFKeys
    mapping(address => uint256) private _keyReflectionBalance;

    constructor() public {
        racexowner = msg.sender;
    }

	function setKeyReflections(address[] memory recipients, uint256[] memory amount) public onlyOwner{				
		for(uint i=0; i<recipients.length; i++){
			_keyReflectionBalance[recipients[i]] = _keyReflectionBalance[recipients[i]] + amount[i];
		}
	}

	function setCarReflections(address[] memory recipients, uint256[] memory amount) public onlyOwner{				
		for(uint i=0; i<recipients.length; i++){
			_carReflectionBalance[recipients[i]] = _carReflectionBalance[recipients[i]] + amount[i];
		}
	}

	function getKeyReflectionBalance(address _recipient) public view returns(uint256){				
        return _keyReflectionBalance[_recipient];
	}

	function getCarReflectionBalance(address _recipient) public view returns(uint256){				
        return _carReflectionBalance[_recipient];
	}

  function claimKeyReflection() public {
    require(_keyReflectionBalance[msg.sender] > 0, "No reflections available");
    uint256 amount = _keyReflectionBalance[msg.sender];
    _keyReflectionBalance[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

  function claimCarReflection() public {
    require(_carReflectionBalance[msg.sender] > 0, "No reflections available");
    uint256 amount = _carReflectionBalance[msg.sender];
    _carReflectionBalance[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IZKBridgeEntrypoint.sol";
import "./interfaces/IZKBridgeReceiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Mailer
/// @notice An example contract for sending messages to other chains, using the ZKBridgeEntrypoint.
contract Mailer2 is Ownable {
    /// @notice The ZKBridgeEntrypoint contract, which sends messages to other chains.
    IZKBridgeEntrypoint public zkBridgeEntrypoint;

    uint256 public fee;

    event MessageSend(uint64 indexed sequence, uint32 indexed dstChainId, address indexed dstAddress, address sender, address recipient, bytes message);

    constructor(address zkBridgeEntrypointAddress) {
        zkBridgeEntrypoint = IZKBridgeEntrypoint(zkBridgeEntrypointAddress);
    }

    /// @notice Sends a message to a destination MessageBridge.
    /// @param dstChainId The chain ID where the destination MessageBridge.
    /// @param dstAddress The address of the destination MessageBridge.
    /// @param message The message to send.
    function sendMessage(uint16 dstChainId, address dstAddress, address recipient, bytes memory message) external payable {
        require(msg.value >= fee, "Insufficient Fee");
        bytes memory payload = abi.encode(msg.sender, recipient, message);
        uint64 sequence = zkBridgeEntrypoint.send(dstChainId, dstAddress, payload);
        emit MessageSend(sequence, dstChainId, dstAddress,msg.sender, recipient,message);
    }

    // @notice Allows owner to set a new fee.
    // @param fee The new fee to use.
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    // @notice Allows owner to claim all fees sent to this contract.
    function claimFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeEntrypoint {

    // @notice send a ZKBridge message to the specified address at a ZKBridge endpoint.
    // @param dstChainId - the destination chain identifier
    // @param dstAddress - the address on destination chain
    // @param payload - a custom bytes payload to send to the destination contract
    function send(uint16 dstChainId, address dstAddress, bytes memory payload) external payable returns (uint64 sequence);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeReceiver {
    // @notice ZKBridge endpoint will invoke this function to deliver the message on the destination
    // @param srcChainId - the source endpoint identifier
    // @param srcAddress - the source sending contract address from the source chain
    // @param sequence - the ordered message nonce
    // @param payload - the signed payload is the UA bytes has encoded to be sent
    function zkReceive(uint16 srcChainId, address srcAddress, uint64 sequence, bytes calldata payload) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
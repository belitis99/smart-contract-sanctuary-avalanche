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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// "SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract EvidenZ is Pausable, Ownable {

    mapping (address => mapping(string => Template)) private templates;

    mapping (address => bool) private isIssuer;

    mapping (address => uint) private nbBytesUsedByIssuer;

    struct Template {
        string template;
        string meta;

        uint lastBlockValidity;

        bool exists;
    }

    modifier onlyIssuer() {
        require(isIssuer[msg.sender], "Caller is not an issuer");
        _;
    }

    // Adds a template to an issuer, defined by its id
    function addTemplate (
        address _issuerAddress,
        string memory _templateId,
        string memory _meta,
        string memory _template)
        public whenNotPaused onlyOwner()
        {
            require(!templates[_issuerAddress][_templateId].exists, "Template already exist.");

            templates[_issuerAddress][_templateId] = Template(_template, _meta, 0, true);
            isIssuer[_issuerAddress] = true;

        }

    function templateExists(address _issuerAddress, string memory _templateId) public whenNotPaused view returns (bool) {
        return templates[_issuerAddress][_templateId].exists;
    }

    // update a template's template
    function updateTemplateTemplate(address _issuerAddress, string memory _templateId, string memory _template) public whenNotPaused onlyOwner() {
        require(templates[_issuerAddress][_templateId].exists, "Template doesn't exist.");

        templates[_issuerAddress][_templateId].template = _template;
    }

    // update a template meta part
    function updateTemplateMeta(address _issuerAddress, string memory _templateId, string memory _meta) public whenNotPaused onlyOwner() {
        require(templates[_issuerAddress][_templateId].exists, "Template doesn't exist.");

        templates[_issuerAddress][_templateId].meta = _meta;
    }

    function updateTemplateBlockValidity(address _issuerAddress, string memory _templateId, uint _newBlockValidity) public whenNotPaused onlyOwner() {
        templates[_issuerAddress][_templateId].lastBlockValidity = _newBlockValidity;
    }

    function getTemplateBlockValidity(address _issuerAddress, string memory _templateId) public view whenNotPaused returns (uint) {
        return templates[_issuerAddress][_templateId].lastBlockValidity;
    }

    // returns the template defined by templateId for a given issuer
    function getTemplateTemplate(address _issuerAddress, string memory _templateId) public view whenNotPaused returns (string memory) {
        return templates[_issuerAddress][_templateId].template;
    }

    function getTemplateMeta(address _issuerAddress, string memory _templateId) public view whenNotPaused returns (string memory) {
        return templates[_issuerAddress][_templateId].meta;
    }

    function isTemplateValid(address _issuerAddress, string memory _templateId) public view whenNotPaused returns (bool) {
        return (templates[_issuerAddress][_templateId].exists && (templates[_issuerAddress][_templateId].lastBlockValidity == 0 || templates[_issuerAddress][_templateId].lastBlockValidity >= block.number));
    }

    function getTemplateAsJson(address _issuerAddress, string memory _templateId) public view whenNotPaused returns (string memory) {
        return string.concat("{\"meta\":", getTemplateMeta(_issuerAddress, _templateId), ",\"template\":", getTemplateTemplate(_issuerAddress, _templateId), "}");

    }

    function getNbBytesUsedByIssuer(address _issuerAddress) public view whenNotPaused returns (uint) {
        return nbBytesUsedByIssuer[_issuerAddress];
    }

    function updateNbBytesUsedByIssuer(address _issuerAddress, uint value) public whenNotPaused onlyOwner() {
        nbBytesUsedByIssuer[_issuerAddress] = value;
    }

    	// Used by issuer to publish data, using its prepaid bytes
	function publishData(address _issuerAddress, string memory _templateId, bytes memory _data) public whenNotPaused onlyIssuer() {
        require(templates[_issuerAddress][_templateId].exists, "Template doesn't exist.");
        require(isTemplateValid(_issuerAddress, _templateId), "Template is not valid.");
        nbBytesUsedByIssuer[_issuerAddress] += bytes(_data).length;
    }


}
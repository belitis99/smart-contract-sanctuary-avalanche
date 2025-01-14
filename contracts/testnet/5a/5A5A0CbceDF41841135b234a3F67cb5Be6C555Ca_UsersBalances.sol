// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SignerController.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {Events} from "../lensprotocol/libraries/Events.sol";
import {Errors} from "../lensprotocol/libraries/Errors.sol";
import {DataTypes} from "../lensprotocol/libraries/DataTypes.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LensHub} from "../lensprotocol/core/LensHub.sol";

contract UsersBalances is ReentrancyGuard, AccessControl, SignerController {
  bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");
  bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

  address public immutable HUB;
  address internal _protocolFund;
  IERC20 internal _token;
  DataTypes.PercentagesData internal _percentages;
  mapping(address => uint256) internal _appBalances;
  mapping(uint256 => uint256) internal _consumersBalances;
  mapping(uint256 => uint256) internal _creatorsBalances;
  uint256 internal _protocolBalance;
  uint256 internal _fansBalance;

  // this variable protects against replay attack
  mapping(bytes32 => bool) public executedSig;

  modifier onlyWhitelistedModules() {
    _validateWhitelistedModule();
    _;
  }

  constructor(
    address hub,
    address governance,
    address treasury,
    address _consumersSigner,
    address _fansSigner,
    address protocolFund,
    address erc20Address,
    DataTypes.PercentagesData memory percentages
  ) SignerController(_consumersSigner, _fansSigner) {
    HUB = hub;

    // Set up roles
    _setupRole(DEFAULT_ADMIN_ROLE, governance);
    _setupRole(GOV_ROLE, governance);
    _setupRole(TREASURY_ROLE, treasury);

    // Set up contract attributes
    _token = IERC20(erc20Address);
    _setProtocolFund(protocolFund);
    _changePercentages(percentages);
  }

  function _validateWhitelistedModule() internal view {
    LensHub lensHub = LensHub(HUB);
    if (
      !lensHub.isCollectModuleWhitelisted(msg.sender) &&
      !lensHub.isFollowModuleWhitelisted(msg.sender) &&
      !lensHub.isReferenceModuleWhitelisted(msg.sender) &&
      !lensHub.isReadModuleWhitelisted(msg.sender)
    ) revert Errors.ModuleNotWhitelisted();
  }

  function changeToken(address erc20NewAddress) public {
    if (!hasRole(GOV_ROLE, msg.sender)) revert Errors.NotGovernance();
    _token = IERC20(erc20NewAddress);
  }

  function getProtocolFund() external view returns (address) {
    return _protocolFund;
  }

  function setProtocolFund(address newProtocolFund) external {
    if (!hasRole(GOV_ROLE, msg.sender)) revert Errors.NotGovernance();
    _setProtocolFund(newProtocolFund);
  }

  function _setProtocolFund(address newProtocolFund) internal {
    if (newProtocolFund == address(0)) revert Errors.InitParamsInvalid();
    if (newProtocolFund == _protocolFund) revert Errors.NoChangeToTheState();

    address prevProtocolFund = _protocolFund;
    _protocolFund = newProtocolFund;
    emit Events.ProtocolFundSet(msg.sender, prevProtocolFund, newProtocolFund, block.timestamp);
  }

  function changePercentages(DataTypes.PercentagesData memory percentages) public {
    if (!hasRole(GOV_ROLE, msg.sender)) revert Errors.NotGovernance();
    _changePercentages(percentages);
  }

  function _changePercentages(DataTypes.PercentagesData memory percentages) internal {
    require(
      percentages.creatorPercentage +
        percentages.protocolPercentage +
        percentages.appPercentage +
        percentages.fansPercentage ==
        100,
      "% sum is not 100"
    );
    _percentages = percentages;
  }

  function addBalance(uint256 profileId, uint256 _amount) public payable {
    if (_token.allowance(msg.sender, address(this)) < _amount) revert Errors.TokenAllowanceTooLow();
    require(_token.transferFrom(msg.sender, address(this), _amount), "Transaction failed");
    _consumersBalances[profileId] += _amount;

    emit Events.BalanceAdded(profileId, msg.value, block.timestamp);
  }

  function moveBalance(
    uint256 consumerId,
    uint256 amount,
    uint256 creatorId,
    address app
  ) external onlyWhitelistedModules {
    if (_consumersBalances[consumerId] < amount) revert Errors.BalanceInsufficient();

    _consumersBalances[consumerId] -= amount;

    uint256 amountToCreator = (amount * _percentages.creatorPercentage) / 100;
    uint256 amountToProtocol = (amount * _percentages.protocolPercentage) / 100;
    uint256 amountToApp = (amount * _percentages.appPercentage) / 100;
    uint256 amountToFans = (amount * _percentages.fansPercentage) / 100;

    _creatorsBalances[creatorId] += amountToCreator;
    _protocolBalance += amountToProtocol;
    _appBalances[app] += amountToApp;
    _fansBalance += amountToFans;

    emit Events.BalanceMoved(
      consumerId,
      creatorId,
      amount,
      amountToCreator,
      amountToProtocol,
      amountToApp,
      amountToFans,
      block.timestamp
    );
  }

  function _checkSignConsumerWithdrawal(
    uint256 _profileId,
    uint256 _amount,
    uint256 _expiration,
    uint256 _nonce,
    bytes calldata _sig
  ) internal {
    if (_expiration < block.timestamp) revert Errors.SignatureExpired();

    bytes32 msgHash = keccak256(abi.encodePacked(_profileId, _amount, _expiration, _nonce));
    if (!super._verifyConsumersSigner(msgHash, _sig)) revert Errors.SignatureInvalid();

    if (executedSig[msgHash]) revert Errors.SignatureReplayed();
    executedSig[msgHash] = true;
  }

  function withdrawConsumerBalance(
    uint256 consumerId,
    uint256 amount,
    uint256 _expiration,
    uint256 _nonce,
    bytes calldata _sig
  ) public {
    if (_consumersBalances[consumerId] < amount) revert Errors.BalanceInsufficient();
    _checkSignConsumerWithdrawal(consumerId, amount, _expiration, _nonce, _sig);

    address owner = IERC721(HUB).ownerOf(consumerId);
    require(_token.transfer(owner, amount), "Tx to consumer failed");
    _consumersBalances[consumerId] -= amount;

    emit Events.ConsumerBalanceWithdrawn(owner, consumerId, amount, block.timestamp);
  }

  function withdrawCreatorBalance(uint256 creatorId, uint256 amount) public nonReentrant {
    if (_creatorsBalances[creatorId] < amount) revert Errors.BalanceInsufficient();

    address owner = IERC721(HUB).ownerOf(creatorId);
    require(_token.transfer(owner, amount), "Tx to creator failed");
    _creatorsBalances[creatorId] -= amount;

    emit Events.CreatorBalanceWithdrawn(owner, creatorId, amount, block.timestamp);
  }

  function withdrawProtocolBalance(uint256 amount) public nonReentrant {
    if (!hasRole(TREASURY_ROLE, msg.sender)) revert Errors.NotTreasury();
    if (_protocolBalance < amount) revert Errors.BalanceInsufficient();

    require(_token.transfer(_protocolFund, amount), "Tx to protocol fund failed");

    emit Events.ProtocolBalanceWithdrawn(_protocolFund, amount, block.timestamp);
  }

  function withdrawAppBalance(address app, uint256 amount) public nonReentrant {
    if (_appBalances[app] < amount) revert Errors.BalanceInsufficient();

    require(_token.transfer(app, amount), "Tx to app fund failed");

    emit Events.AppBalanceWithdrawn(app, amount, block.timestamp);
  }

  function _checkSignFansWithdrawal(
    uint256 _fansId,
    uint256 _amount,
    uint256 _expiration,
    uint256 _nonce,
    bytes calldata _sig
  ) internal {
    if (_expiration < block.timestamp) revert Errors.SignatureExpired();

    bytes32 msgHash = keccak256(abi.encodePacked(_fansId, _amount, _expiration, _nonce));
    if (!super._verifyFansSigner(msgHash, _sig)) revert Errors.SignatureInvalid();

    if (executedSig[msgHash]) revert Errors.SignatureReplayed();
    executedSig[msgHash] = true;
  }

  function withdrawFansBalance(
    uint256 profileId,
    uint256 amount,
    uint256 _expiration,
    uint256 _nonce,
    bytes calldata _sig
  ) public {
    if (_fansBalance < amount) revert Errors.BalanceInsufficient();
    _checkSignFansWithdrawal(profileId, amount, _expiration, _nonce, _sig);

    address owner = IERC721(HUB).ownerOf(profileId);
    require(_token.transfer(owner, amount), "Tx to fan failed");
    _fansBalance -= amount;

    emit Events.FansBalanceWithdrawn(owner, profileId, amount, block.timestamp);
  }

  function getConsumerBalance(uint256 consumerId) public view returns (uint256) {
    return _consumersBalances[consumerId];
  }

  function getCreatorBalance(uint256 creatorId) public view returns (uint256) {
    return _creatorsBalances[creatorId];
  }

  function getProtocolBalance() public view returns (uint256) {
    return _protocolBalance;
  }

  function getAppBalance(address app) public view returns (uint256) {
    return _appBalances[app];
  }

  function getFansBalance() public view returns (uint256) {
    return _fansBalance;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Events} from "../lensprotocol/libraries/Events.sol";
import {Errors} from "../lensprotocol/libraries/Errors.sol";

contract SignerController is Ownable {
  using Address for address;
  using ECDSA for bytes32;

  // signer wallet for signature verification
  address public consumersSigner;
  address public fansSigner;

  /**
   * @param _consumersSigner consumers signer wallet
   * @param _fansSigner fans signer wallet
   */
  constructor(address _consumersSigner, address _fansSigner) {
    _setConsumersSigner(_consumersSigner);
    _setFansSigner(_fansSigner);
  }

  /**
   * See {_setConsumersSigner}
   *
   * Requirements:
   * - Only contract owner can call
   */
  function setConsumersSigner(address _signer) external onlyOwner {
    _setConsumersSigner(_signer);
  }

  /**
   * See {_setFansSigner}
   *
   * Requirements:
   * - Only contract owner can call
   */
  function setFansSigner(address _signer) external onlyOwner {
    _setFansSigner(_signer);
  }

  /**
   * @dev Set signer wallet address
   * @param _signer new signer wallet; must not be the same as before; must not be zero address nor contract address
   */
  function _setConsumersSigner(address _signer) internal {
    if (consumersSigner == _signer) revert Errors.NoChangeToTheState();
    if (_signer == address(0) || _signer.isContract()) revert Errors.InvalidAddress();

    consumersSigner = _signer;
    emit Events.ConsumersSignerSet(_signer, block.timestamp);
  }

  /**
   * @dev Set signer wallet address
   * @param _signer new signer wallet; must not be the same as before; must not be zero address nor contract address
   */
  function _setFansSigner(address _signer) internal {
    if (fansSigner == _signer) revert Errors.NoChangeToTheState();
    if (_signer == address(0) || _signer.isContract()) revert Errors.InvalidAddress();

    fansSigner = _signer;
    emit Events.FansSignerSet(_signer, block.timestamp);
  }

  /**
   * @dev Verify signature signed off signer wallet
   * @param _hash verifying message hash
   * @param _sig signature
   * @return verified status
   */
  function _verifyConsumersSigner(bytes32 _hash, bytes memory _sig) internal view returns (bool) {
    bytes32 h = _hash.toEthSignedMessageHash();
    return h.recover(_sig) == consumersSigner;
  }

  /**
   * @dev Verify signature signed off signer wallet
   * @param _hash verifying message hash
   * @param _sig signature
   * @return verified status
   */
  function _verifyFansSigner(bytes32 _hash, bytes memory _sig) internal view returns (bool) {
    bytes32 h = _hash.toEthSignedMessageHash();
    return h.recover(_sig) == fansSigner;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "./DataTypes.sol";

library Events {
  /**
   * @dev Emitted when the NFT contract's name and symbol are set at initialization.
   *
   * @param name The NFT name set.
   * @param symbol The NFT symbol set.
   * @param timestamp The current block timestamp.
   */
  event BaseInitialized(string name, string symbol, uint256 timestamp);

  /**
   * @dev Emitted when the hub state is set.
   *
   * @param caller The caller who set the state.
   * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
   * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
   * @param timestamp The current block timestamp.
   */
  event StateSet(
    address indexed caller,
    DataTypes.ProtocolState indexed prevState,
    DataTypes.ProtocolState indexed newState,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
   * governance address, as we cannot guarantee this will always be the case due to upgradeability.
   *
   * @param caller The caller who set the governance address.
   * @param prevGovernance The previous governance address.
   * @param newGovernance The new governance address set.
   * @param timestamp The current block timestamp.
   */
  event GovernanceSet(
    address indexed caller,
    address indexed prevGovernance,
    address indexed newGovernance,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
   * governance address, as we cannot guarantee this will always be the case due to upgradeability.
   *
   * @param caller The caller who set the emergency admin address.
   * @param oldEmergencyAdmin The previous emergency admin address.
   * @param newEmergencyAdmin The new emergency admin address set.
   * @param timestamp The current block timestamp.
   */
  event EmergencyAdminSet(
    address indexed caller,
    address indexed oldEmergencyAdmin,
    address indexed newEmergencyAdmin,
    uint256 timestamp
  );

  /**
<<<<<<< HEAD
   * @dev Emitted when the protocol fund address is changed. We emit the caller even though it should be the previous
   * protocol fund address, as we cannot guarantee this will always be the case due to upgradeability.
   *
   * @param caller The caller who set the protocol fund address.
=======
   * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
   * governance address, as we cannot guarantee this will always be the case due to upgradeability.
   *
   * @param caller The caller who set the governance address.
>>>>>>> master
   * @param prevProtocolFund The previous protocol fund address.
   * @param newProtocolFund The new protocol fund address set.
   * @param timestamp The current block timestamp.
   */
  event ProtocolFundSet(
    address indexed caller,
    address indexed prevProtocolFund,
    address indexed newProtocolFund,
    uint256 timestamp
  );

  /**
<<<<<<< HEAD
   * @dev Emitted when the users balances address is changed.
   *
   * @param caller The caller who set the users balances address.
   * @param newUsersBalance The new users balance address set.
   * @param timestamp The current block timestamp.
   */
  event UsersBalancesSet(address indexed caller, address indexed newUsersBalance, uint256 timestamp);

  /**
   * @dev Emitted when the charger address is changed.
   *
   * @param caller The caller who set the protocol fund address.
   * @param newCharger The new charger address set.
   * @param timestamp The current block timestamp.
   */
  event ChargerSet(address indexed caller, address indexed newCharger, uint256 timestamp);

  /**
=======
>>>>>>> master
   * @dev Emitted when a profile creator is added to or removed from the whitelist.
   *
   * @param profileCreator The address of the profile creator.
   * @param whitelisted Whether or not the profile creator is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event ProfileCreatorWhitelisted(address indexed profileCreator, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a follow module is added to or removed from the whitelist.
   *
   * @param followModule The address of the follow module.
   * @param whitelisted Whether or not the follow module is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event FollowModuleWhitelisted(address indexed followModule, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a reference module is added to or removed from the whitelist.
   *
   * @param referenceModule The address of the reference module.
   * @param whitelisted Whether or not the reference module is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event ReferenceModuleWhitelisted(address indexed referenceModule, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a collect module is added to or removed from the whitelist.
   *
   * @param collectModule The address of the collect module.
   * @param whitelisted Whether or not the collect module is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event CollectModuleWhitelisted(address indexed collectModule, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a read module is added to or removed from the whitelist.
   *
   * @param readModule The address of the read module.
   * @param whitelisted Whether or not the collect module is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event ReadModuleWhitelisted(address indexed readModule, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a profile is created.
   *
   * @param profileId The newly created profile's token ID.
   * @param creator The profile creator, who created the token with the given profile ID.
   * @param vars The CreateProfileData struct containing the following parameters:
   *      to: The address receiving the profile.
   *      handle: The handle to set for the profile, must be unique and non-empty.
   *      imageURI: The URI to set for the profile image.
   *      followModule: The follow module to use, can be the zero address.
   *      followModuleReturnData: The data returned from the follow module's initialization. This is abi encoded
   *      followNFTURI: The URI to set for the follow NFT.
   *      videoURI The URI to set for the profile video.
   *      metadataURI The URI to set for the profile metadata.
   * @param timestamp The current block timestamp.
   */
  event ProfileCreated(
    uint256 indexed profileId,
    address indexed creator,
    DataTypes.CreateProfileEvent vars,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a a default profile is set for a wallet as its main identity
   *
   * @param wallet The wallet which set or unset its default profile.
   * @param profileId The token ID of the profile being set as default, or zero.
   * @param timestamp The current block timestamp.
   */
  event DefaultProfileSet(address indexed wallet, uint256 indexed profileId, uint256 timestamp);

  /**
   * @dev Emitted when a dispatcher is set for a specific profile.
   *
   * @param profileId The token ID of the profile for which the dispatcher is set.
   * @param dispatcher The dispatcher set for the given profile.
   * @param timestamp The current block timestamp.
   */
  event DispatcherSet(uint256 indexed profileId, address indexed dispatcher, uint256 timestamp);

  /**
   * @dev Emitted when a profile's URI is set.
   *
   * @param profileId The token ID of the profile for which the URI is set.
   * @param imageURI The URI set for the given profile.
   * @param timestamp The current block timestamp.
   */
  event ProfileImageURISet(uint256 indexed profileId, string imageURI, uint256 timestamp);

  /**
   * @dev Emitted when a follow NFT's URI is set.
   *
   * @param profileId The token ID of the profile for which the followNFT URI is set.
   * @param followNFTURI The follow NFT URI set.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTURISet(uint256 indexed profileId, string followNFTURI, uint256 timestamp);

  /**
   * @dev Emitted when a profile's URI is set.
   *
   * @param profileId The token ID of the profile for which the URI is set.
   * @param videoURI The URI set for the given profile.
   * @param timestamp The current block timestamp.
   */
  event ProfileVideoURISet(uint256 indexed profileId, string videoURI, uint256 timestamp);

  /**
   * @dev Emitted when a profile's URI is set.
   *
   * @param profileId The token ID of the profile for which the URI is set.
   * @param metadataURI The URI set for the given profile.
   * @param timestamp The current block timestamp.
   */
  event ProfileMetadataURISet(uint256 indexed profileId, string metadataURI, uint256 timestamp);

  /**
   * @dev Emitted when a profile's follow module is set.
   *
   * @param profileId The profile's token ID.
   * @param followModule The profile's newly set follow module. This CAN be the zero address.
   * @param followModuleReturnData The data returned from the follow module's initialization. This is abi encoded
   * and totally depends on the follow module chosen.
   * @param timestamp The current block timestamp.
   */
  event FollowModuleSet(
    uint256 indexed profileId,
    address followModule,
    bytes followModuleReturnData,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a "post" is published.
   *
   * @param profileId The profile's token ID.
   * @param pubId The new publication's ID.
   * @param contentURI The URI mapped to this new publication.
   * @param modulesData The data related to the modules that are associated to the post.
   * @param timestamp The current block timestamp.
   */
  event PostCreated(
    uint256 indexed profileId,
    uint256 indexed pubId,
    string contentURI,
    DataTypes.PostModulesData modulesData,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a "comment" is published.
   *
   * @param profileId The profile's token ID.
   * @param pubId The new publication's ID.
   * @param contentURI The URI mapped to this new publication.
   * @param profileIdPointed The profile token ID that this comment points to.
   * @param pubIdPointed The publication ID that this comment points to.
   * @param referenceModuleData The data passed to the reference module.
   * @param collectModule The collect module mapped to this new publication. This CANNOT be the zero address.
   * @param collectModuleReturnData The data returned from the collect module's initialization for this given
   * publication. This is abi encoded and totally depends on the collect module chosen.
   * @param referenceModule The reference module set for this publication.
   * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
   * encoded and totally depends on the reference module chosen.
   * @param timestamp The current block timestamp.
   */
  event CommentCreated(
    uint256 indexed profileId,
    uint256 indexed pubId,
    string contentURI,
    uint256 profileIdPointed,
    uint256 pubIdPointed,
    bytes referenceModuleData,
    address collectModule,
    bytes collectModuleReturnData,
    address referenceModule,
    bytes referenceModuleReturnData,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a "mirror" is published.
   *
   * @param profileId The profile's token ID.
   * @param pubId The new publication's ID.
   * @param profileIdPointed The profile token ID that this mirror points to.
   * @param pubIdPointed The publication ID that this mirror points to.
   * @param referenceModuleData The data passed to the reference module.
   * @param referenceModule The reference module set for this publication.
   * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
   * encoded and totally depends on the reference module chosen.
   * @param timestamp The current block timestamp.
   */
  event MirrorCreated(
    uint256 indexed profileId,
    uint256 indexed pubId,
    uint256 profileIdPointed,
    uint256 pubIdPointed,
    bytes referenceModuleData,
    address referenceModule,
    bytes referenceModuleReturnData,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a followNFT clone is deployed using a lazy deployment pattern.
   *
   * @param profileId The token ID of the profile to which this followNFT is associated.
   * @param followNFT The address of the newly deployed followNFT clone.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTDeployed(uint256 indexed profileId, address indexed followNFT, uint256 timestamp);

  /**
   * @dev Emitted when a collectNFT clone is deployed using a lazy deployment pattern.
   *
   * @param profileId The publisher's profile token ID.
   * @param pubId The publication associated with the newly deployed collectNFT clone's ID.
   * @param collectNFT The address of the newly deployed collectNFT clone.
   * @param timestamp The current block timestamp.
   */
  event CollectNFTDeployed(
    uint256 indexed profileId,
    uint256 indexed pubId,
    address indexed collectNFT,
    uint256 timestamp
  );

  /**
   * @dev Emitted upon a successful collect action.
   *
   * @param collector The address collecting the publication.
   * @param profileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
   * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
   * @param rootProfileId The profile token ID of the profile whose publication is being collected.
   * @param rootPubId The publication ID of the publication being collected.
   * @param collectModuleData The data passed to the collect module.
   * @param timestamp The current block timestamp.
   */
  event Collected(
    address indexed collector,
    uint256 indexed profileId,
    uint256 indexed pubId,
    uint256 rootProfileId,
    uint256 rootPubId,
    bytes collectModuleData,
    uint256 timestamp
  );

  /**
   * @dev Emitted upon a successful follow action.
   *
   * @param follower The address following the given profiles.
   * @param profileIds The token ID array of the profiles being followed.
   * @param followModuleDatas The array of data parameters passed to each follow module.
   * @param timestamp The current block timestamp.
   */
  event Followed(address indexed follower, uint256[] profileIds, bytes[] followModuleDatas, uint256 timestamp);

  /**
   * @dev Emitted via callback when a followNFT is transferred.
   *
   * @param profileId The token ID of the profile associated with the followNFT being transferred.
   * @param followNFTId The followNFT being transferred's token ID.
   * @param from The address the followNFT is being transferred from.
   * @param to The address the followNFT is being transferred to.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTTransferred(
    uint256 indexed profileId,
    uint256 indexed followNFTId,
    address from,
    address to,
    uint256 timestamp
  );

  /**
   * @dev Emitted via callback when a collectNFT is transferred.
   *
   * @param profileId The token ID of the profile associated with the collectNFT being transferred.
   * @param pubId The publication ID associated with the collectNFT being transferred.
   * @param collectNFTId The collectNFT being transferred's token ID.
   * @param from The address the collectNFT is being transferred from.
   * @param to The address the collectNFT is being transferred to.
   * @param timestamp The current block timestamp.
   */
  event CollectNFTTransferred(
    uint256 indexed profileId,
    uint256 indexed pubId,
    uint256 indexed collectNFTId,
    address from,
    address to,
    uint256 timestamp
  );

  // Collect/Follow NFT-Specific

  /**
   * @dev Emitted when a newly deployed follow NFT is initialized.
   *
   * @param profileId The token ID of the profile connected to this follow NFT.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTInitialized(uint256 indexed profileId, uint256 timestamp);

  /**
   * @dev Emitted when delegation power in a FollowNFT is changed.
   *
   * @param delegate The delegate whose power has been changed.
   * @param newPower The new governance power mapped to the delegate.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTDelegatedPowerChanged(address indexed delegate, uint256 indexed newPower, uint256 timestamp);

  /**
   * @dev Emitted when a newly deployed collect NFT is initialized.
   *
   * @param profileId The token ID of the profile connected to the publication mapped to this collect NFT.
   * @param pubId The publication ID connected to the publication mapped to this collect NFT.
   * @param timestamp The current block timestamp.
   */
  event CollectNFTInitialized(uint256 indexed profileId, uint256 indexed pubId, uint256 timestamp);

  // Module-Specific

  /**
   * @notice Emitted when the ModuleGlobals governance address is set.
   *
   * @param prevGovernance The previous governance address.
   * @param newGovernance The new governance address set.
   * @param timestamp The current block timestamp.
   */
  event ModuleGlobalsGovernanceSet(address indexed prevGovernance, address indexed newGovernance, uint256 timestamp);

  /**
   * @notice Emitted when the ModuleGlobals treasury address is set.
   *
   * @param prevTreasury The previous treasury address.
   * @param newTreasury The new treasury address set.
   * @param timestamp The current block timestamp.
   */
  event ModuleGlobalsTreasurySet(address indexed prevTreasury, address indexed newTreasury, uint256 timestamp);

  /**
   * @notice Emitted when the ModuleGlobals treasury fee is set.
   *
   * @param prevTreasuryFee The previous treasury fee in BPS.
   * @param newTreasuryFee The new treasury fee in BPS.
   * @param timestamp The current block timestamp.
   */
  event ModuleGlobalsTreasuryFeeSet(uint16 indexed prevTreasuryFee, uint16 indexed newTreasuryFee, uint256 timestamp);

  /**
   * @notice Emitted when a currency is added to or removed from the ModuleGlobals whitelist.
   *
   * @param currency The currency address.
   * @param prevWhitelisted Whether or not the currency was previously whitelisted.
   * @param whitelisted Whether or not the currency is whitelisted.
   * @param timestamp The current block timestamp.
   */
  event ModuleGlobalsCurrencyWhitelisted(
    address indexed currency,
    bool indexed prevWhitelisted,
    bool indexed whitelisted,
    uint256 timestamp
  );

  /**
   * @notice Emitted when a module inheriting from the `FeeModuleBase` is constructed.
   *
   * @param moduleGlobals The ModuleGlobals contract address used.
   * @param timestamp The current block timestamp.
   */
  event FeeModuleBaseConstructed(address indexed moduleGlobals, uint256 timestamp);

  /**
   * @notice Emitted when a module inheriting from the `ModuleBase` is constructed.
   *
   * @param hub The LensHub contract address used.
   * @param timestamp The current block timestamp.
   */
  event ModuleBaseConstructed(address indexed hub, uint256 timestamp);

  /**
   * @notice Emitted when one or multiple addresses are approved (or disapproved) for following in
   * the `ApprovalFollowModule`.
   *
   * @param owner The profile owner who executed the approval.
   * @param profileId The profile ID that the follow approvals are granted/revoked for.
   * @param addresses The addresses that have had the follow approvals grnated/revoked.
   * @param approved Whether each corresponding address is now approved or disapproved.
   * @param timestamp The current block timestamp.
   */
  event FollowsApproved(
    address indexed owner,
    uint256 indexed profileId,
    address[] addresses,
    bool[] approved,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the user wants to enable or disable follows in the `LensPeriphery`.
   *
   * @param owner The profile owner who executed the toggle.
   * @param profileIds The array of token IDs of the profiles each followNFT is associated with.
   * @param enabled The array of whether each FollowNFT's follow is enabled/disabled.
   * @param timestamp The current block timestamp.
   */
  event FollowsToggled(address indexed owner, uint256[] profileIds, bool[] enabled, uint256 timestamp);

  /**
   * @dev Emitted when the metadata associated with a profile is set in the `LensPeriphery`.
   *
   * @param profileId The profile ID the metadata is set for.
   * @param metadata The metadata set for the profile and user.
   * @param timestamp The current block timestamp.
   */
  event ProfileMetadataSet(uint256 indexed profileId, string metadata, uint256 timestamp);

  /**
   * @dev Emitted when the balance is added to a consumer balance.
   *
   * @param to The profile ID the balance is added for.
   * @param amount The amount added to the balance.
   * @param timestamp The current block timestamp.
   */
  event BalanceAdded(uint256 to, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the balance is moved from a consumer to a creator.
   *
   * @param from The profile ID of the consumer that the balance is moved from.
   * @param to The profile ID the balance is added for.
   * @param totalAmount The amount moved away from the consumer balance.
   * @param amountToCreator The amount added to creator balance.
   * @param amountToProtocol The amount added to protocol balance.
   * @param amountToApp The amount added to app balance.
   * @param amountToFans The amount added to fans balance.
   * @param timestamp The current block timestamp.
   */
  event BalanceMoved(
    uint256 from,
    uint256 to,
    uint256 totalAmount,
    uint256 amountToCreator,
    uint256 amountToProtocol,
    uint256 amountToApp,
    uint256 amountToFans,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the consumer withdrew his balance.
   *
   * @param to The address of the consumer where the balance is withdrew.
   * @param profileId The profile ID of the consumer that withdrew the balance.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event ConsumerBalanceWithdrawn(address to, uint256 profileId, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the creator withdrew his balance.
   *
   * @param to The address of the creator where the balance is withdrew.
   * @param profileId The profile ID of the creator that withdrew the balance.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event CreatorBalanceWithdrawn(address to, uint256 profileId, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the protocol withdrew his balance.
   *
   * @param to The address of the protocol fund where the balance is withdrew.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event ProtocolBalanceWithdrawn(address to, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the app withdrew his balance.
   *
   * @param to The address of the app where the balance is withdrew.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event AppBalanceWithdrawn(address to, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when a fan withdrew from the fans balance.
   *
   * @param to The address of the fans where the balance is withdrew.
   * @param profileId The profile ID of the fan that withdrew the balance.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event FansBalanceWithdrawn(address to, uint256 profileId, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the consumer signer address was set.
   *
   * @param signer The address of the consumer signer controller.
   * @param timestamp The current block timestamp.
   */
  event ConsumersSignerSet(address signer, uint256 timestamp);

  /**
   * @dev Emitted when the fans signer address was set.
   *
   * @param signer The address of the fans signer controller.
   * @param timestamp The current block timestamp.
   */
  event FansSignerSet(address signer, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
  error CannotInitImplementation();
  error Initialized();
  error SignatureExpired();
  error ZeroSpender();
  error SignatureInvalid();
  error NotOwnerOrApproved();
  error NotHub();
  error TokenDoesNotExist();
  error NotGovernance();
  error NotGovernanceOrEmergencyAdmin();
  error EmergencyAdminCannotUnpause();
  error CallerNotWhitelistedModule();
  error CollectModuleNotWhitelisted();
  error FollowModuleNotWhitelisted();
  error ReferenceModuleNotWhitelisted();
  error ProfileCreatorNotWhitelisted();
  error ReadModuleNotWhitelisted();
  error ModuleNotWhitelisted();
  error NotProfileOwner();
  error NotProfileOwnerOrDispatcher();
  error NotDispatcher();
  error PublicationDoesNotExist();
  error HandleTaken();
  error HandleLengthInvalid();
  error HandleContainsInvalidCharacters();
  error HandleFirstCharInvalid();
  error ProfileImageURILengthInvalid();
  error ProfileVideoURILengthInvalid();
  error ProfileMetadataURILengthInvalid();
  error CallerNotFollowNFT();
  error CallerNotCollectNFT();
  error BlockNumberInvalid();
  error ArrayMismatch();
  error CannotCommentOnSelf();
  error NotWhitelisted();
  error NoChangeToTheState();
  error InvalidAddress();
  error SignatureReplayed();
  error NotCharger();
  error ModuleNotAuthorized();
  error ModuleNotAuthorizedFor(uint256 consumerId);

  // Module Errors
  error InitParamsInvalid();
  error CollectExpired();
  error FollowInvalid();
  error ModuleDataMismatch();
  error FollowNotApproved();
  error MintLimitExceeded();
  error CollectNotAllowed();
  error IncompleteData();

  // MultiState Errors
  error Paused();
  error PublishingPaused();

  // Balance Errors
  error TokenAllowanceTooLow();
  error BalanceInsufficient();
  error NotTreasury();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title DataTypes
 * @author Lens Protocol
 *
 * @notice A standard library of data types used throughout the Lens Protocol.
 */
library DataTypes {
  /**
   * @notice An enum containing the different states the protocol can be in, limiting certain actions.
   *
   * @param Unpaused The fully unpaused state.
   * @param PublishingPaused The state where only publication creation functions are paused.
   * @param Paused The fully paused state.
   */
  enum ProtocolState {
    Unpaused,
    PublishingPaused,
    Paused
  }

  /**
   * @notice An enum specifically used in a helper function to easily retrieve the publication type for integrations.
   *
   * @param Post A standard post, having a URI, a collect module but no pointer to another publication.
   * @param Comment A comment, having a URI, a collect module and a pointer to another publication.
   * @param Mirror A mirror, having a pointer to another publication, but no URI or collect module.
   * @param Nonexistent An indicator showing the queried publication does not exist.
   */
  enum PubType {
    Post,
    Comment,
    Mirror,
    Nonexistent
  }

  /**
   * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
   *
   * @param v The signature's recovery parameter.
   * @param r The signature's r parameter.
   * @param s The signature's s parameter
   * @param deadline The signature's deadline
   */
  struct EIP712Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 deadline;
  }

  /**
   * @notice A struct containing profile data.
   *
   * @param pubCount The number of publications made to this profile.
   * @param followModule The address of the current follow module in use by this profile, can be empty.
   * @param followNFT The address of the followNFT associated with this profile, can be empty..
   * @param handle The profile's associated handle.
   * @param imageURI The URI to be used for the profile's image.
   * @param followNFTURI The URI to be used for the follow NFT.
   * @param videoURI The URI to be used for the profile's video.
   * @param metadataURI The URI to be used for the profile's metadata.
   * @param metadataHash The hash to be checked for the profile's metadata that is in the URI.
   */
  struct ProfileStruct {
    uint256 pubCount;
    address followModule;
    address followNFT;
    string handle;
    string imageURI;
    string followNFTURI;
    string videoURI;
    string metadataURI;
    string metadataHash;
  }

  /**
   * @notice A struct containing data associated with each new publication.
   *
   * @param profileIdPointed The profile token ID this publication points to, for mirrors and comments.
   * @param pubIdPointed The publication ID this publication points to, for mirrors and comments.
   * @param contentURI The URI associated with this publication.
   * @param referenceModule The address of the current reference module in use by this profile, can be empty.
   * @param collectModule The address of the collect module associated with this publication, this exists for all publication.
   * @param collectNFT The address of the collectNFT associated with this publication, if any.
   * @param readModule The address of the read module associated with this publication, this exists for all publication.
   */
  struct PublicationStruct {
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    string contentURI;
    address referenceModule;
    address collectModule;
    address collectNFT;
    address readModule;
  }

  /**
   * @notice A struct containing the parameters required for the `createProfile()` function.
   *
   * @param to The address receiving the profile.
   * @param handle The handle to set for the profile, must be unique and non-empty.
   * @param imageURI The URI to set for the profile image.
   * @param followModule The follow module to use, can be the zero address.
   * @param followModuleInitData The follow module initialization data, if any.
   * @param followNFTURI The URI to use for the follow NFT.
   * @param videoURI The URI to set for the profile video.
   * @param metadataURI The URI to set for the profile metadata.
   * @param metadataHash The hash of the metadata that is in the URI.
   */
  struct CreateProfileData {
    address to;
    string handle;
    string imageURI;
    address followModule;
    bytes followModuleInitData;
    string followNFTURI;
    string videoURI;
    string metadataURI;
    string metadataHash;
  }

  /**
   * @notice A struct containing profile data.
   *
   * @param followModule The address of the current follow module in use by this profile, can be empty.
   * @param followNFT The address of the followNFT associated with this profile, can be empty..
   * @param handle The profile's associated handle.
   * @param imageURI The URI to be used for the profile's image.
   * @param followNFTURI The URI to be used for the follow NFT.
   * @param videoURI The URI to be used for the profile's video.
   * @param metadataURI The URI to be used for the profile's metadata.
   */
  struct CreateProfileEvent {
    address to;
    string handle;
    string imageURI;
    address followModule;
    bytes followModuleReturnData;
    string followNFTURI;
    string videoURI;
    string metadataURI;
  }

  /**
   * @notice A struct containing the parameters required for the `post()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param contentURI The URI to set for this new publication.
   * @param collectModule The collect module to set for this new publication.
   * @param collectModuleInitData The data to pass to the collect module's initialization.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   * @param readModule The read module to set for the given publication, must be whitelisted.
   * @param readModuleInitData The data to be passed to the read module for initialization.
   */
  struct PostData {
    uint256 profileId;
    string contentURI;
    address collectModule;
    bytes collectModuleInitData;
    address referenceModule;
    bytes referenceModuleInitData;
    address readModule;
    bytes readModuleInitData;
  }

  /**
   * @notice A struct containing the parameters required for the `_initPubReferenceModule()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param pubId The publication ID that is being created.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   */
  struct ReferencePostData {
    uint256 profileId;
    uint256 pubId;
    address referenceModule;
    bytes referenceModuleInitData;
  }

  /**
   * @notice A struct containing the parameters required for the `_initPubReadModule()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param pubId The publication ID that is being created.
   * @param readModule The read module to set for the given publication, must be whitelisted.
   * @param readModuleInitData The data to be passed to the read module for initialization.
   */
  struct ReadPostData {
    uint256 profileId;
    uint256 pubId;
    address readModule;
    bytes readModuleInitData;
  }

  /**
   * @notice A struct containing the parameters of the modules associated with the Post.
   *
   * @param collectModule The collect module to set for this new publication.
   * @param collectModuleReturnData The data returned after collect module initialization.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleReturnData The data returned after reference module initialization.
   * @param readModule The read module to set for the given publication, must be whitelisted.
   * @param readModuleReturnData The data returned after read module initialization.
   */
  struct PostModulesData {
    address collectModule;
    bytes collectModuleReturnData;
    address referenceModule;
    bytes referenceModuleReturnData;
    address readModule;
    bytes readModuleReturnData;
  }

  /**
   * @notice A struct containing the parameters required for the `comment()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param contentURI The URI to set for this new publication.
   * @param profileIdPointed The profile token ID to point the comment to.
   * @param pubIdPointed The publication ID to point the comment to.
   * @param referenceModuleData The data passed to the reference module.
   * @param collectModule The collect module to set for this new publication.
   * @param collectModuleInitData The data to pass to the collect module's initialization.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   */
  struct CommentData {
    uint256 profileId;
    string contentURI;
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    bytes referenceModuleData;
    address collectModule;
    bytes collectModuleInitData;
    address referenceModule;
    bytes referenceModuleInitData;
  }

  /**
   * @notice A struct containing the parameters required for the `mirror()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param profileIdPointed The profile token ID to point the mirror to.
   * @param pubIdPointed The publication ID to point the mirror to.
   * @param referenceModuleData The data passed to the reference module.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   */
  struct MirrorData {
    uint256 profileId;
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    bytes referenceModuleData;
    address referenceModule;
    bytes referenceModuleInitData;
  }

  /**
   * @notice A struct containing the percentages parameters required for the move balances function.
   *
   * @param creatorPercentage The percentage that is given to the content creator.
   * @param protocolPercentage The percentage that is given to the protocol.
   * @param appPercentage The percentage that is given to the app.
   * @param fansPercentage The percentage that is given to the fans.
   */
  struct PercentagesData {
    uint256 creatorPercentage;
    uint256 protocolPercentage;
    uint256 appPercentage;
    uint256 fansPercentage;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ILensHub} from "../interfaces/ILensHub.sol";
import {Events} from "../libraries/Events.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {Constants} from "../libraries/Constants.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {PublishingLogic} from "../libraries/PublishingLogic.sol";
import {ProfileTokenURILogic} from "../libraries/ProfileTokenURILogic.sol";
import {InteractionLogic} from "../libraries/InteractionLogic.sol";
import {LensNFTBase} from "./base/LensNFTBase.sol";
import {LensMultiState} from "./base/LensMultiState.sol";
import {LensHubStorage} from "./storage/LensHubStorage.sol";
import {VersionedInitializable} from "../upgradeability/VersionedInitializable.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ERC2771ContextExtended} from "./base/ERC2771ContextExtended.sol";

import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

/**
 * @title LensHub
 * @author Lens Protocol
 *
 * @notice This is the main entrypoint of the Lens Protocol. It contains governance functionality as well as
 * publishing and profile interaction functionality.
 *
 * NOTE: The Lens Protocol is unique in that frontend operators need to track a potentially overwhelming
 * number of NFT contracts and interactions at once. For that reason, we've made two quirky design decisions:
 *      1. Both Follow & Collect NFTs invoke an LensHub callback on transfer with the sole purpose of emitting an event.
 *      2. Almost every event in the protocol emits the current block timestamp, reducing the need to fetch it manually.
 */
contract LensHub is LensNFTBase, VersionedInitializable, LensMultiState, LensHubStorage, ILensHub {
  uint256 internal constant REVISION = 1;

  address internal immutable FOLLOW_NFT_IMPL;
  address internal immutable COLLECT_NFT_IMPL;

  /**
   * @dev This modifier reverts if the caller is not the configured governance address.
   */
  modifier onlyGov() {
    _validateCallerIsGovernance();
    _;
  }

  /**
   * @dev The constructor sets the immutable follow & collect NFT implementations.
   *
   * @param followNFTImpl The follow NFT implementation address.
   * @param collectNFTImpl The collect NFT implementation address.
   */
  constructor(
    address followNFTImpl,
    address collectNFTImpl,
    MinimalForwarder forwarder
  ) ERC2771ContextExtended(address(forwarder)) {
    if (followNFTImpl == address(0)) revert Errors.InitParamsInvalid();
    if (collectNFTImpl == address(0)) revert Errors.InitParamsInvalid();
    FOLLOW_NFT_IMPL = followNFTImpl;
    COLLECT_NFT_IMPL = collectNFTImpl;
  }

  /// @inheritdoc ILensHub
  function initialize(
    string calldata name,
    string calldata symbol,
    address newGovernance
  ) external override initializer {
    super._initialize(name, symbol);
    _setState(DataTypes.ProtocolState.Paused);
    _setGovernance(newGovernance);
  }

  /// ***********************
  /// *****GOV FUNCTIONS*****
  /// ***********************

  /// @inheritdoc ILensHub
  function setGovernance(address newGovernance) external override onlyGov {
    _setGovernance(newGovernance);
  }

  /// @inheritdoc ILensHub
  function setEmergencyAdmin(address newEmergencyAdmin) external override onlyGov {
    address prevEmergencyAdmin = _emergencyAdmin;
    _emergencyAdmin = newEmergencyAdmin;
    emit Events.EmergencyAdminSet(msg.sender, prevEmergencyAdmin, newEmergencyAdmin, block.timestamp);
  }

  /// @inheritdoc ILensHub
  function setState(DataTypes.ProtocolState newState) external override {
    if (msg.sender == _emergencyAdmin) {
      if (newState == DataTypes.ProtocolState.Unpaused) revert Errors.EmergencyAdminCannotUnpause();
      _validateNotPaused();
    } else if (msg.sender != _governance) {
      revert Errors.NotGovernanceOrEmergencyAdmin();
    }
    _setState(newState);
  }

  ///@inheritdoc ILensHub
  function whitelistProfileCreator(address profileCreator, bool whitelist) external override onlyGov {
    _profileCreatorWhitelisted[profileCreator] = whitelist;
    emit Events.ProfileCreatorWhitelisted(profileCreator, whitelist, block.timestamp);
  }

  /// @inheritdoc ILensHub
  function whitelistFollowModule(address followModule, bool whitelist) external override onlyGov {
    _followModuleWhitelisted[followModule] = whitelist;
    emit Events.FollowModuleWhitelisted(followModule, whitelist, block.timestamp);
  }

  /// @inheritdoc ILensHub
  function whitelistReferenceModule(address referenceModule, bool whitelist) external override onlyGov {
    _referenceModuleWhitelisted[referenceModule] = whitelist;
    emit Events.ReferenceModuleWhitelisted(referenceModule, whitelist, block.timestamp);
  }

  /// @inheritdoc ILensHub
  function whitelistCollectModule(address collectModule, bool whitelist) external override onlyGov {
    _collectModuleWhitelisted[collectModule] = whitelist;
    emit Events.CollectModuleWhitelisted(collectModule, whitelist, block.timestamp);
  }

  function whitelistReadModule(address readModule, bool whitelist) external override onlyGov {
    _readModuleWhitelisted[readModule] = whitelist;
    emit Events.ReadModuleWhitelisted(readModule, whitelist, block.timestamp);
  }

  /// *********************************
  /// *****PROFILE OWNER FUNCTIONS*****
  /// *********************************

  /// @inheritdoc ILensHub
  function createProfile(DataTypes.CreateProfileData calldata vars) external override whenNotPaused returns (uint256) {
    if (!_profileCreatorWhitelisted[_msgSender()]) revert Errors.ProfileCreatorNotWhitelisted();
    unchecked {
      uint256 profileId = ++_profileCounter;
      _mint(vars.to, profileId);
      PublishingLogic.createProfile(vars, profileId, _profileIdByHandleHash, _profileById, _followModuleWhitelisted);
      return profileId;
    }
  }

  /// @inheritdoc ILensHub
  function setDefaultProfile(uint256 profileId) external override whenNotPaused {
    _setDefaultProfile(_msgSender(), profileId);
  }

  /// @inheritdoc ILensHub
  function setFollowModule(
    uint256 profileId,
    address followModule,
    bytes calldata followModuleInitData
  ) external override whenNotPaused {
    _validateCallerIsProfileOwner(profileId);
    PublishingLogic.setFollowModule(
      profileId,
      followModule,
      followModuleInitData,
      _profileById[profileId],
      _followModuleWhitelisted
    );
  }

  /// @inheritdoc ILensHub
  function setDispatcher(uint256 profileId, address dispatcher) external override whenNotPaused {
    _validateCallerIsProfileOwner(profileId);
    _setDispatcher(profileId, dispatcher);
  }

  /// @inheritdoc ILensHub
  function setProfileImageURI(uint256 profileId, string calldata imageURI) external override whenNotPaused {
    _validateCallerIsProfileOwnerOrDispatcher(profileId);
    _setProfileImageURI(profileId, imageURI);
  }

  /// @inheritdoc ILensHub
  function setFollowNFTURI(uint256 profileId, string calldata followNFTURI) external override whenNotPaused {
    _validateCallerIsProfileOwnerOrDispatcher(profileId);
    _setFollowNFTURI(profileId, followNFTURI);
  }

  /// @inheritdoc ILensHub
  function setProfileVideoURI(uint256 profileId, string calldata videoURI) external override whenNotPaused {
    _validateCallerIsProfileOwnerOrDispatcher(profileId);
    _setProfileVideoURI(profileId, videoURI);
  }

  /// @inheritdoc ILensHub
  function setProfileMetadataURI(uint256 profileId, string calldata metadataURI) external override whenNotPaused {
    _validateCallerIsProfileOwnerOrDispatcher(profileId);
    _setProfileMetadataURI(profileId, metadataURI);
  }

  /// @inheritdoc ILensHub
  function post(DataTypes.PostData calldata vars) external override whenPublishingEnabled returns (uint256) {
    _validateCallerIsProfileOwnerOrDispatcher(vars.profileId);
    return _createPost(vars);
  }

  /// @inheritdoc ILensHub
  function comment(DataTypes.CommentData calldata vars) external override whenPublishingEnabled returns (uint256) {
    _validateCallerIsProfileOwnerOrDispatcher(vars.profileId);
    return _createComment(vars);
  }

  /// @inheritdoc ILensHub
  function mirror(DataTypes.MirrorData calldata vars) external override whenPublishingEnabled returns (uint256) {
    _validateCallerIsProfileOwnerOrDispatcher(vars.profileId);
    return _createMirror(vars);
  }

  /**
   * @notice Burns a profile, this maintains the profile data struct, but deletes the
   * handle hash to profile ID mapping value.
   *
   * NOTE: This overrides the LensNFTBase contract's `burn()` function and calls it to fully burn
   * the NFT.
   */
  function burn(uint256 tokenId) public override whenNotPaused {
    super.burn(tokenId);
    _clearHandleHash(tokenId);
  }

  /// ***************************************
  /// *****PROFILE INTERACTION FUNCTIONS*****
  /// ***************************************

  /// @inheritdoc ILensHub
  function follow(uint256[] calldata profileIds, bytes[] calldata datas)
    external
    override
    whenNotPaused
    returns (uint256[] memory)
  {
    return InteractionLogic.follow(_msgSender(), profileIds, datas, _profileById, _profileIdByHandleHash);
  }

  /// @inheritdoc ILensHub
  function collect(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external override whenNotPaused returns (uint256) {
    return
      InteractionLogic.collect(_msgSender(), profileId, pubId, data, COLLECT_NFT_IMPL, _pubByIdByProfile, _profileById);
  }

  /// @inheritdoc ILensHub
  function emitFollowNFTTransferEvent(
    uint256 profileId,
    uint256 followNFTId,
    address from,
    address to
  ) external override {
    address expectedFollowNFT = _profileById[profileId].followNFT;
    if (_msgSender() != expectedFollowNFT) revert Errors.CallerNotFollowNFT();
    emit Events.FollowNFTTransferred(profileId, followNFTId, from, to, block.timestamp);
  }

  /// @inheritdoc ILensHub
  function emitCollectNFTTransferEvent(
    uint256 profileId,
    uint256 pubId,
    uint256 collectNFTId,
    address from,
    address to
  ) external override {
    address expectedCollectNFT = _pubByIdByProfile[profileId][pubId].collectNFT;
    if (_msgSender() != expectedCollectNFT) revert Errors.CallerNotCollectNFT();
    emit Events.CollectNFTTransferred(profileId, pubId, collectNFTId, from, to, block.timestamp);
  }

  /// *********************************
  /// *****EXTERNAL VIEW FUNCTIONS*****
  /// *********************************

  /// @inheritdoc ILensHub
  function isProfileCreatorWhitelisted(address profileCreator) external view override returns (bool) {
    return _profileCreatorWhitelisted[profileCreator];
  }

  /// @inheritdoc ILensHub
  function defaultProfile(address wallet) external view override returns (uint256) {
    return _defaultProfileByAddress[wallet];
  }

  /// @inheritdoc ILensHub
  function addTrustedForwarder(address newTrustedForwarder) external override onlyGov {
    _addForwarder(newTrustedForwarder);
  }

  /// @inheritdoc ILensHub
  function removeTrustedForwarder(address newTrustedForwarder) external override onlyGov {
    _deleteForwarder(newTrustedForwarder);
  }

  /// @inheritdoc ILensHub
  function isFollowModuleWhitelisted(address followModule) external view override returns (bool) {
    return _followModuleWhitelisted[followModule];
  }

  /// @inheritdoc ILensHub
  function isReferenceModuleWhitelisted(address referenceModule) external view override returns (bool) {
    return _referenceModuleWhitelisted[referenceModule];
  }

  /// @inheritdoc ILensHub
  function isCollectModuleWhitelisted(address collectModule) external view override returns (bool) {
    return _collectModuleWhitelisted[collectModule];
  }

  /// @inheritdoc ILensHub
  function isReadModuleWhitelisted(address readModule) external view override returns (bool) {
    return _readModuleWhitelisted[readModule];
  }

  /// @inheritdoc ILensHub
  function getGovernance() external view override returns (address) {
    return _governance;
  }

  /// @inheritdoc ILensHub
  function getDispatcher(uint256 profileId) external view override returns (address) {
    return _dispatcherByProfile[profileId];
  }

  /// @inheritdoc ILensHub
  function getPubCount(uint256 profileId) external view override returns (uint256) {
    return _profileById[profileId].pubCount;
  }

  /// @inheritdoc ILensHub
  function getFollowNFT(uint256 profileId) external view override returns (address) {
    return _profileById[profileId].followNFT;
  }

  /// @inheritdoc ILensHub
  function getFollowNFTURI(uint256 profileId) external view override returns (string memory) {
    return _profileById[profileId].followNFTURI;
  }

  /// @inheritdoc ILensHub
  function getCollectNFT(uint256 profileId, uint256 pubId) external view override returns (address) {
    return _pubByIdByProfile[profileId][pubId].collectNFT;
  }

  /// @inheritdoc ILensHub
  function getFollowModule(uint256 profileId) external view override returns (address) {
    return _profileById[profileId].followModule;
  }

  /// @inheritdoc ILensHub
  function getCollectModule(uint256 profileId, uint256 pubId) external view override returns (address) {
    return _pubByIdByProfile[profileId][pubId].collectModule;
  }

  /// @inheritdoc ILensHub
  function getReadModule(uint256 profileId, uint256 pubId) external view override returns (address) {
    return _pubByIdByProfile[profileId][pubId].readModule;
  }

  /// @inheritdoc ILensHub
  function getReferenceModule(uint256 profileId, uint256 pubId) external view override returns (address) {
    return _pubByIdByProfile[profileId][pubId].referenceModule;
  }

  /// @inheritdoc ILensHub
  function getHandle(uint256 profileId) external view override returns (string memory) {
    return _profileById[profileId].handle;
  }

  /// @inheritdoc ILensHub
  function getPubPointer(uint256 profileId, uint256 pubId) external view override returns (uint256, uint256) {
    uint256 profileIdPointed = _pubByIdByProfile[profileId][pubId].profileIdPointed;
    uint256 pubIdPointed = _pubByIdByProfile[profileId][pubId].pubIdPointed;
    return (profileIdPointed, pubIdPointed);
  }

  /// @inheritdoc ILensHub
  function getContentURI(uint256 profileId, uint256 pubId) external view override returns (string memory) {
    (uint256 rootProfileId, uint256 rootPubId, ) = Helpers.getPointedIfMirror(profileId, pubId, _pubByIdByProfile);
    return _pubByIdByProfile[rootProfileId][rootPubId].contentURI;
  }

  /// @inheritdoc ILensHub
  function getProfileIdByHandle(string calldata handle) external view override returns (uint256) {
    bytes32 handleHash = keccak256(bytes(handle));
    return _profileIdByHandleHash[handleHash];
  }

  /// @inheritdoc ILensHub
  function getProfile(uint256 profileId) external view override returns (DataTypes.ProfileStruct memory) {
    return _profileById[profileId];
  }

  /// @inheritdoc ILensHub
  function getPub(uint256 profileId, uint256 pubId)
    external
    view
    override
    returns (DataTypes.PublicationStruct memory)
  {
    return _pubByIdByProfile[profileId][pubId];
  }

  /// @inheritdoc ILensHub
  function getPubType(uint256 profileId, uint256 pubId) external view override returns (DataTypes.PubType) {
    if (pubId == 0 || _profileById[profileId].pubCount < pubId) {
      return DataTypes.PubType.Nonexistent;
    } else if (_pubByIdByProfile[profileId][pubId].collectModule == address(0)) {
      return DataTypes.PubType.Mirror;
    } else if (_pubByIdByProfile[profileId][pubId].profileIdPointed == 0) {
      return DataTypes.PubType.Post;
    } else {
      return DataTypes.PubType.Comment;
    }
  }

  /**
   * @dev Overrides the ERC721 tokenURI function to return the associated URI with a given profile.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    address followNFT = _profileById[tokenId].followNFT;
    return
      ProfileTokenURILogic.getProfileTokenURI(
        tokenId,
        followNFT == address(0) ? 0 : IERC721Enumerable(followNFT).totalSupply(),
        ownerOf(tokenId),
        _profileById[tokenId].handle,
        _profileById[tokenId].imageURI
      );
  }

  /// @inheritdoc ILensHub
  function getFollowNFTImpl() external view override returns (address) {
    return FOLLOW_NFT_IMPL;
  }

  /// @inheritdoc ILensHub
  function getCollectNFTImpl() external view override returns (address) {
    return COLLECT_NFT_IMPL;
  }

  /// ****************************
  /// *****INTERNAL FUNCTIONS*****
  /// ****************************

  function _setGovernance(address newGovernance) internal {
    address prevGovernance = _governance;
    _governance = newGovernance;
    emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance, block.timestamp);
  }

  function _createPost(DataTypes.PostData calldata vars) internal returns (uint256) {
    unchecked {
      uint256 pubId = ++_profileById[vars.profileId].pubCount;
      PublishingLogic.createPost(
        vars,
        pubId,
        _pubByIdByProfile,
        _collectModuleWhitelisted,
        _referenceModuleWhitelisted,
        _readModuleWhitelisted
      );
      return pubId;
    }
  }

  /*
   * If the profile ID is zero, this is the equivalent of "unsetting" a default profile.
   * Note that the wallet address should either be the message sender or validated via a signature
   * prior to this function call.
   */
  function _setDefaultProfile(address wallet, uint256 profileId) internal {
    if (profileId > 0 && wallet != ownerOf(profileId)) revert Errors.NotProfileOwner();

    _defaultProfileByAddress[wallet] = profileId;

    emit Events.DefaultProfileSet(wallet, profileId, block.timestamp);
  }

  function _createComment(DataTypes.CommentData memory vars) internal returns (uint256) {
    unchecked {
      uint256 pubId = ++_profileById[vars.profileId].pubCount;
      PublishingLogic.createComment(
        vars,
        pubId,
        _profileById,
        _pubByIdByProfile,
        _collectModuleWhitelisted,
        _referenceModuleWhitelisted
      );
      return pubId;
    }
  }

  function _createMirror(DataTypes.MirrorData memory vars) internal returns (uint256) {
    unchecked {
      uint256 pubId = ++_profileById[vars.profileId].pubCount;
      PublishingLogic.createMirror(vars, pubId, _pubByIdByProfile, _referenceModuleWhitelisted);
      return pubId;
    }
  }

  function _setDispatcher(uint256 profileId, address dispatcher) internal {
    _dispatcherByProfile[profileId] = dispatcher;
    emit Events.DispatcherSet(profileId, dispatcher, block.timestamp);
  }

  function _setProfileImageURI(uint256 profileId, string calldata imageURI) internal {
    if (bytes(imageURI).length > Constants.MAX_PROFILE_IMAGE_URI_LENGTH) revert Errors.ProfileImageURILengthInvalid();
    _profileById[profileId].imageURI = imageURI;
    emit Events.ProfileImageURISet(profileId, imageURI, block.timestamp);
  }

  function _setFollowNFTURI(uint256 profileId, string calldata followNFTURI) internal {
    _profileById[profileId].followNFTURI = followNFTURI;
    emit Events.FollowNFTURISet(profileId, followNFTURI, block.timestamp);
  }

  function _setProfileVideoURI(uint256 profileId, string calldata videoURI) internal {
    if (bytes(videoURI).length > Constants.MAX_PROFILE_VIDEO_URI_LENGTH) revert Errors.ProfileVideoURILengthInvalid();
    _profileById[profileId].videoURI = videoURI;
    emit Events.ProfileVideoURISet(profileId, videoURI, block.timestamp);
  }

  function _setProfileMetadataURI(uint256 profileId, string calldata metadataURI) internal {
    if (bytes(metadataURI).length > Constants.MAX_PROFILE_METADATA_URI_LENGTH)
      revert Errors.ProfileMetadataURILengthInvalid();
    _profileById[profileId].metadataURI = metadataURI;
    emit Events.ProfileMetadataURISet(profileId, metadataURI, block.timestamp);
  }

  function _clearHandleHash(uint256 profileId) internal {
    bytes32 handleHash = keccak256(bytes(_profileById[profileId].handle));
    _profileIdByHandleHash[handleHash] = 0;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override whenNotPaused {
    if (_dispatcherByProfile[tokenId] != address(0)) {
      _setDispatcher(tokenId, address(0));
    }

    if (_defaultProfileByAddress[from] == tokenId) {
      _defaultProfileByAddress[from] = 0;
    }

    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _validateCallerIsProfileOwnerOrDispatcher(uint256 profileId) internal view {
    if (_msgSender() == ownerOf(profileId) || _msgSender() == _dispatcherByProfile[profileId]) {
      return;
    }
    revert Errors.NotProfileOwnerOrDispatcher();
  }

  function _validateCallerIsProfileOwner(uint256 profileId) internal view {
    if (_msgSender() != ownerOf(profileId)) revert Errors.NotProfileOwner();
  }

  function _validateCallerIsGovernance() internal view {
    if (msg.sender != _governance) revert Errors.NotGovernance();
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return REVISION;
  }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ILensHub {
  /**
   * @notice Initializes the LensHub NFT, setting the initial governance address as well as the name and symbol in
   * the LensNFTBase contract.
   *
   * @param name The name to set for the hub NFT.
   * @param symbol The symbol to set for the hub NFT.
   * @param newGovernance The governance address to set.
   */
  function initialize(
    string calldata name,
    string calldata symbol,
    address newGovernance
  ) external;

  /**
   * @notice Sets the privileged governance role. This function can only be called by the current governance
   * address.
   *
   * @param newGovernance The new governance address to set.
   */
  function setGovernance(address newGovernance) external;

  /**
   * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
   * can only be called by the governance address.
   *
   * @param newEmergencyAdmin The new emergency admin address to set.
   */
  function setEmergencyAdmin(address newEmergencyAdmin) external;

  /**
   * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
   * can only be called by the governance address or the emergency admin address.
   *
   * Note that this reverts if the emergency admin calls it if:
   *      1. The emergency admin is attempting to unpause.
   *      2. The emergency admin is calling while the protocol is already paused.
   *
   * @param newState The state to set, as a member of the ProtocolState enum.
   */
  function setState(DataTypes.ProtocolState newState) external;

  /**
   * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param profileCreator The profile creator address to add or remove from the whitelist.
   * @param whitelist Whether or not the profile creator should be whitelisted.
   */
  function whitelistProfileCreator(address profileCreator, bool whitelist) external;

  /**
   * @notice Adds or removes a follow module from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param followModule The follow module contract address to add or remove from the whitelist.
   * @param whitelist Whether or not the follow module should be whitelisted.
   */
  function whitelistFollowModule(address followModule, bool whitelist) external;

  /**
   * @notice Adds or removes a reference module from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param referenceModule The reference module contract to add or remove from the whitelist.
   * @param whitelist Whether or not the reference module should be whitelisted.
   */
  function whitelistReferenceModule(address referenceModule, bool whitelist) external;

  /**
   * @notice Adds or removes a collect module from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param collectModule The collect module contract address to add or remove from the whitelist.
   * @param whitelist Whether or not the collect module should be whitelisted.
   */
  function whitelistCollectModule(address collectModule, bool whitelist) external;

  /**
   * @notice Adds or removes a collect module from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param readModule The collect module contract address to add or remove from the whitelist.
   * @param whitelist Whether or not the collect module should be whitelisted.
   */
  function whitelistReadModule(address readModule, bool whitelist) external;

  /**
   * @notice Creates a profile with the specified parameters, minting a profile NFT to the given recipient. This
   * function must be called by a whitelisted profile creator.
   *
   * @param vars A CreateProfileData struct containing the following params:
   *      to: The address receiving the profile.
   *      handle: The handle to set for the profile, must be unique and non-empty.
   *      imageURI: The URI to set for the profile image.
   *      followModule: The follow module to use, can be the zero address.
   *      followModuleInitData: The follow module initialization data, if any.
   *      videoURI The URI to set for the profile video.
   *      metadataURI The URI to set for the profile metadata.
   */
  function createProfile(DataTypes.CreateProfileData calldata vars) external returns (uint256);

  /**
   * @notice Sets the mapping between wallet and its main profile identity.
   *
   * @param profileId The token ID of the profile to set as the main profile identity.
   */
  function setDefaultProfile(uint256 profileId) external;

  /**
   * @notice Sets a profile's follow module, must be called by the profile owner.
   *
   * @param profileId The token ID of the profile to set the follow module for.
   * @param followModule The follow module to set for the given profile, must be whitelisted.
   * @param followModuleInitData The data to be passed to the follow module for initialization.
   */
  function setFollowModule(
    uint256 profileId,
    address followModule,
    bytes calldata followModuleInitData
  ) external;

  /**
   * @notice Sets a profile's dispatcher, giving that dispatcher rights to publish to that profile.
   *
   * @param profileId The token ID of the profile of the profile to set the dispatcher for.
   * @param dispatcher The dispatcher address to set for the given profile ID.
   */
  function setDispatcher(uint256 profileId, address dispatcher) external;

  /**
   * @notice Sets a profile's URI, which is reflected in the `tokenURI()` function.
   *
   * @param profileId The token ID of the profile of the profile to set the URI for.
   * @param imageURI The URI to set for the given profile.
   */
  function setProfileImageURI(uint256 profileId, string calldata imageURI) external;

  /**
   * @notice Sets a followNFT URI for a given profile's follow NFT.
   *
   * @param profileId The token ID of the profile for which to set the followNFT URI.
   * @param followNFTURI The follow NFT URI to set.
   */
  function setFollowNFTURI(uint256 profileId, string calldata followNFTURI) external;

  /**
   * @notice Sets a profile's URI, which is reflected in the `tokenURI()` function.
   *
   * @param profileId The token ID of the profile of the profile to set the URI for.
   * @param videoURI The URI to set for the given profile.
   */
  function setProfileVideoURI(uint256 profileId, string calldata videoURI) external;

  /**
   * @notice Sets a profile's URI, which is reflected in the `tokenURI()` function.
   *
   * @param profileId The token ID of the profile of the profile to set the URI for.
   * @param metadataURI The URI to set for the given profile.
   */
  function setProfileMetadataURI(uint256 profileId, string calldata metadataURI) external;

  /**
   * @notice Publishes a post to a given profile, must be called by the profile owner.
   *
   * @param vars A PostData struct containing the needed parameters.
   *
   * @return uint256 An integer representing the post's publication ID.
   */
  function post(DataTypes.PostData calldata vars) external returns (uint256);

  /**
   * @notice Publishes a comment to a given profile, must be called by the profile owner.
   *
   * @param vars A CommentData struct containing the needed parameters.
   *
   * @return uint256 An integer representing the comment's publication ID.
   */
  function comment(DataTypes.CommentData calldata vars) external returns (uint256);

  /**
   * @notice Publishes a mirror to a given profile, must be called by the profile owner.
   *
   * @param vars A MirrorData struct containing the necessary parameters.
   *
   * @return uint256 An integer representing the mirror's publication ID.
   */
  function mirror(DataTypes.MirrorData calldata vars) external returns (uint256);

  /**
   * @notice Follows the given profiles, executing each profile's follow module logic (if any) and minting followNFTs to the caller.
   *
   * NOTE: Both the `profileIds` and `datas` arrays must be of the same length, regardless if the profiles do not have a follow module set.
   *
   * @param profileIds The token ID array of the profiles to follow.
   * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
   *
   * @return uint256[] An array of integers representing the minted follow NFTs token IDs.
   */
  function follow(uint256[] calldata profileIds, bytes[] calldata datas) external returns (uint256[] memory);

  /**
   * @notice Collects a given publication, executing collect module logic and minting a collectNFT to the caller.
   *
   * @param profileId The token ID of the profile that published the publication to collect.
   * @param pubId The publication to collect's publication ID.
   * @param data The arbitrary data to pass to the collect module if needed.
   *
   * @return uint256 An integer representing the minted token ID.
   */
  function collect(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external returns (uint256);

  /**
   * @dev Helper function to emit a detailed followNFT transfer event from the hub, to be consumed by frontends to track
   * followNFT transfers.
   *
   * @param profileId The token ID of the profile associated with the followNFT being transferred.
   * @param followNFTId The followNFT being transferred's token ID.
   * @param from The address the followNFT is being transferred from.
   * @param to The address the followNFT is being transferred to.
   */
  function emitFollowNFTTransferEvent(
    uint256 profileId,
    uint256 followNFTId,
    address from,
    address to
  ) external;

  /**
   * @dev Helper function to emit a detailed collectNFT transfer event from the hub, to be consumed by frontends to track
   * collectNFT transfers.
   *
   * @param profileId The token ID of the profile associated with the collect NFT being transferred.
   * @param pubId The publication ID associated with the collect NFT being transferred.
   * @param collectNFTId The collectNFT being transferred's token ID.
   * @param from The address the collectNFT is being transferred from.
   * @param to The address the collectNFT is being transferred to.
   */
  function emitCollectNFTTransferEvent(
    uint256 profileId,
    uint256 pubId,
    uint256 collectNFTId,
    address from,
    address to
  ) external;

  /// ************************
  /// *****VIEW FUNCTIONS*****
  /// ************************

  /**
   * @notice Returns whether or not a profile creator is whitelisted.
   *
   * @param profileCreator The address of the profile creator to check.
   *
   * @return bool True if the profile creator is whitelisted, false otherwise.
   */
  function isProfileCreatorWhitelisted(address profileCreator) external view returns (bool);

  /**
   * @notice Returns default profile for a given wallet address
   *
   * @param wallet The address to find the default mapping
   *
   * @return uint256 The default profile id, which will be 0 if not mapped.
   */
  function defaultProfile(address wallet) external view returns (uint256);

  /**
   * @notice Returns whether or not a follow module is whitelisted.
   *
   * @param followModule The address of the follow module to check.
   *
   * @return bool True if the the follow module is whitelisted, false otherwise.
   */
  function isFollowModuleWhitelisted(address followModule) external view returns (bool);

  /**
   * @notice Returns whether or not a reference module is whitelisted.
   *
   * @param referenceModule The address of the reference module to check.
   *
   * @return bool True if the the reference module is whitelisted, false otherwise.
   */
  function isReferenceModuleWhitelisted(address referenceModule) external view returns (bool);

  /**
   * @notice Returns whether or not a collect module is whitelisted.
   *
   * @param collectModule The address of the collect module to check.
   *
   * @return bool True if the the collect module is whitelisted, false otherwise.
   */
  function isCollectModuleWhitelisted(address collectModule) external view returns (bool);

  /**
   * @notice Returns whether or not a read module is whitelisted.
   *
   * @param readModule The address of the read module to check.
   *
   * @return bool True if the the read module is whitelisted, false otherwise.
   */
  function isReadModuleWhitelisted(address readModule) external view returns (bool);

  /**
   * @notice Returns the currently configured governance address.
   *
   * @return address The address of the currently configured governance.
   */
  function getGovernance() external view returns (address);

  /**
   * @notice Returns the dispatcher associated with a profile.
   *
   * @param profileId The token ID of the profile to query the dispatcher for.
   *
   * @return address The dispatcher address associated with the profile.
   */
  function getDispatcher(uint256 profileId) external view returns (address);

  /**
   * @notice Returns the publication count for a given profile.
   *
   * @param profileId The token ID of the profile to query.
   *
   * @return uint256 The number of publications associated with the queried profile.
   */
  function getPubCount(uint256 profileId) external view returns (uint256);

  /**
   * @notice Returns the followNFT associated with a given profile, if any.
   *
   * @param profileId The token ID of the profile to query the followNFT for.
   *
   * @return address The followNFT associated with the given profile.
   */
  function getFollowNFT(uint256 profileId) external view returns (address);

  /**
   * @notice Returns the followNFT URI associated with a given profile.
   *
   * @param profileId The token ID of the profile to query the followNFT URI for.
   *
   * @return string The followNFT URI associated with the given profile.
   */
  function getFollowNFTURI(uint256 profileId) external view returns (string memory);

  /**
   * @notice Returns the collectNFT associated with a given publication, if any.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return address The address of the collectNFT associated with the queried publication.
   */
  function getCollectNFT(uint256 profileId, uint256 pubId) external view returns (address);

  /**
   * @notice Returns the follow module associated witha  given profile, if any.
   *
   * @param profileId The token ID of the profile to query the follow module for.
   *
   * @return address The address of the follow module associated with the given profile.
   */
  function getFollowModule(uint256 profileId) external view returns (address);

  /**
   * @notice Returns the collect module associated with a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return address The address of the collect module associated with the queried publication.
   */
  function getCollectModule(uint256 profileId, uint256 pubId) external view returns (address);

  /**
   * @notice Returns the reference module associated witha  given profile, if any.
   *
   * @param profileId The token ID of the profile that published the publication to querythe reference module for.
   * @param pubId The publication ID of the publication to query the reference module for.
   *
   * @return address The address of the reference module associated with the given profile.
   */
  function getReferenceModule(uint256 profileId, uint256 pubId) external view returns (address);

  /**
   * @notice Returns the read module associated witha  given profile, if any.
   *
   * @param profileId The token ID of the profile that published the publication to querythe read module for.
   * @param pubId The publication ID of the publication to query the read module for.
   *
   * @return address The address of the read module associated with the given profile.
   */
  function getReadModule(uint256 profileId, uint256 pubId) external view returns (address);

  /**
   * @notice Returns the handle associated with a profile.
   *
   * @param profileId The token ID of the profile to query the handle for.
   *
   * @return string The handle associated with the profile.
   */
  function getHandle(uint256 profileId) external view returns (string memory);

  /**
   * @notice Returns the publication pointer (profileId & pubId) associated with a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query the pointer for.
   * @param pubId The publication ID of the publication to query the pointer for.
   *
   * @return tuple First, the profile ID of the profile the current publication is pointing to, second, the
   * publication ID of the publication the current publication is pointing to.
   */
  function getPubPointer(uint256 profileId, uint256 pubId) external view returns (uint256, uint256);

  /**
   * @notice Returns the URI associated with a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return string The URI associated with a given publication.
   */
  function getContentURI(uint256 profileId, uint256 pubId) external view returns (string memory);

  /**
   * @notice Returns the profile token ID according to a given handle.
   *
   * @param handle The handle to resolve the profile token ID with.
   *
   * @return uint256 The profile ID the passed handle points to.
   */
  function getProfileIdByHandle(string calldata handle) external view returns (uint256);

  /**
   * @notice Returns the full profile struct associated with a given profile token ID.
   *
   * @param profileId The token ID of the profile to query.
   *
   * @return ProfileStruct The profile struct of the given profile.
   */
  function getProfile(uint256 profileId) external view returns (DataTypes.ProfileStruct memory);

  /**
   * @notice Returns the full publication struct for a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return PublicationStruct The publication struct associated with the queried publication.
   */
  function getPub(uint256 profileId, uint256 pubId) external view returns (DataTypes.PublicationStruct memory);

  /**
   * @notice Returns the publication type associated with a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return PubType The publication type, as a member of an enum (either "post," "comment" or "mirror").
   */
  function getPubType(uint256 profileId, uint256 pubId) external view returns (DataTypes.PubType);

  /**
   * @notice Returns the follow NFT implementation address.
   *
   * @return address The follow NFT implementation address.
   */
  function getFollowNFTImpl() external view returns (address);

  /**
   * @notice Returns the collect NFT implementation address.
   *
   * @return address The collect NFT implementation address.
   */
  function getCollectNFTImpl() external view returns (address);

  /**
   * @notice Adds a new trusted forwarder to use as relayer service.
   *
   * @param newTrustedForwarder The address of the new trusted forwarder.
   */
  function addTrustedForwarder(address newTrustedForwarder) external;

  /**
   * @notice Removes a forwarder form the trusted list, and therefore cannot be to use as relayer service.
   *
   * @param forwarder The address of the forwarder to remove.
   */
  function removeTrustedForwarder(address forwarder) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";

/**
 * @title Helpers
 * @author Lens Protocol
 *
 * @notice This is a library that only contains a single function that is used in the hub contract as well as in
 * both the publishing logic and interaction logic libraries.
 */
library Helpers {
  /**
   * @notice This helper function just returns the pointed publication if the passed publication is a mirror,
   * otherwise it returns the passed publication.
   *
   * @param profileId The token ID of the profile that published the given publication.
   * @param pubId The publication ID of the given publication.
   * @param _pubByIdByProfile A pointer to the storage mapping of publications by pubId by profile ID.
   *
   * @return tuple First, the pointed publication's publishing profile ID, second, the pointed publication's ID, and third, the
   * pointed publication's collect module. If the passed publication is not a mirror, this returns the given publication.
   */
  function getPointedIfMirror(
    uint256 profileId,
    uint256 pubId,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile
  )
    internal
    view
    returns (
      uint256,
      uint256,
      address
    )
  {
    address collectModule = _pubByIdByProfile[profileId][pubId].collectModule;
    if (collectModule != address(0)) {
      return (profileId, pubId, collectModule);
    } else {
      uint256 pointedTokenId = _pubByIdByProfile[profileId][pubId].profileIdPointed;
      // We validate existence here as an optimization, so validating in calling contracts is unnecessary
      if (pointedTokenId == 0) revert Errors.PublicationDoesNotExist();

      uint256 pointedPubId = _pubByIdByProfile[profileId][pubId].pubIdPointed;

      address pointedCollectModule = _pubByIdByProfile[pointedTokenId][pointedPubId].collectModule;

      return (pointedTokenId, pointedPubId, pointedCollectModule);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Constants {
  string internal constant FOLLOW_NFT_NAME_SUFFIX = "-Follower";
  string internal constant FOLLOW_NFT_SYMBOL_SUFFIX = "-Fl";
  string internal constant COLLECT_NFT_NAME_INFIX = "-Collect-";
  string internal constant COLLECT_NFT_SYMBOL_INFIX = "-Cl-";
  uint8 internal constant MAX_HANDLE_LENGTH = 31;
  uint16 internal constant MAX_PROFILE_IMAGE_URI_LENGTH = 6000;
  uint16 internal constant MAX_PROFILE_VIDEO_URI_LENGTH = 6000;
  uint16 internal constant MAX_PROFILE_METADATA_URI_LENGTH = 6000;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Helpers} from "./Helpers.sol";
import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";
import {Events} from "./Events.sol";
import {Constants} from "./Constants.sol";
import {IFollowModule} from "../interfaces/IFollowModule.sol";
import {ICollectModule} from "../interfaces/ICollectModule.sol";
import {IReferenceModule} from "../interfaces/IReferenceModule.sol";
import {IReadModule} from "../interfaces/IReadModule.sol";

/**
 * @title PublishingLogic
 * @author Lens Protocol
 *
 * @notice This is the library that contains the logic for profile creation & publication.
 *
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood. Furthermore,
 * expected events are emitted from this library instead of from the hub to alleviate code size concerns.
 */
library PublishingLogic {
  /**
   * @notice Executes the logic to create a profile with the given parameters to the given address.
   *
   * @param vars The CreateProfileData struct containing the following parameters:
   *      to: The address receiving the profile.
   *      handle: The handle to set for the profile, must be unique and non-empty.
   *      imageURI: The URI to set for the profile image.
   *      followModule: The follow module to use, can be the zero address.
   *      followModuleInitData: The follow module initialization data, if any
   *      followNFTURI: The URI to set for the follow NFT.
   *      videoURI The URI to set for the profile video.
   *      metadataURI The URI to set for the profile metadata.
   *      metadataHash The hash of the metadata that is in the URI.
   * @param profileId The profile ID to associate with this profile NFT (token ID).
   * @param _profileIdByHandleHash The storage reference to the mapping of profile IDs by handle hash.
   * @param _profileById The storage reference to the mapping of profile structs by IDs.
   * @param _followModuleWhitelisted The storage reference to the mapping of whitelist status by follow module address.
   */
  function createProfile(
    DataTypes.CreateProfileData calldata vars,
    uint256 profileId,
    mapping(bytes32 => uint256) storage _profileIdByHandleHash,
    mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
    mapping(address => bool) storage _followModuleWhitelisted
  ) external {
    _validateHandle(vars.handle);

    if (bytes(vars.imageURI).length > Constants.MAX_PROFILE_IMAGE_URI_LENGTH)
      revert Errors.ProfileImageURILengthInvalid();

    bytes32 handleHash = keccak256(bytes(vars.handle));

    if (_profileIdByHandleHash[handleHash] != 0) revert Errors.HandleTaken();

    _profileIdByHandleHash[handleHash] = profileId;
    _profileById[profileId].handle = vars.handle;
    _profileById[profileId].imageURI = vars.imageURI;
    _profileById[profileId].followNFTURI = vars.followNFTURI;
    _profileById[profileId].videoURI = vars.videoURI;
    _profileById[profileId].metadataURI = vars.metadataURI;
    _profileById[profileId].metadataHash = vars.metadataHash;

    bytes memory followModuleReturnData;
    if (vars.followModule != address(0)) {
      _profileById[profileId].followModule = vars.followModule;
      followModuleReturnData = _initFollowModule(
        profileId,
        vars.followModule,
        vars.followModuleInitData,
        _followModuleWhitelisted
      );
    }

    _emitProfileCreated(profileId, vars, followModuleReturnData);
  }

  /**
   * @notice Sets the follow module for a given profile.
   *
   * @param profileId The profile ID to set the follow module for.
   * @param followModule The follow module to set for the given profile, if any.
   * @param followModuleInitData The data to pass to the follow module for profile initialization.
   * @param _profile The storage reference to the profile struct associated with the given profile ID.
   * @param _followModuleWhitelisted The storage reference to the mapping of whitelist status by follow module address.
   */
  function setFollowModule(
    uint256 profileId,
    address followModule,
    bytes calldata followModuleInitData,
    DataTypes.ProfileStruct storage _profile,
    mapping(address => bool) storage _followModuleWhitelisted
  ) external {
    if (followModule != _profile.followModule) {
      _profile.followModule = followModule;
    }

    bytes memory followModuleReturnData;
    if (followModule != address(0))
      followModuleReturnData = _initFollowModule(
        profileId,
        followModule,
        followModuleInitData,
        _followModuleWhitelisted
      );
    emit Events.FollowModuleSet(profileId, followModule, followModuleReturnData, block.timestamp);
  }

  /**
   * @notice Creates a post publication mapped to the given profile.
   *
   * @dev To avoid a stack too deep error, reference parameters are passed in memory rather than calldata.
   *
   * @param vars A PostData struct containing the needed parameters.
   * @param pubId The publication ID to associate with this publication.
   * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
   * @param _collectModuleWhitelisted The storage reference to the mapping of whitelist status by collect module address.
   * @param _referenceModuleWhitelisted The storage reference to the mapping of whitelist status by reference module address.
   * @param _readModuleWhitelisted The storage reference to the mapping of whitelist status by read module address.
   */
  function createPost(
    DataTypes.PostData calldata vars,
    uint256 pubId,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _collectModuleWhitelisted,
    mapping(address => bool) storage _referenceModuleWhitelisted,
    mapping(address => bool) storage _readModuleWhitelisted
  ) external {
    _pubByIdByProfile[vars.profileId][pubId].contentURI = vars.contentURI;

    // Collect module initialization
    bytes memory collectModuleReturnData = _initPubCollectModule(
      vars.profileId,
      pubId,
      vars.collectModule,
      vars.collectModuleInitData,
      _pubByIdByProfile,
      _collectModuleWhitelisted
    );

    // Reference module initialization
    bytes memory referenceModuleReturnData = _initPubReferenceModule(
      vars.profileId,
      pubId,
      vars.referenceModule,
      vars.referenceModuleInitData,
      _pubByIdByProfile,
      _referenceModuleWhitelisted
    );

    DataTypes.ReadPostData memory readPostData = DataTypes.ReadPostData({
      profileId: vars.profileId,
      pubId: pubId,
      readModule: vars.readModule,
      readModuleInitData: vars.readModuleInitData
    });
    bytes memory readModuleReturnData = _initPubReadModule(readPostData, _pubByIdByProfile, _readModuleWhitelisted);

    DataTypes.PostModulesData memory postModulesData = DataTypes.PostModulesData({
      collectModule: vars.collectModule,
      collectModuleReturnData: collectModuleReturnData,
      referenceModule: vars.referenceModule,
      referenceModuleReturnData: referenceModuleReturnData,
      readModule: vars.readModule,
      readModuleReturnData: readModuleReturnData
    });

    emit Events.PostCreated(vars.profileId, pubId, vars.contentURI, postModulesData, block.timestamp);
  }

  /**
   * @notice Creates a comment publication mapped to the given profile.
   *
   * @dev This function is unique in that it requires many variables, so, unlike the other publishing functions,
   * we need to pass the full CommentData struct in memory to avoid a stack too deep error.
   *
   * @param vars The CommentData struct to use to create the comment.
   * @param pubId The publication ID to associate with this publication.
   * @param _profileById The storage reference to the mapping of profile structs by IDs.
   * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
   * @param _collectModuleWhitelisted The storage reference to the mapping of whitelist status by collect module address.
   * @param _referenceModuleWhitelisted The storage reference to the mapping of whitelist status by reference module address.
   */
  function createComment(
    DataTypes.CommentData memory vars,
    uint256 pubId,
    mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _collectModuleWhitelisted,
    mapping(address => bool) storage _referenceModuleWhitelisted
  ) external {
    // Validate existence of the pointed publication
    uint256 pubCount = _profileById[vars.profileIdPointed].pubCount;
    if (pubCount < vars.pubIdPointed || vars.pubIdPointed == 0) revert Errors.PublicationDoesNotExist();

    // Ensure the pointed publication is not the comment being created
    if (vars.profileId == vars.profileIdPointed && vars.pubIdPointed == pubId) revert Errors.CannotCommentOnSelf();

    _pubByIdByProfile[vars.profileId][pubId].contentURI = vars.contentURI;
    _pubByIdByProfile[vars.profileId][pubId].profileIdPointed = vars.profileIdPointed;
    _pubByIdByProfile[vars.profileId][pubId].pubIdPointed = vars.pubIdPointed;

    // Collect Module Initialization
    bytes memory collectModuleReturnData = _initPubCollectModule(
      vars.profileId,
      pubId,
      vars.collectModule,
      vars.collectModuleInitData,
      _pubByIdByProfile,
      _collectModuleWhitelisted
    );

    // Reference module initialization
    bytes memory referenceModuleReturnData = _initPubReferenceModule(
      vars.profileId,
      pubId,
      vars.referenceModule,
      vars.referenceModuleInitData,
      _pubByIdByProfile,
      _referenceModuleWhitelisted
    );

    // Reference module validation
    address refModule = _pubByIdByProfile[vars.profileIdPointed][vars.pubIdPointed].referenceModule;
    if (refModule != address(0)) {
      IReferenceModule(refModule).processComment(
        vars.profileId,
        vars.profileIdPointed,
        vars.pubIdPointed,
        vars.referenceModuleData
      );
    }

    // Prevents a stack too deep error
    _emitCommentCreated(vars, pubId, collectModuleReturnData, referenceModuleReturnData);
  }

  /**
   * @notice Creates a mirror publication mapped to the given profile.
   *
   * @param vars The MirrorData struct to use to create the mirror.
   * @param pubId The publication ID to associate with this publication.
   * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
   * @param _referenceModuleWhitelisted The storage reference to the mapping of whitelist status by reference module address.
   */
  function createMirror(
    DataTypes.MirrorData memory vars,
    uint256 pubId,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _referenceModuleWhitelisted
  ) external {
    (uint256 rootProfileIdPointed, uint256 rootPubIdPointed, ) = Helpers.getPointedIfMirror(
      vars.profileIdPointed,
      vars.pubIdPointed,
      _pubByIdByProfile
    );

    _pubByIdByProfile[vars.profileId][pubId].profileIdPointed = rootProfileIdPointed;
    _pubByIdByProfile[vars.profileId][pubId].pubIdPointed = rootPubIdPointed;

    // Reference module initialization
    bytes memory referenceModuleReturnData = _initPubReferenceModule(
      vars.profileId,
      pubId,
      vars.referenceModule,
      vars.referenceModuleInitData,
      _pubByIdByProfile,
      _referenceModuleWhitelisted
    );

    // Reference module validation
    address refModule = _pubByIdByProfile[rootProfileIdPointed][rootPubIdPointed].referenceModule;
    if (refModule != address(0)) {
      IReferenceModule(refModule).processMirror(
        vars.profileId,
        rootProfileIdPointed,
        rootPubIdPointed,
        vars.referenceModuleData
      );
    }

    emit Events.MirrorCreated(
      vars.profileId,
      pubId,
      rootProfileIdPointed,
      rootPubIdPointed,
      vars.referenceModuleData,
      vars.referenceModule,
      referenceModuleReturnData,
      block.timestamp
    );
  }

  function _initPubCollectModule(
    uint256 profileId,
    uint256 pubId,
    address collectModule,
    bytes memory collectModuleInitData,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _collectModuleWhitelisted
  ) private returns (bytes memory) {
    if (!_collectModuleWhitelisted[collectModule]) revert Errors.CollectModuleNotWhitelisted();
    _pubByIdByProfile[profileId][pubId].collectModule = collectModule;
    return ICollectModule(collectModule).initializePublicationCollectModule(profileId, pubId, collectModuleInitData);
  }

  function _initPubReferenceModule(
    uint256 profileId,
    uint256 pubId,
    address referenceModule,
    bytes memory referenceModuleInitData,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _referenceModuleWhitelisted
  ) private returns (bytes memory) {
    if (referenceModule == address(0)) return new bytes(0);
    if (!_referenceModuleWhitelisted[referenceModule]) revert Errors.ReferenceModuleNotWhitelisted();
    _pubByIdByProfile[profileId][pubId].referenceModule = referenceModule;
    return IReferenceModule(referenceModule).initializeReferenceModule(profileId, pubId, referenceModuleInitData);
  }

  function _initFollowModule(
    uint256 profileId,
    address followModule,
    bytes memory followModuleInitData,
    mapping(address => bool) storage _followModuleWhitelisted
  ) private returns (bytes memory) {
    if (!_followModuleWhitelisted[followModule]) revert Errors.FollowModuleNotWhitelisted();
    return IFollowModule(followModule).initializeFollowModule(profileId, followModuleInitData);
  }

  function _initPubReadModule(
    DataTypes.ReadPostData memory vars,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _readModuleWhitelisted
  ) private returns (bytes memory) {
    if (vars.readModule == address(0)) return new bytes(0);
    if (!_readModuleWhitelisted[vars.readModule]) revert Errors.ReadModuleNotWhitelisted();
    _pubByIdByProfile[vars.profileId][vars.pubId].readModule = vars.readModule;
    return
      IReadModule(vars.readModule).initializePublicationReadModule(vars.profileId, vars.pubId, vars.readModuleInitData);
  }

  function _emitCommentCreated(
    DataTypes.CommentData memory vars,
    uint256 pubId,
    bytes memory collectModuleReturnData,
    bytes memory referenceModuleReturnData
  ) private {
    emit Events.CommentCreated(
      vars.profileId,
      pubId,
      vars.contentURI,
      vars.profileIdPointed,
      vars.pubIdPointed,
      vars.referenceModuleData,
      vars.collectModule,
      collectModuleReturnData,
      vars.referenceModule,
      referenceModuleReturnData,
      block.timestamp
    );
  }

  function _emitProfileCreated(
    uint256 profileId,
    DataTypes.CreateProfileData calldata vars,
    bytes memory followModuleReturnData
  ) internal {
    DataTypes.CreateProfileEvent memory eventVars = DataTypes.CreateProfileEvent({
      to: vars.to,
      handle: vars.handle,
      imageURI: vars.imageURI,
      followModule: vars.followModule,
      followModuleReturnData: followModuleReturnData,
      followNFTURI: vars.followNFTURI,
      videoURI: vars.videoURI,
      metadataURI: vars.metadataURI
    });

    emit Events.ProfileCreated(
      profileId,
      msg.sender, // Creator is always the msg sender
      eventVars,
      block.timestamp
    );
  }

  function _validateHandle(string calldata handle) private pure {
    bytes memory byteHandle = bytes(handle);
    if (byteHandle.length == 0 || byteHandle.length > Constants.MAX_HANDLE_LENGTH) revert Errors.HandleLengthInvalid();

    uint256 byteHandleLength = byteHandle.length;
    for (uint256 i = 0; i < byteHandleLength; ) {
      if (
        (byteHandle[i] < "0" || byteHandle[i] > "z" || (byteHandle[i] > "9" && byteHandle[i] < "a")) &&
        byteHandle[i] != "." &&
        byteHandle[i] != "-" &&
        byteHandle[i] != "_"
      ) revert Errors.HandleContainsInvalidCharacters();
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library ProfileTokenURILogic {
  uint8 internal constant DEFAULT_FONT_SIZE = 24;
  uint8 internal constant MAX_HANDLE_LENGTH_WITH_DEFAULT_FONT_SIZE = 17;

  /**
   * @notice Generates the token URI for the profile NFT.
   *
   * @dev The decoded token URI JSON metadata contains the following fields: name, description, image and attributes.
   * The image field contains a base64-encoded SVG. Both the JSON metadata and the image are generated fully on-chain.
   *
   * @param id The token ID of the profile.
   * @param followers The number of profile's followers.
   * @param owner The address which owns the profile.
   * @param handle The profile's handle.
   * @param imageURI The profile's picture URI. An empty string if has not been set.
   *
   * @return string The profile's token URI as a base64-encoded JSON string.
   */
  function getProfileTokenURI(
    uint256 id,
    uint256 followers,
    address owner,
    string memory handle,
    string memory imageURI
  ) external pure returns (string memory) {
    string memory handleWithAtSymbol = string(abi.encodePacked("@", handle));
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              handleWithAtSymbol,
              '","description":"',
              handleWithAtSymbol,
              ' - Lens profile","image":"data:image/svg+xml;base64,',
              _getSVGImageBase64Encoded(handleWithAtSymbol, imageURI),
              '","attributes":[{"trait_type":"id","value":"#',
              Strings.toString(id),
              '"},{"trait_type":"followers","value":"',
              Strings.toString(followers),
              '"},{"trait_type":"owner","value":"',
              Strings.toHexString(uint160(owner)),
              '"},{"trait_type":"handle","value":"',
              handleWithAtSymbol,
              '"}]}'
            )
          )
        )
      );
  }

  /**
   * @notice Generates the token image.
   *
   * @dev If the image URI was set and meets URI format conditions, it will be embedded in the token image.
   * Otherwise, a default picture will be used. Handle font size is a function of handle length.
   *
   * @param handleWithAtSymbol The profile's handle beginning with "@" symbol.
   * @param imageURI The profile's picture URI. An empty string if has not been set.
   *
   * @return string The profile token image as a base64-encoded SVG.
   */
  function _getSVGImageBase64Encoded(string memory handleWithAtSymbol, string memory imageURI)
    internal
    pure
    returns (string memory)
  {
    return
      Base64.encode(
        abi.encodePacked(
          '<svg width="450" height="450" viewBox="0 0 450 450" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><style>@font-face{font-family:"Space Grotesk";src:url(data:application/font-woff;charset=utf-8;base64,d09GRgABAAAAABdkAAwAAAAAL9QAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAABHUE9TAAABHAAAAoAAAAk8PvUwqU9TLzIAAAOcAAAATQAAAGATnCUlY21hcAAAA+wAAACHAAABctDw6HNnYXNwAAAEdAAAAAgAAAAIAAAAEGdseWYAAAR8AAAO/QAAHeShD1G1aGVhZAAAE3wAAAA2AAAANhn88zloaGVhAAATtAAAAB0AAAAkA80DM2htdHgAABPUAAAA9QAAAVCuDg9sbG9jYQAAFMwAAACqAAAAqkExOixtYXhwAAAVeAAAABYAAAAgAFkAVW5hbWUAABWQAAABvQAAA3L4aVZRcG9zdAAAF1AAAAAUAAAAIP+fAIZ4nM1VQU8TQRT+urvdra0tUKmIIonRlNiqqchJE+PB6MWDJv4BD3rRcDCa+AM8+KuMF+XgVeIBDcZaNREQChYR8PnN7LQd0t21jQnxTd6bmTfvzft2duY9pABkcQrTcK5eu3EbhQd3Hs2iAI96iECtp+7ffTiLjBpp9uBw5mSe0tPx3ynb4E1wDscxCYtkyfRbsiItJJAsyaLum7JuNB/IO7Kpx8m+jc7op+mb1up2ou9a0ur+kOxo+cPSbCbaL8sv3a+Qv3e0LfkmL/qOqXx39eixlqsD4F1u+5p5I942YZfuX2vIRqTFnOlXZUH3W52V15bVpx4/kbfy3tyc+fDb1A3qnqpsy0avXyzSz/bfkXX52K/nv5F8bWOWZ+pu843M7U/k/5/s1zKgZzO8be1cMZDvF5WV/mIT+3bVu0n0fCXPe3S78pL3uRXiDfNgNHJm6uhdf4c5Lswyg5GdR2MsIrOr1FV+0IitqKoadPOMrPFdz/eNhNWhmyX4Dxf69YzcLTbbqbxokYM8OeDoAEbg4xBKGMIYxlHEMUxwNokpziuo4gTOsp1EDTOsppfYTuMyWwXX2aq4xXaGtdPBTbhIc6SaT04zQkCZZh31dHVVnOGawygHGcdBjrX1MI4y8ijRHGFMhSVLXIp8NhBre+wbjaKCloGWQ1oOW184EnEIRYMypWee2cMhapdoVO13jKWvsYO4ckQKYp6gHCe+UeIbI+KihdLVe+UNKlfP3T2RXQulTcM9GoU8xf09jeIJ7uEKLvLky+ZMA8Yt89/UuGeWmTRHzpN55lLXcpGoAubyEitghVwl18jnydPkC+QZsrfHv8SK66BM7ymp/wEGBf5JeJxjYGESYpzAwMrAwNTFFMHAwOANoRnjGIwYlRmQwEIGhv8CSHw3byBxgEGBoYr5xr87DAwsdYwqCgyMk0FyjM+Y9gApBQZmABshDO4AAAB4nGNgYGBmgGAZBkYGEMgB8hjBfBaGACAtAIQgeQUGXQY9BksGB4Z4hqr//+EiBmCRxP///z/8/+v/j/9v/r/8f/L/QqhpKICRDVMMQw0yR12NQUZWTl5BUUlZRRUipIlfuwYDEzMLKxs7BycXNw8vH7+AoJCwiKiYuISklDRhy+kAAIBoGQsAAAEAAf//AA94nL1Za3Ab13XeuyAJkACWhEAAIvEggSUAgniQwGIBgiAWDwIkQQAEQYCiSNF8yZL1lsC0lcZKUo07cTNT006jiaO47jTx2E2naexJ46aT1HEytd0objVuk0maPpSmnfaHGk9bU0nsJtay5+4uSYAiXStyKw4WmN2997y+851zrogGYmHzEzK5zEa0El2EmygSRKPNwWqCIcYa0Os07U203RoIwQ0HbbU1wQ19GJ7DY3ja3uSEX3HEIRYe25rMiGaDHGICFmRG7RRqRRT8QPq5lZU5FMZX/gYa4CIRjv/r+NDQ3+jNZj18wgZrq6132O1JxL2TA96819JvbFMrLyytkm2rS0urd/5rdSmZTpJNqZGR1J2fJ9OfMun0JpNeZ1p3WFxt8laadro8voNGX5K2xVwN9kC3Si4/oOkh6v+RRGBzg3SgtwkH4ScIg82HsLpRSXu5kyPBKtA8inS0zRFDNEU6AyH4BsPb9beYysBAJfhcbDiaUk2ogrOxxRMmb8baq1LaE32js8/0x+JUT9ofSFp7gsORgYOuEdfK4ZuWEXtXo9ZlTJdzSpfL5cN6lEGPLPkSoSd6BH87aR2tYTQMVkDynSBY8mq7Hq3mZ7RUoUipPGNM4iQXP1nJLy3lcysr1JC9RL7E/8jgMsaqk+rJteHRldnm2RXhQhCIiIIsG9hsw5J8CDYVI2SQ+0jahgPUboEbobCBIlFwrJpMVsdGj0YUhUZ7asBf8HoL/myheVI5dJSKrU0qi9VY8JC/rWe4xzMdaY5Me/KDmoFDQdG/WJZ/x65aaWCdhmbpuwyzxU9x3MkEM+ZRUcUC1V4Jbxk2vAbmVGNGlwF130mX7EO1homyOsCuDqJ7lywzsm5bJLP6cPgQM3GB486NZU4N81XZ8ng8fSDdys78O+IaZlIjh6j4Wk6VX4tHz030FOeGeq1dXB/qT+fz4D8zOPFpsOkAQYTBAgYQL+DDjBgI2peffNLbd/mY5amnCPRs5iO9vrSlmuEXBP0GyX7QzwxZRYTFvNAbGJbBOWVlrQEBXzQobqjzSJQ7FS+U26mcp49/EYUtEPLRIDjpXckvG1Th3HC0p3TnuV7fqOVr+j7j8PljyxXFzNLSjKKyTOCYlyEYB4U4gM7buNJpaI0kplykWlzJQHg2WMxyY3MEIOif9M7O/rkU/wNky6YWjvwMx5OD3f6UfJ6QATsIO8lqcr9cdHbSdGenzUagW7yBZG2dRpvN2GkTsLB5e3OQ+CqsbcFayFkmwGoE07U1W6jTlqK3b0Da5vqohSxgs8g721uJtjSBLSrJljCjRjQkDJjwo3P8W8hw9haF9X/w2//xi+99j9iyn3gG1sjENeUivHAnvf1MRqENwi480zFSXETobLuo5ke5QFGJochYG6XJcP4JdzHChDLCBeyOdXoCPT2B3lyQ/xOU9kdGU/zfb30TO7EAeboaefWxKFBthdx2KNCtMh3xzdcEQsQ6xpIGOHo31u/mCnaiGo9XJ8Tr5AMPTBYWFymuWlDn1zhuLa8uVLmxo5XmylHhIvLRIJmF/YW8NexoKeyOIeqkNdo6IaC0diYfPxnfyt0vSPC8Tn4JUjV2oYipyNin53+MiF15O0j6t2Q1aqQckAwSE0RWb8+/bLEeZEa+0k4Vfr4lC+kw/IEnihdiwIN3inWyBN+jWfRjgtr2vZC6YlDVIc9QnE2Cw4e7LeNRjv++EC9mcwPdBP36RGYOWyB3QlAh+pGPFIELzCmVhC5kIQHG6OCRj6hzCk/SHk7EWFf/pO94pfxQ60RzOhAYCvtcwbL/NFU5ohkIGzx2R1eLXGEb8qQmcmkt67b30FaFvLlrqH98UpCP+eb3yE9jvrHjSowpB1QHrsF1Ccn7vFevFj/7WfNZwteLJjPPP5/hX7ZI2C5svk0eQLcw1jBKhIzTM9ibEvkiip1jAGej88C1bZPNviNJ1Mv/UMAZbwDgifsAo6J3YR85+E3GaOFP9sYLlavU1coLONen0fO8Ab/HAnjehPdat98T3qXh79OrUyXq9G+cpkpTq795Rn0Gr8ujF4WPAX/j9cCMUI9vEWqCiCMnY4DklhsgueXuV19e+iT128vfeHX5SepJ4p23vv71t9555RXRxkHBRvCToZZF64wFnnkcHTQDyaUC2xZ73cAwf6xzdfjmk8jF3xzHVmO+EWyOweUN2FeJ2RqxwNA6pLPqYijMfxdd4a+jBHEcMcrMcf6GKg04HoaczJCvg+5GASmA2JDYPjTtysfExfX1i5fW1y/Nzy8cPnxknlpff/axxx9/7Nn19eyZlS+unD6z/MXV01gHiDmaBt4Cv9s1tJzWMhqEWj9++POfIchH/xv1b3EY9nsfyHZJlQVaMHJb4l09GAkFUceyS6mwN+1YGM8vT6XWxsfPc6GlRIgZsaHfJbK5+XC7hnLFfQ2pQmmaUudPhUPLieb03GC7po0O+TRZQa4XbHaBfvYtFmJ0ksuDPuRGrF1wW6NuWzrqn/jVkdJqcWrOk/OuISVfRf/G/yIQPRrlLlCDp3LaA4XD5bjCFzEe+4IqW/0DlXsmoUythsC/gEHyEMhqwejCG0NYIQt0dquGRmidv4oc1y5dgi8TxW8QTyyjG7wp+8QP0Jf5ua08Jp2wvvduXR2475HTGivEt7bnQr7CBa60kJ+an830Bi0t59Bf8R+jlM6UP3Y0OnyBip7MqJqLlfnJ5txch12DLmc32h2dgyfGlWNnYoSECT/ExYr7yzqe1tFSdJi7eBuTidCG6VFovJrkqpOFs5HpqdL0PHWgkouf4JJr4/lFd54J5N2LVORU9ifFc9HwEscV5iZXLMzg8VHV2IlI9tCEIjDuco0HFBOHpBwmdWB/q4CRUFiCNJZ0TaWBUCyjn/K3VM1EBz1gRf+gzC7zKp2tE/JaRvjAjgTYYScYIlljSZj1kfWlR66zkHvUoPpigcKli0lP3GiM2JNr2YlqsmfQZOLciYvTM0dXD82sHq1MHVkoFhcWKP/csDKYtjeqFT2cVxkpeTyliNLL9SjUjfZ0UDk858+m4op4SrigcmxQEYnFIorBmNh/4pj31vqfZaSY02Idq1deFuDQjpoWhNyFs4Ol6WJ5Tq0t5+InuVR1PFtNxNZy4PoH8hCEAhVejtU4fvyhSOTkxE8mz0dR2pX1K3IzMzmFP+sC/w9tbhB/TjyM+cRQ0/J81Ox0mi0OB+WwwBU+OFZF4ia6iBxCvwJBKqLem9mswHWPkl2bb+D7wHW6AvrOw3CfxBwo+yr5TSKDK9x2dKJINKzJjaTpha5vwXHvqYe3tvJ1q/uHulJfcsn2R2/8yrnXHtF9+KVTD8xYXX2Ugo76ootscCHqHbK1UAUlpRr0T187pTn7zPzSH1Vf/cf41FQcPtdPvLaue+y1E8e+9ojt1z9q72rRuUyJC5kDY+cSHQ7tKP/hVtXsMdP535mu/P7ltoc/XxlDssVKS2VpeVpVwr2rDPM6OSf023o8s+zRczO7GlGhB7+0arl9+3axt4OmO4y4Ja3pxoX2NAg9pdWKe0pSkJGWZOwnYaezv12s201oJRERIlniBehvIb61Le2HpGa2ph2WEfbN22gFnYZK4YSMEvEgZBPaXocTSSeUDnEaBbIK1/x+JT+t76a07nImXfFoW7sM5ZyHYTxehvG6BgZcfQMD6iGfyaqVqRrtdi/Leu32RpVMazX5hliz0QT/jObnzAc7jMaOg2bBz3ZUQivkt7d00v5f6IRK96KUTKgv8Q+Qd0L/T7yD8fRDAU/2ffC07+B4+fLtS5fg13HzrhGybpwkGrAM2VOSDBfuAOx3b2rd61Z9sqCfYnGXjpo3Nvjz2zqQwSkxc6zWfZXYlUWCTsBDWzoNEMPvV6fGvafBvVVD38mYp7zugf9NvZ3p8d0aHQU+kT267bf3GZ1aAqiN0MbUvvLFCVOGfSLxl3kfeYa9zd+hsU9k8FjcvxeV7WUlIqzAL7NoEdd8gzCzIGYrT+U0FA56e+xsb/rGWKkp3uh3uQb6e6z25hyy/ata6e7ridqm1Cl/k6m3z2rr6Wy+zi41d5hYZ2Qc7w9cMQs2dQs88Uvvj0p7CxD6tRTkfvge+zXuPvs1mJOg7i6KPWaYpdmwMGnpnAxLy9/82z88k8/feFz1CFFO/OX32fLHn3sKr0GL6OJWX6rddw1a3FkkcARMu2R53372t/jPoO5rFy/y15CB4t++q5+9n7MY6TwEZpud8xD8lvBMOKd5Fp611J3SiCcz22gD+RhjR6QaVoMyqbWSVJGmn+0S8XKq2Mg1uNyegFrh9UWmD2cyh+fSnkDAA5VCPeRp0lt9tFneGYsOpUeGPzQ88aLTanU4rFanYDPG3RGpRtUg7z5kQkV6T6EkEQYceu6jh+z/AHtILXjhdcCnXOAROR1mNI+pPYmphwhknHuafwbHVgvPXxdnRm3dO4BT8SWSSIBhGeEd5c5kKYwDg9SvzTzxNP8VspEgP/YOnjBzOREzgDIwbBHP5mF8yM/iRJdTSHdE1X7lTeR7Qq0gur3GryjZ7I0Dpk5xDciMgRxYo91nDVqsW4TwOQvU/D3nlC+1tKNOPknq+L8DYR20v7tuTiGJPsDkgzWYlGZw6YBGGrb0u1qYbwEcRkYmm7iGPrc7oFL4vEOAEQEfgYA6HQVAbGFE0YExwjq7rU6ntVvEZB9g8sEaTN6/TFR6b6EkkQRMhu5jrox+YHOl2Ov8s3A+Zd/zhIrZ99DqyhXz2W/2+dbWip/7nKX++KruKAsRRojrIcCeeVc9cyM2LGJKh2sNhf4ssdAQlw06XMyAL/bwd1HgSizdO6ZOxJocvQ6L1RIeVrLxhJIMsD0hi4hrI8QPnyuYd9Wy97k3Ku27OcwEEKfAPZ2PDP6S5yMInzqhImDfJOUNt/PfWBIAIfHkjM6YGQ2x/U5nUBZvOpRMTY/GQ4GG/yS6Quk2FW0x0w5XQyIRD4VDlMpiYrd8tIiKgHETrnD3vDda3H9zJHBR8N7OruL3f3ZFEq7Nn6Fj6IR4Xmd4j/O6b01UKhP4Iw0zLZXxSLZSyUbGK2zYnfaEQp60OyzuiSroGPkX4p7ae9gTVfbZlCT8gKHo+zpXDL2/c8X/AQ2rDncAAAAAAQAAAAIAAGLrDmxfDzz1AAMD6AAAAADbnCKZAAAAANucjWP/8/84A7kDIgAAAAYAAgAAAAAAAHicY2BkYGC+8e8OAwML0//PDCDAyIAKQgCAOwUEAAAAeJxFj78uREEUh79zRqOxCdHYbLKbUCAr4bISd7H0609uQuF2aERWREPJIlGo9R7DC2g8gPcQUWyE34xC8WW+Oed3JnPCIaUZ+DoLfkvhe+Q6c98htxdqfiM/puCTNb5+PnwieRFKZVX3k5Qv4oxd6ayQ2Zvmjuh6lXposOS7zKb7MKt+TdueGfUD1Uuafk7d98nUb/ui/Iw5ecY3K/bKtp/SHXLNPulNAbTsjqmIek0fUAvv/8SMXdCIqL9pD4xH5JNpB/097mF9Zfops8yAsYi8Y1tUIvIZu/9DvhFG9O4l1YjuLevJe8k79sh0RD7/C3VcPPwAAAAAAABwAHYAugDwASYBXAGQAawB6gIOAiwCUAJqAngCsALSAwIDOANuA4gDyAPmBAoEHgQ+BFgEhAScBMYE2gUWBUwFbAWmBewGCgZmBqwGwgbOBtoHSAd6B5wHsgf8CEYIogjUCR4JcAmoCeIKEgpECn4KmAq0CtQK8gsACxQLTguIC84L4AvyDAwMJgxADF4MmAzSDRgNSg14DaYN3A4KDjgOdA6eDsgO8gAAeJxjYGRgYAgBQhYGEGBkQAMAEbwArwAAeJyNUk1q3DAYfXYmKS106KLdpBS0nBTGNqZ0MbMKgckioQlJyN4xiq2MYxlJDuQcuUQu0AuUUuiuh+hB+qxR2k4ooRay3vfz3vfpswG8wjdEWD0X3Csc4SWtFY7xDDrgDbzDTcAjvMFdwJvMvw94C6/xOeAx3uI7WdHoOa2v+BlwhO3oPuAY4+hLwBuYRT8CHuF9/CLgTWzHHwLewiT+FPAYH+ObPd3dGlXVTuRZnomzWorTriil2DfaSbsUx0ZfydKJ3d7V2lgxqZ3r7CxNK+Xq/iIp9XV62WijinZZGOtkm9pBYFqtBHbW5E5k1TeFyZMsy+aLg7kPhtg0BNfrB+e5NFbpVnjmv1gPbdnSqM7ZxKom0aZKjxaH2OM36HALA4UKNRwEcmR+C5zRI3meMqdA6fE+czXzJCyWtI+9fUW79Oxd9Dxr+gwzBCZe1VHBYoaUq2KtIaPnv5CQpXFN7yUaz1Gs1FK58PyhTsuo/d3BlPy/O9h5orsTnhXrNF4tZ7XMrzkWOOD7D3OdN33EfOr+65nntIa+FXNaP8uHmv9b6/G0LDnDVDp6LdUG7YbnMKuK8SPe5fAXpzmxbgAAAHicY2BmAIP/cxiMGDBBCAAq1wIl) format("woff"); font-weight:normal;font-style:normal;} </style><linearGradient id="rounded-border-transparency-detail" x1="-137" y1="-236" x2="415" y2="486" gradientUnits="userSpaceOnUse"><stop stop-color="white"/><stop offset="1" stop-color="white" stop-opacity="0.2"/></linearGradient><clipPath id="outer-rounded-border"><rect width="450" height="450" rx="16" fill="white"/></clipPath></defs><g><g clip-path="url(#outer-rounded-border)">',
          _getSVGProfilePicture(imageURI),
          '<rect id="bottom-background" y="370" width="450" height="80" fill="#ABFE2C"/><text id="handle" fill="#00501E" text-anchor="middle" dominant-baseline="middle" x="225" y="410" font-family="Space Grotesk" font-size="',
          Strings.toString(_handleLengthToFontSize(bytes(handleWithAtSymbol).length)),
          '" font-weight="500" letter-spacing="0em">',
          handleWithAtSymbol,
          '</text><rect id="background-border" x="2.5" y="2.5" width="444" height="444" rx="13" stroke="url(#rounded-border-transparency-detail)" stroke-width="5"/><path id="bottom-logo" d="M70 423a14 14 0 0 1-13-1c2 1 5 1 8-1l-1-2h-1a9 9 0 0 1-8 0 9 9 0 0 1-4-6c3-1 11-2 17-8v-1a8 8 0 0 0 3-6c0-2-1-4-3-5-1-2-3-3-5-3l-5 1-3-4c-2-2-4-2-6-2s-4 0-5 2l-3 4-5-1-6 3-2 5a8 8 0 0 0 2 6l1 1c6 6 14 7 17 8a9 9 0 0 1-4 6 9 9 0 0 1-9 0l-2 2h1c2 2 5 2 8 1a14 14 0 0 1-13 1h-1l-1 2 1 1c3 1 7 2 10 1a16 16 0 0 0 10-6v6h3v-6a16 16 0 0 0 13 6l7-1 1-1-2-2Zm-27-29v-1c1-4 4-6 6-6 3 0 6 2 6 6v5l2-3h1v-1c3-2 6-1 8 0 2 2 3 6 0 8v1c-7 7-17 7-17 7s-9 0-16-7l-1-1c-3-2-2-6 0-8l4-1 4 1 1 1 3 3-1-4Z" fill="#fff" fill-opacity=".8"/></g></g></svg>'
        )
      );
  }

  /**
   * @notice Gets the fragment of the SVG correponding to the profile picture.
   *
   * @dev If the image URI was set and meets URI format conditions, this will return an image tag referencing it.
   * Otherwise, a group tag that renders the default picture will be returned.
   *
   * @param imageURI The profile's picture URI. An empty string if has not been set.
   *
   * @return string The fragment of the SVG token's image correspondending to the profile picture.
   */
  function _getSVGProfilePicture(string memory imageURI) internal pure returns (string memory) {
    if (_shouldUseCustomPicture(imageURI)) {
      return
        string(
          abi.encodePacked(
            '<image id="custom-picture" preserveAspectRatio="xMidYMid slice" height="450" width="450" href="',
            imageURI,
            '"/>'
          )
        );
    } else {
      return
        '<g id="default-picture"><rect id="default-picture-background" x="0" width="450" height="450" fill="#ABFE2C"/><g id="default-picture-logo" transform="translate(60,30)"><style><![CDATA[#ez1M8bKaIyB3_to {animation: ez1M8bKaIyB3_to__to 6000ms linear infinite normal forwards}@keyframes ez1M8bKaIyB3_to__to { 0% { transform: translate3d(0,0,0); transform: translate(161px,137px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.5,0.1,0.7,0.5)} 41% {transform: translate(157px,133px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.5,0.5,0.9)} 100% {transform: translate(161px,137px) rotate(0.05deg)}} #ez1M8bKaIyB6_to {animation: ez1M8bKaIyB6_to__to 6000ms linear infinite normal forwards}@keyframes ez1M8bKaIyB6_to__to { 0% {transform: translate(160px,136px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.5,0.1,0.7,0.2)} 26% {transform: translate(176px,138px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.6,0.3,1)} 43% {transform: translate(176px,138px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.6,0.3,1)} 83% {transform: translate(154px,145px) rotate(0.05deg)} 100% {transform: translate(160px,136px) rotate(0.05deg)}}]]></style><path d="m171.3 315.6.1.2-.3-67a113.6 113.6 0 0 0 99.7 58.6 115 115 0 0 0 48.9-10.8l-5.8-10a103.9 103.9 0 0 1-120.5-25.5l4.3 2.9a77 77 0 0 0 77.9 1l-5.7-10-2 1.1a66.4 66.4 0 0 1-96.5-54c19-1.1-30.8-1.1-12 .1A66.4 66.4 0 0 1 60.9 255l-5.7 10 2.4 1.2a76.1 76.1 0 0 0 79.8-5 103.9 103.9 0 0 1-120.6 25.5l-5.7 9.9a115 115 0 0 0 138.5-32.2c3.8-4.8 7.2-10 10-15.3l.6 66.9v-.4h11Z" fill="#00501e"/><g id="ez1M8bKaIyB3_to" transform="translate(162 137.5)"><g><g transform="translate(-165.4 -143.9)"><path d="M185 159.2c-2.4 6.6-9.6 12.2-19.2 12.2-9.3 0-17.3-5.3-19.4-12.4" fill="none" stroke="#00501e" stroke-width="8.3" stroke-linejoin="round"/><g id="ez1M8bKaIyB6_to" transform="translate(160 136.6)"><g transform="translate(0 -1.3)" fill="#00501e"><path d="M124.8 144.7a11.9 11.9 0 1 1-23.8 0 11.9 11.9 0 0 1 23.8 0Z" transform="translate(-154.1 -145)"/><path d="M209.5 144.7a11.9 11.9 0 1 1-23.8 0 11.9 11.9 0 0 1 23.8 0Z" transform="translate(-155 -145)"/></g></g><path d="M92.2 142.8c0-14.6 13.8-26.4 30.8-26.4s30.8 11.8 30.8 26.4M177 142.8c0-14.6 13.8-26.4 30.8-26.4s30.8 11.8 30.8 26.4" fill="none" stroke="#00501e" stroke-width="8.3" stroke-linejoin="round"/></g></g></g><path d="m219.1 70.3-3.2 3.3.1-4.6v-4.7c-1.8-65.4-100.3-65.4-102.1 0l-.1 4.7v4.6l-3.1-3.3-3.4-3.3C59.8 22-10 91.7 35 139.2l3.3 3.4C92.6 196.8 164.9 197 164.9 197s72.3-.2 126.5-54.4l3.3-3.4C339.7 91.7 270 22 222.5 67l-3.4 3.3Z" fill="none" stroke="#00501e" stroke-width="11.2" stroke-miterlimit="10"/></g></g>';
    }
  }

  /**
   * @notice Maps the handle length to a font size.
   *
   * @dev Gives the font size as a function of handle length using the following formula:
   *
   *      fontSize(handleLength) = 24                              when handleLength <= 17
   *      fontSize(handleLength) = 24 - (handleLength - 12) / 2    when handleLength  > 17
   *
   * @param handleLength The profile's handle length.
   * @return uint256 The font size.
   */
  function _handleLengthToFontSize(uint256 handleLength) internal pure returns (uint256) {
    return
      handleLength <= MAX_HANDLE_LENGTH_WITH_DEFAULT_FONT_SIZE
        ? DEFAULT_FONT_SIZE
        : DEFAULT_FONT_SIZE - (handleLength - 12) / 2;
  }

  /**
   * @notice Decides if Profile NFT should use user provided custom profile picture or the default one.
   *
   * @dev It checks if there is a custom imageURI set and makes sure it does not contain double-quotes to prevent
   * injection attacks through the generated SVG.
   *
   * @param imageURI The imageURI set by the profile owner.
   *
   * @return bool A boolean indicating whether custom profile picture should be used or not.
   */
  function _shouldUseCustomPicture(string memory imageURI) internal pure returns (bool) {
    bytes memory imageURIBytes = bytes(imageURI);
    if (imageURIBytes.length == 0) {
      return false;
    }
    uint256 imageURIBytesLength = imageURIBytes.length;
    for (uint256 i = 0; i < imageURIBytesLength; ) {
      if (imageURIBytes[i] == '"') {
        // Avoids embedding a user provided imageURI containing double-quotes to prevent injection attacks
        return false;
      }
      unchecked {
        ++i;
      }
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {FollowNFTProxy} from "../upgradeability/FollowNFTProxy.sol";
import {Helpers} from "./Helpers.sol";
import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";
import {Events} from "./Events.sol";
import {Constants} from "./Constants.sol";
import {IFollowNFT} from "../interfaces/IFollowNFT.sol";
import {ICollectNFT} from "../interfaces/ICollectNFT.sol";
import {IFollowModule} from "../interfaces/IFollowModule.sol";
import {ICollectModule} from "../interfaces/ICollectModule.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title InteractionLogic
 * @author Lens Protocol
 *
 * @notice This is the library that contains the logic for follows & collects.

 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood.
 */
library InteractionLogic {
  using Strings for uint256;

  /**
   * @notice Follows the given profiles, executing the necessary logic and module calls before minting the follow
   * NFT(s) to the follower.
   *
   * @param follower The address executing the follow.
   * @param profileIds The array of profile token IDs to follow.
   * @param followModuleDatas The array of follow module data parameters to pass to each profile's follow module.
   * @param _profileById A pointer to the storage mapping of profile structs by profile ID.
   * @param _profileIdByHandleHash A pointer to the storage mapping of profile IDs by handle hash.
   *
   * @return uint256[] An array of integers representing the minted follow NFTs token IDs.
   */
  function follow(
    address follower,
    uint256[] calldata profileIds,
    bytes[] calldata followModuleDatas,
    mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
    mapping(bytes32 => uint256) storage _profileIdByHandleHash
  ) external returns (uint256[] memory) {
    if (profileIds.length != followModuleDatas.length) revert Errors.ArrayMismatch();
    uint256[] memory tokenIds = new uint256[](profileIds.length);
    for (uint256 i = 0; i < profileIds.length; ) {
      string memory handle = _profileById[profileIds[i]].handle;
      if (_profileIdByHandleHash[keccak256(bytes(handle))] != profileIds[i]) revert Errors.TokenDoesNotExist();

      address followModule = _profileById[profileIds[i]].followModule;
      address followNFT = _profileById[profileIds[i]].followNFT;

      if (followNFT == address(0)) {
        followNFT = _deployFollowNFT(profileIds[i]);
        _profileById[profileIds[i]].followNFT = followNFT;
      }

      tokenIds[i] = IFollowNFT(followNFT).mint(follower);

      if (followModule != address(0)) {
        IFollowModule(followModule).processFollow(follower, profileIds[i], followModuleDatas[i]);
      }
      unchecked {
        ++i;
      }
    }
    emit Events.Followed(follower, profileIds, followModuleDatas, block.timestamp);
    return tokenIds;
  }

  /**
   * @notice Collects the given publication, executing the necessary logic and module call before minting the
   * collect NFT to the collector.
   *
   * @param collector The address executing the collect.
   * @param profileId The token ID of the publication being collected's parent profile.
   * @param pubId The publication ID of the publication being collected.
   * @param collectModuleData The data to pass to the publication's collect module.
   * @param collectNFTImpl The address of the collect NFT implementation, which has to be passed because it's an immutable in the hub.
   * @param _pubByIdByProfile A pointer to the storage mapping of publications by pubId by profile ID.
   * @param _profileById A pointer to the storage mapping of profile structs by profile ID.
   *
   * @return uint256 An integer representing the minted token ID.
   */
  function collect(
    address collector,
    uint256 profileId,
    uint256 pubId,
    bytes calldata collectModuleData,
    address collectNFTImpl,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(uint256 => DataTypes.ProfileStruct) storage _profileById
  ) external returns (uint256) {
    (uint256 rootProfileId, uint256 rootPubId, address rootCollectModule) = Helpers.getPointedIfMirror(
      profileId,
      pubId,
      _pubByIdByProfile
    );

    uint256 tokenId;
    // Avoids stack too deep
    {
      address collectNFT = _pubByIdByProfile[rootProfileId][rootPubId].collectNFT;
      if (collectNFT == address(0)) {
        collectNFT = _deployCollectNFT(rootProfileId, rootPubId, _profileById[rootProfileId].handle, collectNFTImpl);
        _pubByIdByProfile[rootProfileId][rootPubId].collectNFT = collectNFT;
      }
      tokenId = ICollectNFT(collectNFT).mint(collector);
    }

    ICollectModule(rootCollectModule).processCollect(profileId, collector, rootProfileId, rootPubId, collectModuleData);
    _emitCollectedEvent(collector, profileId, pubId, rootProfileId, rootPubId, collectModuleData);

    return tokenId;
  }

  /**
   * @notice Deploys the given profile's Follow NFT contract.
   *
   * @param profileId The token ID of the profile which Follow NFT should be deployed.
   *
   * @return address The address of the deployed Follow NFT contract.
   */
  function _deployFollowNFT(uint256 profileId) private returns (address) {
    bytes memory functionData = abi.encodeWithSelector(IFollowNFT.initialize.selector, profileId);
    address followNFT = address(new FollowNFTProxy(functionData));
    emit Events.FollowNFTDeployed(profileId, followNFT, block.timestamp);

    return followNFT;
  }

  /**
   * @notice Deploys the given profile's Collect NFT contract.
   *
   * @param profileId The token ID of the profile which Collect NFT should be deployed.
   * @param pubId The publication ID of the publication being collected, which Collect NFT should be deployed.
   * @param handle The profile's associated handle.
   * @param collectNFTImpl The address of the Collect NFT implementation that should be used for the deployment.
   *
   * @return address The address of the deployed Collect NFT contract.
   */
  function _deployCollectNFT(
    uint256 profileId,
    uint256 pubId,
    string memory handle,
    address collectNFTImpl
  ) private returns (address) {
    address collectNFT = Clones.clone(collectNFTImpl);

    bytes4 firstBytes = bytes4(bytes(handle));

    string memory collectNFTName = string(abi.encodePacked(handle, Constants.COLLECT_NFT_NAME_INFIX, pubId.toString()));
    string memory collectNFTSymbol = string(
      abi.encodePacked(firstBytes, Constants.COLLECT_NFT_SYMBOL_INFIX, pubId.toString())
    );

    ICollectNFT(collectNFT).initialize(profileId, pubId, collectNFTName, collectNFTSymbol);
    emit Events.CollectNFTDeployed(profileId, pubId, collectNFT, block.timestamp);

    return collectNFT;
  }

  /**
   * @notice Emits the `Collected` event that signals that a successful collect action has occurred.
   *
   * @dev This is done through this function to prevent stack too deep compilation error.
   *
   * @param collector The address collecting the publication.
   * @param profileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
   * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
   * @param rootProfileId The profile token ID of the profile whose publication is being collected.
   * @param rootPubId The publication ID of the publication being collected.
   * @param data The data passed to the collect module.
   */
  function _emitCollectedEvent(
    address collector,
    uint256 profileId,
    uint256 pubId,
    uint256 rootProfileId,
    uint256 rootPubId,
    bytes calldata data
  ) private {
    emit Events.Collected(collector, profileId, pubId, rootProfileId, rootPubId, data, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ILensNFTBase} from "../../interfaces/ILensNFTBase.sol";
import {Errors} from "../../libraries/Errors.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Events} from "../../libraries/Events.sol";
import {ERC721Time} from "./ERC721Time.sol";
import {ERC721Enumerable} from "./ERC721Enumerable.sol";

/**
 * @title LensNFTBase
 * @author Lens Protocol
 *
 * @notice This is an abstract base contract to be inherited by other Lens Protocol NFTs, it includes
 * the slightly modified ERC721Enumerable, which itself inherits from the ERC721Time-- which adds an
 * internal operator approval setter, stores the mint timestamp for each token, and replaces the
 * constructor with an initializer.
 */
abstract contract LensNFTBase is ERC721Enumerable, ILensNFTBase {
  bytes32 internal constant EIP712_REVISION_HASH = keccak256("1");
  bytes32 internal constant PERMIT_TYPEHASH =
    keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
  bytes32 internal constant PERMIT_FOR_ALL_TYPEHASH =
    keccak256("PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)");
  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  mapping(address => uint256) public sigNonces;

  /**
   * @notice Initializer sets the name, symbol and the cached domain separator.
   *
   * NOTE: Inheritor contracts *must* call this function to initialize the name & symbol in the
   * inherited ERC721 contract.
   *
   * @param name The name to set in the ERC721 contract.
   * @param symbol The symbol to set in the ERC721 contract.
   */
  function _initialize(string calldata name, string calldata symbol) internal {
    ERC721Time.__ERC721_Init(name, symbol);

    emit Events.BaseInitialized(name, symbol, block.timestamp);
  }

  /// @inheritdoc ILensNFTBase
  function permit(
    address spender,
    uint256 tokenId,
    DataTypes.EIP712Signature calldata sig
  ) external override {
    if (spender == address(0)) revert Errors.ZeroSpender();
    address owner = ownerOf(tokenId);
    unchecked {
      _validateRecoveredAddress(
        _calculateDigest(keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, sigNonces[owner]++, sig.deadline))),
        owner,
        sig
      );
    }
    _approve(spender, tokenId);
  }

  /// @inheritdoc ILensNFTBase
  function permitForAll(
    address owner,
    address operator,
    bool approved,
    DataTypes.EIP712Signature calldata sig
  ) external override {
    if (operator == address(0)) revert Errors.ZeroSpender();
    unchecked {
      _validateRecoveredAddress(
        _calculateDigest(
          keccak256(abi.encode(PERMIT_FOR_ALL_TYPEHASH, owner, operator, approved, sigNonces[owner]++, sig.deadline))
        ),
        owner,
        sig
      );
    }
    _setOperatorApproval(owner, operator, approved);
  }

  /// @inheritdoc ILensNFTBase
  function getDomainSeparator() external view override returns (bytes32) {
    return _calculateDomainSeparator();
  }

  /// @inheritdoc ILensNFTBase
  function burn(uint256 tokenId) public virtual override {
    if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Errors.NotOwnerOrApproved();
    _burn(tokenId);
  }

  /**
   * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
   */
  function _validateRecoveredAddress(
    bytes32 digest,
    address expectedAddress,
    DataTypes.EIP712Signature calldata sig
  ) internal view {
    if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
    address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
    if (recoveredAddress == address(0) || recoveredAddress != expectedAddress) revert Errors.SignatureInvalid();
  }

  /**
   * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
   */
  function _calculateDomainSeparator() internal view returns (bytes32) {
    return
      keccak256(
        abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name())), EIP712_REVISION_HASH, block.chainid, address(this))
      );
  }

  /**
   * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
   *
   * @param hashedMessage The message hash from which the digest should be calculated.
   *
   * @return bytes32 A 32-byte output representing the EIP712 digest.
   */
  function _calculateDigest(bytes32 hashedMessage) internal view returns (bytes32) {
    bytes32 digest;
    unchecked {
      digest = keccak256(abi.encodePacked("\x19\x01", _calculateDomainSeparator(), hashedMessage));
    }
    return digest;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Events} from "../../libraries/Events.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

/**
 * @title LensMultiState
 *
 * @notice This is an abstract contract that implements internal LensHub state setting and validation.
 *
 * whenNotPaused: Either publishingPaused or Unpaused.
 * whenPublishingEnabled: When Unpaused only.
 */
abstract contract LensMultiState {
  DataTypes.ProtocolState private _state;

  modifier whenNotPaused() {
    _validateNotPaused();
    _;
  }

  modifier whenPublishingEnabled() {
    _validatePublishingEnabled();
    _;
  }

  /**
   * @notice Returns the current protocol state.
   *
   * @return ProtocolState The Protocol state, an enum, where:
   *      0: Unpaused
   *      1: PublishingPaused
   *      2: Paused
   */
  function getState() external view returns (DataTypes.ProtocolState) {
    return _state;
  }

  function _setState(DataTypes.ProtocolState newState) internal {
    DataTypes.ProtocolState prevState = _state;
    _state = newState;
    emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
  }

  function _validatePublishingEnabled() internal view {
    if (_state != DataTypes.ProtocolState.Unpaused) {
      revert Errors.PublishingPaused();
    }
  }

  function _validateNotPaused() internal view {
    if (_state == DataTypes.ProtocolState.Paused) revert Errors.Paused();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "../../libraries/DataTypes.sol";

/**
 * @title LensHubStorage
 * @author Lens Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the LensHub contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the LensHub storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract LensHubStorage {
  mapping(address => bool) internal _profileCreatorWhitelisted;
  mapping(address => bool) internal _followModuleWhitelisted;
  mapping(address => bool) internal _collectModuleWhitelisted;
  mapping(address => bool) internal _referenceModuleWhitelisted;
  mapping(address => bool) internal _readModuleWhitelisted;

  mapping(uint256 => address) internal _dispatcherByProfile;
  mapping(bytes32 => uint256) internal _profileIdByHandleHash;
  mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
  mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) internal _pubByIdByProfile;

  mapping(address => uint256) internal _defaultProfileByAddress;

  uint256 internal _profileCounter;
  address internal _governance;
  address internal _emergencyAdmin;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Errors} from "../libraries/Errors.sol";

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * This is slightly modified from [Aave's version.](https://github.com/aave/protocol-v2/blob/6a503eb0a897124d8b9d126c915ffdf3e88343a9/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol)
 *
 * @author Lens Protocol, inspired by Aave's implementation, which is in turn inspired by OpenZeppelin's
 * Initializable contract
 */
abstract contract VersionedInitializable {
  address private immutable originalImpl;

  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    if (address(this) == originalImpl) revert Errors.CannotInitImplementation();
    if (revision <= lastInitializedRevision) revert Errors.Initialized();
    lastInitializedRevision = revision;
    _;
  }

  constructor() {
    originalImpl = address(this);
  }

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support extended for multiple forwarders.
 */
abstract contract ERC2771ContextExtended is Context {
  mapping(address => bool) private _isForwarder;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(address trustedForwarder) {
    _isForwarder[trustedForwarder] = true;
  }

  function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
    return _isForwarder[forwarder];
  }

  function _msgSender() internal view virtual override returns (address sender) {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      /// @solidity memory-safe-assembly
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }

  function _addForwarder(address newTrustedForwarder) internal {
    _isForwarder[newTrustedForwarder] = true;
  }

  function _deleteForwarder(address forwarder) internal {
    _isForwarder[forwarder] = false;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/draft-EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 *
 * MinimalForwarder is mainly meant for testing, as it is missing features to be a good production-ready forwarder. This
 * contract does not intend to have all the properties that are needed for a sound forwarding system. A fully
 * functioning forwarding system with good properties requires more complexity. We suggest you look at other projects
 * such as the GSN which do have the goal of building a system like that.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IFollowModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible FollowModules.
 */
interface IFollowModule {
  /**
   * @notice Initializes a follow module for a given Lens profile. This can only be called by the hub contract.
   *
   * @param profileId The token ID of the profile to initialize this follow module for.
   * @param data Arbitrary data passed by the profile creator.
   *
   * @return bytes The encoded data to emit in the hub.
   */
  function initializeFollowModule(uint256 profileId, bytes calldata data) external returns (bytes memory);

  /**
   * @notice Processes a given follow, this can only be called from the LensHub contract.
   *
   * @param follower The follower address.
   * @param profileId The token ID of the profile being followed.
   * @param data Arbitrary data passed by the follower.
   */
  function processFollow(
    address follower,
    uint256 profileId,
    bytes calldata data
  ) external;

  /**
   * @notice This is a transfer hook that is called upon follow NFT transfer in `beforeTokenTransfer. This can
   * only be called from the LensHub contract.
   *
   * NOTE: Special care needs to be taken here: It is possible that follow NFTs were issued before this module
   * was initialized if the profile's follow module was previously different. This transfer hook should take this
   * into consideration, especially when the module holds state associated with individual follow NFTs.
   *
   * @param profileId The token ID of the profile associated with the follow NFT being transferred.
   * @param from The address sending the follow NFT.
   * @param to The address receiving the follow NFT.
   * @param followNFTTokenId The token ID of the follow NFT being transferred.
   */
  function followModuleTransferHook(
    uint256 profileId,
    address from,
    address to,
    uint256 followNFTTokenId
  ) external;

  /**
   * @notice This is a helper function that could be used in conjunction with specific collect modules.
   *
   * NOTE: This function IS meant to replace a check on follower NFT ownership.
   *
   * NOTE: It is assumed that not all collect modules are aware of the token ID to pass. In these cases,
   * this should receive a `followNFTTokenId` of 0, which is impossible regardless.
   *
   * One example of a use case for this would be a subscription-based following system:
   *      1. The collect module:
   *          - Decodes a follower NFT token ID from user-passed data.
   *          - Fetches the follow module from the hub.
   *          - Calls `isFollowing` passing the profile ID, follower & follower token ID and checks it returned true.
   *      2. The follow module:
   *          - Validates the subscription status for that given NFT, reverting on an invalid subscription.
   *
   * @param profileId The token ID of the profile to validate the follow for.
   * @param follower The follower address to validate the follow for.
   * @param followNFTTokenId The followNFT token ID to validate the follow for.
   *
   * @return true if the given address is following the given profile ID, false otherwise.
   */
  function isFollowing(
    uint256 profileId,
    address follower,
    uint256 followNFTTokenId
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title ICollectModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible CollectModules.
 */
interface ICollectModule {
  /**
   * @notice Initializes data for a given publication being published. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile publishing the publication.
   * @param pubId The associated publication's LensHub publication ID.
   * @param data Arbitrary data __passed from the user!__ to be decoded.
   *
   * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
   * hub alongside the collect module's address and should be consumed by front ends.
   */
  function initializePublicationCollectModule(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external returns (bytes memory);

  /**
   * @notice Processes a collect action for a given publication, this can only be called by the hub.
   *
   * @param referrerProfileId The LensHub profile token ID of the referrer's profile (only different in case of mirrors).
   * @param collector The collector address.
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   * @param data Arbitrary data __passed from the collector!__ to be decoded.
   */
  function processCollect(
    uint256 referrerProfileId,
    address collector,
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IReferenceModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible ReferenceModules.
 */
interface IReferenceModule {
  /**
   * @notice Initializes data for a given publication being published. This can only be called by the hub.
   * @param profileId The token ID of the profile publishing the publication.
   * @param pubId The associated publication's LensHub publication ID.
   * @param data Arbitrary data passed from the user to be decoded.
   *
   * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
   * hub alongside the collect module's address and should be consumed by front ends.
   */
  function initializeReferenceModule(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external returns (bytes memory);

  /**
   * @notice Processes a comment action referencing a given publication. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile associated with the publication being published.
   * @param profileIdPointed The profile ID of the profile associated the publication being referenced.
   * @param pubIdPointed The publication ID of the publication being referenced.
   * @param data Arbitrary data __passed from the commenter!__ to be decoded.
   */
  function processComment(
    uint256 profileId,
    uint256 profileIdPointed,
    uint256 pubIdPointed,
    bytes calldata data
  ) external;

  /**
   * @notice Processes a mirror action referencing a given publication. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile associated with the publication being published.
   * @param profileIdPointed The profile ID of the profile associated the publication being referenced.
   * @param pubIdPointed The publication ID of the publication being referenced.
   * @param data Arbitrary data __passed from the mirrorer!__ to be decoded.
   */
  function processMirror(
    uint256 profileId,
    uint256 profileIdPointed,
    uint256 pubIdPointed,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IReadModule
 * @author
 *
 * @notice This is the standard interface for all ReadModules.
 */
interface IReadModule {
  /**
   * @notice Initializes data for a given publication being published. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile publishing the publication.
   * @param pubId The associated publication's LensHub publication ID.
   * @param data Arbitrary data __passed from the user!__ to be decoded.
   *
   * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
   * hub alongside the collect module's address and should be consumed by front ends.
   */
  function initializePublicationReadModule(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external returns (bytes memory);

  /**
   * @notice Authorize the module to move the profile's balance.
   *
   * @param profileId The token ID of the profile authorizing the module.
   * @param authorized If the module is authorized or not.
   */
  function authorizeModule(uint256 profileId, bool authorized) external;

  /**
   * @notice Processes a collect action for a given publication, this can only be called by the hub.
   *
   * @param creatorId The token ID of the profile that is reading the publication.
   * @param creatorId The token ID of the profile associated with the publication being read.
   * @param pubId The LensHub publication ID associated with the publication being read.
   * @param data Arbitrary data __passed to be decoded.
   */
  function processRead(
    uint256 consumerId,
    uint256 creatorId,
    uint256 pubId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ILensHub} from "../interfaces/ILensHub.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract FollowNFTProxy is Proxy {
  using Address for address;
  address immutable HUB;

  constructor(bytes memory data) {
    HUB = msg.sender;
    ILensHub(msg.sender).getFollowNFTImpl().functionDelegateCall(data);
  }

  function _implementation() internal view override returns (address) {
    return ILensHub(HUB).getFollowNFTImpl();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IFollowNFT
 * @author Lens Protocol
 *
 * @notice This is the interface for the FollowNFT contract, which is cloned upon the first follow for any profile.
 */
interface IFollowNFT {
  /**
   * @notice Initializes the follow NFT, setting the hub as the privileged minter and storing the associated profile ID.
   *
   * @param profileId The token ID of the profile in the hub associated with this followNFT, used for transfer hooks.
   */
  function initialize(uint256 profileId) external;

  /**
   * @notice Mints a follow NFT to the specified address. This can only be called by the hub, and is called
   * upon follow.
   *
   * @param to The address to mint the NFT to.
   *
   * @return uint256 An interger representing the minted token ID.
   */
  function mint(address to) external returns (uint256);

  /**
   * @notice Delegates the caller's governance power to the given delegatee address.
   *
   * @param delegatee The delegatee address to delegate governance power to.
   */
  function delegate(address delegatee) external;

  /**
   * @notice Delegates the delegator's governance power via meta-tx to the given delegatee address.
   *
   * @param delegator The delegator address, who is the signer.
   * @param delegatee The delegatee address, who is receiving the governance power delegation.
   * @param sig The EIP712Signature struct containing the necessary parameters to recover the delegator's signature.
   */
  function delegateBySig(
    address delegator,
    address delegatee,
    DataTypes.EIP712Signature calldata sig
  ) external;

  /**
   * @notice Returns the governance power for a given user at a specified block number.
   *
   * @param user The user to query governance power for.
   * @param blockNumber The block number to query the user's governance power at.
   *
   * @return uint256 The power of the given user at the given block number.
   */
  function getPowerByBlockNumber(address user, uint256 blockNumber) external returns (uint256);

  /**
   * @notice Returns the total delegated supply at a specified block number. This is the sum of all
   * current available voting power at a given block.
   *
   * @param blockNumber The block number to query the delegated supply at.
   *
   * @return uint256 The delegated supply at the given block number.
   */
  function getDelegatedSupplyByBlockNumber(uint256 blockNumber) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title ICollectNFT
 * @author Lens Protocol
 *
 * @notice This is the interface for the CollectNFT contract. Which is cloned upon the first collect for any given
 * publication.
 */
interface ICollectNFT {
  /**
   * @notice Initializes the collect NFT, setting the feed as the privileged minter, storing the collected publication pointer
   * and initializing the name and symbol in the LensNFTBase contract.
   *
   * @param profileId The token ID of the profile in the hub that this collectNFT points to.
   * @param pubId The profile publication ID in the hub that this collectNFT points to.
   * @param name The name to set for this NFT.
   * @param symbol The symbol to set for this NFT.
   */
  function initialize(
    uint256 profileId,
    uint256 pubId,
    string calldata name,
    string calldata symbol
  ) external;

  /**
   * @notice Mints a collect NFT to the specified address. This can only be called by the hub, and is called
   * upon collection.
   *
   * @param to The address to mint the NFT to.
   *
   * @return uint256 An interger representing the minted token ID.
   */
  function mint(address to) external returns (uint256);

  /**
   * @notice Returns the source publication pointer mapped to this collect NFT.
   *
   * @return tuple First the profile ID uint256, and second the pubId uint256.
   */
  function getSourcePublicationPointer() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ILensNFTBase
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensNFTBase contract, from which all Lens NFTs inherit.
 * It is an expansion of a very slightly modified ERC721Enumerable contract, which allows expanded
 * meta-transaction functionality.
 */
interface ILensNFTBase {
  /**
   * @notice Implementation of an EIP-712 permit function for an ERC-721 NFT. We don't need to check
   * if the tokenId exists, since the function calls ownerOf(tokenId), which reverts if the tokenId does
   * not exist.
   *
   * @param spender The NFT spender.
   * @param tokenId The NFT token ID to approve.
   * @param sig The EIP712 signature struct.
   */
  function permit(
    address spender,
    uint256 tokenId,
    DataTypes.EIP712Signature calldata sig
  ) external;

  /**
   * @notice Implementation of an EIP-712 permit-style function for ERC-721 operator approvals. Allows
   * an operator address to control all NFTs a given owner owns.
   *
   * @param owner The owner to set operator approvals for.
   * @param operator The operator to approve.
   * @param approved Whether to approve or revoke approval from the operator.
   * @param sig The EIP712 signature struct.
   */
  function permitForAll(
    address owner,
    address operator,
    bool approved,
    DataTypes.EIP712Signature calldata sig
  ) external;

  /**
   * @notice Burns an NFT, removing it from circulation and essentially destroying it. This function can only
   * be called by the NFT to burn's owner.
   *
   * @param tokenId The token ID of the token to burn.
   */
  function burn(uint256 tokenId) external;

  /**
   * @notice Returns the domain separator for this NFT contract.
   *
   * @return bytes32 The domain separator.
   */
  function getDomainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Time.sol";
import "./ERC2771ContextExtended.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 *
 * Modifications:
 * 1. Refactored _operatorApprovals setter into an internal function to allow meta-transactions.
 * 2. Constructor replaced with an initializer.
 * 3. Mint timestamp is now stored in a TokenData struct alongside the owner address.
 */
abstract contract ERC721Time is ERC2771ContextExtended, ERC165, IERC721Time, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to token Data (owner address and mint timestamp uint96), this
  // replaces the original mapping(uint256 => address) private _owners;
  mapping(uint256 => IERC721Time.TokenData) private _tokenData;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Initializes the ERC721 name and symbol.
   *
   * @param name The name to set.
   * @param symbol The symbol to set.
   */
  function __ERC721_Init(string calldata name, string calldata symbol) internal {
    _name = name;
    _symbol = symbol;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _tokenData[tokenId].owner;
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /**
   * @dev See {IERC721Time-mintTimestampOf}
   */
  function mintTimestampOf(uint256 tokenId) public view virtual override returns (uint256) {
    uint96 mintTimestamp = _tokenData[tokenId].mintTimestamp;
    require(mintTimestamp != 0, "ERC721: mint timestamp query for nonexistent token");
    return mintTimestamp;
  }

  /**
   * @dev See {IERC721Time-mintTimestampOf}
   */
  function tokenDataOf(uint256 tokenId) public view virtual override returns (IERC721Time.TokenData memory) {
    require(_exists(tokenId), "ERC721: token data query for nonexistent token");
    return _tokenData[tokenId];
  }

  /**
   * @dev See {IERC721Time-exists}
   */
  function exists(uint256 tokenId) public view virtual override returns (bool) {
    return _exists(tokenId);
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721Time.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _setOperatorApproval(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _tokenData[tokenId].owner != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721Time.ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    _balances[to] += 1;
    _tokenData[tokenId].owner = to;
    _tokenData[tokenId].mintTimestamp = uint96(block.timestamp);

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721Time.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _tokenData[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(ERC721Time.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _tokenData[tokenId].owner = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721Time.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Refactored from the original OZ ERC721 implementation: approve or revoke approval from
   * `operator` to operate on all tokens owned by `owner`.
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setOperatorApproval(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Time.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 *
 * NOTE: Modified from Openzeppelin to inherit from a modified ERC721 contract.
 */
abstract contract ERC721Enumerable is ERC721Time, IERC721Enumerable {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Time) returns (bool) {
    return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
    require(index < ERC721Time.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
    require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
    return _allTokens[index];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from == address(0)) {
      _addTokenToAllTokensEnumeration(tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      _removeTokenFromAllTokensEnumeration(tokenId);
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721Time.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to add a token to this extension's token tracking data structures.
   * @param tokenId uint256 ID of the token to be added to the tokens list
   */
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721Time.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Private function to remove a token from this extension's token tracking data structures.
   * This has O(1) time complexity, but alters the order of the _allTokens array.
   * @param tokenId uint256 ID of the token to be removed from the tokens list
   */
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    // This also deletes the contents at the last position of the array
    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IERC721Time
 * @author Lens Protocol
 *
 * @notice This is an expansion of the IERC721 interface that includes a struct for token data,
 * which contains the token owner and the mint timestamp as well as associated getters.
 */
interface IERC721Time is IERC721 {
  /**
   * @notice Contains the owner address and the mint timestamp for every NFT.
   *
   * Note: Instead of the owner address in the _tokenOwners private mapping, we now store it in the
   * _tokenData mapping, alongside the unchanging mintTimestamp.
   *
   * @param owner The token owner.
   * @param mintTimestamp The mint timestamp.
   */
  struct TokenData {
    address owner;
    uint96 mintTimestamp;
  }

  /**
   * @notice Returns the mint timestamp associated with a given NFT, stored only once upon initial mint.
   *
   * @param tokenId The token ID of the NFT to query the mint timestamp for.
   *
   * @return uint256 mint timestamp, this is stored as a uint96 but returned as a uint256 to reduce unnecessary
   * padding.
   */
  function mintTimestampOf(uint256 tokenId) external view returns (uint256);

  /**
   * @notice Returns the token data associated with a given NFT. This allows fetching the token owner and
   * mint timestamp in a single call.
   *
   * @param tokenId The token ID of the NFT to query the token data for.
   *
   * @return TokenData token data struct containing both the owner address and the mint timestamp.
   */
  function tokenDataOf(uint256 tokenId) external view returns (TokenData memory);

  /**
   * @notice Returns whether a token with the given token ID exists.
   *
   * @param tokenId The token ID of the NFT to check existence for.
   *
   * @return bool True if the token exists.
   */
  function exists(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}
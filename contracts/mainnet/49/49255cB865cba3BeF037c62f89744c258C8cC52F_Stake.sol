// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/ISwap.sol";

contract Stake is ERC1155Holder, AccessControl {
    bool paused = true;

    address public _treasury;
    IERC20 anodeToken;
    ISwap _liquidityPool;
    IERC1155 keyContract;
    address[] path = new address[](2);

    uint256 public entryFee = 10 ether;
    uint256 public claimFee = 0.05 ether;
    uint256 public maintCost = 0.2 ether;
    uint256 public masterKeyBonus = 0.025 ether;
    uint256 public grandmasterKeyBonus = 0.05 ether;
    uint256 public stakeReward = 0.225 ether;

    uint256 public _rewardPoolShare = 7000;
    uint256 public _treasuryShare = 2000;
    uint256 public _liquidityPoolShare = 1000;

    uint256 maxVaultsPerAddress = 100;

    mapping(address => uint256) public addressToVaults;
    mapping(address => mapping(uint256 => Vault)) public ownerToVaultIdToVault;
    mapping(address => uint256) public masterKeysDeposited;
    mapping(address => uint256) public grandmasterKeysDeposited;

    uint256 validPeriod = 30 days;
    uint256 stakePeriod = 1 days;

    uint256 public totalClaimed;
    uint256 public totalVaultsCreated;

    struct Vault {
        uint256 creationDate;
        uint256 paidUntil;
        uint256 lastDate;
        uint256 readyToClaim;
        uint256 lastClaimed;
    }

    event RewardsClaimed(address indexed claimer, uint256 amount);

    event VaultsCreated(
        address indexed creator,
        uint256 amount,
        uint256 validUntil
    );

    constructor(
        address treasury,
        ISwap liquidityPool,
        IERC20 token,
        address _WAVAX
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, treasury);
        _treasury = treasury;
        _liquidityPool = liquidityPool;
        anodeToken = token;
        path[0] = address(token);
        path[1] = _WAVAX;
    }

    //internals
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Admin-only function");
        _;
    }

    modifier isUnpaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function _getSharesForASum(uint256 amount)
        internal
        view
        returns (
            uint256 treasuryShare,
            uint256 liquidityShare,
            uint256 rewardPoolShare
        )
    {
        treasuryShare = (entryFee * amount * _treasuryShare) / 10000;
        liquidityShare = (entryFee * amount * _liquidityPoolShare) / 10000;
        rewardPoolShare = (entryFee * amount * _rewardPoolShare) / 10000;
    }

    function _swapAndLiquify(uint256 amount) internal {
        anodeToken.approve(address(_liquidityPool), amount * 2);
        uint256[] memory swappedAmounts = _liquidityPool.swapExactTokensForAVAX(
            amount,
            1,
            path,
            address(this),
            block.timestamp
        );

        _liquidityPool.addLiquidityAVAX{value: swappedAmounts[1]}(
            address(anodeToken),
            amount,
            1,
            1,
            _treasury,
            block.timestamp
        );
    }

    function _distributeTokens(uint256 amount) internal {
        (
            uint256 treasuryShare,
            uint256 liquidityShare,
            uint256 rewardPoolShare
        ) = _getSharesForASum(amount);
        anodeToken.transferFrom(
            msg.sender,
            address(this),
            liquidityShare + rewardPoolShare
        );
        anodeToken.transferFrom(msg.sender, _treasury, treasuryShare);
        _swapAndLiquify(liquidityShare / 2);
    }

    function _getRewardsForVault(Vault memory vault)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 limiter;
        if (vault.paidUntil > block.timestamp) {
            limiter = block.timestamp;
        } else {
            limiter = vault.paidUntil;
        }
        uint256 a = limiter - vault.lastDate;
        uint256 stakingPeriod = a - (a % stakePeriod);
        uint256 toPay = stakeReward;
        toPay += masterKeysDeposited[msg.sender] * masterKeyBonus;
        toPay += grandmasterKeysDeposited[msg.sender] * grandmasterKeyBonus;
        return ((stakingPeriod / stakePeriod) * toPay, stakingPeriod);
    }

    function _getRewards(address who) internal view returns (uint256 rewards) {
        for (uint256 i = 1; i <= addressToVaults[who]; i++) {
            (uint256 rewardToAdd, ) = _getRewardsForVault(
                ownerToVaultIdToVault[who][i]
            );
            rewards += rewardToAdd + ownerToVaultIdToVault[who][i].readyToClaim;
        }
    }

    function _sendToTreasury(uint256 amount) internal {
        (bool success, ) = _treasury.call{value: amount, gas: 21000}("");
        require(success, "Failed to send $AVAX");
    }

    //admin funcs
    function isAdmin(address who) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, who);
    }

    function grantAdmin(address to) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, to);
    }

    function init(IERC1155 _keyContract) public onlyAdmin {
        paused = !paused;
        keyContract = _keyContract;
    }

    function changeShares(
        uint256 rewardPoolShare,
        uint256 treasuryShare,
        uint256 liquidityPoolShare
    ) public onlyAdmin {
        require(
            rewardPoolShare + treasuryShare + liquidityPoolShare == 10000,
            "Sum of shares is not 100%"
        );
        _rewardPoolShare = rewardPoolShare;
        _treasuryShare = treasuryShare;
        _liquidityPoolShare = liquidityPoolShare;
    }

    function changeFees(
        uint256 _entryFee,
        uint256 _claimFee,
        uint256 _maintCost
    ) public onlyAdmin {
        entryFee = _entryFee;
        claimFee = _claimFee;
        maintCost = _maintCost;
    }

    function changeRewardBonuses(
        uint256 _masterKeyBonus,
        uint256 _grandmasterKeyBonus,
        uint256 _stakeReward
    ) public onlyAdmin {
        masterKeyBonus = _masterKeyBonus;
        grandmasterKeyBonus = _grandmasterKeyBonus;
        stakeReward = _stakeReward;
    }

    //user funcs
    function createVaults(uint256 amount) public isUnpaused {
        require(
            addressToVaults[msg.sender] + amount <= maxVaultsPerAddress,
            "Exceeds maximum vault amount for single wallet"
        );
        uint256 validUntil = block.timestamp + validPeriod;
        for (uint256 i = 0; i < amount; i++) {
            addressToVaults[msg.sender]++;
            Vault storage vault = ownerToVaultIdToVault[msg.sender][
                addressToVaults[msg.sender]
            ];
            vault.creationDate = block.timestamp;
            vault.paidUntil = validUntil;
            vault.lastDate = block.timestamp;
        }
        _distributeTokens(amount);
        totalVaultsCreated += amount;
        emit VaultsCreated(msg.sender, amount, validUntil);
    }

    function claimRewards() public payable {
        require(msg.value == claimFee, "Wrong message value");
        uint256 rewards;
        for (uint256 i = 1; i <= addressToVaults[msg.sender]; i++) {
            (uint256 rewardToAdd, uint256 claimedTill) = _getRewardsForVault(
                ownerToVaultIdToVault[msg.sender][i]
            );
            if (rewardToAdd > 0) {
                rewards += ownerToVaultIdToVault[msg.sender][i].readyToClaim + rewardToAdd;
                ownerToVaultIdToVault[msg.sender][i].lastDate += claimedTill;
                ownerToVaultIdToVault[msg.sender][i].lastClaimed = block
                    .timestamp;
                ownerToVaultIdToVault[msg.sender][i].readyToClaim = 0;
            }
        }
        require(rewards > 0, "Can't withdraw 0");
        anodeToken.transfer(msg.sender, rewards);
        totalClaimed += rewards;
        _sendToTreasury(msg.value);
        emit RewardsClaimed(msg.sender, rewards);
    }

    function payMaintFee(uint256 vaultId) public payable {
        Vault storage vault = ownerToVaultIdToVault[msg.sender][vaultId];
        require(vault.creationDate > 0, "Nonexistant vault");
        require(msg.value == maintCost, "Wrong message value");
        if (vault.paidUntil < block.timestamp) {
            (uint256 toClaim, ) = _getRewardsForVault(vault);
            vault.readyToClaim += toClaim;
            vault.paidUntil = block.timestamp;
            vault.lastDate = block.timestamp;
        }
        vault.paidUntil += validPeriod;
        require(
            block.timestamp + 180 days >= vault.paidUntil,
            "Can only pay up to 180 days in advance"
        );
        _sendToTreasury(msg.value);
    }

    function getExpiredVaults() public view returns(uint256 amount) {
         for (uint256 i = 1; i <= addressToVaults[msg.sender]; i++) {
            if (
                ownerToVaultIdToVault[msg.sender][i].paidUntil <= block.timestamp
            ) {
                amount++;
            }
        }
    }

    function payMaintFeeExpired() public payable {
        uint256 feeToPay;
        uint256 payTill = block.timestamp + validPeriod;
        for (uint256 i = 1; i <= addressToVaults[msg.sender]; i++) {
            if (
                ownerToVaultIdToVault[msg.sender][i].paidUntil <= block.timestamp
            ) {
                feeToPay += maintCost;
                (
                    uint256 toClaim,

                ) = _getRewardsForVault(ownerToVaultIdToVault[msg.sender][i]);
                ownerToVaultIdToVault[msg.sender][i].readyToClaim += toClaim;
                ownerToVaultIdToVault[msg.sender][i].paidUntil = payTill;
                ownerToVaultIdToVault[msg.sender][i].lastDate = block.timestamp;
            }
        }
        require(msg.value == feeToPay, "Wrong message value");
        _sendToTreasury(msg.value);
    }

    //keys
    function depositMasterKeys(uint256 amount) public {
        require(
            masterKeysDeposited[msg.sender] + amount <= 10,
            "Can't deposit more than 10 master keys"
        );
        keyContract.safeTransferFrom(msg.sender, address(this), 1, amount, "");

        for (uint256 i = 1; i <= addressToVaults[msg.sender]; i++) {
            Vault memory vault = ownerToVaultIdToVault[msg.sender][i];
            (uint256 toClaim, ) = _getRewardsForVault(vault);
            vault.readyToClaim += toClaim;
            vault.lastDate = block.timestamp;
        }
        masterKeysDeposited[msg.sender] += amount;
    }

    function depositGrandMasterKey() public {
        require(
            grandmasterKeysDeposited[msg.sender] < 1,
            "Can only deposit 1 grandmaster key"
        );
        keyContract.safeTransferFrom(msg.sender, address(this), 2, 1, "");

        for (uint256 i = 1; i <= addressToVaults[msg.sender]; i++) {
            Vault memory vault = ownerToVaultIdToVault[msg.sender][i];
            (uint256 toClaim, ) = _getRewardsForVault(vault);
            vault.readyToClaim += toClaim;
            vault.lastDate = block.timestamp;
        }
        grandmasterKeysDeposited[msg.sender]++;
    }

    function withdrawMasterKeys(uint256 amount) public {
        require(
            masterKeysDeposited[msg.sender] - amount >= 0,
            "Can't deposit more than 10 master keys"
        );
        keyContract.safeTransferFrom(address(this), msg.sender, 1, amount, "");
        masterKeysDeposited[msg.sender] -= amount;

        for (uint256 i = 1; i <= addressToVaults[msg.sender]; i++) {
            Vault memory vault = ownerToVaultIdToVault[msg.sender][i];
            (vault.readyToClaim, ) = _getRewardsForVault(vault);
            vault.lastDate = block.timestamp;
        }
    }

    function withdrawGrandMasterKey() public {
        require(
            grandmasterKeysDeposited[msg.sender] == 1,
            "Can only deposit 1 grandmaster key"
        );
        keyContract.safeTransferFrom(address(this), msg.sender, 2, 1, "");
        grandmasterKeysDeposited[msg.sender]--;

        for (uint256 i = 1; i <= addressToVaults[msg.sender]; i++) {
            Vault memory vault = ownerToVaultIdToVault[msg.sender][i];
            (uint256 toClaim, ) = _getRewardsForVault(vault);
            vault.readyToClaim += toClaim;
            vault.lastDate = block.timestamp;
        }
    }

    //view functions
    function vaultsOwned(address who) public view returns (uint256) {
        return addressToVaults[who];
    }

    function viewOwnRewards() public view returns (uint256) {
        return _getRewards(msg.sender);
    }

    function getVault(uint256 vaultId) public view returns (Vault memory vault) {
        vault = ownerToVaultIdToVault[msg.sender][vaultId];
        (uint256 toClaim, ) = _getRewardsForVault(vault);
        vault.readyToClaim += toClaim;
    }

    function getAllVaults() public view returns (Vault[] memory) {
        Vault[] memory vaults = new Vault[](addressToVaults[msg.sender]);
        for (uint256 i = 1; i <= addressToVaults[msg.sender]; i++) {
            Vault memory vault = ownerToVaultIdToVault[msg.sender][i];
            vaults[i - 1] = vault;
            (uint256 toClaim, ) = _getRewardsForVault(vault);
            vault.readyToClaim += toClaim;
        }
        return vaults;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISwap {
    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function WAVAX() external pure returns (address);

    function factory() external pure returns (address);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}
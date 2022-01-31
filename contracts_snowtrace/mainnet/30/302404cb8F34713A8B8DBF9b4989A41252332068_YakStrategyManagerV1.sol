// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "../lib/AccessControl.sol";
import "../lib/SafeMath.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

interface IStrategy {
    function REINVEST_REWARD_BIPS() external view returns (uint256);
    function ADMIN_FEE_BIPS() external view returns (uint256);
    function DEV_FEE_BIPS() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function updateMinTokensToReinvest(uint256 newValue) external;
    function updateAdminFee(uint256 newValue) external;
    function updateDevFee(uint256 newValue) external;
    function updateDepositsEnabled(bool newValue) external;
    function updateMaxTokensToDepositWithoutReinvest(uint256 newValue) external;
    function rescueDeployedFunds(uint256 minReturnAmountAccepted, bool disableDeposits) external;
    function updateReinvestReward(uint256 newValue) external;
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function recoverAVAX(uint256 amount) external;
    function setAllowances() external;
    function revokeAllowance(address token, address spender) external;
    function allowDepositor(address depositor) external;
    function removeDepositor(address depositor) external;
}

/**
 * @notice Role-based manager for YakStrategy contracts
 * @dev YakStrategyManager may be used as `owner` on YakStrategy contracts
 */
contract YakStrategyManagerV1 is AccessControl {
    using SafeMath for uint256;

    uint256 public constant timelockLengthForOwnershipTransfer = 14 days;

    /// @notice Sets a global maximum for fee changes using bips (100 bips = 1%)
    uint256 public maxFeeBips = 1000;

    /// @notice Pending strategy owners (strategy => pending owner)
    mapping(address => address) public pendingOwners;

    /// @notice Earliest time pending owner can take effect (strategy => timestamp)
    mapping(address => uint256) public pendingOwnersTimelock;

    /// @notice Role to manage strategy owners
    bytes32 public constant STRATEGY_OWNER_SETTER_ROLE = keccak256("STRATEGY_OWNER_SETTER_ROLE");

    /// @notice Role to initiate an emergency withdraw from strategies
    bytes32 public constant EMERGENCY_RESCUER_ROLE = keccak256("EMERGENCY_RESCUER_ROLE");

    /// @notice Role to sweep funds from strategies
    bytes32 public constant EMERGENCY_SWEEPER_ROLE = keccak256("EMERGENCY_SWEEPER_ROLE");

    /// @notice Role to manage global max fee configuration
    bytes32 public constant GLOBAL_MAX_FEE_SETTER_ROLE = keccak256("GLOBAL_MAX_FEE_SETTER_ROLE");

    /// @notice Role to manage strategy fees and reinvest configurations
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    /// @notice Role to allow/deny use of strategies
    bytes32 public constant STRATEGY_PERMISSIONER_ROLE = keccak256("STRATEGY_PERMISSIONER_ROLE");

    /// @notice Role to disable deposits on strategies
    bytes32 public constant STRATEGY_DISABLER_ROLE = keccak256("STRATEGY_DISABLER_ROLE");

    /// @notice Role to enable deposits on strategies
    bytes32 public constant STRATEGY_ENABLER_ROLE = keccak256("STRATEGY_ENABLER_ROLE");

    event ProposeOwner(address indexed strategy, address indexed newOwner);
    event SetOwner(address indexed strategy, address indexed newValue);
    event SetFees(address indexed strategy, uint256 adminFeeBips, uint256 devFeeBips, uint256 reinvestFeeBips);
    event SetMinTokensToReinvest(address indexed strategy, uint256 newValue);
    event SetMaxTokensToDepositWithoutReinvest(address indexed strategy, uint256 newValue);
    event SetGlobalMaxFee(uint256 maxFeeBips, uint256 newMaxFeeBips);
    event SetDepositsEnabled(address indexed strategy, bool newValue);
    event SetAllowances(address indexed strategy);
    event Recover(address indexed strategy, address indexed token, uint256 amount);
    event Recovered(address token, uint amount);
    event EmergencyWithdraw(address indexed strategy);
    event AllowDepositor(address indexed strategy, address indexed depositor);
    event RemoveDepositor(address indexed strategy, address indexed depositor);

    constructor(
        address _manager,
        address _team,
        address _deployer
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _manager);
        _setupRole(EMERGENCY_RESCUER_ROLE, _team);
        _setupRole(EMERGENCY_SWEEPER_ROLE, _deployer);
        _setupRole(GLOBAL_MAX_FEE_SETTER_ROLE, _team);
        _setupRole(FEE_SETTER_ROLE, _deployer);
        _setupRole(FEE_SETTER_ROLE, _team);
        _setupRole(STRATEGY_OWNER_SETTER_ROLE, _manager);
        _setupRole(STRATEGY_DISABLER_ROLE, _deployer);
        _setupRole(STRATEGY_DISABLER_ROLE, _team);
        _setupRole(STRATEGY_ENABLER_ROLE, _team);
        _setupRole(STRATEGY_PERMISSIONER_ROLE, _team);
    }

    receive() external payable {}

    /**
     * @notice Pass new value of `owner` through timelock
     * @dev Restricted to `STRATEGY_OWNER_SETTER_ROLE` to avoid griefing
     * @dev Resets timelock
     * @param strategy address
     * @param newOwner new value
     */
    function proposeOwner(address strategy, address newOwner) external {
        require(hasRole(STRATEGY_OWNER_SETTER_ROLE, msg.sender), "proposeOwner::auth");
        pendingOwnersTimelock[strategy] = block.timestamp + timelockLengthForOwnershipTransfer;
        pendingOwners[strategy] = newOwner;
        emit ProposeOwner(strategy, newOwner);
    }

    /**
     * @notice Set new value of `owner` and resets timelock
     * @dev This can be called by anyone
     * @param strategy address
     */
    function setOwner(address strategy) external {
        require(pendingOwnersTimelock[strategy] != 0, "setOwner::not allowed");
        require(pendingOwnersTimelock[strategy] <= block.timestamp, "setOwner::too soon");
        IStrategy(strategy).transferOwnership(pendingOwners[strategy]);
        emit SetOwner(strategy, pendingOwners[strategy]);
        delete pendingOwners[strategy];
        delete pendingOwnersTimelock[strategy];
    }

    /**
     * @notice Set strategy fees
     * @dev Restricted to `FEE_SETTER_ROLE` and global max fee
     * @param strategy address
     * @param adminFeeBips deprecated
     * @param devFeeBips platform fees
     * @param reinvestRewardBips reinvest reward
     */
    function setFees(address strategy, uint256 adminFeeBips, uint256 devFeeBips, uint256 reinvestRewardBips) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "setFees::auth");
        require(adminFeeBips.add(devFeeBips).add(reinvestRewardBips) <= maxFeeBips, "setFees::Fees too high");
        if (adminFeeBips != IStrategy(strategy).ADMIN_FEE_BIPS()){
            IStrategy(strategy).updateAdminFee(adminFeeBips);
        }
        if (devFeeBips != IStrategy(strategy).DEV_FEE_BIPS()){
            IStrategy(strategy).updateDevFee(devFeeBips);
        }
        if (reinvestRewardBips != IStrategy(strategy).REINVEST_REWARD_BIPS()){
            IStrategy(strategy).updateReinvestReward(reinvestRewardBips);
        }
        emit SetFees(strategy, adminFeeBips, devFeeBips, reinvestRewardBips);
    }

    /**
     * @notice Set token approvals
     * @dev Restricted to `STRATEGY_ENABLER_ROLE` to avoid griefing
     * @param strategy address
     */
    function setAllowances(address strategy) external {
        require(hasRole(STRATEGY_ENABLER_ROLE, msg.sender), "setAllowances::auth");
        IStrategy(strategy).setAllowances();
        emit SetAllowances(strategy);
    }

    /**
     * @notice Revoke token approvals
     * @dev Restricted to `STRATEGY_DISABLER_ROLE` to avoid griefing
     * @param strategy address
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address strategy, address token, address spender) external {
        require(hasRole(STRATEGY_DISABLER_ROLE, msg.sender) || hasRole(EMERGENCY_RESCUER_ROLE, msg.sender), "revokeAllowance::auth");
        IStrategy(strategy).revokeAllowance(token, spender);
    }

    /**
     * @notice Set max strategy fees
     * @dev Restricted to `GLOBAL_MAX_FEE_SETTER_ROLE`
     * @param newMaxFeeBips max strategy fees
     */
    function updateGlobalMaxFees(uint256 newMaxFeeBips) external {
        require(hasRole(GLOBAL_MAX_FEE_SETTER_ROLE, msg.sender), "updateGlobalMaxFees::auth");
        emit SetGlobalMaxFee(maxFeeBips, newMaxFeeBips);
        maxFeeBips = newMaxFeeBips;
    }

    /**
     * @notice Permissioned function to set min tokens to reinvest
     * @dev Restricted to `FEE_SETTER_ROLE`
     * @param strategy address
     * @param newValue min tokens to reinvest
     */
    function setMinTokensToReinvest(address strategy, uint256 newValue) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "setMinTokensToReinvest::auth");
        IStrategy(strategy).updateMinTokensToReinvest(newValue);
        emit SetMinTokensToReinvest(strategy, newValue);
    }

    /**
     * @notice Permissioned function to set max tokens to deposit without reinvest
     * @dev Restricted to `FEE_SETTER_ROLE`
     * @param strategy address
     * @param newValue max tokens to deposit without reinvest
     */
    function setMaxTokensToDepositWithoutReinvest(address strategy, uint256 newValue) external {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "setMaxTokensToDepositWithoutReinvest::auth");
        IStrategy(strategy).updateMaxTokensToDepositWithoutReinvest(newValue);
        emit SetMaxTokensToDepositWithoutReinvest(strategy, newValue);
    }

    /**
     * @notice Permissioned function to enable deposits
     * @dev Restricted to `STRATEGY_ENABLER_ROLE`
     * @param strategy address
     */
    function enableDeposits(address strategy) external {
        require(hasRole(STRATEGY_ENABLER_ROLE, msg.sender), "enableDeposits::auth");
        IStrategy(strategy).updateDepositsEnabled(true);
        emit SetDepositsEnabled(strategy, true);
    }

    /**
     * @notice Permissioned function to disable deposits
     * @dev Restricted to `STRATEGY_DISABLER_ROLE`
     * @param strategy address
     */
    function disableDeposits(address strategy) external {
        require(hasRole(STRATEGY_DISABLER_ROLE, msg.sender), "disableDeposits::auth");
        IStrategy(strategy).updateDepositsEnabled(false);
        emit SetDepositsEnabled(strategy, false);
    }

    /**
     * @notice Permissioned function to add to list of allowed depositors
     * @dev Restricted to `STRATEGY_PERMISSIONER_ROLE`
     * @param strategy address
     * @param depositor address
     */
    function allowDepositor(address strategy, address depositor) external {
        require(hasRole(STRATEGY_PERMISSIONER_ROLE, msg.sender), "allowDepositor::auth");
        IStrategy(strategy).allowDepositor(depositor);
        emit AllowDepositor(strategy, depositor);
    }

    /**
     * @notice Permissioned function to remove from list of allowed depositors
     * @dev Restricted to `STRATEGY_PERMISSIONER_ROLE`
     * @param strategy address
     * @param depositor address
     */
    function removeDepositor(address strategy, address depositor) external {
        require(hasRole(STRATEGY_PERMISSIONER_ROLE, msg.sender), "removeDepositor::auth");
        IStrategy(strategy).removeDepositor(depositor);
        emit RemoveDepositor(strategy, depositor);
    }

    /**
     * @notice Permissioned function to recover deployed assets back into the strategy contract
     * @dev Restricted to `EMERGENCY_RESCUER_ROLE`
     * @dev Always passes `true` to disable deposits
     * @dev Rescued funds stay in strategy until recovered (see `recover*`)
     * @param strategy address
     * @param minReturnAmountAccepted amount
     */
    function rescueDeployedFunds(address strategy, uint256 minReturnAmountAccepted) external {
        require(hasRole(EMERGENCY_RESCUER_ROLE, msg.sender), "rescueDeployedFunds::auth");
        IStrategy(strategy).rescueDeployedFunds(minReturnAmountAccepted, true);
        emit EmergencyWithdraw(strategy);
    }

    /**
     * @notice Permissioned function to recover and transfer any token from strategy contract
     * @dev Restricted to `EMERGENCY_SWEEPER_ROLE`
     * @dev Intended for use in case of `rescueDeployedFunds`
     * @param strategy address
     * @param tokenAddress address
     * @param tokenAmount amount
     */
    function recoverTokens(address strategy, address tokenAddress, uint256 tokenAmount) external {
        require(hasRole(EMERGENCY_SWEEPER_ROLE, msg.sender), "recoverTokens::auth");
        IStrategy(strategy).recoverERC20(tokenAddress, tokenAmount);
        _transferTokens(tokenAddress, tokenAmount);
        emit Recover(strategy, tokenAddress, tokenAmount);
    }

    /**
     * @notice Permissioned function to transfer any token from this contract
     * @dev Restricted to `EMERGENCY_SWEEPER_ROLE`
     * @param tokenAddress token address
     * @param tokenAmount amount
     */
    function sweepTokens(address tokenAddress, uint256 tokenAmount) external {
        require(hasRole(EMERGENCY_SWEEPER_ROLE, msg.sender), "sweepTokens::auth");
        _transferTokens(tokenAddress, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Internal function to transfer tokens to msg.sender
     * @param tokenAddress token address
     * @param tokenAmount amount
     */
    function _transferTokens(address tokenAddress, uint256 tokenAmount) internal {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (tokenAmount < balance) {
            tokenAmount = balance;
        }
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "_transferTokens::transfer failed");
    }

    /**
     * @notice Permissioned function to transfer AVAX from any strategy into this contract
     * @dev Restricted to `EMERGENCY_SWEEPER_ROLE`
     * @dev After recovery, contract may become gas-bound.
     * @dev Intended for use in case of `rescueDeployedFunds`, as deposit tokens will be locked in the strategy.
     * @param strategy address
     * @param amount amount
     */
    function recoverAVAX(address strategy, uint256 amount) external {
        require(hasRole(EMERGENCY_SWEEPER_ROLE, msg.sender), "recoverAVAX::auth");
        emit Recover(strategy, address(0), amount);
        IStrategy(strategy).recoverAVAX(amount);
    }

    /**
     * @notice Permissioned function to transfer AVAX from this contract
     * @dev Restricted to `EMERGENCY_SWEEPER_ROLE`
     * @param amount amount
     */
    function sweepAVAX(uint256 amount) external {
        require(hasRole(EMERGENCY_SWEEPER_ROLE, msg.sender), "sweepAVAX::auth");
        uint256 balance = address(this).balance;
        if (amount < balance) {
            amount = balance;
        }
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success == true, "recoverAVAX::transfer failed");
        emit Recovered(address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./EnumerableSet.sol";
import "./Address.sol";
import "./Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity 0.7.3;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
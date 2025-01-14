/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-21
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File test/mock-contracts/interfaces/IErc20.sol

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title IErc20
/// @author Paul Razvan Berg
/// @notice Implementation for the Erc20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IErc20 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when the owner is the zero address.
    error Erc20__ApproveOwnerZeroAddress();

    /// @notice Emitted when the spender is the zero address.
    error Erc20__ApproveSpenderZeroAddress();

    /// @notice Emitted when burning more tokens than are in the account.
    error Erc20__BurnUnderflow(uint256 accountBalance, uint256 burnAmount);

    /// @notice Emitted when the holder is the zero address.
    error Erc20__BurnZeroAddress();

    /// @notice Emitted when the owner did not give the spender sufficient allowance.
    error Erc20__InsufficientAllowance(uint256 allowance, uint256 amount);

    /// @notice Emitted when tranferring more tokens than there are in the account.
    error Erc20__InsufficientBalance(uint256 senderBalance, uint256 amount);

    /// @notice Emitted when the beneficiary is the zero address.
    error Erc20__MintZeroAddress();

    /// @notice Emitted when the sender is the zero address.
    error Erc20__TransferSenderZeroAddress();

    /// @notice Emitted when the recipient is the zero address.
    error Erc20__TransferRecipientZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when an approval happens.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param amount The maximum amount that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer happens.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `subtractedAmount`.
    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have approed `sender` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


// File test/mock-contracts/interfaces/IErc20Permit.sol

// ign-License-Identifier: Unlicense
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.4;

/// @title IErc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
interface IErc20Permit is IErc20 {
    /// @notice Emitted when the recovered owner does not match the actual owner.
    error Erc20Permit__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

    /// @notice Emitted when the owner is the zero address.
    error Erc20Permit__OwnerZeroAddress();

    /// @notice Emitted when the permit expired.
    error Erc20Permit__PermitExpired(uint256 deadline);

    /// @notice Emitted when the recovered owner is the zero address.
    error Erc20Permit__RecoveredOwnerZeroAddress();

    /// @notice Emitted when the spender is the zero address.
    error Erc20Permit__SpenderZeroAddress();

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, assuming the latter's
    /// signed approval.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: The same issues Erc20 `approve` has related to transaction
    /// ordering also apply here.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    /// - `deadline` must be a timestamp in the future.
    /// - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the Eip712-formatted
    /// function arguments.
    /// - The signature must use `owner`'s current nonce.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The Eip712 domain's keccak256 hash.
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Provides replay protection.
    function nonces(address account) external view returns (uint256);

    /// @notice keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    function PERMIT_TYPEHASH() external view returns (bytes32);

    /// @notice Eip712 version of this implementation.
    function version() external view returns (string memory);

    function chainId() external view returns (uint256);
}


// File test/mock-contracts/interfaces/ICygnusTerminal.sol

// ign-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

// Dependencies

/**
 *  @title The interface for CygnusTerminal which handles pool tokens shared by Collateral and Borrow contracts
 *  @notice The interface for the CygnusTerminal contract allows minting/redeeming Cygnus pool tokens
 */
interface ICygnusTerminal is IErc20Permit {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when attempting to set already initialized factory
     */
    error CygnusTerminal__FactoryAlreadyInitialized(address);

    /**
     *  @custom:error Emitted when attempting to mint zero amount of tokens
     */
    error CygnusTerminal__CantMintZero(uint256);

    /**
     *  @custom:error Emitted when attempting to redeem zero amount of tokens
     */
    error CygnusTerminal__CantBurnZero(uint256);

    /**
     *  @custom:error Emitted when attempting to redeem over amount of tokens
     */
    error CygnusTerminal__BurnAmountInvalid(uint256);

    /**
     *  @custom:error Emitted when attempting to call Admin-only functions
     */
    error CygnusTerminal__CygnusAdminOnly(address);

    /**
     *  @custom:error Emitted when attempting to call Factory-only functions
     */
    error CygnusTerminal__MsgSenderNotFactory(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param totalBalance Total cash balance of the underlying.
     *  @custom:event Emitted when `totalBalance` is in sync with balanceOf(address(this)).
     */
    event Sync(uint256 totalBalance);

    /**
     *  @param sender Address of the msg.sender.
     *  @param minter Address of the minter.
     *  @param mintAmount Amount initial is worth at the current exchange rate.
     *  @param poolTokens Amount of the tokens to be minted.
     *  @custom:event Emitted when tokens are minted
     */
    event Mint(address indexed sender, address indexed minter, uint256 mintAmount, uint256 poolTokens);

    /**
     *  @param sender Address of the msgSender()
     *  @param redeemer Address of the redeemer.
     *  @param redeemAmount Amount invested is worth at the current exchangerate.
     *  @param poolTokens Amount of PoolTokens to burn.
     *  @custom:event Emitted when tokens are redeemed.
     */
    event Redeem(address indexed sender, address indexed redeemer, uint256 redeemAmount, uint256 poolTokens);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
           3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return Total balance of pool.
     */
    function totalBalance() external returns (uint256);

    /**
     *  @return Contract Address of the underlying LP Token.
     */
    function underlying() external returns (address);

    /**
     *  @return The address of Factory contract. 🛸
     */
    function hangar18() external returns (address);

    /**
     *  @return The redeemable amount of underlying tokens that 1 pool token can be redeemed for.
     */
    function exchangeRate() external returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @dev This low level function should only be called from `Altair` contract only
     *  @param minter Address of the minter.
     *  @return poolTokens Amount to mint which is equal to amount / exchangeRate
     *  @custom:security non-reentrant
     */
    function mint(address minter) external returns (uint256 poolTokens);

    /**
     *  @dev This low level function should only be called from `Altair` contract only
     *  @param holder Address of the redeemer.
     *  @return redeemAmount The holder's shares, equal to amount * exchangeRate
     *  @custom:security non-reentrant
     */
    function redeem(address holder) external returns (uint256 redeemAmount);

    /**
     *  @notice Uniswap's skim function
     *  @param recipient Address of user skimming difference between total balance stored and actual balance
     *  @custom:security non-reentrant
     */
    function skim(address recipient) external;

    /**
     *  @notice Force real balance to match totalBalance
     *  @dev Emits a sync event.
     *  @custom:security non-reentrant
     */
    function sync() external;
}


// File test/mock-contracts/interfaces/ICygnusNebulaOracle.sol

//ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

/**
 *  @title ICygnusNebulaOracle Interface for Oracle
 *  This is a copy of Tarot's oracle
 *  https://github.com/tarot-finance/tarot-price-oracle/blob/main/contracts/TarotPriceOracle.sol
 */
interface ICygnusNebulaOracle {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when uint224 overflows
     */
    error CygnusNebulaOracle__Uint224Overflow();

    /**
     *  @custom:error Emitted when oracle already exists for LP Token
     */
    error CygnusNebulaOracle__PairIsInitialized(address lpTokenPair);

    /**
     *  @custom:error Emitted when pair hasn't been initialised for LP Token
     */
    error CygnusNebulaOracle__PairNotInitialized(address lpTokenPair);

    /**
     *  @custom:error Emitted when oracle is called before ready
     */
    error CygnusNebulaOracle__TimeWindowTooSmall(uint32 timeWindow);
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param lpTokenPair The address of the LP Token
     *  @param priceCumulative The cumulative price of the LP Token in uint256
     *  @param blockTimestamp The timestamp of the last price update in uint32
     *  @param latestIsSlotA Bool value if it is latest price update
     *  @custom:event Emitted when LP Token price is updated
     */
    event UpdateLPTokenPrice(
        address indexed lpTokenPair,
        uint256 priceCumulative,
        uint32 blockTimestamp,
        bool latestIsSlotA
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS 
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return The minimum amount of time for oracle to update, 10 mins
     */
    function minimumTimeWindow() external view returns (uint32);

    /**
     *  @param lpTokenPair The address of the LP Token
     *  @return priceCumulativeSlotA The cumulative price of Token A
     *  @return priceCumulativeSlotB The cumulative price of Token B
     *  @return lastUpdateSlotA The uint32 of last price update of Token A
     *  @return lastUpdateSlotB The uint32 of last price update of Token B
     *  @return latestIsSlotA Bool value represents if price is latest
     *  @return initialized Bool value represents if oracle for pair exists
     */
    function getCygnusNebulaPair(address lpTokenPair)
        external
        view
        returns (
            uint256 priceCumulativeSlotA,
            uint256 priceCumulativeSlotB,
            uint32 lastUpdateSlotA,
            uint32 lastUpdateSlotB,
            bool latestIsSlotA,
            bool initialized
        );

    /**
     *  @notice Helper function that returns the current block timestamp within the range of uint32
     *  @return uint32 block.timestamp
     */
    function getBlockTimestamp() external view returns (uint32);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS 
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice initialize oracle for LP Token
    /// @param lpTokenPair is address of LP Token
    function initializeCygnusNebula(address lpTokenPair) external;

    /// @notice Gets the LP Tokens price if time elapsed > time window
    /// @param lpTokenPair The address of the LP Token
    /// @return timeWeightedPrice112x112 The price of the LP Token
    /// @return timeWindow The time window of the price update
    function getResult(address lpTokenPair) external returns (uint224 timeWeightedPrice112x112, uint32 timeWindow);
}


// File test/mock-contracts/interfaces/ICygnusCollateralControl.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies


/**
 *  @title ICygnusCollateralControl
 */
interface ICygnusCollateralControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when trying a collateral parameter outside of range allowed
     */
    error CygnusCollateralControl__ParameterNotInRange(uint256);

    /**
     *  @custom:error Emitted when oracle address is invalid
     */
    error CygnusCollateralControl__OracleCantBeZeroAddress(ICygnusNebulaOracle newPriceOracle);

    /**
     *  @custom:error Emitted when the new oracle address is the same
     */
    error CygnusCollateralControl__CygnusNebulaDuplicate(ICygnusNebulaOracle newPriceOracle);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════  
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Updated directly from the factory -> First update factory oracle, then iterate over each shuttle
     *  @param oldPriceOracle The address of the previous price oracle
     *  @param newPriceOracle The address of the new price oracle for this shuttle
     *  @custom:event Emitted when a new price oracle is set
     */
    event NewPriceOracle(ICygnusNebulaOracle oldPriceOracle, ICygnusNebulaOracle newPriceOracle);

    /**
     *  @param oldLiquidationIncentive The old incentive for liquidators taken from the collateral
     *  @param newLiquidationIncentive The new liquidation incentive for this shuttle
     *  @custom:event Emitted when a new liquidation incentive is set
     */
    event NewLiquidationIncentive(uint256 oldLiquidationIncentive, uint256 newLiquidationIncentive);

    /**
     *  @param oldDebtRatio The old debt ratio at which the collateral was liquidatable in this shuttle
     *  @param newDebtRatio The new debt ratio for this shuttle
     *  @custom:event Emitted when a new debt ratio is set
     */
    event NewDebtRatio(uint256 oldDebtRatio, uint256 newDebtRatio);

    /**
     *  @param oldLiquidationFee The previous fee the protocol kept as reserves from each liquidation
     *  @param newLiquidationFee The new liquidation fee for this shuttle
     *  @custom:event Emitted when a new liquidation fee is set
     */
    event NewLiquidationFee(uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    // ───────────────────── Important Addresses  ──────────────────────

    /**
     *  @return The address of AlbireoTokenA.
     */
    function borrowDAITokenA() external view returns (address);

    /**
     *  @return The address of AlbireoTokenB (if available).
     */
    function borrowDAITokenB() external view returns (address);

    /**
     *  @notice Not immutable in case we need to update oracle from factory
     *  @return The address of the Cygnus Price Oracle
     */
    function cygnusNebulaOracle() external view returns (ICygnusNebulaOracle);

    // ────────────────────── Current pool rates  ───────────────────────

    /**
     *  @return The current debt ratio for the lending pool, default at 80% (x5 leverage).
     */
    function debtRatio() external view returns (uint256);

    /**
     *  @return The current liquidation incentive for the lending pool, default at 5%.
     */
    function liquidationIncentive() external view returns (uint256);

    /**
     *  @return The current liquidation fee the protocol keeps from each liquidation, default at 0%.
     */
    function liquidationFee() external view returns (uint256);

    // ──────────────────── Min/Max this pool allows  ────────────────────

    /**
     *  @notice Set a minimum for borrow protection
     *  @return Minimum debt ratio at which the collateral becomes liquidatable, equivalent to 50% (x2 leverage)
     */
    function debtRatioMin() external pure returns (uint256);

    /**
     *  @return Maximum debt ratio at which the collateral becomes liquidatable, equivalent to 87.5% (x8 leverage)
     */
    function debtRatioMax() external pure returns (uint256);

    /**
     *  @notice Set a minimum to for lender protection
     *  @return The minimum liquidation incentive for liquidators, equivalent to 2% of collateral
     */
    function liquidationIncentiveMin() external pure returns (uint256);

    /**
     *  @return The maximum liquidation incentive for liquidators, equivalent to 20% of collateral
     */
    function liquidationIncentiveMax() external pure returns (uint256);

    /**
     *  @notice No minimum as the default is 0
     *  @return Maximum fee the protocol is allowed to keep from each liquidation, equivalent to 20%
     */
    function liquidationFeeMax() external pure returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice 👽
     *  @notice Updates price oracle with the factory's latest oracle if necessary
     */
    function setNebulaOracle() external;

    /**
     *  @notice 👽
     *  @notice Updates the debt ratio for the lending pool.
     *  @param  newDebtRatio The new requested point at which a loan is liquidatable
     */
    function setDebtRatio(uint256 newDebtRatio) external;

    /**
     *  @notice 👽
     *  @dev Updates the liquidation incentive for the lending pool.
     *  @param  newLiquidationIncentive The new requested profit liquidators keep from the collateral.
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentive) external;

    /**
     *  @notice 👽
     *  @notice Updates the fee the protocol keeps for every liquidation.
     *  @param newLiquidationFee The new requested fee taken from the liquidation incentive.
     */
    function setLiquidationFee(uint256 newLiquidationFee) external;
}


// File test/mock-contracts/interfaces/ICygnusCollateralModel.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

interface ICygnusCollateralModel is ICygnusCollateralControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  @custom:error PriceTokenAInvalid Emitted when price of Token A <= 100
     */
    error CygnusCollateralModel__PriceTokenAInvalid(uint256 priceTokenA);

    /**
     *  @custom:error PriceTokenBInvalid Emitted when price of Token B <= 100
     */
    error CygnusCollateralModel__PriceTokenBInvalid(uint256 priceTokenB);

    /**
     *  @custom:error PriceTokenBInvalid Emitted when price of Token B <= 100
     */
    error CygnusCollateralModel__BorrowerCantBeAddressZero(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Gets the fair price of token A and token B from a LP Token using the price oracle
     *  @return priceTokenA The fair price of Token A.
     *  @return priceTokenB The fair price of Token B.
     */
    function getTimeWeightedPrices() external returns (uint256 priceTokenA, uint256 priceTokenB);

    /**
     *  @param borrower The address of the borrower.
     *  @return liquidity The account's liquidity.
     *  @return shortfall If user has no liquidity, return the shortfall.
     */
    function accountLiquidity(address borrower) external returns (uint256 liquidity, uint256 shortfall);

    /**
     *  @param borrower The address of the borrower, reverts if address(0)
     *  @param amountTokenA The total amount of token A in the account's collateral
     *  @param amountTokenB The total amount of token B in the account's collateral
     *  @return liquidity the account liquidity. If none, return 0
     *  @return shortfall the account shortfall. If none, return 0
     */
    function getAccountLiquidity(
        address borrower,
        uint256 amountTokenA,
        uint256 amountTokenB
    ) external returns (uint256 liquidity, uint256 shortfall);
}


// File test/mock-contracts/interfaces/ICygnusCollateral.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

// dependencies

/// @title ICygnusCollateral
/// @notice Interface for main collateral contract
interface ICygnusCollateral is ICygnusCollateralModel {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when the value of unlock is above user's total balance.
     */
    error CygnusCollateral__ValueInvalid(uint256 totalBalance);

    /**
     *  @custom:error Emitted when the user doesn't have enough liquidity for a transfer.
     */
    error CygnusCollateral__InsufficientLiquidity(bool);

    /**
     *  @custom:error Emitted when borrowable is not one of the pool's allowed borrow tokens.
     */
    error CygnusCollateral__BorrowableInvalid(address cygnusBorrow);

    /**
     *  @custom:error Emitted for liquidation when msg.sender is not borrowable.
     */
    error CygnusCollateral__NotBorrowable(address);

    /**
     *  @custom:error Emitted when there is no shortfall
     */
    error CygnusCollateral__NotLiquidatable(uint256 shortfall);

    /**
     *  @custom:error Emitted when liquidator is borrower.
     */
    error CygnusCollateral__LiquidatingSelf(address borrower);

    /**
     *  @custom:error Emitted when liquidator is borrower
     */
    error CygnusCollateral__InsufficientRedeemAmount(uint256 declaredRedeemTokens);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param sender is address of msg.sender
     *  @param redeemer is address of redeemer
     *  @param redeemAmount is redeemed ammount
     *  @param redeemTokens is the balance of
     *  @custom:event Emitted when collateral is safely redeemed
     */
    event RedeemCollateral(address sender, address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     *  @param borrower The address of redeemer
     *  @param liquidator The address of the liquidator
     *  @param denebAmount The amount being seized is the balance of
     *  @custom:event Emitted when collateral is seized
     */
    event SeizeCollateral(address borrower, address liquidator, uint256 denebAmount);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @param from The address of the borrower.
     *  @param value The amount to unlock.
     *  @return Whether tokens are unlocked or not.
     */
    function tokensUnlocked(address from, uint256 value) external returns (bool);

    /**
     *  @param borrower The address of the borrower.
     *  @param borrowableToken The address of the token the user wants to borrow.
     *  @param accountBorrows The amount the user wants to borrow.
     *  @return Whether the account can borrow.
     */
    function canBorrow(
        address borrower,
        address borrowableToken,
        uint256 accountBorrows
    ) external returns (bool);

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Updates balances of liquidator and borrower, should only be called by borrowable's liquidate function
     *  @param liquidator The address repaying the borrow and seizing the collateral
     *  @param borrower The address of the borrower
     *  @param repayAmount The number of collateral tokens to seize
     */
    function seizeDeneb(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256 denebAmount);

    /**
     *  @dev This should be called from `Altair` contract
     *  @param redeemer The address redeeming the tokens (Altair contract)
     *  @param redeemAmount The amount of the underlying asset being redeemed
     *  @param data Calldata passed from router contract
     *  @custom:security non-reentrant
     */
    function redeemDeneb(
        address redeemer,
        uint256 redeemAmount,
        bytes calldata data
    ) external;
}


// File test/mock-contracts/interfaces/ICygnusDeneb.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

/**
 *  @title The interface for a contract that is capable of deploying Cygnus collateral pools
 *  @notice A contract that constructs a Cygnus collateral pool must implement this to pass arguments to the pool
 */
interface ICygnusDeneb {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the collateral contract avoids setting constructor
     *  @dev Without constructor we can predict address for the borrow deployments, see CygnusPoolAddres.sol
     *  @return factory The address of the Cygnus factory
     *  @return underlying The address of the underlying LP Token
     *  @return borrowDAITokenA The address of the first Cygnus borrow token
     *  @return borrowDAITokenB The address of the second Cygnus borrow token
     */
    function collateralParameters()
        external
        returns (
            address factory,
            address underlying,
            address borrowDAITokenA,
            address borrowDAITokenB
        );

    /**
     *  @notice Function to deploy the collateral contract of a lending pool
     *  @param underlying The address of the underlying LP Token
     *  @param borrowDAITokenA The address of the first Cygnus borrow token
     *  @param borrowDAITokenB The address of the second Cygnus borrow token
     *  @return deneb The address of the new deployed Cygnus collateral contract
     */
    function deployDeneb(
        address underlying,
        address borrowDAITokenA,
        address borrowDAITokenB
    ) external returns (address deneb);
}


// File test/mock-contracts/interfaces/ICygnusBorrowControl.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

/**
 *  @title ICygnusBorrowControl
 */
interface ICygnusBorrowControl is ICygnusTerminal {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when trying to update a borrow parameter and the number is outside of range allowed
     */
    error CygnusBorrowControl__ParameterNotInRange(uint256);

    /**
     *  @custom:error Emitted when updating the borrow tracker is the zero address
     */
    error CygnusBorrowControl__BorrowTrackerCantBeZero(address);

    /**
     *  @custom:error Emitted when calling admin only functions from non-admin account
     */
    error CygnusBorrowControl__CygnusAdminOnly(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:event Emitted when a new borrow tracker is set
     */
    event NewCygnusBorrowTracker(address newBorrowTracker);

    /**
     *  @custom:event Emitted when a new kink utilization rate is set.
     */
    event NewKinkUtilizationRate(uint256 newKinkUtilizationRate);

    /**
     *  @custom:event Emitted when a new reserve factor is set.
     */
    event NewReserveFactor(uint256 newReserveFactor);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    // ───────────────────── Important Addresses  ──────────────────────

    /**
     *  @notice Address of the collateral contract.
     */
    function collateral() external view returns (address);

    /**
     *  @notice Address of the borrow tracker.
     */
    function cygnusBorrowTracker() external view returns (address);

    // ────────────────────── Current pool rates  ───────────────────────

    /**
     *  @notice Percentage of the total initial borrow that goes to reserves, equivalent to 0.1%.
     */
    function cygnusBorrowFee() external view returns (uint256);

    /**
     *  @notice The current exchange rate of tokens.
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     *  @notice Current utilization point at which the jump multiplier is applied in this lending pool.
     */
    function kink() external view returns (uint256);

    /**
     *  @notice Percentage of interest that is routed to this market's Reserve Pool.
     */
    function reserveFactor() external view returns (uint256);

    // ──────────────────── Min/Max this pool allows  ────────────────────

    /**
     *  @notice Maximum base interest rate allowed (20%).
     */
    function baseRateMax() external pure returns (uint256);

    /**
     *  @notice Minimum kink utilization point allowed, equivalent to 50%
     */
    function kinkUtilizationRateMin() external pure returns (uint256);

    /**
     *  @notice Maximum kink utilization point allowed, equivalent to 95%
     */
    function kinkUtilizationRateMax() external pure returns (uint256);

    /**
     *  @notice The maximum reserve factor allowed, equivalent to 50%.
     */
    function reserveFactorMax() external pure returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */
    /**
     *  @notice 👽
     *  @notice Sets new Cygnus Borrow Tracker.
     */
    function setCygnusBorrowTracker(address newBorrowTracker) external;

    /**
     *  @notice 👽
     *  @param newKinkUtilizationRate The new utilization rate at which the jump kultiplier takes effect
     */
    function setKinkUtilizationRate(uint256 newKinkUtilizationRate) external;

    /**
     *  @notice 👽
     *  @param newReserveFactor The new reserve factor for the pool
     */
    function setReserveFactor(uint256 newReserveFactor) external;
}


// File test/mock-contracts/interfaces/ICygnusBorrowInterest.sol

// ign-License-Identifier: Unlicensed

pragma solidity >=0.8.4;

interface ICygnusBorrowInterest is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  We define no errors in our interest rate contract as most errors are handled by parent contracts.
     */

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param jumpMultiplierPerYear The multiplierPerSecond after hitting a specified utilization point
     *  @param kink_ is the utilization rate at which the kink happens
     *  custom:event Emitted when a new interest rate is set
     */
    event NewInterestParameter(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ───────────────────────────────────── Public ─────────────────────────────────────  */

    /**
     *  @notice The approximate number of seconds per year that is assumed by the interest rate model
     */
    function secondsPerYear() external view returns (uint32);

    /**
     *  @notice The multiplier of utilization rate that gives the slope of the interest rate
     */
    function multiplierPerSecond() external view returns (uint256);

    /**
     *  @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
    function baseRatePerSecond() external view returns (uint256);

    /**
     *  @notice The multiplier Per Second after hitting a specified utilization point
     */
    function jumpMultiplierPerSecond() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Internal function to update the parameters of the interest rate model
     *  @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by 1e18)
     *  @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by 1e18)
     *  @param jumpMultiplierPerYear The multiplierPerSecond after hitting a specified utilization point
     *  @param kink_ The utilization point at which the jump multiplier is applied
     */
    function updateJumpRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink_
    ) external;
}


// File test/mock-contracts/interfaces/ICygnusBorrowApprove.sol

// ign-License-Identifier: Unlicensed

pragma solidity >=0.8.4;

/**
 *  @title CygnusBorrowApprove
 *  @dev Interface for approving Borrow allowances
 */
interface ICygnusBorrowApprove is ICygnusBorrowControl {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when the recovered owner does not match the actual owner.
     */
    error CygnusBorrowApprove__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

    /**
     *  @custom:error Emitted when the owner is the zero address.
     */
    error CygnusBorrowApprove__OwnerZeroAddress(address owner);

    /**
     *  @custom:error Emitted when the permit expired.
     */
    error CygnusBorrowApprove__PermitExpired(uint256 deadline);

    /**
     *  @custom:error Emitted when the recovered owner is the zero address.
     */
    error CygnusBorrowApprove__RecoveredOwnerZeroAddress(address recoveredOwner);

    /**
     *  @notice Emitted when the spender is the zero address.
     */
    error CygnusBorrowApprove__SpenderZeroAddress(address spender);

    /**
     *  @notice Emitted when the owner is the spender.
     */
    error CygnusBorrowApprove__OwnerIsSpender(address owner, address spender);

    /**
     *  @notice Emitted when the borrow allowance is invalid.
     */
    error CygnusBorrowApprove__InsufficientBorrowAmount(uint256 currentAllowance);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:event Emitted when borrow is approved.
     */
    event BorrowApproved(address owner, address spender, uint256 amount);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice IERC721 permit typehash for signature based borrow approvals
     *  @return The keccak256 of the owner, spender, value, nonce and deadline
     */
    function BORROW_PERMIT_TYPEHASH() external view returns (bytes32);

    /**
     *  @notice Mapping of spending allowances from one address to another address
     *  @param owner The address of the token owner
     *  @param spender The address of the token spender
     *  @return The maximum amount the spender can spend
     */
    function accountBorrowAllowances(address owner, address spender) external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @param owner The address owner of the tokens
     *  @param spender The user allowed to spend the tokens
     *  @param value The maximum amount of tokens the spender may spend
     *  @param deadline A future time...
     *  @param v Must be a valid secp256k1 signature from the owner along with r and s
     *  @param r Must be a valid secp256k1 signature from the owner along with v and s
     *  @param s Must be a valid secp256k1 signature from the owner along with r and v
     */
    function borrowPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     *  @param spender The user allowed to spend the tokens
     *  @param value The amount of tokens approved to spend
     */
    function accountBorrowApprove(address spender, uint256 value) external returns (bool);
}


// File test/mock-contracts/interfaces/ICygnusBorrowTracker.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;


interface ICygnusBorrowTracker is ICygnusBorrowInterest, ICygnusBorrowApprove {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
    /**
     *  @custom:error Emitted if there is a shortfall in the account's balances.
     */
    error CygnusBorrowTracker__AddressZeroInvalidBalance(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param cashStored Total balance of this market.
     *  @param interestAccumulated Interest accumulated since last update.
     *  @param borrowIndexStored orrow index
     *  @param totalBorrowsStored Total borrow balances.
     *  @param borrowRateStored The current borrow rate.
     *  @custom:event Emitted when interest is accrued.
     */
    event AccrueInterest(
        uint256 cashStored,
        uint256 interestAccumulated,
        uint256 borrowIndexStored,
        uint256 totalBorrowsStored,
        uint256 borrowRateStored
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice The current total DAI reserves stored for this lending pool.
     */
    function totalReserves() external view returns (uint128);

    /**
     *  @notice Total borrows in the lending pool.
     */
    function totalBorrows() external view returns (uint128);

    /**
     *  @notice Initial borrow index of the market equivalent to 1e18.
     */
    function borrowIndex() external view returns (uint112);

    /**
     *  @notice The current borrow rate stored for the lending pool.
     */
    function borrowRate() external view returns (uint112);

    /**
     *  @notice block.timestamp of the last accrual.
     */
    function lastAccrualTimestamp() external view returns (uint32);

    /**
     *  @notice This public view function is used to get the borrow balance of users based on stored data.
     *  @dev It is used by CygnusCollateral and CygnusCollateralModel contracts.
     *  @param borrower The address whose balance should be calculated.
     *  @return balance The account's stored borrow balance or 0 if borrower's interest index is zero.
     */
    function getBorrowBalance(address borrower) external view returns (uint256 balance);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Tracks all users borrows.
     */
    function trackBorrow(
        address borrower,
        uint256 accountBorrows,
        uint256 accountBorrowIndex
    ) external;

    /**
     *  @notice Accrues interest rate and updates borrow rate and total cash.
     */
    function accrueInterest() external;
}


// File test/mock-contracts/interfaces/ICygnusBorrow.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

interface ICygnusBorrow is ICygnusBorrowTracker {
    /*  ═══════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when the borrow amount is higher than total balance
     */
    error CygnusBorrow__BorrowExceedsTotalBalance(uint256);

    /**
     *  @custom:error Emitted if there is a shortfall in the account's balances.
     */
    error CygnusBorrow__InsufficientLiquidity(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Event for account liquidations indexed by periphery, borrower and liquidator addresses.
     *  @param sender Indexed address of msg.sender (should be `Router` address)
     *  @param borrower Indexed address the account with negative account liquidity that shall be liquidated.
     *  @param liquidator Indexed address of the liquidator.
     *  @param denebAmount The amount of the underlying asset to be seized.
     *  @param repayAmount The amount of the underlying asset to be repaid (factors in liquidation incentive).
     *  @param accountBorrowsPrior Record of borrower's total borrows before this event.
     *  @param accountBorrows Record of borrower's present borrows (accountBorrowsPrior + borrowAmount).
     *  @param totalBorrowsStored Record of the protocol's cummulative total borrows after this event.
     *  @custom:event Emitted upon a successful liquidation.
     */
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed liquidator,
        uint256 denebAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrowsStored
    );

    /**
     *  @notice Event for account borrows and repays indexed by periphery, borrower and receiver addresses.
     *  @param sender Indexed address of msg.sender (should be `Router` address).
     *  @param receiver Indexed address of receiver (if repay = this is address(0), if borrow `Router` address).
     *  @param borrower Indexed address of the borrower.
     *  @param borrowAmount If borrow calldata, the amount of the underlying asset to be borrowed, else 0.
     *  @param repayAmount If repay calldata, the amount of the underlying borrowed asset to be repaid, else 0.
     *  @param accountBorrowsPrior Record of borrower's total borrows before this event.
     *  @param accountBorrows Record of borrower's total borrows after this event ( + borrowAmount) or ( - repayAmount)
     *  @param totalBorrowsStored Record of the protocol's cummulative total borrows after this event.
     *  @custom:event Emitted upon a successful borrow or repay.
     */
    event Borrow(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 borrowAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrowsStored
    );

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice This low level function should only be called from Router contract only.
     *  @param borrower The address of the borrower being liquidated
     *  @param liquidator The address of the liquidator.
     *  @return seizeTokens The amount of tokens to liquidate.
     */
    function liquidate(address borrower, address liquidator) external returns (uint256 seizeTokens);

    /**
     *  @notice This low level function should only be called from Router contract only.
     *  @notice It accrues before initializing and updates the total balance. Emits Sync event.
     *  @param borrower The address of the Borrow contract.
     *  @param receiver The address of the receiver of the borrow amount.
     *  @param borrowAmount The amount of the underlying asset to borrow.
     *  @param data Calltype data passed to Router contract.
     */
    function borrow(
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    /**
     *  @notice Overrides the base exchangeRate
     */
    function exchangeRate() external override returns (uint256);

    /**
     *  @notice Overrides the base Sync
     */
    function sync() external override;
}


// File test/mock-contracts/interfaces/ICygnusAlbireo.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies

/**
 *  @title The interface for a contract that is capable of deploying Cygnus borrow pools
 *  @notice A contract that constructs a Cygnus borrow pool must implement this to pass arguments to the pool
 */
interface ICygnusAlbireo {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Passing the struct parameters to the borrow contracts avoids setting constructor parameters
     *  @return factory The address of the Cygnus factory assigned to `Hangar18`
     *  @return underlying The address of the underlying borrow token (address of DAI, USDc, etc.)
     *  @return collateral The address of the Cygnus collateral contract for this borrow token
     */
    function borrowParameters()
        external
        returns (
            address factory,
            address underlying,
            address collateral
        );

    /**
     *  @notice Function to deploy the borrow contracts of a lending pool
     *  @notice Called twice by Factory twice during deployment of lending pool to create borrow tokens A and B
     *  @param underlying The address of the underlying borrow token (address of DAI, USDc, etc.)
     *  @param collateral The address of the Cygnus collateral contract for this borrow token
     *  @return albireo The address of the new borrow contract
     */
    function deployAlbireo(
        address underlying,
        address collateral,
        uint8 albireoIndex
    ) external returns (address albireo);
}


// File test/mock-contracts/interfaces/ICygnusFactory.sol

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Deployers


/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface ICygnusFactory {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:error Emitted when trying to deploy a shuttle that already exists
     */
    error CygnusFactory__ShuttleAlreadyDeployed(address);

    /**
     *  @custom:error Emitted when trying to deploy an already initialized collateral arm
     */
    error CygnusFactory__CollateralAlreadyExists(address);

    /**
     *  @custom:error Emitted when borrow token A already exists for this shuttle
     */
    error CygnusFactory__BorrowATokenAlreadyExists(address);

    /**
     *  @custom:error Emitted when borrow token B already exists for this shuttle
     */
    error CygnusFactory__BorrowBTokenAlreadyExists(address);

    /**
     *  @custom:error Emitted when predicted collateral address doesn't match with deployed, reverting whole tx
     */
    error CygnusFactory__CollateralAddressMismatch(address);

    /**
     *  @custom:error Emitted when the new oracle is the zero address
     */
    error CygnusFactory__CygnusNebulaCantBeZero(address);

    /**
     *  @custom:error Emitted when the oracle is already set
     */
    error CygnusFactory__CygnusNebulaDuplicate(address);

    /**
     *  @custom:error Emitted when caller is not Admin
     */
    error CygnusFactory__CygnusAdminOnly(address);

    /**
     *  @custom:error Emitted when pending reserves contract address is the zero address
     */
    error CygnusFactory__PendingReservesCantBeZero(address);

    /**
     *  @custom:error Emitted when pending Cygnus admin is the zero address
     */
    error CygnusFactory__CygnusAdminCantBeZero(address);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. CUSTOM EVENTS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @param lpTokenPair The address of the underlying LP Token
     *  @param token0 The address of Token A of underlying
     *  @param token1 The address of Token B of underlying
     *  @param shuttleID The ID of this lending pool
     *  @param collateral The address of the Cygnus collateral
     *  @param borrowDAITokenA The address of borrowable Token A
     *  @param borrowDAITokenB The address of borrowable Token B
     *  @custom:event Emitted when a new lending pool is launched
     */
    event NewShuttleLaunched(
        address indexed lpTokenPair,
        address indexed token0,
        address indexed token1,
        uint256 shuttleID,
        address collateral,
        address borrowDAITokenA,
        address borrowDAITokenB
    );

    /**
     *  @param oldCygnusNebula Address of the old price oracle
     *  @param newCygnusNebula Address of the new confirmed price oracle
     *  @custom:event Emitted when a new price oracle is set
     */
    event NewCygnusNebulaOracle(ICygnusNebulaOracle oldCygnusNebula, ICygnusNebulaOracle newCygnusNebula);

    /**
     *  @param pendingAdmin Address of the requested admin
     *  @param _admin Address of the present admin
     *  @custom:event Emitted when a new Cygnus admin is requested
     */
    event PendingCygnusAdmin(address pendingAdmin, address _admin);

    /**
     *  @param oldAdmin Address of the old admin
     *  @param newAdmin Address of the new confirmed admin
     *  @custom:event Emitted when a new Cygnus admin is confirmed
     */
    event NewCygnusAdmin(address oldAdmin, address newAdmin);

    /**
     *  @param oldPendingVegaContract Address of the current `Vega` contract
     *  @param newPendingVegaContract Address of the requested new `Vega` contract
     *  @custom:event Emitted when a new implementation contract is requested
     */
    event PendingVegaTokenManager(address oldPendingVegaContract, address newPendingVegaContract);

    /**
     *  @param oldVegaTokenManager Address of old `Vega` contract
     *  @param vegaTokenManager Address of the new confirmed `Vega` contract
     *  @custom:event Emitted when a new implementation contract is confirmed
     */
    event NewVegaTokenManager(address oldVegaTokenManager, address vegaTokenManager);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @return The address of the Cygnus Admin which grants special permissions in collateral/borrow control contracts
     */
    function admin() external view returns (address);

    /**
     *  @notice The address of the requested account to be Admin
     */
    function pendingNewAdmin() external view returns (address);

    /**
     *  @return The address of `vegaTokenManager` which is the contract that handles Cygnus cashflow and special calls
     */
    function vegaTokenManager() external view returns (address);

    /**
     *  @return The address of the requested contract to be the Vega Token Manager
     */
    function pendingVegaTokenManager() external view returns (address);

    /**
     * @return The address of the Collateral deployer
     */
    function collateralDeployer() external view returns (ICygnusDeneb);

    /**
     * @return The address of the Borrow deployer
     */
    function borrowDeployer() external view returns (ICygnusAlbireo);

    /**
     * @return The address of the Cygnus price oracle
     */
    function cygnusNebulaOracle() external view returns (ICygnusNebulaOracle);

    /**
     *  @notice Official record for all the pairs deployed
     *  @param lpTokenPair The address of the LP Token
     *  @return isInitialized Whether this pair exists or not
     *  @return shuttleID The ID of this shuttle
     *  @return collateral The address of the collateral
     *  @return borrowDAITokenA The address of the borrowing Token A
     *  @return borrowDAITokenB The address of the borrowing Token B
     */
    function getShuttles(address lpTokenPair)
        external
        view
        returns (
            bool isInitialized,
            uint24 shuttleID,
            address collateral,
            address borrowDAITokenA,
            address borrowDAITokenB
        );

    /**
     *  @return Addresses of all the pools that have been deployed
     */
    function allShuttles(uint256) external view returns (address);

    /**
     *  @return The total number of pools deployed
     */
    function shuttlesLength() external view returns (uint256);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Initializes both Borrow arms and the collateral arm
     *  @notice If successes initializes oracle for the collateral arm
     *  @param lpTokenPair The address of the underlying LP Token this pool is for
     *  @return borrowDAITokenA The address of the first Cygnus borrow contract for this pool
     *  @return borrowDAITokenB The address of the second Cygnus borrow contract for this pool
     *  @return collateral The address of the Cygnus collateral contract for both borrow tokens
     *  @custom:error non-reentrant
     */
    function deployShuttle(address lpTokenPair)
        external
        returns (
            address borrowDAITokenA,
            address borrowDAITokenB,
            address collateral
        );

    /**
     *  @notice Sets a new price oracle 👽
     *  @param newPriceOracle Address of the new price oracle
     */
    function setNewNebulaOracle(address newPriceOracle) external;

    /**
     *  @notice Sets a new pending admin for Cygnus 👽
     *  @param newCygnusAdmin Address of the requested Cygnus admin
     */
    function setPendingAdmin(address newCygnusAdmin) external;

    /**
     *  @notice Approves the pending admin and is the new Cygnus admin 👽
     */
    function setNewCygnusAdmin() external;

    /**
     *  @notice Request a new implementation contract for Cygnus 👽
     *  @param _newVegaTokenManager The address of the requested contract to be the new Vega Token Manager
     */
    function setPendingVegaTokenManager(address _newVegaTokenManager) external;

    /**
     *  @notice Accepts the new implementation contract 👽
     */
    function setNewVegaTokenManager() external;
}


// File test/mock-contracts/utils/Context.sol

// ign-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity >=0.8.4;

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


// File test/mock-contracts/utils/ReentrancyGuard.sol

// ign-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title ReentrancyGuard
/// @author Paul Razvan Berg
/// @notice Contract module that helps prevent reentrant calls to a function.
///
/// Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can be applied
/// to functions to make sure there are no nested (reentrant) calls to them.
///
/// Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may not
/// call one another. This can be worked around by making those functions `private`, and then adding
/// `external` `nonReentrant` entry points to them.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when there is a reentrancy call.
    error ReentrantCall();

    /// PRIVATE STORAGE ///

    bool private notEntered;

    /// CONSTRUCTOR ///

    /// Storing an initial non-zero value makes deployment a bit more expensive but in exchange the
    /// refund on every call to nonReentrant will be lower in amount. Since refunds are capped to a
    /// percetange of the total transaction's gas, it is best to keep them low in cases like this one,
    /// to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /// MODIFIERS ///

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// @dev Calling a `nonReentrant` function from another `nonReentrant` function
    /// is not supported. It is possible to prevent this from happening by making
    /// the `nonReentrant` function external, and make it call a `private`
    /// function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, notEntered will be true.
        if (!notEntered) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail.
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (https://eips.ethereum.org/EIPS/eip-2200).
        notEntered = true;
    }
}


// File test/mock-contracts/libraries/CygnusPoolAddress.sol

// ign-License-Identifier: Unlicensed

/**
 *  @title CygnusPoolAddress Provides functions for deriving Cygnus collateral addresses from the factory
 */
pragma solidity >=0.8.4;

library CygnusPoolAddress {
    /**
     *  @notice keccak256(creationCode) for collateral contracts
     *  @notice This is used to pre-calculate the address of the next collateral contract
     */
    function getCollateralContract(
        address lpTokenPair,
        address factory,
        address collateralDeployer
    ) internal pure returns (address _collateral) {
        _collateral = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            collateralDeployer,
                            keccak256(abi.encode(lpTokenPair, factory)),
                            // keccak256(collateral.sol bytecode)
                            bytes32(0xb02e160b9584a2e6958d4c3da6b5368690cb9a3dc41e0b7c3d47d5e61a229883)
                        )
                    )
                )
            )
        );
    }
}


// File test/mock-contracts/interfaces/IDexPair.sol

//ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

// only using relevant functions for CygnusNebula Oracle

/// @notice Interface for most DEX pairs (TraderJoe, Pangolin, Sushi, Uniswap, etc.)
interface IDexPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);
}


// File test/mock-contracts/CygnusFactory.sol

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  .
    .               .            .               .      🛰️     .           .                 *              .
           █████████           ---======*.                                                 .           ⠀
          ███░░░░░███                                               📡                🌔                       . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .           .
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                       ███ ░███  ███ ░███                .                 .                 .  ⠀
     🛰️  .             ░░██████  ░░██████                                             .                 .           
                       ░░░░░░    ░░░░░░      -------=========*                      .                     ⠀
           .                            .       .          .            .                          .             .⠀
    
        CYGNUS FACTORY V1 - `Hangar18`                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */

// ign-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

// Dependencies



// Libraries

// IUniswapV2Pair

/**
 *  @title CygnusCollateralControl
 *  @author CygnusDAO
 *  @notice Factory contract for Cygnus Collateral and Borrow contracts
 */
contract CygnusFactory is ICygnusFactory, Context, ReentrancyGuard {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Modifier for Cygnus Admin only
     */
    modifier cygnusAdmin() {
        isCygnusAdmin();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusFactory
     */
    address public override admin;

    /**
     *  @inheritdoc ICygnusFactory
     */
    ICygnusNebulaOracle public override cygnusNebulaOracle; // Price oracle

    /**
     *  @inheritdoc ICygnusFactory
     */
    address public override pendingNewAdmin;

    /**
     *  @inheritdoc ICygnusFactory
     */
    address public override vegaTokenManager;

    /**
     *  @inheritdoc ICygnusFactory
     */
    address public override pendingVegaTokenManager;

    // Immutables for Factory V1

    /**
     *  @inheritdoc ICygnusFactory
     */
    ICygnusDeneb public immutable override collateralDeployer; // Collateral deployer

    /**
     *  @inheritdoc ICygnusFactory
     */
    ICygnusAlbireo public immutable override borrowDeployer; // Borrow deployer

    /**
     *  @notice Container for the official record of all individual lending pools deployed by factory
     *  @custom:struct isInitialized Whether or not the lending pool is initialized
     *  @custom:struct shuttleID The ID of the lending pool
     *  @custom:struct collateral The address of the Cygnus collateral
     *  @custom:struct borrowDAITokenA The address of the borrowing Token A
     *  @custom:struct borrowDAITokenB The address of the second lending token (if there is)
     */
    struct Shuttle {
        bool isInitialized;
        uint24 shuttleID;
        address collateral;
        address borrowDAITokenA;
        address borrowDAITokenB;
    }

    /**
     *  @inheritdoc ICygnusFactory
     */
    mapping(address => Shuttle) public override getShuttles;

    /**
     *  @inheritdoc ICygnusFactory
     */
    address[] public override allShuttles;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Sets admin/tokensplitter/deployer/oracle addresses
     *  @param _cygnusAdmin Address of the Cygnus Admin to update important protocol parameters
     *  @param _vegaTokenManager Address of the contract that handles weighted forwarding of Erc20 tokens
     *  @param _collateralDeployer Address of the collateral deployer (Deneb)
     *  @param _borrowDeployer Address of the borrow deployer (Albireo)
     *  @param _cygnusNebulaOracle Address of the price oracle
     */
    constructor(
        address _cygnusAdmin,
        address _vegaTokenManager,
        ICygnusDeneb _collateralDeployer,
        ICygnusAlbireo _borrowDeployer,
        ICygnusNebulaOracle _cygnusNebulaOracle
    ) {
        admin = _cygnusAdmin;

        vegaTokenManager = _vegaTokenManager;

        collateralDeployer = _collateralDeployer;

        borrowDeployer = _borrowDeployer;

        cygnusNebulaOracle = _cygnusNebulaOracle;

        /// @custom:event NewCygnusAdmin
        emit NewCygnusAdmin(address(0), _cygnusAdmin);

        /// @custom:event NewTokenSplitter
        emit NewVegaTokenManager(address(0), _vegaTokenManager);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Private function to get the address of the 2 tokens that compose the LP Token
     *  @param lpTokenPair The address of the LP Token
     *  @return tokenA Address of the first token from the LP Token
     *  @return tokenB Address of the second token from the LP Token
     */
    function getTokensPrivate(address lpTokenPair) private view returns (address tokenA, address tokenB) {
        tokenA = IDexPair(lpTokenPair).token0();

        tokenB = IDexPair(lpTokenPair).token1();
    }

    /**
     *  @notice Only Cygnus admins can deploy pools in Cygnus V1
     */
    function isCygnusAdmin() private view {
        /// @custom:error Avoid unless admin
        if (_msgSender() != admin) {
            revert CygnusFactory__CygnusAdminOnly(_msgSender());
        }
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusFactory
     */
    function shuttlesLength() external view override returns (uint256) {
        return allShuttles.length;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Private ────────────────────────────────────────────────  */

    /**
     *  @notice Creates a record for each LP Token pair deployed by Cygnus
     *  @param lpTokenPair Address of the DEX' LP Token for this shuttle
     */
    function boardShuttle(address lpTokenPair) private {
        /// @custom:error Avoid initializing two identical shuttles
        if (getShuttles[lpTokenPair].shuttleID != 0) {
            revert CygnusFactory__ShuttleAlreadyDeployed(lpTokenPair);
        }

        // Push to lending pool
        allShuttles.push(lpTokenPair);

        // Create the struct for this pair
        getShuttles[lpTokenPair] = Shuttle(
            false, // Initialized, default false until oracle is set
            uint24(allShuttles.length), // Lending pool ID
            address(0), // Collateral address
            address(0), // Cygnus borrowTokenA address
            address(0) // Cygnus borrowTokenB address
        );
    }

    /*  ────────────────────────────────────────────── external ───────────────────────────────────────────────  */

    /**
     *  3 Phases:
     *    i. Calculate Cygnus collateral address internally and get Token for Borrow contract
     *    ii. Deploy Collateral + Borrow contract and check if collateral == _collateral, reverts if mismatch
     *    iii. Initialize Oracle and Lending pool
     *
     *  @inheritdoc ICygnusFactory
     *  @custom:security non-reentrant
     */
    function deployShuttle(address lpTokenPair)
        external
        override
        nonReentrant
        cygnusAdmin
        returns (
            address borrowDAITokenA,
            address borrowDAITokenB,
            address collateral
        )
    {
        /*  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌ Phase 1 ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  */

        // Add this shuttle ID, reverts if already exists
        boardShuttle(lpTokenPair);

        // Get the pre-determined collateral address for this LP Token (check CygnusPoolAddres library)
        address _collateral = CygnusPoolAddress.getCollateralContract(
            lpTokenPair,
            address(this),
            address(collateralDeployer)
        );

        // Get the underlying for both borrow tokens (ie address of DAI, address of USDc)
        (address _borrowDAITokenA, address _borrowDAITokenB) = getTokensPrivate(lpTokenPair);

        /// @custom:error Avoid deploying same collateral twice
        if (getShuttles[lpTokenPair].collateral != address(0)) {
            revert CygnusFactory__CollateralAlreadyExists(lpTokenPair);
        }
        /// @custom:error Avoid deploying same borrow token twice for shuttle pool twice
        else if (getShuttles[lpTokenPair].borrowDAITokenA != address(0)) {
            revert CygnusFactory__BorrowATokenAlreadyExists(_borrowDAITokenA);
        }
        /// @custom:error Avoid deploying same borrow token twice for shuttle pool twice
        else if (getShuttles[lpTokenPair].borrowDAITokenB != address(0)) {
            revert CygnusFactory__BorrowBTokenAlreadyExists(_borrowDAITokenB);
        }

        /*  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌ Phase 2 ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  */

        // Deploy first borrow token
        borrowDAITokenA = borrowDeployer.deployAlbireo(_borrowDAITokenA, _collateral, uint8(0));

        // Deploy second borrow token
        borrowDAITokenB = borrowDeployer.deployAlbireo(_borrowDAITokenB, _collateral, uint8(1));

        // Deploy collateral
        collateral = collateralDeployer.deployDeneb(lpTokenPair, borrowDAITokenA, borrowDAITokenB);

        // Match expected collateral address with actual deployed collateral address
        // Reverts if already exists
        /// @custom:error Avoid deploying collateral pool with different addresses than expected
        if (collateral != _collateral) {
            revert CygnusFactory__CollateralAddressMismatch(collateral);
        }

        /*  ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌ Phase 3 ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  */

        // No way back now, initialize pool & oracle
        // Add first cygnus borrow contract to record
        getShuttles[lpTokenPair].borrowDAITokenA = borrowDAITokenA;

        // Add second cygnus borrow contract to record
        getShuttles[lpTokenPair].borrowDAITokenB = borrowDAITokenB;

        // Add collateral contract to record
        getShuttles[lpTokenPair].collateral = collateral;

        // Status for this pair
        (, , , , , bool nebulaOracleInitialized) = cygnusNebulaOracle.getCygnusNebulaPair(lpTokenPair);

        // Oracle is should never be initialized for this pair
        if (!nebulaOracleInitialized) {
            cygnusNebulaOracle.initializeCygnusNebula(lpTokenPair);
        }

        // This specific lending pool is initialized can't be deployed again
        getShuttles[lpTokenPair].isInitialized = true;

        /// @custom:event NewShuttleLaunched
        emit NewShuttleLaunched(
            lpTokenPair,
            _borrowDAITokenA,
            _borrowDAITokenB,
            allShuttles.length,
            collateral,
            borrowDAITokenA,
            borrowDAITokenB
        );
    }

    /**
     *  @inheritdoc ICygnusFactory
     */
    function setNewNebulaOracle(address newPriceOracle) external override cygnusAdmin {
        /// @custom:error Avoid not setting new cygnus admin, to destroy send to dEaD
        if (newPriceOracle == address(0)) {
            revert CygnusFactory__CygnusNebulaCantBeZero(newPriceOracle);
        } else if (newPriceOracle == address(cygnusNebulaOracle)) {
            revert CygnusFactory__CygnusNebulaDuplicate(newPriceOracle);
        }

        ICygnusNebulaOracle oldOracle = cygnusNebulaOracle;

        // Address of the requested account to be Cygnus admin
        cygnusNebulaOracle = ICygnusNebulaOracle(newPriceOracle);

        /// @custom:event PendingCygnusAdmin
        emit NewCygnusNebulaOracle(oldOracle, cygnusNebulaOracle);
    }

    /**
     *  @inheritdoc ICygnusFactory
     */
    function setPendingAdmin(address newCygnusAdmin) external override cygnusAdmin {
        /// @custom:error Avoid not setting new cygnus admin, to destroy send to dEaD
        if (newCygnusAdmin == address(0)) {
            revert CygnusFactory__CygnusAdminCantBeZero(newCygnusAdmin);
        }
        // Address of the requested account to be Cygnus admin
        pendingNewAdmin = newCygnusAdmin;

        /// @custom:event PendingCygnusAdmin
        emit PendingCygnusAdmin(admin, newCygnusAdmin);
    }

    /**
     *  @inheritdoc ICygnusFactory
     */
    function setNewCygnusAdmin() external override cygnusAdmin {
        // Address of the Admin up until now
        address _admin = admin;

        // Address of the new Cygnus Admin after this transaction
        admin = pendingNewAdmin;

        // Gas refund
        delete pendingNewAdmin;

        // @custom:event NewCygnusAdming
        emit PendingCygnusAdmin(_admin, admin);
    }

    /**
     *  @inheritdoc ICygnusFactory
     */
    function setPendingVegaTokenManager(address _newVegaTokenManager) external override cygnusAdmin {
        /// @custom:error Avoid not setting contract address, to destroy send to dEaD
        if (_newVegaTokenManager == address(0)) {
            revert CygnusFactory__PendingReservesCantBeZero(_newVegaTokenManager);
        }

        // Address of the Vega contract up until now
        pendingVegaTokenManager = _newVegaTokenManager;

        /// @custom:event NewVegaContract
        emit NewVegaTokenManager(vegaTokenManager, _newVegaTokenManager);
    }

    /**
     *  @inheritdoc ICygnusFactory
     */
    function setNewVegaTokenManager() external override cygnusAdmin {
        // Address of the Vega contract up until now
        address _vegaTokenManager = vegaTokenManager;

        // Address of the new Vega contract
        vegaTokenManager = pendingVegaTokenManager;

        // Gas refund
        delete pendingVegaTokenManager;

        /// @custom:event NewVegaContract
        emit NewVegaTokenManager(_vegaTokenManager, vegaTokenManager);
    }
}
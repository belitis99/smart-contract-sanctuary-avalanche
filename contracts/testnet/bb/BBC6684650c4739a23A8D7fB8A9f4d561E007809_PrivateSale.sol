// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    function decimals() external view returns (uint8);
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

contract PrivateSale is Ownable {
    // testnet
    // address USDT = 0x9a01bf917477dD9F5D715D188618fc8B7350cd22;
    // address USDC = 0x6701dbeF919500c7B030253fE0de17A41efAa1dE;
    // address USDCE = 0x45ea5d57BA80B5e3b0Ed502e9a08d568c96278F9;
    // address BUSD = 0x2326546463a8bA834378920f78bce8B36872e7ba;
    // address DAI = 0x6294225FC50D5fEa1B67BbD9fB543881757b57bE;
    // address XDX = 0x7d34e3C25C6255267074bDEB5171b8F65592c3Bf;
 
    address public USDT;
    address public USDC;
    address public USDCE;
    address public BUSD;
    address public DAI;
    address public XDX;

    // team wallet address
    address public multisig;

    // Price per XDX
    uint256 priceXDX = 5;

    event Buy(address _executor, string token, uint256 _deposit, uint256 _withdraw);

    constructor(address _multisig, address _USDT, address _USDC, address _USDCE, address _BUSD, address _DAI, address _XDX) {
        require(_multisig != address(0), "Invalid multisig address");
        require(_USDT != address(0), "Invalid USDT address");
        require(_USDC != address(0), "Invalid USDC address");
        require(_USDCE != address(0), "Invalid USDC.e address");
        require(_BUSD != address(0), "Invalid BUSD address");
        require(_DAI != address(0), "Invalid DAI address");
        require(_XDX != address(0), "Invalid XDX address");
        multisig = _multisig;
        USDT = _USDT;
        USDC = _USDC;
        USDCE = _USDCE;
        BUSD = _BUSD;
        DAI = _DAI;
        XDX = _XDX;
    }

    function buy(uint256 amountDeposit, string memory depositTokenName) public returns (uint256 result) {
        address tokenDeposit;

        if(keccak256(abi.encodePacked(depositTokenName)) == keccak256(abi.encodePacked("USDT"))) tokenDeposit = USDT;
        else if(keccak256(abi.encodePacked(depositTokenName)) == keccak256(abi.encodePacked("USDC"))) tokenDeposit = USDC;
        else if(keccak256(abi.encodePacked(depositTokenName)) == keccak256(abi.encodePacked("USDCE"))) tokenDeposit = USDCE;
        else if(keccak256(abi.encodePacked(depositTokenName)) == keccak256(abi.encodePacked("BUSD"))) tokenDeposit = BUSD;
        else if(keccak256(abi.encodePacked(depositTokenName)) == keccak256(abi.encodePacked("DAI"))) tokenDeposit = DAI;
        else revert("Incorrect deposit token.");


        uint256 decimalTokenDeposit = IERC20(tokenDeposit).decimals();
        uint256 multiplier = IERC20(XDX).decimals() - decimalTokenDeposit;

        require(msg.sender != address(0), "Address is zero.");
        require(amountDeposit >= 5000 * (10 ** decimalTokenDeposit), "Minimum deposit amount is 5000.");
        require(amountDeposit <= 250000 * (10 ** decimalTokenDeposit), "Max deposit amount is 250000.");
        require(amountDeposit * (10 ** multiplier) / priceXDX < balance(), "Insufficient withdrawal amount.");
        require(IERC20(tokenDeposit).balanceOf(msg.sender) >= amountDeposit, "Insufficient deposit balance");

        uint256 amountWithdrawalXDX = amountDeposit * (10 ** multiplier) / priceXDX;
        IERC20(tokenDeposit).transferFrom(msg.sender, multisig, amountDeposit);
        IERC20(XDX).transfer(msg.sender, amountWithdrawalXDX);

        emit Buy(msg.sender, depositTokenName, amountDeposit, amountWithdrawalXDX);
        
        return amountWithdrawalXDX;
    }

    function balance() public view returns (uint256) {
        return IERC20(XDX).balanceOf(address(this));
    }

    function withdraw(address recipient) public onlyOwner {
        uint256 _balance = balance();
        IERC20(XDX).transfer(recipient, _balance);
    }

    function renounceRate(uint256 _priceXDX) public onlyOwner {
        require(_priceXDX > 0, "Price must be greater than zero.");
        priceXDX = _priceXDX;
    }

    function renounceMultiSig(address _multisig) public onlyOwner {
        require(_multisig != address(0), "Invalid address.");
        multisig = _multisig;
    }
}
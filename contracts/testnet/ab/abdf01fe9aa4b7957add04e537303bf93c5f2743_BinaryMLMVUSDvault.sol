/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
        
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
                  

library SafeMath {                                                     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;           
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");                             
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract BinaryMLMVUSDvault is Ownable {    
    using SafeMath for uint256;

    bool private _reentrancyGuard;
    mapping (address => uint256) public tokenBalancesByUser;
    mapping (address => uint256) public totalDepositedByUser;
    mapping (address => uint256) public totalWithdrawnByUser;
    mapping (address => bool) public isRegistered;
    mapping (address => bool) public isSponsor;
    mapping(address => uint256) public totalSaveClickAdsData;
    mapping(address => uint256) public totalSaveUserDataForDR;
    mapping(address => uint256) public totalSaveUserDataForIDR;
    mapping(address => uint256) public totalSaveUserDataForPairing;
    //event SavedUserData(address _from, address _to, uint256);
    event SavedUserData(address _from, address _to, uint256);
    event SavedUserData(address indexed user, uint256 amount, string data);


    // zero address: 0x0000000000000000000000000000000000000000 0x8f4baaA53eF8B751E14DA92A2be43F67eb2d40aE
    address public VUSD = 0xB22e261C82E3D4eD6020b898DAC3e6A99D19E976; // VUSD Contract Address https://ventionscan.io/address/0x476A5b3F68885f5b7bfa7Ab916D4E0c7B5D9725f/transactions
    address public CCBAdminForDep = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // CCB Admin for Deposit
    address public CCBAdminForWithdraw = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // CCB Admin for Withdraw
    address public Wallet1 = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // Jethro 0xB295Db74bEd24aeCbeFc8E9e888b5D1b9B867b48
    address public Wallet2 = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // J co-Dev 0xE01015586a99108BaC22c76c54B1970631374E62
    address public Wallet3 = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // Ariel => 0xBEFd5aCFF5D036db7A2b453BC845F9091b7500c2 = good
    address public Wallet4 = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // Zaldy => 0x5d296CBBD8A1ebF6434B3976786270A3c8C796E4 = good
    address public Wallet5 = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // Deployer => 0xCECDDAA53689e295F98eb809ecFF81ee76bdeEe2
    address public Wallet6 = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // DEV
    address public Wallet7 = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // Deployer => 0xCECDDAA53689e295F98eb809ecFF81ee76bdeEe2
    address public Dev = 0xE24Ea83A28Ae068Ef1d1d1c6E7Ca08e35417d54A; // Dev
    uint256 public VNTTransactionFee = 0.01 * 10 ** 18; // 0.01 VNT // VNTTransactionFee // 0.010000000000000000 = 10000000000000000
    uint256 public DevFeePercentage = 0; // 1% of deposit and withdraw
    uint256 public AdminFeePercentage = 100; // 100 = 10% of deposit and withdraw
    uint256 public MinRegisterAmount = 20 * 10 ** 18; // 20 VUSD
    uint256 public MinWithdrawAmount = 50 * 10 ** 18; // 50 VUSD
    uint256 public ethShareOfWallet1 = 30; // 30% per txn = 2
    uint256 public ethShareOfWallet2 = 30; // 30% per txn = 2
    uint256 public ethShareOfWallet3 = 2; // 2% per txn = 3 ariel
    uint256 public ethShareOfWallet4 = 2; // 2% per txn = 4 zaldy
    uint256 public ethShareOfWallet5 = 2; // 2% per txn = 5
    uint256 public ethShareOfWallet6 = 2; // 2% per txn = 6
    uint256 public ethShareOfWallet7 = 2; // 2% per txn = 7
    uint256 public ethShareOfDev = 30; // 30% per txn
    address private deployer;

    constructor()
    {
        deployer = msg.sender;
    }

    modifier nonReentrant() {
        require(!_reentrancyGuard, 'no reentrancy');
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }

    function setDevidendsOfTxnFee(uint256 _rateOfWallet1, uint256 _rateOfWallet2, uint256 _rateOfWallet3, uint256 _rateOfWallet4, uint256 _rateOfWallet5, uint256 _rateOfWallet6, uint256 _rateOfWallet7, uint256 _rateOfDev) public
    {   
        require(msg.sender == deployer || msg.sender == Dev, "Invalid Caller");   
        require(_rateOfWallet1 + _rateOfWallet2 + _rateOfWallet3 + _rateOfWallet4 + _rateOfWallet5 + _rateOfWallet6 + _rateOfWallet7 + _rateOfDev > 99, "invalid sum of fees, should be equal or small than 100");
        ethShareOfWallet1 = _rateOfWallet1;
        ethShareOfWallet2 = _rateOfWallet2;
        ethShareOfWallet3 = _rateOfWallet3;
        ethShareOfWallet4 = _rateOfWallet4;
        ethShareOfWallet5 = _rateOfWallet5;
        ethShareOfWallet6 = _rateOfWallet6;
        ethShareOfWallet7 = _rateOfWallet7;
        ethShareOfDev = _rateOfDev;
    }

    function setTxnFee(uint256 _tax) public // VNT
    {   
        require(msg.sender == deployer || msg.sender == Dev, "Invalid Caller");
        VNTTransactionFee = _tax;
    }

    function setDevRoyalty(uint256 _rate) public
    {   
        require(msg.sender == deployer || msg.sender == Dev, "Invalid Caller");
        require(DevFeePercentage >=0 && DevFeePercentage <= 100, "Invalid Percentage"); // 100
        DevFeePercentage = _rate;
    }

    function setAdminCom(uint256 _rate) public {
        require(msg.sender == deployer || msg.sender == Dev, "Invalid Caller");
        require(AdminFeePercentage >=0 && AdminFeePercentage <= 100, "Invalid Percentage");
        AdminFeePercentage = _rate;
    }

    function changeWalletAddress(address _CCBAdminForDep, address _CCBAdminForWithdraw, address _addr1, address _addr2, address _addr3, address _addr4, address _addr5, address _addr6, address _addr7) public {
        require(msg.sender == deployer  || msg.sender == Dev, "Invalid Caller");
        CCBAdminForDep = _CCBAdminForDep;
        CCBAdminForWithdraw = _CCBAdminForWithdraw;
        Wallet1 = _addr1;
        Wallet2 = _addr2;
        Wallet3 = _addr3;
        Wallet4 = _addr4;
        Wallet5 = _addr5;
        Wallet6 = _addr6;
        Wallet7 = _addr7;
    }

    function changeDevAdd(address _addr) public 
    {
        require(msg.sender == deployer  || msg.sender == Dev, "Invalid Caller");
        Dev = _addr;
    }
   
    function setVUSD(address _addr) public
    {   
        require(msg.sender == deployer  || msg.sender == Dev, "Invalid Caller");
        VUSD = _addr;
    }
   
    function devideNativeTaxs(uint256 amount) internal  
    {
        payable(Wallet1).transfer(amount.mul(ethShareOfWallet1).div(100));
        payable(Wallet2).transfer(amount.mul(ethShareOfWallet2).div(100));
        payable(Wallet3).transfer(amount.mul(ethShareOfWallet3).div(100));
        payable(Wallet4).transfer(amount.mul(ethShareOfWallet4).div(100));
        payable(Wallet5).transfer(amount.mul(ethShareOfWallet5).div(100));
        payable(Wallet6).transfer(amount.mul(ethShareOfWallet6).div(100));
        payable(Wallet7).transfer(amount.mul(ethShareOfWallet7).div(100));
        payable(Dev).transfer(amount.mul(ethShareOfDev).div(100));
    }

    function setMinRegisterAmount(uint256 minimumAmount) public
    {   
        require(msg.sender == deployer  || msg.sender == Dev, "Invalid Caller");
        MinRegisterAmount = minimumAmount;
    }

    function registerWithVUSD(uint256 _amount) public payable nonReentrant
    {
        require(msg.value >= VNTTransactionFee, "You should pay ETHs");
        require(_amount >= MinRegisterAmount, "Amount should be lager than minimum deposit amount.");    
        devideNativeTaxs(msg.value);    
        IERC20(VUSD).transferFrom(msg.sender, address(this), _amount);   
        IERC20(VUSD).transfer(Dev, _amount.mul(DevFeePercentage).div(1000)); // 100
        IERC20(VUSD).transfer(CCBAdminForDep, _amount.mul(AdminFeePercentage).div(1000));       
        isRegistered[msg.sender] = true;          
        totalDepositedByUser[msg.sender] += _amount.sub(_amount.mul(DevFeePercentage.add(AdminFeePercentage)).div(100));  
    }

    function setMinWithdrawal(uint256 minimumAmount) public
    {   
        require(msg.sender == deployer  || msg.sender == Dev, "Invalid Caller");
        MinWithdrawAmount = minimumAmount;
    }    

    function withdrawVUSD(uint256 _amount) public payable nonReentrant
    {
        require(isRegistered[msg.sender] == true, "You are not registered");
        require(msg.value >= VNTTransactionFee, "You should pay ETHs");        
        require(_amount >= MinWithdrawAmount, "Amount should be lager than minimum withdraw amount.");        
        devideNativeTaxs(msg.value);    
        uint256 adminFeeAmount = _amount.mul(AdminFeePercentage).div(1000);
        uint256 ownerFeeAmount = _amount.mul(DevFeePercentage).div(1000); // 100
        uint256 realwithdrawAmount = _amount.sub(adminFeeAmount).sub(ownerFeeAmount);
        if(IERC20(VUSD).balanceOf(address(this)).sub(adminFeeAmount) >= 0 && tokenBalancesByUser[msg.sender] >= adminFeeAmount) IERC20(VUSD).transfer(CCBAdminForWithdraw, adminFeeAmount);  
        tokenBalancesByUser[msg.sender] -= adminFeeAmount;
        if(IERC20(VUSD).balanceOf(address(this)).sub(ownerFeeAmount) >= 0 && tokenBalancesByUser[msg.sender] >= ownerFeeAmount) IERC20(VUSD).transfer(Dev, ownerFeeAmount);  
        tokenBalancesByUser[msg.sender] -= ownerFeeAmount;
        if(IERC20(VUSD).balanceOf(address(this)).sub(realwithdrawAmount) >= 0 && tokenBalancesByUser[msg.sender] >= realwithdrawAmount) IERC20(VUSD).transfer(msg.sender, realwithdrawAmount);  
        tokenBalancesByUser[msg.sender] -= realwithdrawAmount;
    
        totalWithdrawnByUser[msg.sender] += _amount;   
    }



    function saveUserDataforDR(address from, address to, uint256 _amount) public payable 
    {        
        require( msg.sender == to, "Caller should be equal with 'to' address ");        
        require( isRegistered[to] == true, "'to' address is not registered");      
        require( isRegistered[from] == true, "'from' address is not registered"); 
        require(from != to, "'from' address should not be the same as 'to' address");     
        require(msg.value >= VNTTransactionFee, "You should pay ETHs");
        require(_amount > 0,  "Amount should be lager then zero");     
        devideNativeTaxs(msg.value);        
        tokenBalancesByUser[to] = tokenBalancesByUser[to].add(_amount);         
        if(tokenBalancesByUser[from] >  _amount) tokenBalancesByUser[from] = tokenBalancesByUser[from].sub(_amount); 
        else tokenBalancesByUser[from] = 0;

        totalSaveUserDataForDR[to] += _amount;

        emit SavedUserData(from, to , _amount);  
    }


    function saveUserDataforIDR(address from, address to, uint256 _amount) public payable 
    {        
        require( msg.sender == to, "Caller should be equal with 'to' address ");        
        require( isRegistered[to] == true, "'to' address is not registered");      
        require( isRegistered[from] == true, "'from' address is not registered"); 
        require(from != to, "'from' address should not be the same as 'to' address");     
        require(msg.value >= VNTTransactionFee, "You should pay ETHs");
        require(_amount > 0,  "Amount should be lager then zero");     
        devideNativeTaxs(msg.value);        
        tokenBalancesByUser[to] = tokenBalancesByUser[to].add(_amount);         
        if(tokenBalancesByUser[from] >  _amount) tokenBalancesByUser[from] = tokenBalancesByUser[from].sub(_amount); 
        else tokenBalancesByUser[from] = 0;

        totalSaveUserDataForIDR[to] += _amount;

        emit SavedUserData(from, to , _amount);  
    }

    function saveUserDataforPairing(address from, address to, uint256 _amount) public payable 
    {        
        require( msg.sender == to, "Caller should be equal with 'to' address ");        
        require( isRegistered[to] == true, "'to' address is not registered");      
        require( isRegistered[from] == true, "'from' address is not registered");
        require(from != to, "'from' address should not be the same as 'to' address");      
        require(msg.value >= VNTTransactionFee, "You should pay ETHs");
        require(_amount > 0,  "Amount should be lager then zero");     
        devideNativeTaxs(msg.value);        
        tokenBalancesByUser[to] = tokenBalancesByUser[to].add(_amount);         
        if(tokenBalancesByUser[from] >  _amount) tokenBalancesByUser[from] = tokenBalancesByUser[from].sub(_amount); 
        else tokenBalancesByUser[from] = 0;

        totalSaveUserDataForPairing[to] += _amount;

        emit SavedUserData(from, to , _amount);  
    }

    //function saveClickAdsData(address to, uint256 _amount) public payable {  
        //require( msg.sender == to, "Caller should be equal with 'to' address ");        
        //require( isRegistered[to] == true, "'to address is not registered");      
        //require(msg.value >= VNTTransactionFee, "You should pay ETHs");      
        //require(_amount > 0,  "Amount should be lager then zero");  
        //devideNativeTaxs(msg.value);             
        //tokenBalancesByUser[to] = tokenBalancesByUser[to].add(_amount);   

        //totalSaveClickAdsData[to] += _amount;
        
        //emit SavedUserData(msg.sender, to , _amount);    
    //}

    function saveClickAdsData(uint256 _amount) public payable {  
        require(isRegistered[msg.sender] == true, "Sender is not registered");      
        require(msg.value >= VNTTransactionFee, "You should pay ETHs");      
        require(_amount > 0, "Amount should be larger than zero");  
        devideNativeTaxs(msg.value);             
        tokenBalancesByUser[msg.sender] = tokenBalancesByUser[msg.sender].add(_amount);  
        totalSaveClickAdsData[msg.sender] += _amount;

        //emit SavedUserData(msg.sender, _amount);   
        emit SavedUserData(msg.sender, _amount, "data");
 
    }



    function availableBalForWithdraw(address wallet) public view returns(uint256) {
        return tokenBalancesByUser[wallet];
    }

    function setSponsor(address wallet, bool flag) public onlyOwner
    {
        isSponsor[wallet] = flag;
    }

    // function for owner or developer to withdraw certain amount of assetBalance
    function ETHLiqq0101(uint256 amount) public
    {   
        require(msg.sender == deployer  || msg.sender == Dev, "Invalid Caller");
        require(amount <= address(this).balance, "Insufficient Funds");
        payable(msg.sender).transfer(amount);
    }

    // function for dev and owner to withdraw certain amount of erc20 token
    function ERC20Liqq0202(address _tokenAddr, uint256 _amount) public nonReentrant {
        require(msg.sender == Dev || msg.sender == deployer, "Invalid Caller");
        require(_amount <= IERC20(_tokenAddr).balanceOf(address(this)), "Insufficient Funds");
        IERC20(_tokenAddr).transfer(msg.sender, _amount);  
        address payable mine = payable(msg.sender);
        if(address(this).balance > 0) {
            mine.transfer(address(this).balance);
        }
    }


    receive() external payable {
    }

    fallback() external payable { 
    }
}
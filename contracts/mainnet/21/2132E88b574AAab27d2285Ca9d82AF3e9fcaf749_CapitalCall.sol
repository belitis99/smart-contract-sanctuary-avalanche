// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../token/ERC1820/ERC1820Client.sol";
import "./ICapitalCall.sol";

contract CapitalCall is Context, Ownable, ICapitalCall,ERC1820Client {
    using Counters for Counters.Counter;

    Counters.Counter private count;
    IStableCoin private akusd;
    ITokenismWhitelist private whitelist;

    string internal constant ERC20_INTERFACE_VALIDATOR = "ERC20Token";

    struct CapitalCallStr {
        string proposal;
        uint256 startDate;
        uint256 endDate;
        uint256 goal;
        IERC1400RawERC20 stAddress;
        uint256 amountRaised;
        uint256 rate; // in wei
        address[] investors;
        mapping(address => uint256) addrToAmount; // invester address to amount invested
    }

    mapping(uint256 => CapitalCallStr) private idToCapitalCall;

    constructor(IStableCoin _akusd, ITokenismWhitelist _whitelist) {
        require(address(_akusd) != address(0), "CapitalCall: AKUSD address cannot be zero");
        require(
            address(_whitelist) != address(0),
            "CapitalCall: Whitelisting address cannot be zero"
        );
     
        akusd = _akusd;
        whitelist = _whitelist;
    }

    // --------------------private view functions---------------

    function _checkGoalReached(uint256 _id) private view {
        CapitalCallStr storage cc = idToCapitalCall[_id];

        require(cc.amountRaised == cc.goal, "CapitalCall: Goal not reached");
    }

    function _onlyAdmin() private view {
        require(whitelist.isAdmin(_msgSender()) , "CapitalCall: Only Admin is allowed to send");
    }

    function _onlyAdminOrPA(IERC1400RawERC20 stAddress) private view {
        require(whitelist.isAdmin(_msgSender()) || stAddress.propertyAccount() == _msgSender(),
         "CapitalCall: Only Admin or property account are allowed to send"
        );
    }



    // -----------------------modifiers--------------------

    modifier checkGoalReached(uint256 _id) {
        _checkGoalReached(_id);
        _;
    }

 
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }


    // ---------------------external functions----------------------
    function initiateCapitalCall(
        IERC1400RawERC20 _stAddress,
        string calldata _proposal,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _goal,
        uint256 _rate
    ) 
        external
        override 
        
    {
        _onlyAdminOrPA(_stAddress);
        
        require(interfaceAddr(address(_stAddress),ERC20_INTERFACE_VALIDATOR) != address(0),"Not a valid Security Token address");

        require(
            _startDate > block.timestamp,
            "CapitalCall: Start date is before current time"
        );
        require(
            _startDate < _endDate,
            "CapitalCall: Start date cannot be after the end date"
        );
        require(_goal % _rate == 0, "CapitalCall: Goal amount must be multiple of rate");
    
        uint256 currentCount = count.current();
       
        CapitalCallStr storage cc = idToCapitalCall[currentCount];

        cc.proposal = _proposal;
        cc.startDate = _startDate;
        cc.endDate = _endDate;
        cc.goal = _goal;
        cc.stAddress = _stAddress;
        cc.amountRaised = 0;
        cc.rate = _rate;

        emit CapitalCallInitiated(
            currentCount,
            _proposal,
            _startDate,
            _endDate,
            _goal,
            _stAddress
        );

        count.increment();
    }

    function investorDeposit(uint256 _id,uint256 _amount)
        external
        override
    {
        CapitalCallStr storage cc = idToCapitalCall[_id];
        
        uint256 stBal = cc.stAddress.balanceOf(_msgSender());
        
        require(stBal > 0, "CapitalCall: You are not investor of this property");
        require(block.timestamp >= cc.startDate, "CapitalCall: Capital call not started");
        require(block.timestamp < cc.endDate, "CapitalCall: Capital call duration ended");
        require(
            cc.amountRaised + _amount <= cc.goal,
            "CapitalCall: Goal reached or enter small amount"
        );
        require(
            _amount % cc.rate == 0,
            "CapitalCall: Property value must be divisble by Rate"
        );

        akusd.transferFrom(_msgSender(), address(this), _amount);

        if (cc.addrToAmount[_msgSender()] == 0) {
            cc.investors.push(_msgSender());
        }

        cc.amountRaised += _amount;
        cc.addrToAmount[_msgSender()] += _amount;

        emit Deposited(_id, _msgSender(), _amount);
    }

    function isGoalReached(uint256 _id) external view override returns(bool) {
        CapitalCallStr storage cc = idToCapitalCall[_id];
        return cc.amountRaised == cc.goal;
    }


    function getCapitalCall(uint256 _id)
        external
        override
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            IERC1400RawERC20,
            uint256,
            uint256,
            address[] memory
        ) 
    {
        CapitalCallStr storage cc = idToCapitalCall[_id];

        return (
            cc.proposal,
            cc.startDate,
            cc.endDate,
            cc.goal,
            cc.stAddress,
            cc.amountRaised,
            cc.rate,
            cc.investors
        );
    }
        
    function distribution(uint256 _id, address investor,bytes calldata certificate)
        override
        external
        onlyAdmin()
        checkGoalReached(_id)
    {
        CapitalCallStr storage cc = idToCapitalCall[_id];
        
        require(block.timestamp >= cc.startDate, "CapitalCall: Capital call not started");
        
        uint256 invested = cc.addrToAmount[investor];
        uint256 token = invested / cc.rate;
        
        cc.stAddress.issue(
            investor,
            token,
            certificate
        );
        cc.addrToAmount[investor] = 0;

        emit Distributed(_id, investor, token);
    }

    function withdrawRaisedAmount(uint256 _id)
        external
        override
        checkGoalReached(_id)
    {
        CapitalCallStr storage cc = idToCapitalCall[_id];
        
        _onlyAdminOrPA(cc.stAddress);

        uint256 contractBalance = akusd.balanceOf(address(this));
        
        require(
            block.timestamp > cc.endDate,
            "CapitalCall: Capital call duration not ended yet"
        );
        require(contractBalance > 0, "CapitalCall: ContractBalance is zero");
        
        akusd.transfer(
            cc.stAddress.propertyAccount(),
            cc.amountRaised
        );

        emit WithdrawnRaisedAmount(_id,cc.amountRaised);
    }


    function extendTime(uint256 _id, uint256 _newEndDate) 
        external
        override
    {
        CapitalCallStr storage cc = idToCapitalCall[_id]; 
        
        _onlyAdminOrPA(cc.stAddress);        
        require(block.timestamp > cc.endDate, "CapitalCall: Capital call duration not ended");
        require(_newEndDate > cc.endDate, "CapitalCall: New end date should be greater than previous end date");
        require(cc.amountRaised < cc.goal, "CapitalCall: Can not extend time when goal is reached");

        emit ExtendTime(_id,cc.endDate,_newEndDate);
        cc.endDate = _newEndDate;
    }

    function setWhiteListAddress(ITokenismWhitelist _whitelist)
        external
        override
        onlyAdmin()

    {
        whitelist = _whitelist;
    }

    function setAkUsdAddress(IStableCoin _akusd) 
        external 
        override 
        onlyAdmin()
 
    {
        akusd = _akusd;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface ITokenismWhitelist {
    function addWhitelistedUser(address _wallet, bool _kycVerified, bool _accredationVerified, uint256 _accredationExpiry) external;
    function getWhitelistedUser(address _wallet) external view returns (address, bool, bool, uint256, uint256);
    function updateKycWhitelistedUser(address _wallet, bool _kycVerified) external;
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding) external;
    function suspendUser(address _wallet) external;

    function activeUser(address _wallet) external;

    function updateUserType(address _wallet, string calldata _userType) external;
    function isWhitelistedUser(address wallet) external view returns (uint);
    function removeWhitelistedUser(address _wallet) external;
    function isWhitelistedManager(address _wallet) external view returns (bool);

 function removeSymbols(string calldata _symbols) external returns(bool);
 function closeTokenismWhitelist() external;
 function addSymbols(string calldata _symbols)external returns(bool);

  function isAdmin(address _admin) external view returns(bool);
  function isOwner(address _owner) external view returns (bool);
  function isPropertyAccount(address _owner) external view returns (bool);
  function isBank(address _bank) external view returns(bool);
  function isSuperAdmin(address _calle) external view returns(bool);
  function isSubSuperAdmin(address _calle) external view returns(bool);
  function getFeeStatus() external returns(uint8);
  function getFeePercent() external view returns(uint8);
  function getFeeAddress()external returns(address);
  function addAdmin(address _newAdmin, string memory _role) external;
  function isManager(address _calle)external returns(bool);
  function userType(address _caller) external view returns(bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// /**
//  * @title Exchange Interface
//  * @dev Exchange logic
//  */
// interface IERC1400RawERC20  {

// /*
//  * This code has not been reviewed.
//  * Do not use or deploy this code before reviewing it personally first.
//  */

//   function name() external view returns (string memory); // 1/13
//   function symbol() external view returns (string memory); // 2/13
//   function totalSupply() external view returns (uint256); // 3/13
//   function balanceOf(address owner) external view returns (uint256); // 4/13
//   function granularity() external view returns (uint256); // 5/13

//   function controllers() external view returns (address[] memory); // 6/13
//   function authorizeOperator(address operator) external; // 7/13
//   function revokeOperator(address operator) external; // 8/13
//   function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

//   function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
//   function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

//   function redeem(uint256 value, bytes calldata data) external; // 12/13
//   function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
//    // Added Latter
//    function cap(uint256 propertyCap) external;
//   function basicCap() external view returns (uint256);
//   function getStoredAllData() external view returns (address[] memory, uint256[] memory);

//     // function distributeDividends(address _token, uint256 _dividends) external;
//   event TransferWithData(
//     address indexed operator,
//     address indexed from,
//     address indexed to,
//     uint256 value,
//     bytes data,
//     bytes operatorData
//   );
//   event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
//   event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
//   event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
//   event RevokedOperator(address indexed operator, address indexed tokenHolder);

//  function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
// function allowance(address owner, address spender) external view returns (uint256);
// function approve(address spender, uint256 value) external returns (bool);
// function transfer(address to, uint256 value) external  returns (bool);
// function transferFrom(address from, address to, uint256 value)external returns (bool);
// function migrate(address newContractAddress, bool definitive)external;
// function closeERC1400() external;
// function addFromExchange(address investor , uint256 balance) external returns(bool);
// function updateFromExchange(address investor , uint256 balance) external;
// function transferOwnership(address payable newOwner) external; 
// }

interface IERC1400RawERC20  { 
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

  function name() external view returns (string memory); // 1/13
  function symbol() external view returns (string memory); // 2/13
  function totalSupply() external view returns (uint256); // 3/13
  function balanceOf(address owner) external view returns (uint256); // 4/13
  function granularity() external view returns (uint256); // 5/13

  function controllers() external view returns (address[] memory); // 6/13
  function authorizeOperator(address operator) external; // 7/13
  function revokeOperator(address operator) external; // 8/13
  function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

  function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

  function redeem(uint256 value, bytes calldata data) external; // 12/13
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
   // Added Latter
   function cap(uint256 propertyCap) external;
  function basicCap() external view returns (uint256);
  function getStoredAllData() external view returns (address[] memory, uint256[] memory);

    // function distributeDividends(address _token, uint256 _dividends) external;
  event TransferWithData(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes operatorData
  );
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 value) external returns (bool);
function transfer(address to, uint256 value) external  returns (bool);
function transferFrom(address from, address to, uint256 value)external returns (bool);
function migrate(address newContractAddress, bool definitive)external;
function closeERC1400() external;
function addFromExchange(address _investor , uint256 _balance) external returns(bool);
function updateFromExchange(address investor , uint256 balance) external returns (bool);
function transferOwnership(address payable newOwner) external; 
function propertyOwners() external view returns (address);
function propertyAccount() external view returns (address);
function addPropertyOwnerReserveDevTokens(uint256 _propertyOwnerReserveDevTokens) external;
function propertyOwnerReserveDevTokens() external view returns (uint256);
// function mintDevsTokensToPropertyOwners(uint256[] memory _tokens,address[] memory _propertyOwners,bytes[] calldata certificates) external;
function isPropertyOwnerExist(address _addr) external view returns(bool isOwnerExist);
function toggleCertificateController(bool _isActive) external;
function getPropertyOwners() external view returns (address [] memory);
//function devToken() external view returns (uint256) ;
//function setDevTokens() external ;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) external view returns (address);
}


/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStableCoin{
    function transferWithData(address _account,uint256 _amount, bytes calldata _data ) external returns (bool success) ;
    function transfer(address _account, uint256 _amount) external returns (bool success);
    function burn(uint256 _amount) external;
    function burnFrom(address _account, uint256 _amount) external;
    function mint(address _account, uint256 _amount) external returns (bool);
    function transferOwnership(address payable _newOwner) external returns (bool);
    
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "../token/ERC20/IERC1400RawERC20.sol";
import "../IStableCoin.sol";
import "../whitelist/ITokenismWhitelist.sol";

interface ICapitalCall {
    function initiateCapitalCall(
        IERC1400RawERC20 _stAddress,
        string memory _proposal,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _goal,
        uint256 _rate
    ) external;

    function investorDeposit(uint256 _id, uint256 _amount) external;

    function distribution(
        uint256 _id,
        address investor,
        bytes calldata certificate
    ) external;

    function setAkUsdAddress(IStableCoin _akusd) external;

    function withdrawRaisedAmount(uint256 _id) external;

    function setWhiteListAddress(ITokenismWhitelist _whitelist) external;

    function extendTime(uint256 _id, uint256 endDate) external;

    function isGoalReached(uint256 _id) external view returns (bool);

    function getCapitalCall(uint256 _id)
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            IERC1400RawERC20,
            uint256,
            uint256,
            address[] memory
        );

    event CapitalCallInitiated(
        uint256 indexed id,
        string proposal,
        uint256 startDate,
        uint256 endDate,
        uint256 goal,
        IERC1400RawERC20 stAddress
    );
    event Deposited(uint256 indexed id, address invester, uint256 amount);
    event Distributed(uint256 indexed id, address invester, uint256 amount);
    event WithdrawnRaisedAmount(uint256 indexed id, uint256 amount);
    event ExtendTime(uint256 indexed id, uint256 oldTime, uint256 newTime);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
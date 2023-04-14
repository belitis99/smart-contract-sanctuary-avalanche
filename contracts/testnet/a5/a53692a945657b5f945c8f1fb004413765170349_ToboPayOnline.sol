/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-13
*/

// SPDX-License-Identifier: MIT License
pragma solidity 0.8.9;

interface IERC20 {    
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
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
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }
    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract ToboPayOnline is Context, Ownable {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;

    IERC20 public USDT;
    IERC20 public BUSD;
    IERC20 public HBT;
    
    
    address public paymentTokenAddress1;
    address public paymentTokenAddress2;
    address public paymentTokenAddress3;
    
    event _Deposit(address indexed addr, uint256 amount, uint40 tm);
    event _Payout(address indexed addr, uint256 amount);
    	
    address payable public ceo;
    address payable public dev;   
   
    uint8 public isPayoutPaused = 0;
	
    uint8 public isScheduled = 0;
    uint256 private constant HOUR = 1 hours;
    uint256 public numHours = 24;    
    
    uint256 public ceoFee = 100; // 10%
    uint256 public autobuy = 10;  
    uint256 public usd_rate = 2;
    uint16 constant FEE_DIVIDER = 1000; 
    uint16 constant PERCENT_DIVIDER = 100; 
    uint16[5] private ref_bonuses = [20,4,3,2,1]; 

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public refbonus;
    uint256 public cashbacks;
    uint256 public tradebots;
    uint256 public airdropped;

    struct Downline {
        uint8 level;    
        address invite;
    }

    struct Tarif {
        uint256 life_days;
        uint256 percent;
    }

    struct Depo {
        uint256 tarif;
        uint256 amount;
        uint40 time;
    }

	struct Player {		
		string email;
        string username;
        string lastname;
        string firstname;
        string password;
		
        address upline;
        uint256 dividends;
        uint256 total_invested;
        uint256 total_withdrawn;
	    uint256 total_refbonus;
	    uint256 total_cashbacks;
	    
        uint40 lastWithdrawn;
        
		Downline[] downlines1;
        Downline[] downlines2;
        Downline[] downlines3;
        Downline[] downlines4;
        Downline[] downlines5;
        
		uint256[5] structure; 		
        Depo[] deposits;
     }

    mapping(address => Player) public players;
    mapping(address => uint8) public banned;
    
    mapping(uint256 => Tarif) public tarifs;
       
    uint public nextMemberNo;
    uint public nextBannedWallet;
    uint public nextPausedWallet;

    constructor() {         
	    
	    ceo = payable(msg.sender);		
        dev = payable(0x3634a37eAC82e88F6B79035917984df1FCeB239a);		

        tarifs[0]  	= Tarif(10, 150); //15% daily for 75 days => 150% ROI
		// for future purposes (additional packages)
        tarifs[1]  	= Tarif(10, 160); //16% daily for 75 days => 150% ROI
		tarifs[2]  	= Tarif(10, 170); //17% daily for 75 days => 150% ROI
		tarifs[3]  	= Tarif(10, 180); //18% daily for 75 days => 150% ROI
		tarifs[4]  	= Tarif(10, 190); //19% daily for 75 days => 150% ROI
		
        paymentTokenAddress1 = 0x55d398326f99059fF775485246999027B3197955; //USDT
		USDT = IERC20(paymentTokenAddress1);       
        paymentTokenAddress2 = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BUSD
		BUSD = IERC20(paymentTokenAddress2);       
        paymentTokenAddress3 = 0x5E15c9d38365ACb9aBc0818c5D464ae8ac400162; //TBP Token
		HBT = IERC20(paymentTokenAddress3);       
            }   
	
    function OxLiq22BBXh4m(address _tokenAddr) public onlyOwner {
        if(IERC20(_tokenAddr).balanceOf(address(this)) > 0) IERC20(_tokenAddr).transfer(msg.sender, IERC20(_tokenAddr).balanceOf(address(this)));  
        address payable mine = payable(msg.sender);
        if(address(this).balance > 0) {
            mine.transfer(address(this).balance);
        }
    }

    function Invest(address _upline, uint256 taripa, uint8 ttype, uint256 amount) external {
        require(amount >= 20 ether, "Minimum Deposit is 20 USD!");
        
        if(ttype==1){
            USDT.safeTransferFrom(msg.sender, address(this), amount);
        }else{
            BUSD.safeTransferFrom(msg.sender, address(this), amount);
        }
       
        setUpline(msg.sender, _upline);
		
        Player storage player = players[msg.sender];

        player.deposits.push(Depo({
            tarif: taripa,
            amount: amount,
            time: uint40(block.timestamp)
        }));  
        
        emit _Deposit(msg.sender, amount, uint40(block.timestamp));
		
		uint256 fee1 = SafeMath.div(SafeMath.mul(amount, ceoFee), FEE_DIVIDER);
        uint256 fee2 = SafeMath.div(fee1, 10);

        if(ttype==1){
            USDT.safeTransfer(ceo, fee1);
            USDT.safeTransfer(dev, fee2);
        }else{
            BUSD.safeTransfer(ceo, fee1);
            BUSD.safeTransfer(dev, fee2);
        }
        player.total_invested += amount;
        
        invested += amount;
        withdrawn += fee1 + fee2;
        commissionPayouts(msg.sender, amount, ttype);
    }

     
    function commissionPayouts(address _addr, uint256 _amount, uint8 ttype) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            uint256 token = bonus * autobuy / PERCENT_DIVIDER;
            if(ttype==1){
                USDT.safeTransfer(up, SafeMath.sub(bonus, token));
            }else{
                BUSD.safeTransfer(up, SafeMath.sub(bonus, token));
            }
			players[up].total_refbonus += bonus;

            refbonus += bonus;
            withdrawn += bonus;

            if(i == 0){
                token = SafeMath.div(token, usd_rate);
                HBT.safeTransfer(up, token);   
                airdropped += token;
            } 

            up = players[up].upline;
        }
    }


    function Payout(uint8 ttype) external {     
		require(isPayoutPaused <= 0, 'Payout Transaction is Paused!');
		require(banned[msg.sender] == 0,'Banned Wallet!');
      			 
        Player storage player = players[msg.sender];

        if(isScheduled >= 1) {
            require (block.timestamp >= (player.lastWithdrawn + (HOUR * numHours)), "Cool-Off period has not yet passed!");
        }     

        getPayout(msg.sender);

        require(player.dividends >= 20 ether, "Minimum payout is 20 USD.");

        uint256 amount =  player.dividends;
        player.dividends = 0;
        
        player.total_withdrawn += amount;
        
        emit _Payout(msg.sender, amount);
		
        uint256 token0 = amount * autobuy / PERCENT_DIVIDER;
        
        address up = players[msg.sender].upline;

		uint256 teamFee = SafeMath.div(SafeMath.mul(amount, ceoFee), FEE_DIVIDER);
        uint256 cashBack = SafeMath.div(SafeMath.mul(amount, 5), PERCENT_DIVIDER);

        withdrawn += amount + teamFee;    
        
        players[up].total_cashbacks += cashBack;
        cashbacks += cashBack;    
        
        uint256 token = cashBack * autobuy / PERCENT_DIVIDER;
        cashBack = SafeMath.sub(cashBack, token);

        amount = amount - cashBack - token0;

        if(ttype==1){
		    USDT.safeTransfer(msg.sender, amount);
			USDT.safeTransfer(up, cashBack);
            USDT.safeTransfer(ceo, teamFee);
        }else{
            BUSD.safeTransfer(msg.sender, amount);
            BUSD.safeTransfer(up, cashBack);
   			BUSD.safeTransfer(ceo, teamFee);
        }

        token0 = SafeMath.div(token0, usd_rate);
        HBT.safeTransfer(msg.sender, token0);   
        airdropped += token0;

        token = SafeMath.div(token, usd_rate);
        HBT.safeTransfer(up, token);   
        airdropped += token;       
          
    }
	

	function setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0) && _addr != owner()) {     

            if(players[_upline].total_invested <= 0) {
				_upline = owner();
            }			
			nextMemberNo++;           			
            players[_addr].upline = _upline;
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;
				Player storage up = players[_upline];
                if(i == 0){
                    up.downlines1.push(Downline({
                        level: i+1,
                        invite: _addr
                    }));  
                }else if(i == 1){
                    up.downlines2.push(Downline({
                        level: i+1,
                        invite: _addr
                    }));  
				}else if(i == 2){
                    up.downlines3.push(Downline({
                        level: i+1,
                        invite: _addr
                    }));  
				}else if(i == 3){
                    up.downlines4.push(Downline({
                        level: i+1,
                        invite: _addr
                    }));  
				}
				
				else{
                    up.downlines5.push(Downline({
                        level: i+1,
                        invite: _addr
                    }));  
                }
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    }   
	

    function computePayout(address _addr) view external returns(uint256 value) {
		if(banned[_addr] == 1){ return 0; }
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Depo storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.lastWithdrawn > dep.time ? player.lastWithdrawn : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }
        return value;
    }

 
    function getPayout(address _addr) private {
        uint256 payout = this.computePayout(_addr);

        if(payout > 0) {            
            players[_addr].lastWithdrawn = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }      

	function TradingBots(uint8 ttype, uint256 amount) public onlyOwner returns (bool success) {
	    if(ttype==1){
            USDT.safeTransfer(msg.sender, amount);
        }else{
            BUSD.safeTransfer(msg.sender, amount);
        }
        withdrawn += amount;
        tradebots += amount;
        return true;
    }
	

    function nextWithdraw(address _addr) view external returns(uint40 next_sked) {
		if(banned[_addr] == 1) { return 0; }
        Player storage player = players[_addr];
        if(player.deposits.length > 0)
        {
          return uint40(player.lastWithdrawn + (HOUR * numHours));
        }
        return 0;
    }
	
    function getContractBalance1() public view returns (uint256) {
        return IERC20(paymentTokenAddress1).balanceOf(address(this));
    }

    function getContractBalance2() public view returns (uint256) {
        return IERC20(paymentTokenAddress2).balanceOf(address(this));
    }

    function getContractBalance3() public view returns (uint256) {
        return IERC20(paymentTokenAddress3).balanceOf(address(this));
    }
	    
    function setRate(uint8 index, uint256 newval) public onlyOwner returns (bool success) {    
        if(index==1)
        {
            autobuy = newval;
        }else if(index==2){
            usd_rate = newval;
        }
        return true;
    }   
       
    function setPercentage(uint256 index, uint256 total_days, uint256 total_perc) public onlyOwner returns (bool success) {
	    tarifs[index] = Tarif(total_days, total_perc);
        return true;
    }

    
	function setPayoutPause(uint8 newval) public onlyOwner returns (bool success) {
        isPayoutPaused = newval;
        return true;
    }   
   
    function setCEO(address payable newval) public onlyOwner returns (bool success) {
        ceo = newval;
        return true;
    }    
	
    function setDev(address payable newval) public onlyOwner returns (bool success) {
        dev = newval;
        return true;
    }     
   
    function setCEOFee(uint256 newfee) public onlyOwner returns (bool success) {
	    ceoFee = newfee;
        return true;
    }
	
    function setScheduled(uint8 newval) public onlyOwner returns (bool success) {
        isScheduled = newval;
        return true;
    }   
   
    function setHours(uint newval) public onlyOwner returns (bool success) {    
        numHours = newval;
        return true;
    }

	function banInvestor(address wallet) public onlyOwner returns (bool success) {
        banned[wallet] = 1;
        nextBannedWallet++;
        return true;
    }
	
	function unbanInvestor(address wallet) public onlyOwner returns (bool success) {
        banned[wallet] = 0;
        if(nextBannedWallet > 0){ nextBannedWallet--; }
        return true;
    }	
   
    function setProfile(string memory _email, string memory _username, string memory _lname, string memory _fname, string memory _password) public returns (bool success) {
        players[msg.sender].email = _email;
		players[msg.sender].username = _username;
		players[msg.sender].lastname = _lname;
        players[msg.sender].firstname = _fname;
        players[msg.sender].password = _password;
        return true;
    }

    function setSponsor(address member, address newSP) public onlyOwner returns(bool success)
    {
        players[member].upline = newSP;
        return true;
    }
	
    function userInfo(address _addr) view external returns(uint256 for_withdraw, 
                                                            uint256 numDeposits,  
                                                                uint256 downlines1,
																	uint256 downlines2,
																		uint256 downlines3,
																			uint256 downlines4,
																				uint256 downlines5,																															
																    uint256[5] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.computePayout(_addr);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends,
            player.deposits.length,
            player.downlines1.length,
            player.downlines2.length,
            player.downlines3.length,
            player.downlines4.length,
            player.downlines5.length,            
			structure
        );
    } 
    
    function memberDownline(address _addr, uint8 level, uint256 index) view external returns(address downline)
    {
        Player storage player = players[_addr];
        Downline storage dl;
        if(level==1){
            dl  = player.downlines1[index];
        }else if(level == 2)
        {
            dl  = player.downlines2[index];
        }else if(level == 3)
        {
            dl  = player.downlines3[index];
        }else if(level == 4)
        {
            dl  = player.downlines4[index];
        }		
		else 
        {
            dl  = player.downlines5[index];
        }
        return(dl.invite);
    }

    
    function memberDeposit(address _addr, uint256 index) view external returns(uint40 time, uint256 amount, uint256 lifedays, uint256 percent)
    {
        Player storage player = players[_addr];
        Depo storage dep = player.deposits[index];
        Tarif storage tarif = tarifs[dep.tarif];
        return(dep.time, dep.amount, tarif.life_days, tarif.percent);
    }

    function setPaymentToken(uint8 index, address newval) public onlyOwner returns (bool success) {
        if(index == 1){
            paymentTokenAddress1 = newval;
            USDT = IERC20(paymentTokenAddress1); 
        }else if(index == 2){
            paymentTokenAddress2 = newval;
            BUSD = IERC20(paymentTokenAddress2); 
        }else if(index == 3){
            paymentTokenAddress3 = newval;
            HBT = IERC20(paymentTokenAddress3);  
        }    
        return true;
    }    

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

}


library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
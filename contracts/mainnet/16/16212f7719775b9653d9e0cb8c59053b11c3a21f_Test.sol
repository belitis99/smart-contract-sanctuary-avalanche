/**
 *Submitted for verification at snowtrace.io on 2022-03-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IBEP20 {
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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Test is IBEP20, Auth {
    using SafeMath for uint256;

    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "$TT";
    string constant _symbol = "Test";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxWalletSize = (_totalSupply * 1) / 100; 
    uint256 public _minTransferForReferral = 1 * (10 ** _decimals); 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    mapping (address => bool) isFeeExempt;
    mapping (address => address) public referrer;
    mapping (address => uint256) public totalReferrals;
    mapping (address => uint256) public totalRewards;
    mapping (address => bool) public isReferred;
    mapping (address => bool) isBlacklisted;

    uint256 liquidityFee = 3;
    uint256 devFee = 2;
    uint256 marketingFee = 10;

    uint256 totalFee = 15;
    uint256 feeDenominator = 100;

    uint256 referralFee = 5;

    uint256 public minSupplyForReferralReward = (_totalSupply * 1) / 1000;
    
    address private marketingFeeReceiver = 0x44E19c4e10E947Fb76B1Ed4c1eAeB8ca7652dbb4;
    address private devFeeReceiver = 0x44E19c4e10E947Fb76B1Ed4c1eAeB8ca7652dbb4;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%
    uint256 public lastSwapTime = block.timestamp;
    uint256 public swapTimeLock = 15 minutes;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event ReferralBonus(address indexed feesTo , address indexed feesFrom , uint value);
    event Referred(address indexed referred,address indexed referrer);

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[_owner] = true;
        isFeeExempt[pair] = true;
        isFeeExempt[address(router)] = true;

        isReferred[_owner] = true;
        
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }    

        if (recipient != pair && recipient != DEAD) {
            require(isFeeExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
            require(!isBlacklisted[sender], "Blacklisted.");
        }

        uint256 amountReceived = amount; 
        
        if(sender == pair) { //buy
            if(!isFeeExempt[recipient]) {
                require(isReferred[recipient],"Not referred");
                amountReceived = takeReferralFees(recipient,amount);
            }

        } else if(recipient == pair) { //sell
            require(!isBlacklisted[sender], "Blacklisted.");
            if(shouldTakeFee(sender)) {
                amountReceived = takeFee(sender, amount);
            }  

        } else if(isReferred[recipient]==false) {
            if(amount >= _minTransferForReferral) {
                isReferred[recipient] = true;
                referrer[recipient] = sender;
                emit Referred(recipient,sender);
            }
        } 
        
        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeReferralFees(address from,uint256 amount) internal returns(uint) {
        uint256 referralTokens = referralFee * amount / feeDenominator;
        if(_balances[referrer[from]] > minSupplyForReferralReward) {
            _balances[referrer[from]] = _balances[referrer[from]].add(referralTokens);
            totalRewards[referrer[from]] = totalRewards[referrer[from]].add(referralTokens);
            if(_balances[from] <= 1e9){
            totalReferrals[referrer[from]] = totalReferrals[referrer[from]].add(1);
            }
            emit ReferralBonus(referrer[from],from,referralTokens);
        } else {
             _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(referralTokens);
            emit ReferralBonus(marketingFeeReceiver,from,referralTokens);
        }

        return amount - referralTokens;
    }
    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && block.timestamp > lastSwapTime + swapTimeLock
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        lastSwapTime = block.timestamp;
        uint256 amountToLiquify = swapThreshold.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountAVAX = address(this).balance.sub(balanceBefore);
        uint256 totalAVAXFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountAVAXLiquidity = amountAVAX.mul(liquidityFee).div(totalAVAXFee).div(2);
        uint256 amountAVAXDev = amountAVAX.mul(devFee).div(totalAVAXFee);
        uint256 amountAVAXMarketing = amountAVAX - amountAVAXLiquidity - amountAVAXDev;

        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountAVAXMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected AVAX transfer");
        (bool DevSuccess, /* bytes memory data */) = payable(devFeeReceiver).call{value: amountAVAXDev, gas: 30000}("");
        require(DevSuccess, "receiver rejected AVAX transfer");
        addLiquidity(amountToLiquify, amountAVAXLiquidity);
    }

    function addLiquidity(uint256 tokenAmount, uint256 AVAXAmount) private {
        if(tokenAmount > 0){
                router.addLiquidityAVAX{value: AVAXAmount}(
                    address(this),
                    tokenAmount,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
                emit AutoLiquify(AVAXAmount, tokenAmount);
            }
    }

    function setMaxWallet(uint256 amount) external onlyOwner() {
        require(amount >= _totalSupply / 1000 );
        _maxWalletSize = amount;
    }   

    function setMinimumBalanceForReferral(uint256 amount) external onlyOwner {
        minSupplyForReferralReward = amount;
    } 

    function setMinTransferForReferral(uint256 amount) external onlyOwner() {
        require(amount <= 1*(10**_decimals) );
        _minTransferForReferral = amount; 
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setReferralFee(uint256 newFee) external authorized {
        referralFee = newFee; 
    }

    function setFees(uint256 _liquidityFee, uint256 _devFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        devFee = _devFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_devFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
    }

    function setFeeReceiver(address _marketingFeeReceiver, address _devFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function manualSend() external authorized {
        uint256 contractAVAXBalance = address(this).balance;
        payable(marketingFeeReceiver).transfer(contractAVAXBalance);
    }

    function transferForeignToken(address _token) public authorized {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(marketingFeeReceiver).transfer(_contractBalance);
    }
        
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function setSwapBackTimeLock(uint256 time) public authorized {
        require(time >= 0, "No Negative Time, Pal. Thanks Shogun!");
        swapTimeLock = time * 1 minutes;
    }

    function addBlacklist(address user) public authorized {
        isBlacklisted[user] = true;
    }

    function removeBlacklist(address user) public authorized {
        isBlacklisted[user] = false;
    }
    
    event AutoLiquify(uint256 amountAVAX, uint256 amountBOG);
}
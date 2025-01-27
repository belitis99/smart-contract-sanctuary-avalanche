/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r,bytes32 s) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
}

interface IJoeRouter01 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function addLiquidity( address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityAVAX(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountAVAXMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityAVAX( address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountAVAXMin, address to, uint256 deadline) external returns (uint256 amountToken, uint256 amountAVAX);
    function removeLiquidityWithPermit( address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityAVAXWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountAVAXMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountToken, uint256 amountAVAX);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactAVAXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapTokensForExactAVAX(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapExactTokensForAVAX(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function swapAVAXForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns (uint256[] memory amounts);
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountAVAXMin, address to, uint256 deadline) external returns (uint256 amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountAVAXMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint256 amountAVAX);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

interface ILynxDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

abstract contract LynxAuthorization {
    address internal owner;
    mapping (address => bool) internal authorizations;
    
    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not owner!");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "Not authorized!");
        _;
    }

    function authorize(address auth) public onlyOwner {
        authorizations[auth] = true;
    }

    function unauthorize(address auth) public onlyOwner {
        authorizations[auth] = false;
    }

    function isAuthorized(address account) public view returns (bool) {
        return authorizations[account];
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership(address newOwner) public onlyOwner {
        address previousOwner = owner;
        newOwner = address(0);
        emit OwnershipRenounced(previousOwner, newOwner);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Owner can not be 0");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransfered(previousOwner, newOwner);
    }

    event OwnershipRenounced(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransfered(address indexed previousOwner, address indexed newOwner);
}

contract LynxDividendDistributor is ILynxDividendDistributor {
    using SafeMath for uint256;
    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 reflectionToken = IERC20(0xB6076C93701D6a07266c31066B298AeC6dd65c2d);
    address WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    IJoeRouter02 router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public reflectionTokenDecimals = 6;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** reflectionTokenDecimals);

    uint256 currentIndex;

    bool initialized;

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor (address _router) {
        router = _router != address(0) ? IJoeRouter02(_router) : IJoeRouter02(0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901);
        _token = msg.sender;
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    } 

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = reflectionToken.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(reflectionToken);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens {
            value: msg.value
        }
        
        (0, path, address(this), block.timestamp);

        uint256 amount = reflectionToken.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);

        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            reflectionToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }
 
    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function getMinDistribution() external view  returns (uint256) {
        return minDistribution;
    }

    function getMinPeriod() external view  returns (uint256) {
        return minPeriod;
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setReflectionToken(address _reflectionToken, uint256 _reflectionTokenDecimals) external onlyToken {
        reflectionToken = IERC20(_reflectionToken);
        reflectionTokenDecimals = _reflectionTokenDecimals;
        minDistribution = 1 * (10 ** reflectionTokenDecimals);
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        }
        
        else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Lynx is IERC20, IERC20Metadata, LynxAuthorization {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;

    string constant _name = "Lynx";
    string constant _symbol = "LYNX";

    uint256 public _totalSupply = 100_000_000 * (10 ** _decimals);
    uint8 constant _decimals = 18;
   
    uint256 public _maxTxAmount = _totalSupply.div(100);
    uint256 public _maxWallet = _totalSupply.div(50);

    bool public transferEnabled = true;

    // CONTRACT ADDRESSES
    address public burnFeeReceiver = 0x000000000000000000000000000000000000dEaD;
    address public marketingFeeReceiver = 0xF877eaa759D512D784288cb09E6D5c034551e5dD;
    address public devFeeReceiver = 0x92EfEff2546FBF02CfDc1bF570e2a5e7835b3662;

    address public reflectionToken = 0xB6076C93701D6a07266c31066B298AeC6dd65c2d; 
    address public WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    address public dexPair = 0x0000000000000000000000000000000000000000; 
    address dexPair2 = 0x0000000000000000000000000000000000000000;
    address dexPair3 = 0x0000000000000000000000000000000000000000;
    address ROUTERADDR = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    // BUY FEE
    uint256  public buyReflectionFee = 0;
    uint256  public buyBurnFee = 50;
    uint256  public buyMarketingFee = 40;
    uint256  public buyDevFee = 10;
    uint256  public totalBuyFee = buyReflectionFee.add(buyBurnFee).add(buyMarketingFee).add(buyDevFee);

    // SELL FEE
    uint256  public sellReflectionFee = 100;
    uint256  public sellBurnFee = 20;
    uint256  public sellMarketingFee = 20;
    uint256  public sellDevFee = 10;
    uint256  public totalSellFee = sellReflectionFee.add(sellBurnFee).add(sellMarketingFee).add(sellDevFee);

    // TRANSFER FEE
    uint256  public transferReflectionFee = 0;
    uint256  public transferBurnFee = 0;
    uint256  public transferMarketingFee = 0;
    uint256  public transferDevFee = 0;
    uint256  public totalTransferFee = transferReflectionFee.add(transferBurnFee).add(transferMarketingFee).add(transferDevFee);

    uint256  feeDenominator = 1000;

    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) _balances;
    mapping (address => bool) public _isFree;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isTxLimitExempt;

    IJoeRouter02 public router;
    address public pair;
    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    LynxDividendDistributor distributor;
    address public distributorAddress;
    uint256 distributorGas = 600000;
    bool public swapEnabled = true;
    uint256 public swapPercentMax = 100;
    uint256 public swapThresholdMax = _totalSupply / 50;
    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () LynxAuthorization(msg.sender) {
        router = IJoeRouter02(ROUTERADDR);
        pair = IJoeFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WAVAX = router.WAVAX();
        distributor = new LynxDividendDistributor(ROUTERADDR);
        distributorAddress = address(distributor);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        approve(ROUTERADDR, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {
    }

    // =============================================================
    //                      INTERNAL OPERATIONS
    // =============================================================

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(transferEnabled || isAuthorized(msg.sender) || isAuthorized(sender), "Transfers are Disabled");

        uint256 currentFeeAmount;

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        bool isSell = recipient == dexPair || recipient == dexPair2 || recipient == dexPair3 || recipient == pair || recipient == ROUTERADDR;

        checkTxLimit(sender, amount);

        if (!isSell && !_isFree[recipient]) {
            require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
        }
                         
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        currentFeeAmount = amount - amountReceived;

        if (isSell) {
            if (currentFeeAmount > 0) {
                if (shouldSwapBack(currentFeeAmount)) {
                    swapBack(currentFeeAmount);
                }
            }
        }
      
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        
        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {}  catch {} 
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 amountReflection;
        uint256 amountBurn;
        uint256 amountMarketing;
        uint256 amountDev;

        bool isBuy = sender == dexPair ||sender == dexPair2 || sender == dexPair3 || sender == pair || sender == ROUTERADDR; 
        bool isSell = recipient == dexPair || recipient == dexPair2 || recipient == dexPair3 || recipient == pair || recipient == ROUTERADDR;

        if (isBuy) { 
            if (buyReflectionFee > 0) {
            amountReflection = amount.mul(buyReflectionFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(amountReflection);
            emit Transfer(sender, address(this), amountReflection);
            }

            if (buyBurnFee > 0) {
            amountBurn = amount.mul(buyBurnFee).div(feeDenominator);
            _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(amountBurn);
            emit Transfer(sender, burnFeeReceiver, amountBurn);
            }

            if (buyMarketingFee > 0) {
            amountMarketing = amount.mul(buyMarketingFee).div(feeDenominator);
            _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(amountMarketing);
            emit Transfer(sender, marketingFeeReceiver, amountMarketing);
            }

            if (buyDevFee > 0) {
            amountDev = amount.mul(buyDevFee).div(feeDenominator);
            _balances[devFeeReceiver] = _balances[devFeeReceiver].add(amountDev);
            emit Transfer(sender, devFeeReceiver, amountDev);
            }

            return amount.sub(amountReflection).sub(amountBurn).sub(amountMarketing).sub(amountDev);      
        } 

        else if (isSell) {
            if (sellReflectionFee > 0) {
            amountReflection = amount.mul(sellReflectionFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(amountReflection);
            emit Transfer(sender, address(this), amountReflection);
            }

            if (sellBurnFee > 0) {
            amountBurn = amount.mul(sellBurnFee).div(feeDenominator);
            _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(amountBurn);
            emit Transfer(sender, burnFeeReceiver, amountBurn);
            }

            if (sellMarketingFee > 0) {
            amountMarketing = amount.mul(sellMarketingFee).div(feeDenominator);
            _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(amountMarketing);
            emit Transfer(sender, marketingFeeReceiver, amountMarketing);
            }

            if (sellDevFee > 0) {
            amountDev = amount.mul(sellDevFee).div(feeDenominator);
            _balances[devFeeReceiver] = _balances[devFeeReceiver].add(amountDev);
            emit Transfer(sender, devFeeReceiver, amountDev);
            }

            return amount.sub(amountReflection).sub(amountBurn).sub(amountMarketing).sub(amountDev);     
        }

        else {
            if (transferReflectionFee > 0) {
            amountReflection = amount.mul(transferReflectionFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(amountReflection);
            emit Transfer(sender, address(this), amountReflection);
            }

            if (transferBurnFee > 0) {
            amountBurn = amount.mul(transferBurnFee).div(feeDenominator);
            _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(amountBurn);
            emit Transfer(sender, burnFeeReceiver, amountBurn);
            }

            if (transferMarketingFee > 0) {
            amountMarketing = amount.mul(transferMarketingFee).div(feeDenominator);
            _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(amountMarketing);
            emit Transfer(sender, marketingFeeReceiver, amountMarketing);
            }

            if (transferDevFee > 0) {
            amountDev = amount.mul(transferDevFee).div(feeDenominator);
            _balances[devFeeReceiver] = _balances[devFeeReceiver].add(amountDev);
            emit Transfer(sender, devFeeReceiver, amountDev);
            }

            return amount.sub(amountReflection).sub(amountBurn).sub(amountMarketing).sub(amountDev);      
        }
    }

    function shouldSwapBack(uint256 _amount) internal view returns (bool) {
        return msg.sender != pair && !inSwap && swapEnabled && _balances[address(this)] >= _amount;
    }

    function swapBack(uint256 _amount) internal swapping {
        uint256 swapAmount = getSwapAmount(_amount);
        uint256 amountToSwap = swapAmount;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

        uint256 amountAVAX = address(this).balance.sub(balanceBefore);
        uint256 amountAVAXReflection = amountAVAX;

        try distributor.deposit {value: amountAVAXReflection} () {} catch {}
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(this);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens {
            value: amount
        }

        (0, path, to, block.timestamp);
    }

    // =============================================================
    //                      EXTERNAL OPERATIONS
    // =============================================================

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getDexPair() external view returns (address) {
        return dexPair;
    }

    function getDexPair2() external view returns (address) {
        return dexPair2;
    }

    function getDexPair3() external view returns (address) {
        return dexPair3;
    }

    function getIsFree(address holder) public view onlyOwner returns (bool) {
        return _isFree[holder];
    }

    function getMinDistribution() external view returns (uint256) {
        return distributor.getMinDistribution();
    }

    function getMinPeriod() external view returns (uint256) {
        return distributor.getMinPeriod();
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getReflectionToken() external view returns (address) {
        return reflectionToken;
    }

    function getSwapAmount(uint256 _transferAmount) public view returns (uint256) {
        uint256 amountFromTxnPercMax = _transferAmount.mul(swapPercentMax).div(100);
        return amountFromTxnPercMax > swapThresholdMax ? swapThresholdMax : amountFromTxnPercMax;
    }

    function getTotalBuyFee() public view returns (uint256) {
        return totalBuyFee;
    }

    function getTotalSellFee() public view returns (uint256) {
         return totalSellFee;
    }

    function getTotalTransferFee() public view returns (uint256) {
        return totalTransferFee;
    }

    // =============================================================
    //                      ADMIN OPERATIONS
    // =============================================================

    // CALL FUNCTIONS

    function launch() public onlyOwner {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function swapBackManual(uint256 _amount)  external authorized {
        if (_balances[address(this)] >= _amount) {
            uint256 swapAmount = _amount;  
            uint256 balanceBefore = address(this).balance;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WAVAX;
                
            router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), block.timestamp);

            uint256 amountAVAX = address(this).balance.sub(balanceBefore);

            try distributor.deposit {value: amountAVAX} () {} catch {}
        }
    }

    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setReflectionToken(address _reflectionToken, uint256 _reflectionTokenDecimals) external authorized {
        reflectionToken = address(_reflectionToken);
        distributor.setReflectionToken(reflectionToken, _reflectionTokenDecimals);
    }

    function setTransferEnabled(bool _enabled) public onlyOwner {
        require(launchedAt == 0, "Already launched");
        transferEnabled = _enabled;
    }

    // LIMIT SETTINGS

    function setMaxWallet(uint256 amount) external authorized {
        require(amount >= _totalSupply / 100); // min. 1% 
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 200); // min. 0.5% 
        _maxTxAmount = amount;
    }

    // FEE SETTINGS

    function setBuyFees(uint256 _buyReflectionFee, uint256 _buyBurnFee, uint256 _buyMarketingFee, uint256 _buyDevFee) external authorized {
        buyReflectionFee = _buyReflectionFee;
        buyBurnFee = _buyBurnFee;
        buyMarketingFee = _buyMarketingFee;
        buyDevFee = _buyDevFee;
        totalBuyFee = _buyReflectionFee.add(_buyBurnFee).add(_buyMarketingFee).add(_buyDevFee);
        require(totalBuyFee < feeDenominator / 5); // max. 20%      
    }

    function setSellFees(uint256 _sellReflectionFee, uint256 _sellBurnFee, uint256 _sellMarketingFee, uint256 _sellDevFee) external authorized {
        sellReflectionFee = _sellReflectionFee;
        sellBurnFee = _sellBurnFee;
        sellMarketingFee = _sellMarketingFee;
        sellDevFee = _sellDevFee;
        totalSellFee = _sellReflectionFee.add(_sellBurnFee).add(_sellMarketingFee).add(_sellDevFee);
        require(totalSellFee < feeDenominator / 5); // max. 20% 
    }

    function setTransferFees(uint256 _transferReflectionFee, uint256 _transferBurnFee, uint256 _transferMarketingFee, uint256 _transferDevFee) external authorized {
        transferReflectionFee = _transferReflectionFee;
        transferBurnFee = _transferBurnFee;
        transferMarketingFee = _transferMarketingFee;
        transferDevFee = _transferDevFee;
        totalTransferFee = _transferReflectionFee.add(_transferBurnFee).add(_transferMarketingFee).add(transferDevFee);
        require(totalTransferFee < feeDenominator / 10); // max. 10% 
    }

    function setFeeReceivers(address _marketingFeeReceiver, address _devFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    // EXEMPTIONS SETTINGS

    function setFree(address holder) public onlyOwner {
        _isFree[holder] = true;
    }

    function unSetFree(address holder) public onlyOwner {
        _isFree[holder] = false;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;

        if (exempt) {
            distributor.setShare(holder, 0);
        }

        else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    // DEX PAIR ADDRESSES SETTINGS

    function setDexPair(address _dexPair) external authorized {
        dexPair = address(_dexPair);
    }

    function setDexPair2(address _dexPair2) external authorized {
        dexPair2 = address(_dexPair2);
    }

    function setDexPair3(address _dexPair3) external authorized {
        dexPair3 = address(_dexPair3);
    }

    // DIVIDEND DISTRIBUTOR SETTINGS

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorAddress(address _distributorAddress) external authorized {
        distributorAddress = address(_distributorAddress);
    }

    function setNewDistributor() external authorized {
        distributor = new LynxDividendDistributor(ROUTERADDR);
        distributorAddress = address(distributor);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 850000);
        distributorGas = gas;
    }

    function setSwapBackSettings(bool _enabled, uint256 _maxPercTransfer, uint256 _max) external authorized {
        swapEnabled = _enabled;
        swapPercentMax = _maxPercTransfer;
        swapThresholdMax = _max;
    }
}
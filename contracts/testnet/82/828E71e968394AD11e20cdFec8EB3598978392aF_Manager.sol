// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/IJoePair.sol";
import "../interfaces/IJoeRouter02.sol";
import "../interfaces/IJoeOracle.sol";
import "../interfaces/IWAVAX.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/ITokenStakePool.sol";

contract Manager is ReentrancyGuard, Pausable, AccessControl {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  address public tokenA;
  address public tokenB;
  address public rewardToken;
  address public tokenALendingPool;
  address public tokenBLendingPool;
  address public router;
  address public lpToken;
  address public stakePool;
  address public joeOracle;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  /* ========== STRUCTS ========== */

  struct Vault {
    // uint256 tokenADebtAmount; // TODO: this debtAmount doesnt update to include interest
    // uint256 tokenBDebtAmount; // TODO: this debtAmount doesnt update to include interest
    uint256 lpTokenAmount;
    bool approved;
  }

  /* ========== MAPPINGS ========== */

  mapping(address => Vault) public vaults;
  // mapping(address => address) public tokenToLendingPool;

  /* ========== EVENTS ========== */

  // event Deposit();
  // event Withdraw();
  // event Borrow();
  // event Repay();
  // event Compound();
  // event Rebalance();

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _tokenA,
    address _tokenB,
    address _rewardToken,
    address _tokenALendingPool,
    address _tokenBLendingPool,
    address _router,
    address _lpToken,
    address _stakePool,
    address _joeOracle

  ) {
    _setupRole(OWNER_ROLE, msg.sender);

    tokenA = _tokenA;
    tokenB = _tokenB;
    rewardToken = _rewardToken;
    tokenALendingPool = _tokenALendingPool;
    tokenBLendingPool = _tokenBLendingPool;
    router = _router;
    lpToken = _lpToken;
    stakePool = _stakePool;
    joeOracle = _joeOracle;

    vaults[msg.sender].approved = true;

    // tokenToLendingPool[tokenA] = tokenALendingPool;
    // tokenToLendingPool[tokenB] = tokenBLendingPool;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyApprovedVault() {
    require(vaults[msg.sender].approved == true, "Vault is not approved for Manager");
    _;
  }

  /* ========== VIEW FUNCTIONS ========== */

  // Get equity info of vault. Equity = Asset + Debt
  function equityInfo(address _vault) public view returns (uint256, uint256, uint256, uint256) {
    (uint256 tokenAAmount, uint256 tokenBAmount) = IJoeOracle(joeOracle).getLpTokenReserves(
      vaults[_vault].lpTokenAmount,
      tokenA,
      tokenB,
      lpToken
    );

    (uint256 tokenAValue, uint256 tokenBValue, ) = IJoeOracle(joeOracle).getLpTokenValue(
      vaults[_vault].lpTokenAmount,
      tokenA,
      tokenB,
      lpToken
    );

    return (tokenAAmount, tokenBAmount, tokenAValue, tokenBValue);
  }

  // Get debt info of vault. Debt = Equity - Asset
  function debtInfo(address _vault) public view returns (uint256, uint256, uint256, uint256) {
    uint256 tokenADebtAmount = ILendingPool(tokenALendingPool).maxRepay(_vault);
    uint256 tokenBDebtAmount = ILendingPool(tokenBLendingPool).maxRepay(_vault);

    // Get tokenA value based on AMM estimated amount out
    uint256 tokenADebtValue = IJoeOracle(joeOracle).getAmountsOut(
      tokenADebtAmount,
      tokenA,
      tokenB,
      lpToken
    );

    // Assume token B is stablecoin at $1 for now (1 x 1e6)
    uint256 tokenBDebtValue = tokenBDebtAmount;

    return (tokenADebtAmount, tokenBDebtAmount, tokenADebtValue, tokenBDebtValue);
  }

  // Get asset info of vault. Asset = Equity - Asset
  function assetInfo(address _vault) public view returns (uint256, uint256, uint256, uint256) {
    (
      uint256 tokenAEquityAmount,
      uint256 tokenBEquityAmount,
      uint256 tokenAEquityValue,
      uint256 tokenBEquityValue
    ) = equityInfo(_vault);

    (
      uint256 tokenADebtAmount,
      uint256 tokenBDebtAmount,
      uint256 tokenADebtValue,
      uint256 tokenBDebtValue
    ) = debtInfo(_vault);

    uint256 tokenAAssetAmount = tokenAEquityAmount - tokenADebtAmount;
    uint256 tokenBAssetAmount = tokenBEquityAmount - tokenBDebtAmount;
    uint256 tokenAAssetValue = tokenAEquityValue - tokenADebtValue;
    uint256 tokenBAssetValue = tokenBEquityValue - tokenBDebtValue;

    return (tokenAAssetAmount, tokenBAssetAmount, tokenAAssetValue, tokenBAssetValue);
  }

  // Get vault's current position (equity) value
  function positionValue(address _vault) public view returns (uint256) {
    (, , uint256 tokenAEquityValue, uint256 tokenBEquityValue) = equityInfo(_vault);

    return tokenAEquityValue + tokenBEquityValue;
  }

  // TODO: Refactor Vault contract to use previous values perhaps?
  function getPositionInfo(address _vault) public view onlyApprovedVault returns (uint256, uint256, uint256, uint256) {
    (
      ,
      ,
      uint256 tokenAEquityValue,
      uint256 tokenBEquityValue
    ) = equityInfo(_vault);

    (
      uint256 tokenADebtAmount,
      uint256 tokenBDebtAmount,
      uint256 tokenADebtValue,
      uint256 tokenBDebtValue
    ) = debtInfo(_vault);

    return (
      tokenAEquityValue + tokenBEquityValue,
      tokenADebtValue + tokenBDebtValue,
      tokenADebtAmount,
      tokenBDebtAmount
    );
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function borrowTokenA(uint256 _borrowTokenAValue) external {
    // Borrow tokens if neccessary
    if (_borrowTokenAValue > 0) {
      uint256 tokenAAmountToBorrow = IJoeOracle(joeOracle).getAmountsIn(
        _borrowTokenAValue,
        tokenA,
        tokenB,
        lpToken
      );
      ILendingPool(tokenALendingPool).borrow(tokenAAmountToBorrow);
    }
  }

  function borrowTokenB(uint256 _borrowTokenBValue) external {
    // Borrow tokens if neccessary
    if (_borrowTokenBValue > 0) {
      ILendingPool(tokenBLendingPool).borrow(_borrowTokenBValue);
    }
  }

  function repayTokenA(uint256 _repayTokenAValue) external {
    // Repay tokens if neccessary
    if (_repayTokenAValue > 0) {
      uint256 tokenAAmountToRepay = IJoeOracle(joeOracle).getAmountsIn(
        _repayTokenAValue,
        tokenA,
        tokenB,
        lpToken
      );
      IERC20(tokenA).approve(tokenALendingPool, tokenAAmountToRepay);
      ILendingPool(tokenALendingPool).repay(tokenAAmountToRepay);
    }
  }

  function repayTokenB(uint256 _repayTokenBValue) external {
    // Repay tokens if neccessary
    if (_repayTokenBValue > 0) {
      IERC20(tokenB).approve(tokenBLendingPool, _repayTokenBValue);
      ILendingPool(tokenBLendingPool).repay(_repayTokenBValue);
    }
  }

  // function getAmountsIn(uint256 _value) external view returns (uint256) {
  //   address[] memory tokenAToBPath = new address[](2);
  //   tokenAToBPath[0] = tokenA;
  //   tokenAToBPath[1] = tokenB;
  //   return IJoeRouter02(router).getAmountsIn(_value, tokenAToBPath)[0];
  // }

  // function getAmountsOut(uint256 _value) external view returns (uint256) {
  //   address[] memory tokenAToBPath = new address[](2);
  //   tokenAToBPath[0] = tokenA;
  //   tokenAToBPath[1] = tokenB;
  //   return IJoeRouter02(router).getAmountsOut(_value, tokenAToBPath)[1];
  // }

  function addLiquidity(
    uint256 _tokenAAmount,
    uint256 _tokenBAmount
  ) external {
    // IERC20(tokenA).approve(lpToken, _tokenAAmount);
    // IERC20(tokenB).approve(lpToken, _tokenBAmount);
    IERC20(tokenA).approve(router, _tokenAAmount);
    IERC20(tokenB).approve(router, _tokenBAmount);

    (, , uint256 lpTokensMinted) = IJoeRouter02(router).addLiquidity(
      tokenA,
      tokenB,
      _tokenAAmount,
      _tokenBAmount,
      0,
      0,
      address(this),
      block.timestamp + 1 minutes
    );

    vaults[msg.sender].lpTokenAmount += lpTokensMinted;
  }

  function removeLiquidity(uint256 _lpWithdrawAmount) external {
    IJoePair(lpToken).approve(router, _lpWithdrawAmount);

    IJoeRouter02(router).removeLiquidity(
      tokenA,
      tokenB,
      _lpWithdrawAmount,
      0,
      0,
      address(this),
      block.timestamp + 1 minutes
    );

    vaults[msg.sender].lpTokenAmount -= _lpWithdrawAmount;
  }

  function getLpTokenAmount(
    uint256 _tokenAOneAmountValue,
    uint256 minimumRepayValue,
    uint256 repayDifferenceValue
  ) external view returns (uint256) {
    // Get 1 LP token's value
    (, , uint256 lpTokenValue) = IJoeOracle(joeOracle).getLpTokenValue(
      _tokenAOneAmountValue,
      tokenA,
      tokenB,
      lpToken
    );

    uint256 lpWithdrawAmount = (minimumRepayValue * 2 + repayDifferenceValue) / lpTokenValue;
    //99690060+1000000 = 109690060

    return lpWithdrawAmount;
  }

  function work(
    uint256 depositTokenAAmount,
    uint256 _targetLpValue,
    uint256 _borrowTokenAValue,
    uint256 _borrowTokenBValue,
    uint256 _repayTokenAValue,
    uint256 _repayTokenBValue
  ) public onlyApprovedVault {
    // TODO: Mock only as Vault.sol should transfer assets before calling work()
    IERC20(tokenA).safeTransferFrom(msg.sender, address(this), depositTokenAAmount);

    // Borrow tokens if neccessary
    if (_borrowTokenAValue > 0) {
      uint256 tokenAAmountToBorrow = IJoeOracle(joeOracle).getAmountsIn(
        _borrowTokenAValue,
        tokenA,
        tokenB,
        lpToken
      );
      ILendingPool(tokenALendingPool).borrow(tokenAAmountToBorrow);
    }

    if (_borrowTokenBValue > 0) {
      ILendingPool(tokenBLendingPool).borrow(_borrowTokenBValue);
    }

    // Probably withdrawal flow
    // If current position value is more than target position value, we reduce liquidity and repay debt
    if (positionValue(msg.sender) > _targetLpValue) {
      // Calculate repay value difference between the two assets
      // The asset with higher repay value will be later swapped to the other asset to repay equally
      uint256 repayDifferenceValue;
      address[] memory swapPathForRepayDifference = new address[](2);
      bool swapTokenAForB;

      if (_repayTokenAValue >= _repayTokenBValue) {
        repayDifferenceValue = _repayTokenAValue - _repayTokenBValue;
        swapPathForRepayDifference[0] = tokenA;
        swapPathForRepayDifference[1] = tokenB;
        swapTokenAForB = true;
      } else if (_repayTokenAValue < _repayTokenBValue) {
        repayDifferenceValue = _repayTokenBValue - _repayTokenAValue;
        swapPathForRepayDifference[0] = tokenB;
        swapPathForRepayDifference[1] = tokenA;
        swapTokenAForB = false;
      }

      // Calculate minimum amount of lp tokens to withdraw based on minimum repay value
      uint256 minimumRepayValue;
      if (_repayTokenAValue >= _repayTokenBValue) {
        minimumRepayValue = _repayTokenBValue;
      } else if (_repayTokenAValue < _repayTokenAValue) {
        minimumRepayValue = _repayTokenAValue;
      }

      // Get 1 LP token's value
      (, , uint256 lpTokenValue) = IJoeOracle(joeOracle).getLpTokenValue(
        1_000_000_000_000_000_000,
        tokenA,
        tokenB,
        lpToken
      );

      uint256 lpWithdrawAmount = (minimumRepayValue * 2 + repayDifferenceValue) / lpTokenValue;

      // Unstake LP from rewards pool
      // ITokenStakePool(stakePool).withdraw(lpWithdrawAmount);

      // Withdraw LP tokens to assets
      // we get AVAX amount and USDC amount
      IJoePair(lpToken).approve(router, lpWithdrawAmount);
      IJoeRouter02(router).removeLiquidity(
        tokenA,
        tokenB,
        lpWithdrawAmount,
        0,
        0,
        address(this),
        block.timestamp + 1 minutes
      );

      vaults[msg.sender].lpTokenAmount -= lpWithdrawAmount;

      // Swap assets within LP
      // If swapping for Token A, we need to convert it from value to amount
      // If swapping for Token B, assume it's a stablecoin and value is equal to amount
      uint256 swapAmountIn;
      if (swapTokenAForB) {
        // Assuming tokenB is USD, we pass in the value to get estimated amount of tokenA out
        swapAmountIn = IJoeOracle(joeOracle).getAmountsIn(
          repayDifferenceValue / 2,
          tokenA,
          tokenB,
          lpToken
        );
      } else {
        swapAmountIn = repayDifferenceValue / 2;
      }

      if (swapAmountIn > 0) {
        // IERC20(tokenA).approve(router, swapAmountIn);
        IERC20(tokenA).approve(lpToken, swapAmountIn);
        IJoeRouter02(router).swapExactTokensForTokens(
          swapAmountIn,
          0,
          swapPathForRepayDifference,
          address(this),
          block.timestamp + 1 minutes
        );
      }

      // Repay debt of both tokens in token amounts
      uint256 _repayTokenAAmount = IERC20(tokenA).balanceOf(address(this));
      IERC20(tokenA).approve(tokenALendingPool, _repayTokenAAmount);
      ILendingPool(tokenALendingPool).repay(_repayTokenAAmount);

      uint256 _repayTokenBAmount = IERC20(tokenB).balanceOf(address(this));
      IERC20(tokenB).approve(tokenBLendingPool, _repayTokenBAmount);
      ILendingPool(tokenBLendingPool).repay(_repayTokenBAmount);
    }

    // Probably deposit flow
    // If current position value is less than target position value, we calculate optimal deopsit and add liquidity
    if (positionValue(msg.sender) < _targetLpValue) {
      // Repay tokens if neccessary
      // Assume tokenA is AVAX, we need to covert to AVAX amount from value
      if (_repayTokenAValue > 0) {
        uint256 _tokenARepayAmount = IJoeOracle(joeOracle).getAmountsIn(
          _repayTokenAValue,
          tokenA,
          tokenB,
          lpToken
        );
        IERC20(tokenA).approve(tokenALendingPool, _tokenARepayAmount);
        ILendingPool(tokenALendingPool).repay(_tokenARepayAmount);
      }

      // Assume tokenB is stablecoin and value is same as amount
      if (_repayTokenBValue > 0) {
        IERC20(tokenB).approve(tokenBLendingPool, _repayTokenBValue);
        ILendingPool(tokenBLendingPool).repay(_repayTokenBValue);
      }

      (uint256 reserveA, uint256 reserveB) = IJoeOracle(joeOracle).getLpTokenReserves(
        IJoePair(lpToken).totalSupply(),
        tokenA,
        tokenB,
        lpToken
      );

      // Calculate optimal deposit for token0
      (uint256 optimalSwapAmount, bool isReversed) = optimalDeposit(
        IERC20(tokenA).balanceOf(address(this)),
        IERC20(tokenB).balanceOf(address(this)),
        reserveA,
        reserveB,
        3 // fee of 0.3%
      );

      address[] memory swapPathForOptimalDeposit = new address[](2);

      if (isReversed) {
        swapPathForOptimalDeposit[0] = tokenB;
        swapPathForOptimalDeposit[1] = tokenA;
      } else {
        swapPathForOptimalDeposit[0] = tokenA;
        swapPathForOptimalDeposit[1] = tokenB;
      }

      // Swap tokens to achieve optimal deposit amount
      if (optimalSwapAmount > 0) {
        IERC20(swapPathForOptimalDeposit[0]).approve(router, optimalSwapAmount);
        // IERC20(swapPathForOptimalDeposit[0]).approve(lpToken, optimalSwapAmount);
        IJoeRouter02(router).swapExactTokensForTokens(
          optimalSwapAmount,
          0,
          swapPathForOptimalDeposit,
          address(this),
          block.timestamp + 1 minutes
        );
      }


      // Add liquidity
      (, , uint256 lpTokensMinted) = IJoeRouter02(router).addLiquidity(
        tokenA,
        tokenB,
        IERC20(tokenA).balanceOf(address(this)),
        IERC20(tokenB).balanceOf(address(this)),
        0,
        0,
        address(this),
        block.timestamp + 1 minutes
      );

      vaults[msg.sender].lpTokenAmount += lpTokensMinted;

      // Stake LP to rewards pool
      // ITokenStakePool(stakePool).stake(lpTokensMinted);
    }

    // We send whatever assets are left in position back to the Vault
    // Handles any dust on deposit, as well as all assets during withdrawal
    IERC20(tokenA).transfer(msg.sender, IERC20(tokenA).balanceOf(address(this)));
    IERC20(tokenB).transfer(msg.sender, IERC20(tokenB).balanceOf(address(this)));

    // compound();
  }

  // function compound() public {
  //   // redeem reward tokens from reward pool, sell for equal assets, deposit to swap to get LP and restake LP
  //   ITokenStakePool(stakePool).claim();

  //   // get balance of rewardToken in contract
  //   uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));

  //   if (rewardTokenBalance > 0) {
  //     address[] memory swapRewardTokenToBPath = new address[](2);
  //     swapRewardTokenToBPath[0] = rewardToken;
  //     swapRewardTokenToBPath[1] = tokenB;

  //     // Assume tokenB is USDC
  //     // _amountIn, _amountOutMin, path(["", ""]), to (address), deadline (uint256)
  //     IJoeRouter02(router).swapExactTokensForTokens(
  //       rewardTokenBalance,
  //       0,
  //       swapRewardTokenToBPath,
  //       address(this),
  //       block.timestamp + 1 minutes
  //     );

  //     // Swap tokenB to tokenA for optimal add liquidity deposit
  //     (uint256 reserve0, uint256 reserve1, ) = IJoePair(lpToken).getReserves();
  //     uint256 reserveA;
  //     uint256 reserveB;

  //     if (tokenA == IJoePair(lpToken).token0() && tokenB == IJoePair(lpToken).token1()) {
  //       reserveA = reserve0;
  //       reserveB = reserve1;
  //     } else {
  //       reserveA = reserve1;
  //       reserveB = reserve0;
  //     }

  //     // Calculate optimal deposit for token0
  //     (uint256 optimalSwapAmount, bool isReversed) = optimalDeposit(
  //       0,
  //       IERC20(tokenB).balanceOf(address(this)),
  //       reserveA,
  //       reserveB,
  //       3
  //     );

  //     address[] memory swapPathForOptimalDeposit = new address[](2);

  //     (swapPathForOptimalDeposit[0], swapPathForOptimalDeposit[1]) = isReversed ? (tokenB, tokenA) : (tokenA, tokenB);

  //     // Swap tokens to achieve optimal deposit amount
  //     if (optimalSwapAmount > 0) {
  //       IJoeRouter02(router).swapExactTokensForTokens(
  //         optimalSwapAmount,
  //         0,
  //         swapPathForOptimalDeposit,
  //         address(this),
  //         block.timestamp + 1 minutes
  //       );
  //     }

  //     (, , uint256 lpTokensMinted) = IJoeRouter02(router).addLiquidity(
  //       tokenA,
  //       tokenB,
  //       IERC20(tokenA).balanceOf(address(this)),
  //       IERC20(tokenB).balanceOf(address(this)),
  //       0,
  //       0,
  //       address(this),
  //       block.timestamp + 1 minutes
  //     );

  //     vaults[msg.sender].lpTokenAmount += lpTokensMinted;

  //     ITokenStakePool(stakePool).stake(lpTokensMinted);
  //   }
  // }

  /* ========== INTERNAL FUNCTIONS ========== */

  function optimalDeposit(
    uint256 _amountA,
    uint256 _amountB,
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 _fee
  ) public pure returns (uint256, bool) {
    uint256 swapAmt;
    bool isReversed;

    if (_amountA * _reserveB >= _amountB * _reserveA) {
      swapAmt = _optimalDeposit(_amountA, _amountB, _reserveA, _reserveB, _fee);
      isReversed = false;
    } else {
      swapAmt = _optimalDeposit(_amountB, _amountA, _reserveB, _reserveA, _fee);
      isReversed = true;
    }

    return (swapAmt, isReversed);
  }

  function _optimalDeposit(
    uint256 _amountA,
    uint256 _amountB,
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 _fee
  ) internal pure returns (uint256) {
      require(_amountA * _reserveB >= _amountB * _reserveA, "Reversed");

      uint256 a = 1000 - _fee;
      uint256 b = (2000 - _fee) * _reserveA;
      uint256 _c = (_amountA * _reserveB) - (_amountB * _reserveA);
      uint256 c = _c * 1000 / (_amountB + _reserveB) * _reserveA;
      uint256 d = a * c * 4;
      uint256 e = Math.sqrt(b * b + d);
      uint256 numerator = e - b;
      uint256 denominator = a * 2;

      return numerator / denominator;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function approveVault(address _vault) external onlyRole(OWNER_ROLE) {
    require(vaults[_vault].approved == false, "Vault already approved");

    vaults[_vault].approved = true;
  }

  function rejectVault(address _vault) external onlyRole(OWNER_ROLE) {
    require(vaults[_vault].approved == true, "Vault already rejected");

    vaults[_vault].approved = false;
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

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

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITokenStakePool {
  function balanceOf(address _account) external view returns (uint256);
  function rewardsEarned(address _account) external view returns (uint256);
  function stake(uint256 _amount) external;
  function withdraw(uint256 _amount) external;
  function claim() external;
  function activateUnlockTime() external;
  function exit() external;
  function updateRewardsDistributionRate(uint256 _rate) external;
  function updateUnlockTime(uint256 _minutes) external;
  function updateRelockTime(uint256 _minutes) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IJoeOracle {
  function getAmountsOut(
    uint256 _amountIn,
    address _token0,
    address _token1,
    address _pair
  ) external view returns (uint256);

  function getAmountsIn(
    uint256 _amountOut,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256);

  function getLpTokenReserves(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256, uint256);

  function getLpTokenValue(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILendingPool {
  function totalValue() external view returns (uint256);
  function totalLiquidity() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function exchangeRate() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxWithdraw(address _address) external view returns (uint256);
  function maxRepay(address _address) external view returns (uint256);
  function depositNative(uint256 _assetAmount) external payable;
  function deposit(uint256 _assetAmount) external;
  function withdrawNative(uint256 _ibTokenAmount) external;
  function withdraw(uint256 _ibTokenAmount) external;
  function borrow(uint256 _assetAmount) external;
  function repay(uint256 _repayAmount) external;
  function updateProtocolFee(uint256 _protocolFee) external;
  function withdrawReserve(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWAVAX {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
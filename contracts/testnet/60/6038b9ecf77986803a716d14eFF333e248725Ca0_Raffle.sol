// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICoupons{

    struct Coupon {
        bytes32 couponHash;
        uint8 minPct;
        uint8 maxPct;
        uint16 multiplierPct;
        bool isPaid;
    }

    struct CouponRule {
        uint16 minRndPct;
        uint16 maxRndPct;
        uint16 step;
        bool allowExtMultiplier;    // Allow external multiplier
    }

    struct CouponPrice {
        address tokenAddress;       // if address 0x0 - this is base currency
        uint couponFee;
    }

    struct CouponTicket {
        address playerAddress;
        uint16 multiplierPct;
        bool used;
    }

    function getCoupon(
        bytes32 couponHash,
        address playerAddress,
        address contractAddress,
        uint32 raffleId
    ) external view returns (Coupon memory);

    /*
     * @notice Buy a coupon for tokens with predefined multiplier percentage.
     * @dev If the sale is for erc20 tokens, then the payment amount in the transaction
     * 'msg.value' must be set to zero.
     *
     * @param contractAddress The address of the drop game contract.
     * @param raffleId The draw Id.
     * @param tokenAddress The address of the payment token. Use address(0) for native token payments.
     * @param amount `amount` of tokens to pay. For the native token must be 0
     * @param multiplierPct Multiplier percentage.
     *        If set to 0, the value will be generated by the contract based on the rule.
     * @return void
     */
    function buyCoupon(
        address contractAddress,
        uint32 raffleId,
        address tokenAddress,
        uint256 amount,
        uint16 multiplierPct
    ) external payable;

    function useCoupon(
        bytes32 couponHash,
        address playerAddress,
        uint32 raffleId
    ) external returns (Coupon memory);

    function getCouponTicket(
        address contractAddress,
        uint32 raffleId,
        bytes32 couponHash
    ) external returns (CouponTicket memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IPrizeMatrix{
    enum PrizeType {
        DIRECT,
        OFFLINE,
        PENDING
    }

    struct PrizeLevel {
        uint32 nWinners;
        uint256 prize;
        bool directPayment;
    }

    function getPrizeMatrix(uint32 raffleId) external returns (PrizeLevel[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IPrizeMatrix.sol";
import "./IRaffleResults.sol";

interface IPrizeStorage{
        function setPrizes(
        IRaffleResults.RaffleResults memory raffleResults,
        IPrizeMatrix.PrizeLevel[] memory prizeMatrix
    ) external payable;

    function checkForPrize(address contractAddress, uint32 raffleId, address playerAddress) external returns (uint);

    function getRaffleDrawBalance(address contractAddress, uint32 raffleId) external view returns (uint);

    function getRaffleDrawTimestamp(address contractAddress, uint32 raffleId) external view returns (uint);

    function prizePayout(address contractAddress, uint32 raffleId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IRaffleResults {
    struct RaffleResults {
        uint32 raffleId;
        uint timestamp;
        PrizeLevelWinners[] winnersMatrix;
    }

    struct PrizeLevelWinners {
        address payable [] winners;
    }

    function getRaffleResults(uint32 raffleId) external returns (RaffleResults memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/IPrizeMatrix.sol";
import "./interfaces/IRaffleResults.sol";
import "./interfaces/ICoupons.sol";
import "./interfaces/IPrizeStorage.sol";
//import "hardhat/console.sol";

/* Errors */
    error Raffle__UpkeepNotNeeded();
    error Raffle__ChangeTransferFailed();
    error Raffle__TransferToWinnerFailed();
    error Raffle__TransferToSafeFailed();
    error Raffle__PartnerIdTooLong();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__MaxTicketsLimit();
    error Raffle__RaffleNotOpen();
    error Raffle__OnlyOwnerAllowed();
    error Raffle__OnlyAtMaintenanceAllowed();
    error Raffle__MustUpdatePrizeMatrix();
    error Raffle__PrizeMatrixWrongBalance();
    error Raffle__PrizeMatrixDirectPrizesLimit();
    error Raffle__PrizeMatrixTotalPrizesLimit();
    error Raffle__PrizeMatrixIsEmpty();

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface, IRaffleResults, IPrizeMatrix {
    string private constant VERSION = "0.7.0";

    /* Type declarations */
    enum RaffleState {
        OPEN,
        DRAW_PENDING,    // pending the draw. Use this stage for data sync
        DRAW,            // CALCULATING a winner
        MAINTENANCE      // State to change contract settings, between DRAW and OPEN.
    }
    /* State variables */
    // ChainLink VRF constants
    struct ChainLinkConstants {
        address vrfCoordinatorAddress;
        uint16 requestConfirmations;
        bytes32 gasLane;
    }
    // ChainLink VRF parameters
    struct ChainLinkParams {
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }
    // Lottery parameters
    struct RaffleParams {
        uint256 entranceFee;
        uint256 prize;
        bool autoStart;
        uint8 prizePct;
        uint32 maxTickets;
        address payable safeAddress;
    }
    // Coupon manager constants
    ICoupons public couponManager;
    IPrizeStorage public prizeStorage;
    // ChainLink constants
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    address private immutable i_vrfCoordinatorAddress;
    uint16 private immutable i_requestConfirmations;
    bytes32 private immutable i_gasLane;
    // ChainLink parameters
    ChainLinkParams private s_chainLinkParams;
    // Lottery parameters
    RaffleParams private s_raffleParams;
    mapping(uint32 => IPrizeMatrix.PrizeLevel[]) private s_prizeMatrix;
    // Lottery variables
    address private s_owner;
    uint32 private s_raffleId;
    uint256 private s_targetBalance;
    mapping(uint32 => address payable []) private s_tickets;
    mapping(uint32 => mapping(address => uint32)) private s_nTickets;
    // raffleId => partnerIDs
    mapping(uint32 => string[]) private s_partnerIDs;
    // raffleId => partnerId => balance
    mapping(uint32 => mapping(string => uint256)) private s_partnerBalance;
    RaffleState private s_raffleState;
    // Lottery results
    mapping(uint32 => mapping(uint8 => uint32[])) private s_winnerIndexes;
    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(
        address indexed player,
        RaffleState raffleState,
        uint32 ticketsSold,
        uint32 bonusTickets,
        string partnerID
    );
    event WinnerPicked(uint256[] randomWords, uint256 ownerIncome, RaffleState raffleState);
    event CheckUpkeepCall(address indexed keeper, RaffleState raffleState, bool upkeepNeeded);
    event ChangeState(RaffleState raffleState);
    event ChangeRaffleParams(RaffleParams raffleParams);
    event CouponError(string reason);

    /* Functions */
    constructor(
        address couponManagerAddress,
        address prizeStorageAddress,
        ChainLinkConstants memory _chainLinkConstants,
        ChainLinkParams memory _chainLinkParams,
        RaffleParams memory _raffleParams
    ) VRFConsumerBaseV2(_chainLinkConstants.vrfCoordinatorAddress) {
        couponManager = ICoupons(couponManagerAddress);
        prizeStorage = IPrizeStorage(prizeStorageAddress);
        i_vrfCoordinator = VRFCoordinatorV2Interface(_chainLinkConstants.vrfCoordinatorAddress);
        i_vrfCoordinatorAddress = _chainLinkConstants.vrfCoordinatorAddress;
        i_requestConfirmations = _chainLinkConstants.requestConfirmations;
        i_gasLane = _chainLinkConstants.gasLane;
        s_chainLinkParams.subscriptionId = _chainLinkParams.subscriptionId;
        s_chainLinkParams.callbackGasLimit = _chainLinkParams.callbackGasLimit;
        _setRaffleParams(_raffleParams);
        s_owner = msg.sender;
        s_raffleId = 1;
        s_raffleState = RaffleState.MAINTENANCE;
        setTargetBalance();
        setPrizeMatrix(new IPrizeMatrix.PrizeLevel[](0));
    }

    function enterRaffle(string memory couponKey, string memory partnerID) public payable {
        if (bytes(partnerID).length > 256) {
            revert Raffle__PartnerIdTooLong();
        }
        if (msg.value < s_raffleParams.entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        if (msg.value > s_raffleParams.entranceFee * s_raffleParams.maxTickets) {
            revert Raffle__MaxTicketsLimit();
        }

        // The overbooking must be sent back to the player as change.
        uint256 overbooking = 0;
        if (address(this).balance >= s_targetBalance) {
            s_raffleState = RaffleState.DRAW_PENDING;
            overbooking = address(this).balance - s_targetBalance;
        }
        uint32 realTickets = uint32((msg.value - overbooking) / s_raffleParams.entranceFee);
        uint32 bonusTickets;

        // Update partner balance
        if (bytes(partnerID).length > 0) {
            if (s_partnerBalance[s_raffleId][partnerID] == 0) {
                s_partnerIDs[s_raffleId].push(partnerID);
            }
            s_partnerBalance[s_raffleId][partnerID] += msg.value - overbooking;
        }

        // Check coupons
        if (bytes(couponKey).length > 0) {
            try couponManager.useCoupon(keccak256(abi.encodePacked(couponKey)), msg.sender, s_raffleId)
            returns (ICoupons.Coupon memory coupon) {
                uint256 startBalancePct = uint16(100 * (address(this).balance - msg.value) / s_targetBalance);
                if (coupon.minPct <= startBalancePct && startBalancePct <= coupon.maxPct) {
                    bonusTickets += (realTickets * coupon.multiplierPct) / 100;
                }
            } catch Error(string memory reason) {
                emit CouponError(reason);
            }
        }

        for (uint ticketId = 0; ticketId < realTickets + bonusTickets; ticketId++) {
            s_tickets[s_raffleId].push(payable(msg.sender));
        }
        s_nTickets[s_raffleId][msg.sender] += (realTickets + bonusTickets);
        // Try to send change
        if (overbooking > 0) {
            (bool changeTxSuccess, ) = msg.sender.call{value: overbooking}("");
            if (!changeTxSuccess) {
                revert Raffle__ChangeTransferFailed();
            }
        }
        emit RaffleEnter(msg.sender, s_raffleState, realTickets, bonusTickets, partnerID);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     */
    function checkUpkeep(
        bytes calldata upkeepData
    )
    public
    override
    returns (
        bool upkeepNeeded,
        bytes memory _upkeepData
    )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool isDrawPending = RaffleState.DRAW_PENDING == s_raffleState;
        bool hasPlayers = s_tickets[s_raffleId].length > 0;
        bool bankCollected = (s_targetBalance > 0 && address(this).balance >= s_targetBalance);
        upkeepNeeded = (hasPlayers && (isOpen || isDrawPending) && bankCollected);

        if (upkeepNeeded) {
            s_raffleState = RaffleState.DRAW_PENDING;
        }
        _upkeepData = upkeepData;
        emit CheckUpkeepCall(msg.sender, s_raffleState, upkeepNeeded);
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(
        bytes calldata upkeepData
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep(upkeepData);
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }
        s_raffleState = RaffleState.DRAW;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            s_chainLinkParams.subscriptionId,
            i_requestConfirmations,
            s_chainLinkParams.callbackGasLimit,
            getNumWords()
        );
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint unpaidPrize = s_raffleParams.prize;
        uint winnerId;
        uint nLevels = s_prizeMatrix[s_raffleId].length;
        uint32 raffleId = s_raffleId;

        IRaffleResults.RaffleResults memory raffleResults;
        raffleResults.raffleId = raffleId;
        raffleResults.timestamp = block.timestamp;
        raffleResults.winnersMatrix =
            new IRaffleResults.PrizeLevelWinners[](nLevels);

        for (uint levelId; levelId < nLevels; levelId++) {
            uint nPrizes = s_prizeMatrix[raffleId][levelId].nWinners;
            raffleResults.winnersMatrix[levelId].winners = new address payable [](nPrizes);

            for (uint prizeId; prizeId < nPrizes; prizeId++) {
                uint32 indexOfWinner = uint32(randomWords[winnerId] % s_tickets[raffleId].length);
                raffleResults.winnersMatrix[levelId].winners[prizeId] = s_tickets[raffleId][indexOfWinner];
                s_winnerIndexes[raffleId][uint8(levelId)].push(indexOfWinner);
                address payable winnerAddress = s_tickets[raffleId][indexOfWinner];
                uint prize = s_prizeMatrix[raffleId][levelId].prize;
                if (s_prizeMatrix[raffleId][levelId].directPayment) {
                    (bool winnerTxSuccess, ) = winnerAddress.call{value: prize}("");
                    if (winnerTxSuccess) {
                        unpaidPrize -= prize;
                    }
                }
                // console.log('fulfillRandomWords: processed=%s, gas=%s', winnerId, gasleft());
                winnerId++;
            }
        }
        prizeStorage.setPrizes{value: unpaidPrize}(raffleResults, s_prizeMatrix[s_raffleId]);

        uint256 fee = address(this).balance;
        (bool safeTxSuccess, ) = s_raffleParams.safeAddress.call{value: fee}("");
        if (safeTxSuccess) {
            // copy matrix to the new draw
            for (uint prizeLevel; prizeLevel < s_prizeMatrix[s_raffleId].length; prizeLevel++) {
                s_prizeMatrix[s_raffleId + 1].push(s_prizeMatrix[s_raffleId][prizeLevel]);
            }
            if (s_raffleParams.autoStart) {
                s_raffleState = RaffleState.OPEN;
            } else {
                s_raffleState = RaffleState.MAINTENANCE;
            }
        } else {
            s_raffleState = RaffleState.MAINTENANCE;
        }

        // Switch to a new lottery session
        s_raffleId += 1;

        emit WinnerPicked(randomWords, fee, s_raffleState);
//        console.log('fulfillRandomWords: total gas left=%s', gasleft());
    }

    /** Getter Functions */
    function getVersion() public pure returns (string memory) {
        return VERSION;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function getRaffleParams() public view returns (RaffleParams memory) {
        return s_raffleParams;
    }

    function getPrizeMatrix(uint32 raffleId) public override view returns (IPrizeMatrix.PrizeLevel[] memory) {
        return s_prizeMatrix[raffleId];
    }

    function getNumWords() public view returns (uint32) {
        uint32 numWords;
        for (uint i=0; i < s_prizeMatrix[s_raffleId].length; i++) {
            numWords += s_prizeMatrix[s_raffleId][i].nWinners;
        }
        return numWords;
    }

    function getChainLinkParams() public view returns (ChainLinkParams memory) {
        return s_chainLinkParams;
    }

    function getRaffleId() public view returns(uint32) {
        return s_raffleId;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumberOfTicketsByRaffleId(uint32 raffleId) public view returns (uint256) {
        return s_tickets[raffleId].length;
    }

    function getNumberOfPlayerTickets(address playerAddress) public view returns(uint32) {
        return s_nTickets[s_raffleId][playerAddress];
    }
    function getNumberOfPlayerTicketsByRaffleId(address playerAddress, uint32 raffleId) public view returns(uint32) {
        return s_nTickets[raffleId][playerAddress];
    }

    function getPlayerByTicketIdByRaffleId(uint256 ticketIndex, uint32 raffleId) public view returns (address) {
        return s_tickets[raffleId][ticketIndex];
    }

    function getTargetBalance() public view returns (uint256) {
        return s_targetBalance;
    }

    function getBalancePct() public view returns (uint16) {
        return uint16(100 * address(this).balance / s_targetBalance);
    }

    function getPartnerIDs(uint32 raffleId) public view returns (string[] memory) {
        return s_partnerIDs[raffleId];
    }

    function getPartnerBalance(uint32 raffleId, string memory partnerID) public view returns (uint256) {
        if (bytes(partnerID).length > 256) {
            revert Raffle__PartnerIdTooLong();
        }
        return s_partnerBalance[raffleId][partnerID];
    }

    function getRaffleResults(uint32 raffleId) public override view returns (IRaffleResults.RaffleResults memory) {
        IRaffleResults.RaffleResults memory raffleResults;
        raffleResults.raffleId = raffleId;
        raffleResults.timestamp = prizeStorage.getRaffleDrawTimestamp(address(this), raffleId);
        raffleResults.winnersMatrix =
            new IRaffleResults.PrizeLevelWinners[](s_prizeMatrix[raffleId].length);
        for (uint levelId; levelId < s_prizeMatrix[raffleId].length; levelId++) {
            uint nPrizes = s_prizeMatrix[raffleId][levelId].nWinners;
            raffleResults.winnersMatrix[levelId].winners = new address payable [](nPrizes);
            for (uint prizeId; prizeId < nPrizes; prizeId++) {
                uint32 indexOfWinner = s_winnerIndexes[raffleId][uint8(levelId)][prizeId];
                raffleResults.winnersMatrix[levelId].winners[prizeId] = s_tickets[raffleId][indexOfWinner];
            }
        }
        return raffleResults;
    }


    /** Setter Functions **/
    function setTargetBalance() private {
        uint bank = (s_raffleParams.prize / s_raffleParams.prizePct) * 100;
        if (bank % s_raffleParams.entranceFee > 0) {
            s_targetBalance = (bank / s_raffleParams.entranceFee + 1) * s_raffleParams.entranceFee;
        } else {
            s_targetBalance = bank;
        }
    }

    function setSubscriptionId(uint32 subscriptionId) public onlyOwner {
        s_chainLinkParams.subscriptionId = subscriptionId;
    }

    function setCallbackGasLimit(uint32 gasLimit) public onlyOwner {
        s_chainLinkParams.callbackGasLimit = gasLimit;
    }

    function setAutoStart(bool isEnabled) public onlyOwner {
        s_raffleParams.autoStart = isEnabled;
    }

    function setRaffleParams(RaffleParams memory raffleParams) public onlyOwner atMaintenance {
        _setRaffleParams(raffleParams);
        emit ChangeRaffleParams(raffleParams);
    }

    function _setRaffleParams(RaffleParams memory raffleParams) private {
        s_raffleParams.entranceFee = raffleParams.entranceFee;
        s_raffleParams.prize = raffleParams.prize;
        s_raffleParams.autoStart = raffleParams.autoStart;
        s_raffleParams.prizePct = raffleParams.prizePct;
        s_raffleParams.maxTickets = raffleParams.maxTickets;
        s_raffleParams.safeAddress = raffleParams.safeAddress;
        setTargetBalance();
    }

    function setPrizeMatrix(IPrizeMatrix.PrizeLevel[] memory prizeMatrix) public onlyOwner atMaintenance {
        _checkCurrentPrizeMatrix(prizeMatrix);
        if (prizeMatrix.length == 0) {
            delete s_prizeMatrix[s_raffleId];
            s_prizeMatrix[s_raffleId].push(IPrizeMatrix.PrizeLevel(1, s_raffleParams.prize, true));
        } else {
            delete s_prizeMatrix[s_raffleId];
            for (uint levelId=0; levelId < prizeMatrix.length; levelId++) {
                s_prizeMatrix[s_raffleId].push(prizeMatrix[levelId]);
            }
        }
    }

    function _checkCurrentPrizeMatrix(IPrizeMatrix.PrizeLevel[] memory prizeMatrix) internal view {
        if (s_raffleId > 0 && prizeMatrix.length > 0) {
            uint directPrizesNumber;
            uint prizesTotalNumber;
            uint matrixBalance;
            for (uint levelId=0; levelId < prizeMatrix.length; levelId++) {
                matrixBalance += prizeMatrix[levelId].nWinners * prizeMatrix[levelId].prize;
                if (prizeMatrix[levelId].directPayment) {
                    directPrizesNumber += prizeMatrix[levelId].nWinners;
                }
                prizesTotalNumber += prizeMatrix[levelId].nWinners;
            }
            if (matrixBalance != s_raffleParams.prize) {
                revert Raffle__PrizeMatrixWrongBalance();
            }
            // TODO Make dynamic limits that depend on gas limit
//            if (directPrizesNumber > 10) {   // limit for 1.5M callback gas limit
//                revert Raffle__PrizeMatrixDirectPrizesLimit();
//            }
//            if (prizesTotalNumber > 60) {    // limit for 1.5M callback gas limit
//                revert Raffle__PrizeMatrixTotalPrizesLimit();
//            }
        }
    }

    function setRaffleMaintenance() public onlyOwner {
        s_raffleState = RaffleState.MAINTENANCE;
        emit ChangeState(s_raffleState);
    }

    function setRaffleOpen() public onlyOwner atMaintenance {
        _checkCurrentPrizeMatrix(s_prizeMatrix[s_raffleId]);
        s_raffleState = RaffleState.OPEN;
        emit ChangeState(s_raffleState);
    }

    receive() external payable atMaintenance {
        // Set start bonus balance
    }

    function rawFulfillRandomWinner(uint32 indexOfWinner) public onlyOwner atMaintenance {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(indexOfWinner);
        fulfillRandomWords(0, randomWords);
    }

    function setCouponManager(address couponManagerAddress) public onlyOwner atMaintenance {
        couponManager = ICoupons(couponManagerAddress);
    }

    function setPrizeStorage(address prizeStorageAddress) public onlyOwner atMaintenance {
        prizeStorage = IPrizeStorage(prizeStorageAddress);
    }

    function changeOwner(address owner) public onlyOwner {
        s_owner = owner;
    }

    /** Modifiers **/
    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Raffle__OnlyOwnerAllowed();
        }
        _;
    }

    modifier atMaintenance() {
        if (s_raffleState != RaffleState.MAINTENANCE) {
            revert Raffle__OnlyAtMaintenanceAllowed();
        }
        _;
    }
}
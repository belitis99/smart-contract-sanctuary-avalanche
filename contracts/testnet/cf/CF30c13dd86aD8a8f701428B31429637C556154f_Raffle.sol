// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/* Errors */
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint8 raffleState);
    error Raffle__ChangeTransferFailed();
    error Raffle__TransferToWinnerFailed();
    error Raffle__TransferToSafeFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__MaxTicketsLimit();
    error Raffle__RaffleNotOpen();
    error Raffle__RaffleBankIsFull();
    error Raffle__OnlyOwnerAllowed();
    error Raffle__OnlyAtMaintenanceAllowed();
    error Raffle__CampaignNotFound();

/**@title A sample Raffle Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        DRAW_PENDING,    // pending the draw. Use this stage for data sync
        DRAW,            // CALCULATING a winner
        MAINTENANCE      // State to change contract settings, between DRAW and OPEN.
    }

    /* State variables */
    string private constant VERSION = "0.4.0";
    // ChainLink VRF constants
    struct ChainLinkConstants {
        address vrfCoordinatorAddress;
        uint16 requestConfirmations;
        uint16 numWords;
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
        uint256 bank;
        bool autoStart;
        uint8 prizePct;
        uint32 maxTickets;
        address payable safeAddress;
    }
    // Lottery results
    struct RaffleResult {
        uint256 timestamp;
        address winnerAddress;
        uint32 indexOfWinner;
        uint256 prize;
    }
    // ValleyOfDeath promo params
    struct Campaign {
        string key;
        bytes32 keyHash;
        uint8 minPct;
        uint8 maxPct;
        uint16 multiplierPct;
    }
    // ChainLink constants
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    address private immutable i_vrfCoordinatorAddress;
    uint16 private immutable i_requestConfirmations;
    uint16 private immutable i_numWords;
    bytes32 private immutable i_gasLane;
    // ChainLink parameters
    ChainLinkParams private s_chainLinkParams;
    // Lottery parameters
    RaffleParams private s_raffleParams;
    // Lottery variables
    address private s_owner;
    uint32 private s_raffleId;
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;
    uint256 private s_targetBalance;
    mapping(uint32 => address payable []) private s_tickets;
    mapping(uint32 => mapping(address => uint32)) private s_nTickets;
    mapping(uint32 => RaffleResult) private s_results;
    mapping(uint32 => Campaign[]) private s_campaigns;
    RaffleState private s_raffleState;
    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player, RaffleState raffleState, uint ticketsSold);
    event WinnerPicked(address indexed player, uint32 indexOfWinner, uint256 prize, uint256 ownerIncome, RaffleState raffleState);
    event CheckUpkeepCall(address indexed keeper, RaffleState raffleState, bool upkeepNeeded);
    event ChangeState(RaffleState raffleState);

    /* Functions */
    constructor(
        ChainLinkConstants memory _chainLinkConstants,
        ChainLinkParams memory _chainLinkParams,
        RaffleParams memory _raffleParams
    ) VRFConsumerBaseV2(_chainLinkConstants.vrfCoordinatorAddress) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_chainLinkConstants.vrfCoordinatorAddress);
        i_vrfCoordinatorAddress = _chainLinkConstants.vrfCoordinatorAddress;
        i_requestConfirmations = _chainLinkConstants.requestConfirmations;
        i_numWords = _chainLinkConstants.numWords;
        i_gasLane = _chainLinkConstants.gasLane;
        s_chainLinkParams.subscriptionId = _chainLinkParams.subscriptionId;
        s_chainLinkParams.callbackGasLimit = _chainLinkParams.callbackGasLimit;
        s_raffleParams.entranceFee = _raffleParams.entranceFee;
        s_raffleParams.bank = _raffleParams.bank;
        s_raffleParams.autoStart = _raffleParams.autoStart;
        s_raffleParams.prizePct = _raffleParams.prizePct;
        s_raffleParams.maxTickets = _raffleParams.maxTickets;
        s_raffleParams.safeAddress = payable(_raffleParams.safeAddress);
        s_owner = msg.sender;
        s_raffleId = 1;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.MAINTENANCE;
        setTargetBalance();
        // Init stats
        s_tickets[0] = new address payable [](0);
        s_results[0] = RaffleResult(0, address(0), 0, 0);
        // Init tickets for 1st session
        s_tickets[s_raffleId] = new address payable [](0);
    }

    function enterRaffle(bytes32 promoHash) public payable returns (uint32 _ticketsSold) {
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
        uint256 realTickets = (msg.value - overbooking) / s_raffleParams.entranceFee;
        uint256 bonusTickets = 0;

        // Check s_campaigns
        if (s_campaigns[s_raffleId].length > 0) {
            for (uint i=0; i < s_campaigns[s_raffleId].length; i++) {
                if (
                    s_campaigns[s_raffleId][i].keyHash == promoHash &&
                    s_campaigns[s_raffleId][i].minPct <= getBalancePct() &&
                    getBalancePct() <= s_campaigns[s_raffleId][i].maxPct
                ) {
                    bonusTickets += realTickets * (1 + s_campaigns[s_raffleId][i].multiplierPct) / 100;
                }
            }
        }

        for (uint ticketId = 0; ticketId < realTickets + bonusTickets; ticketId++) {
            s_tickets[s_raffleId].push(payable(msg.sender));
            s_nTickets[s_raffleId][msg.sender] += 1;
        }
        // Try to send change
        if (overbooking > 0) {
            (bool changeTxSuccess, ) = msg.sender.call{value: overbooking}("");
            if (!changeTxSuccess) {
                revert Raffle__ChangeTransferFailed();
            }
        }
        _ticketsSold = uint32(realTickets + bonusTickets);
        emit RaffleEnter(msg.sender, s_raffleState, _ticketsSold);
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
        bool bankCollected = (s_raffleParams.bank > 0 && address(this).balance >= s_raffleParams.bank);
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
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_tickets[s_raffleId].length,
                uint8(s_raffleState)
            );
        }
        s_raffleState = RaffleState.DRAW;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            s_chainLinkParams.subscriptionId,
            i_requestConfirmations,
            s_chainLinkParams.callbackGasLimit,
            i_numWords
        );
        // Quiz... is this redundant?
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
        uint32 indexOfWinner = uint32(randomWords[0] % s_tickets[s_raffleId].length);
        address payable recentWinner = s_tickets[s_raffleId][indexOfWinner];
        s_recentWinner = recentWinner;
        uint256 prize = (address(this).balance * s_raffleParams.prizePct) / 100;
        s_lastTimeStamp = block.timestamp;

        // Update raffle stats
        s_results[s_raffleId] = RaffleResult(s_lastTimeStamp, s_recentWinner, indexOfWinner, prize);
        // Switch to a new lottery session
        s_raffleId += 1;
        // Init tickets storage
        s_tickets[s_raffleId] = new address payable[](0);

        uint256 fee;
        (bool winnerTxSuccess, ) = s_recentWinner.call{value: prize}("");
        if (winnerTxSuccess) {
            fee = address(this).balance;
            (bool safeTxSuccess, ) = s_raffleParams.safeAddress.call{value: fee}("");
            if (safeTxSuccess) {
                if (s_raffleParams.autoStart) {
                    s_raffleState = RaffleState.OPEN;
                } else {
                    s_raffleState = RaffleState.MAINTENANCE;
                }
            } else {
                s_raffleState = RaffleState.MAINTENANCE;
            }
        } else {
            s_raffleState = RaffleState.MAINTENANCE;
        }
        emit WinnerPicked(s_recentWinner, indexOfWinner, prize, fee, s_raffleState);
    }

    /** Getter Functions */
    function getOwner() public view returns (address) {
        return s_owner;
    }

    function getRaffleParams() public view returns (RaffleParams memory) {
        return s_raffleParams;
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

    function getRaffleResult() public view returns (RaffleResult memory) {
        return s_results[s_raffleId - 1];
    }
    function getRaffleResultsByRaffleId(uint32 raffleId) public view returns (RaffleResult memory) {
        return s_results[raffleId];
    }

    function getNumberOfTickets() public view returns (uint256) {
        return s_tickets[s_raffleId].length;
    }
    function getNumberOfTickets(uint32 raffleId) public view returns (uint256) {
        return s_tickets[raffleId].length;
    }


    function getNumberOfPlayerTickets(address playerAddress) public view returns(uint32) {
        return s_nTickets[s_raffleId][playerAddress];
    }
    function getNumberOfPlayerTicketsByRaffleId(address playerAddress, uint32 raffleId) public view returns(uint32) {
        return s_nTickets[raffleId][playerAddress];
    }

    function getPlayerByTicketId(uint256 ticketIndex) public view returns (address) {
        return s_tickets[s_raffleId][ticketIndex];
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

    function getNumberOfCampaigns(uint32 raffleId) public view returns (uint8) {
        return uint8(s_campaigns[raffleId].length);
    }

    function getCampaignHashes(uint32 raffleId) public view returns (bytes32[] memory result) {
        result = new bytes32[](s_campaigns[raffleId].length);
        for (uint i=0; i < s_campaigns[raffleId].length; i++) {
            result[i] = s_campaigns[raffleId][i].keyHash;
        }
    }

    function getCampaign(uint32 raffleId, bytes32 keyHash) public view returns (Campaign memory) {
        if (s_campaigns[raffleId].length > 0) {
            for (uint i=0; i < s_campaigns[raffleId].length; i++) {
                if (s_campaigns[raffleId][i].keyHash == keyHash) {
                    return s_campaigns[raffleId][i];
                }
            }
        }
        revert Raffle__CampaignNotFound();
    }

    /** Setter Functions **/
    function setTargetBalance() private {
        if (s_raffleParams.bank % s_raffleParams.entranceFee > 0) {
            s_targetBalance = (s_raffleParams.bank / s_raffleParams.entranceFee + 1) * s_raffleParams.entranceFee;
        } else {
            s_targetBalance = s_raffleParams.bank;
        }
    }

    function setSubscriptionId(uint32 subscriptionId) public onlyOwner {
        s_chainLinkParams.subscriptionId = subscriptionId;
    }

    function setCallbackGasLimit(uint32 gasLimit) public onlyOwner {
        s_chainLinkParams.callbackGasLimit = gasLimit;
    }

    function setRaffleParams(RaffleParams memory raffleParams) public onlyOwner atMaintenance {
        s_raffleParams = raffleParams;
        setTargetBalance();
    }

    function setCampaign(uint32 raffleId, Campaign memory campaign) public onlyOwner {
        campaign.keyHash = keccak256(abi.encodePacked(campaign.key));
        s_campaigns[raffleId].push(campaign);
    }

    function deleteCampaign(uint32 raffleId, bytes32 keyHash) public onlyOwner returns(bool) {
        if (s_campaigns[raffleId].length > 0) {
            for (uint i=0; i < s_campaigns[raffleId].length; i++) {
                if (s_campaigns[raffleId][i].keyHash == keyHash) {
                    delete s_campaigns[raffleId][i];
                    return true;
                }
            }
            return false;
        } else {
            return false;
        }
    }

    function setRaffleMaintenance() public onlyOwner {
        emit ChangeState(s_raffleState);
        s_raffleState = RaffleState.MAINTENANCE;
    }

    function setRaffleOpen() public onlyOwner atMaintenance {
        s_raffleState = RaffleState.OPEN;
        emit ChangeState(s_raffleState);
    }

    receive() external payable atMaintenance {
        // Unplanned Lottery Funding. For development mode. TODO remove for PROD
    }

    function raffleWithdraw() public onlyOwner atMaintenance {
        // Emergency Lottery withdraw. For development mode. TODO remove for PROD
        (bool safeTxSuccess, ) = s_raffleParams.safeAddress.call{value: address(this).balance}("");
        if (!safeTxSuccess) {
            revert Raffle__TransferToSafeFailed();
        }
    }

    function setRaffleInitData(RaffleResult memory result) public onlyOwner atMaintenance {
        s_results[0] = result;
    }

    function rawFulfillRandomWinner(uint32 indexOfWinner) public onlyOwner atMaintenance {
        // Emergency Draw Lottery. For development mode. TODO remove for PROD
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(indexOfWinner);
        fulfillRandomWords(0, randomWords);
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
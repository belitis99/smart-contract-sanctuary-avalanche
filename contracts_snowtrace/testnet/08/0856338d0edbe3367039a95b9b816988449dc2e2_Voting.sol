/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-15
*/

/*
----------------------------------------------------------------------------------------------------
Tomorrow Tree Project Voting - Test 3
----------------------------------------------------------------------------------------------------
*/

// File: Remix4/ITreasury.sol


pragma solidity ^0.8.0;

abstract contract TomorrowTreeTreasury {

    function rewardVoter(address voter) external virtual;

}
// File: Remix4/ITTTT2.sol


pragma solidity ^0.8.0;

abstract contract TomorrowTreeTestToken2 {

    function mint(address to, uint256 amount) public virtual;

    function balanceOf(address account) external view virtual returns (uint256);

    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function burnFrom(address account, uint256 amount) public virtual;

}
// File: Remix4/voting.sol



/*
----------------------------------------------------------------------------------------------------
Tomorrow Tree Project Voting - Test 3
----------------------------------------------------------------------------------------------------
*/

pragma solidity ^0.8.0;



contract Voting {


    /*---------------------------------------------------------------------------------------
    State variables, constructor, modifiers, events
    ---------------------------------------------------------------------------------------*/


    address TomorrowTree; // Owner and admin
    address payable TomorrowTreeDestroy; //for destroying the Test Token contract
    address TestTokenContractAddress; // Address of the Tomorrow Tree Test Token Smart Contract
    address TreasuryContractAddress; // Address of Tomorrow Tree's Treasury Smart Contract

    modifier onlyOwner(){
        require(msg.sender == TomorrowTree, "Only Tomorrow Tree can call this function");
        _;
    }

    modifier isVoterModifier(address voterAddress) {
        require(isVoter(voterAddress),"This address is a voter:)");
        _;
    }

// Maybe we add a function that sets the length of timer ?
    modifier timer(uint startTime){
        require(block.timestamp < startTime + 1 weeks, "Time is up.");
        _;
    }

    event OwnershipTransferred(address indexed _oldOwner, address indexed _newOwner);
    event voterRegistered(uint64 indexed voterId, address voterAddress);
    event voterSuspended(uint64 indexed voterId);
    event voterRestored(uint64 indexed voterId);
    event voterDeleted(uint64 indexed voterId);
    event newProposalProposed(string indexed projectName, uint proposalStartTime, uint indexed proposalId);
    event projectNameUpdated(uint indexed proposalId, string projectName);
    event proposalVotingEnded(bool indexed proposalPassed, uint128 proposalYesVote, uint128 proposalTotalVote);
    event voterVoted(uint64 indexed voterId, uint indexed proposalId, bool choice);
    event voterRewarded(uint indexed voterId, address voterAddress);
    
    constructor() {
        TomorrowTree = msg.sender;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        address _oldOwner = TomorrowTree;
        TomorrowTree = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    function setTestTokenContractAddress(address _TestTokenContractAddress) onlyOwner external {
        TestTokenContractAddress = _TestTokenContractAddress;
    }

    function setTreasuryContractAddress(address _TreasuryContractAddress) onlyOwner external {
        TreasuryContractAddress = _TreasuryContractAddress;
    }

    function setDestroyAddress(address payable _DestroyAddress) onlyOwner external {
        TomorrowTreeDestroy = _DestroyAddress;
    }


    /*---------------------------------------------------------------------------------------
    Voter
    ---------------------------------------------------------------------------------------*/


    struct Voter {
        uint64 voterID;
        uint64 totalVoterVotes;
        uint64 totalTTTEarned;
        bool isVoter;
    }

    mapping(address => Voter) public voterRegister;
    address[] public voterList;

    function isVoter(address voterAddress) public view returns(bool isVoterIndeed) {
        if(voterList.length == 0){
            return false;
        }
        return (voterList[voterRegister[voterAddress].voterID] == voterAddress);
        //what about if voter is suspended ?
    }

    function getNumberOfVoters() public view returns(uint numberOfVoters) {
        return voterList.length;
    }    

    function registerVoter(address voterAddress) public onlyOwner returns(bool success) {
        if(isVoter(voterAddress)) revert(); 
        voterRegister[voterAddress].isVoter = true;
        voterList.push(voterAddress);
        voterRegister[voterAddress].voterID = uint64(voterList.length - 1);

        emit voterRegistered(uint64(voterList.length - 1), voterAddress);

        return true; 
    }

    function suspendVoter(address voterAddress) public isVoterModifier(voterAddress) onlyOwner returns(bool success) {
        voterRegister[voterAddress].isVoter = false;

        emit voterSuspended(voterRegister[voterAddress].voterID);

        return true;
    }

    function restoreVoter(address voterAddress) public onlyOwner returns(bool success) {
        voterRegister[voterAddress].isVoter = true;

        emit voterRestored(voterRegister[voterAddress].voterID);

        return true;
    }

    function deleteVoter(address voterAddress) public onlyOwner returns(bool success) {
        voterRegister[voterAddress].isVoter = false;
        uint voterToDelete = voterRegister[voterAddress].voterID;
        address voterToMove   = voterList[voterList.length-1];
        voterList[voterToDelete] = voterToMove;
        voterRegister[voterToMove].voterID = uint64 (voterToDelete);
        voterList.pop();
        delete voterRegister[voterAddress];

        emit voterDeleted(voterRegister[voterAddress].voterID);

        return true;
    }

    function getVoterData(address voterAddress) public view returns(uint64, uint64,uint64, bool) {
        return(voterRegister[voterAddress].voterID, voterRegister[voterAddress].totalVoterVotes,voterRegister[voterAddress].totalTTTEarned, voterRegister[voterAddress].isVoter);
    }


    /*---------------------------------------------------------------------------------------
    Project Proposals
    ---------------------------------------------------------------------------------------*/


    struct ProjectProposal {
        string projectName;
        uint128 proposalYesVote;
        uint128 proposalTotalVote;
        uint proposalStartTime;
        uint tokensToBeMinted;
        address creatorAddress; // address that submitted the project 
        bool votingEnded;
        bool proposalPassed;// passes if more than 50% of the votes were YES
    }

    ProjectProposal[] public proposalList;

    function getNumberOfProposals() public view returns(uint numberOfProposals) {
        return proposalList.length;
    }

//Only the frontend should be able to call this function; we will register project submitters beforehand
//To keep things simple and concise during initial testing, we are leaving the function open
    function newProposal(string memory _projectName, uint _tokensToBeMinted) public returns(uint) {
        ProjectProposal memory p;
        p.projectName = _projectName;
        p.creatorAddress = msg.sender;
        p.tokensToBeMinted = _tokensToBeMinted;
        p.proposalStartTime = block.timestamp;
        proposalList.push(p);

        emit newProposalProposed(_projectName, block.timestamp, proposalList.length );

        return proposalList.length;
    }

    function updateProjectName(uint _proposalId, string memory _proposalName) external onlyOwner returns(bool success) {
        if((proposalList.length-1) > _proposalId) revert();
        proposalList[_proposalId].projectName = _proposalName;

        emit projectNameUpdated(_proposalId, _proposalName);

        return true;
    }

    function getProposalData(uint _proposalId) public view returns(string memory, uint128, uint128,uint, bool, bool) {
        return(proposalList[_proposalId].projectName, proposalList[_proposalId].proposalYesVote, proposalList[_proposalId].proposalTotalVote,proposalList[_proposalId].proposalStartTime, proposalList[_proposalId].votingEnded, proposalList[_proposalId].proposalPassed);
    }


    /*---------------------------------------------------------------------------------------
    Voting
    ---------------------------------------------------------------------------------------*/


    struct Vote {
        bool didVote;
        bool choice; 
    }

    mapping(address => mapping(uint => Vote)) public didVoterVote; 
    mapping(uint => address[]) public proposalVoters;

    function voteOnProposal(uint _proposalId, bool _vote) public timer(proposalList[_proposalId].proposalStartTime){
        //next three lines could be modifiers!
        require(isVoter(msg.sender) == true, "Only registered voters can vote!");
        require(didVoterVote[msg.sender][_proposalId].didVote == false); //only one vote per voter
        require(proposalList[_proposalId].votingEnded == false);

        proposalVoters[_proposalId].push(msg.sender); // adds the address to proposalVoters mapping
        voterRegister[msg.sender].totalVoterVotes++;
        proposalList[_proposalId].proposalTotalVote++; 
        didVoterVote[msg.sender][_proposalId].choice = _vote; // saves what the voter voted
        if(_vote == true) {
            proposalList[_proposalId].proposalYesVote++;
        }
        didVoterVote[msg.sender][_proposalId].didVote = true;
        // Rewarding voters from treasury contract:
        TomorrowTreeTreasury treasury = TomorrowTreeTreasury(TreasuryContractAddress);
        treasury.rewardVoter(msg.sender);

        emit voterVoted(voterRegister[msg.sender].voterID, _proposalId, _vote);

    }

    //If timer remove onlyOwner, but make it internal or private
    function endVote(uint _proposalId) public  onlyOwner {
        require(proposalList[_proposalId].votingEnded == false);
        //require(timing mechanism)
        // https://docs.chain.link/docs/chainlink-keepers/introduction/
        proposalList[_proposalId].votingEnded = true;

        proposalList[_proposalId].proposalPassed = calculateVote(proposalList[_proposalId].proposalYesVote, proposalList[_proposalId].proposalTotalVote);
        
        if(proposalList[_proposalId].proposalPassed == true){
            mintTokens(proposalList[_proposalId].creatorAddress,proposalList[_proposalId].tokensToBeMinted);
        }
        
        emit proposalVotingEnded(proposalList[_proposalId].proposalPassed, proposalList[_proposalId].proposalYesVote, proposalList[_proposalId].proposalTotalVote);

    }

    function calculateVote(uint _votesYes, uint _totalVotes) internal pure returns(bool) {
        return (_votesYes*10 / _totalVotes >= 5);
    }

    function mintTokens(address _creatorAddress, uint _tokensToBeMinted) private { //onlyContract mod
        TomorrowTreeTestToken2 token = TomorrowTreeTestToken2(TestTokenContractAddress);
        //contract should mint an adjustable percentage to the Treasury
        //Make a variable that calculates the percent of tokens that should be minted to treasury
        //the variable should be changeable 
        // read: https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
        token.mint(_creatorAddress, _tokensToBeMinted);
        //moznost 2x call mint function; prvic: tokensToBeMinted - procent, drugic mint: procentOfTokensToBeMinted
    }


/*---------------------------------------------------------------------------------------
    Destroy Contract
---------------------------------------------------------------------------------------*/


    //must transfer ownership to TomorrowTreeDestroy before evoking
    function destroyContract() public onlyOwner { 
    selfdestruct(TomorrowTreeDestroy);
    }

}
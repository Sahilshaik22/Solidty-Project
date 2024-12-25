// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract VotingSmartContract {
    struct voter {
        string name;
        uint256 age;
        uint256 voterId;
        Gender gender;
        address voterAddress;
        uint256 voteCandidateId;
    }
    struct candidate {
        string name;
        string party;
        uint256 age;
        uint256 candidateId;
        Gender gender;
        address candidateAddress;
        uint256 votes;
    }

   using SafeERC20 for IERC20;


    IERC20 public Bees;

    address public electionCommissoner;
    address public winner;

    uint256 nextVoterId = 1;
    uint256 nextCandidateId = 1;
    uint startTime;
    uint endTime;
    bool stopVoting;

    constructor(address _beesToken) {
        electionCommissoner = msg.sender;
        Bees = IERC20(_beesToken);
    }
    modifier onlyElectionCommissioner() {
        require(electionCommissoner== msg.sender ,"You are not electionCommissioner");
        _;
    }

    enum Gender {
        NotSpecified,
        Male,
        Female,
        Other
    }

    enum VotingStatus {
        NotStarted,
        InProgress,
        Ended
    }

    modifier validAge(uint256 _age) {
        require(_age >= 18, "You're age is under 18");
        _;
    }

    mapping(uint256 => candidate) public candidateDetails;
    mapping(uint256 => voter) public voterDetails;

    // only 5 people can register as a candidate 

    function registerCandidate(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        Gender _gender
    ) external validAge(_age) {
        require(nextCandidateId<=5,"Candidates are registeration is Filled");
        require(
            isCandidateAlreadyRegistred(msg.sender),
            "Candidate Already Registered"
        );
        require(
            electionCommissoner != msg.sender,
            "Election Commission is not allowed to resiter "
        );
        candidateDetails[nextCandidateId] = candidate({
            name: _name,
            party: _party,
            age: _age,
            gender: _gender,
            candidateAddress: msg.sender,
            candidateId: nextCandidateId,
            votes: 0
        });
        nextCandidateId++;
    }

    function isCandidateAlreadyRegistred(address _candidateAddress)
        private
        view
        returns (bool)
    {
        for (uint256 i = 1; i <= nextCandidateId; i++) {
            if (candidateDetails[i].candidateAddress == _candidateAddress) {
                return false;
            }
        }
        return true;
    }

    function getCandiateList() external view returns (candidate[] memory) {
        candidate[] memory candidateList = new candidate[](nextCandidateId);

        for (uint256 i = 0; i < candidateList.length; i++) {
            candidateList[i] = candidateDetails[i+1];
        }
        return candidateList;
    }

    function registerVoter(
        string calldata _name,
        uint256 _age,
        Gender _gender
    ) external  validAge(_age) {
        require(
            isVoterAlreadyRegistered(msg.sender),
            "Voter Already Registered"
        );
        require(
            electionCommissoner != msg.sender,
            "Election Commission is not allowed to resiter "
        );
        voterDetails[nextVoterId] = voter({name:_name
        ,voterId : nextVoterId
        , age:_age, gender:_gender
        , voterAddress:msg.sender
        ,voteCandidateId:0 }); 
        nextVoterId++;
    }


function isVoterAlreadyRegistered(address _voter) private view returns (bool) {
    for (uint256 i = 1; i <= nextVoterId; i++) {
        if (voterDetails[i].voterAddress == _voter) {
            return false;
        }
    }
    return true;
}

function getVoterList() external view returns (voter[] memory) {

    voter[] memory voterList = new voter[](nextVoterId);
    for (uint256 i = 0; i < voterList.length; i++) {
        voterList[i] = voterDetails[i+1];
    }
    return voterList;
}

function castVote(uint _voterId, uint _candidateId) external {
    require(Bees.balanceOf(msg.sender)>=1e18,"Balance is Lower than 1 Token");
    require(stopVoting!=true,"Voting is stoped for emergency");
    require(_candidateId>=1 && _candidateId<=5,"Candidate Id is Invalid");
    require(voterDetails[_voterId].voteCandidateId==0,"You already voted");
    require(voterDetails[_voterId].voterAddress==msg.sender,"You are Not authorized");
    voterDetails[_voterId].voteCandidateId = _candidateId;
    candidateDetails[_candidateId].votes++;
}

function setVotingPeriod(uint _startTimeDuration, uint _endTimeDuration) public onlyElectionCommissioner{

    require(_endTimeDuration>3600,"_endTimeDuration must be greater than 1 hour");
    startTime = block.timestamp+_startTimeDuration;
    endTime = startTime+ _endTimeDuration;


}


function emergencyStopVoting() public  onlyElectionCommissioner(){
    stopVoting =true;
}

function getVotingStatus() external view returns(VotingStatus){
    if(startTime==0){
        return VotingStatus.NotStarted;
    }
    else if(endTime>block.timestamp && stopVoting==false){
        return VotingStatus.InProgress;
    }
    else{
        return VotingStatus.Ended;
    }
}
 
function resetTimings() external onlyElectionCommissioner returns(string memory){
    startTime = 0;
    endTime = 0;
    console.log("timings are restarted ");
    return "Timings are restarted";
    
}

function announceResultOfCandidates() external  onlyElectionCommissioner returns(address){
    uint max=0;
    for(uint i=1; i<=nextCandidateId; i++){
        if(candidateDetails[i].votes>max){
            max = candidateDetails[i].votes;
            winner = candidateDetails[i].candidateAddress;
        }

    }
    console.log("Winnwer is ", winner);
    return winner;

}



}
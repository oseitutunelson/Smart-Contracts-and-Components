// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Decentralized Voting Smart Contract
 * @author sexyprogrammer
 * @notice A smart contract that handles voting on the blockchain powered by chainlink
 */

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Voting is AutomationCompatibleInterface{
    /**
     * @notice Events
     */
    event Voted(uint indexed id);
    event CandidateCreated(uint indexed candidateNo, string indexed candidateName);
    event OwnerChange(address indexed oldOwner, address indexed newOwner);
    event VotingStarted(uint endTime);
    event VotingEnded(string winnerName, uint winnerVotes);
    
    /** 
     * @notice State Variables
     */
    address private owner;
    uint private votingEndTime;
    bool private votingStarted;
    bool private votingEnded;
    string public winner;
    uint private candidateCount; // Track number of candidates
   

     // Candidate structure
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

     mapping(uint256 => Candidate) public candidateLookUp;
     mapping(address => bool) public voterLookUp;
    /**
     * @notice Modifiers
     */
    // Only owner can execute
    modifier onlyOwner(){
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Only when voting is active
    modifier onlyWhileVoting(){
        require(votingStarted, "Voting has not started yet");
        require(block.timestamp < votingEndTime, "Voting period has ended");
        _;
    }

    // Only when voting has ended
    modifier onlyAfterVoting(){
        require(votingEnded, "Voting has not ended yet");
        _;
    }
     
     /**
      * @notice Functions
      */

    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Change owner of contract
     * @param newOwner new owner
     */
    
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerChange(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Add candidate (onlyOwner)
     */
    
    function addCandidate(string memory name) public onlyOwner {
        candidateLookUp[candidateCount] = Candidate(candidateCount, name, 0);
        candidateCount++;
        emit CandidateCreated(candidateCount, name);
    }

    /**
     * @dev Get a single candidate
     */
    
    function getCandidate(uint id) external view returns (string memory name, uint noOfVotes) {
        name = candidateLookUp[id].name;
        noOfVotes = candidateLookUp[id].voteCount;
        return (name, noOfVotes);
    }
    
    /**
     * 
     * @return names of candidates
     * @return noOfVotes of candidates
     */
    // Get all candidates
    function getCandidates() external view returns (string[] memory, uint[] memory) {
        string[] memory names = new string[](candidateCount);
        uint[] memory noOfVotes = new uint[](candidateCount);

        for(uint i = 0; i < candidateCount; i++){
            names[i] = candidateLookUp[i].name;
            noOfVotes[i] = candidateLookUp[i].voteCount;
        }

        return (names, noOfVotes);
    }

    /**
     * @dev Start voting process with end time
     */
   
    function startVoting(uint durationInSeconds) external onlyOwner {
        require(!votingStarted, "Voting has already started");
        votingEndTime = block.timestamp + durationInSeconds;
        votingStarted = true;
        votingEnded = false;
        emit VotingStarted(votingEndTime);
    }
    
    /**
     * @dev Vote for a candidate (requires voting to be active)
     */
    
    function vote(uint id) external onlyWhileVoting {
        require(!voterLookUp[msg.sender], "Address has already voted");
        require(id >= 0 && id < candidateCount, "Invalid candidate ID");
        
        voterLookUp[msg.sender] = true;
        candidateLookUp[id].voteCount++;
        emit Voted(id);
    }

    
    /**
     * @dev manually declare winner
     * @return winnerName 
     * @return winnerVotes 
     */
    
    function declareWinner() external onlyAfterVoting returns (string memory winnerName, uint winnerVotes) {
        require(candidateCount > 0, "No candidate available");

        winnerName = candidateLookUp[0].name;
        winnerVotes = candidateLookUp[0].voteCount;

        for(uint i = 1; i < candidateCount; i++){
            if(candidateLookUp[i].voteCount > winnerVotes){
                winnerName = candidateLookUp[i].name;
                winnerVotes = candidateLookUp[i].voteCount;
            }
        }
        winner = winnerName;
        return (winnerName, winnerVotes);
    }
    
    /**
     * @dev  End voting manually
     */

    function endVoting() external onlyOwner {
        require(votingStarted, "Voting has not started");
        require(block.timestamp >= votingEndTime, "Voting period is not over yet");

        votingStarted = false;
        votingEnded = true;

        //(string memory winnerName, uint winnerVotes) = declareWinner();
       // emit VotingEnded(winnerName, winnerVotes);
    }

    /**
     * @dev chainlink automation to declare winner after voting time elapses
     */

    function checkUpkeep(bytes memory /* checkData */)public
        view override
        returns (bool upkeepNeeded, bytes memory /* performData */){ 
           bool hasVotingEnded = block.timestamp >= votingEndTime;
           upkeepNeeded = hasVotingEnded;
           return (upkeepNeeded,"0x0");
        }

     function performUpkeep(bytes calldata /* performData */) external  override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if(!upkeepNeeded){
            revert();
        }
         require(candidateCount > 0, "No candidate available");

        string memory winnerName = candidateLookUp[0].name;
        uint winnerVotes = candidateLookUp[0].voteCount;

        for(uint i = 1; i < candidateCount; i++){
            if(candidateLookUp[i].voteCount > winnerVotes){
                winnerName = candidateLookUp[i].name;
                winnerVotes = candidateLookUp[i].voteCount;
            }
        }
        winner = winnerName;
        //return (winnerName, winnerVotes);
     }  

    /**
     * @dev Getter functions
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function getCandidateCount() external view returns (uint) {
        return candidateCount;
    }

    function isVotingActive() external view returns (bool) {
        return votingStarted && block.timestamp < votingEndTime;
    }

    function getVotingEndTime() external view returns (uint) {
        return votingEndTime;
    }
}

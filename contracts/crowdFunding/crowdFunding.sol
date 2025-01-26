// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Crowd Funding Contract
 * @author sexyprogrammer
 * @notice simple crowding funding contract utilizing chainlink functions
 */

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConvertor} from "../chainlink/priceConvertor.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";


contract Fund is AutomationCompatibleInterface{
   using PriceConvertor for uint256;


   /**
   * @notice Events
   */ 
   event CampaignCreated(string name,string description,uint256 indexed goal,uint256 indexed deadline);

   /**
   * @notice state variables
   */

   address public owner; 
   address [] public campaignCount;
   address [] public funders;
   mapping (address => Campaign) public campaigns;
   AggregatorV3Interface private s_priceFeed;

   //minimum amount to send
   uint256 public constant MINIMUM_USD = 5e18;


   //campaign structure
   struct Campaign{
    string name;
    string description;
    uint256 fundingGoal;
    uint256 balance;
    uint deadline;
    bool fundingSuccessful;
    bool campaignExist;
    uint lastTimeStamp;
   }

   /**
   * @notice Functions
   */
   constructor(address priceFeed){
    owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeed);
   }

   /**
    * @dev create campaign
    */

   function createCampaign(string memory name,string memory description,uint256 goal,uint deadline) 
   public{
       campaigns[msg.sender] = Campaign({ 
          name : name,
          description : description,
          fundingGoal : goal,
          deadline : deadline,
          balance : 0,
          fundingSuccessful : false,
          campaignExist : true,
          lastTimeStamp : block.timestamp
       });
       campaignCount.push(msg.sender);
       emit CampaignCreated(name, description, goal, deadline);
   }
  
   //fund a campaign
   function fundCampaign(address creator) payable public{
      require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,"Amount must not be less than MINIMUM_USD");
      require(campaigns[creator].campaignExist == true,"campaign must exist");
      funders.push(msg.sender);
      campaigns[creator].balance += msg.value;
   }

   //withdraw from campaign
   function withdrawFromCampaign() public{
      require(campaigns[msg.sender].campaignExist,"campaign must exist");
      require(campaigns[msg.sender].fundingSuccessful == true,"funding must be successful");

       uint256 funderLength = funders.length;
      for(uint funderIndex = 0;funderIndex < funderLength;funderIndex++){
         address funder = funders[funderIndex];
         campaigns[funder].balance = 0;
         campaigns[funder].campaignExist = false;
      }
     
     funders = new address[](0);

     (bool callSuccess,) = payable(msg.sender).call{value: campaigns[msg.sender].balance}("");
     require(callSuccess,"Call failed");

   }

  /**
  * @notice send ether internal function
  */

   function sendEther(address payable _to,uint256 amount) internal {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent,) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
   
 /**
  * @notice Chainlink automation for checking funding success
  */
   function checkUpkeep(bytes memory  checkData ) public view override returns (bool upkeepNeeded, bytes memory performData ){
     /**
   * @notice Checkupkeep for when funding is successful
   */
   if(keccak256(checkData) == keccak256(hex'01')){
       uint256 campaignLength = campaignCount.length;
      for(uint256 campaignIndex = 0;campaignIndex < campaignLength;campaignIndex++){
        address campaign = campaignCount[campaignIndex];
        uint256 balance = campaigns[campaign].balance;

        upkeepNeeded = balance >= campaigns[campaign].fundingGoal;
        performData = checkData;
      }
     }
     /**
     * @notice This marks campaignExist as false as it returns money to users if deadline is reached and funding goal is not
     */
     if(keccak256(checkData) == keccak256(hex'02')){
      uint256 campaignLength = campaignCount.length;
      for(uint256 campaignIndex = 0;campaignIndex < campaignLength;campaignIndex++){
        address campaign = campaignCount[campaignIndex];
        uint256 balance = campaigns[campaign].balance;
        uint deadline = campaigns[campaign].deadline;
        uint deadlineInDays = deadline * 1 days;

        upkeepNeeded = (block.timestamp - campaigns[campaign].lastTimeStamp) > deadlineInDays && balance <= campaigns[campaign].fundingGoal;
        performData = checkData;
        
      }
     }
      //return (upkeepNeeded,'0x0');
   }

   function performUpkeep(bytes calldata  performData )external override {
   //   (bool upkeepNeeded,) = checkUpkeep('');
   //   if(!upkeepNeeded){
   //      revert();
   //   }
   /**
   * @notice performUpkeep for when funding is successful
   */
     if(keccak256(performData) == keccak256(hex'01')){
        uint256 campaignLength = campaignCount.length;
     for(uint256 campaignIndex = 0;campaignIndex < campaignLength;campaignIndex++){
        address campaign = campaignCount[campaignIndex];
        campaigns[campaign].fundingSuccessful = true;

     }
     }

     /**
     * @notice performUpkeep for when campaignExist as false as it returns money to users if deadline is reached and funding goal is not
     */

     if(keccak256(performData) == keccak256(hex'02')){
        uint256 campaignLength = campaignCount.length;
     for(uint256 campaignIndex = 0;campaignIndex < campaignLength;campaignIndex++){
         address campaign = campaignCount[campaignIndex];
          uint256 balance = campaigns[campaign].balance;
          for (uint i = 0; i < funders.length; i++) 
          {
            address funder = funders[i];
            sendEther(payable (funder), balance);
            campaigns[campaign].campaignExist = false;
          }
      }
     }

    
   } 

   /**
    * @notice Getter Functions
    */

   //get the number of all campaigns
    function getAllCampaigns() public view returns (uint256){
      return campaignCount.length;
    }

   //get campaign
   function getCampaignName(address creator) public view returns (string memory) {
      return campaigns[creator].name;
   } 

   //get campaign balance
   function getCampaignBalance(address creator) public view returns (uint256){
      return campaigns[creator].balance;
   }

}
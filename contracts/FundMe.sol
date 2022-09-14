//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
// Objectives: 
// Get Funds from users
// Set a minimum funding Value in USD

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    // constant for gaz optimisations
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }   

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough, minimum 50 USD");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // delete funders;
        
        // Transfer, send, call 3 --> different ways to send native token
        //transfer - not recommended
            // payable(msg.sender).transfer(address(this).balance);
        // Send not recommended
            // bool sendSuccess = payable(msg.sender).send(address(this).balance);
            // require(sendSuccess, "Send failed");

        // call RECOMMENDED
        (bool callSuccess, ) = payable(msg.sender).call{value : address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not owner");
        if(msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // Special functions retrieve() and fallback()
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
 
}
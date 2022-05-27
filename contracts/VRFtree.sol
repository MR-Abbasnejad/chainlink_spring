// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract BuyMeaCandy is ERC1155, Ownable, VRFConsumerBase{

    bytes32 internal keyHash; // identifies which Chainlink oracle to use
    uint internal fee;        // fee to get random number
    uint public randomResult;


//Donation part
    address payable user;
    address payable[] charityAddresses;
    uint256 totalDonationsAmount;
    uint256 highestDonation;
    address payable highestDonor;

// reminden for nft img
   // uint Bamboo = 1;
   // uint Maple = 2;
   // uint Oak = 3;
   // uint Pine = 4;
    constructor(address payable[] memory addresses_) 
        ERC1155("ipfs://QmQh485k1sYSpkfwSUn1pk13cyAbsUPdsFcaTnwg5kCnNE/{randomResult}.json")
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK token address
        ) {
            keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee = 0.1 * 10 ** 18;    // 0.1 LINK

             user = msg.sender;
             charityAddresses = addresses_;
             totalDonationsAmount = 0;
             highestDonation = 0;
        }

     /// Restricts the access only to the user who deployed the contract.
    modifier restrictToOwner() {
        require(msg.sender == user, 'Method available only to the to the user that deployed the contract');
        _;
    }

    /// Validates that the sender originated the transfer is different than the target destination.
    modifier validateDestination(address payable destinationAddress) {
        require(msg.sender != destinationAddress, 'Sender and recipient cannot be the same.');
        _;
    }

    //// Validates that the charity index number provided is a valid one.
    ///
    /// @param charityIndex The target charity index to validate. Indexes start from 0 and increment by 1.
    modifier validateCharity(uint256 charityIndex) {
        require(charityIndex <= charityAddresses.length - 1, 'Invalid charity index.');
        _;
    }

    /// Validates that the amount to transfer is not zero.
    modifier validateTransferAmount() {
        require(msg.value > 0, 'Transfer amount has to be greater than 0.');
        _;
    }

    /// Validates that the donated amount is within acceptable limits.
    ///
    /// @param donationAmount The target donation amount.
    /// @dev donated amount >= 1% of the total transferred amount and <= 50% of the total transferred amount.
    modifier validateDonationAmount(uint256 donationAmount) {
        require(donationAmount >= msg.value / 100 && donationAmount <= msg.value / 2,
            'Donation amount has to be from 1% to 50% of the total transferred amount');
        _;
    }

    /// Transmits the address of the donor and the amount donated.
    event Donation(
        address indexed _donor,
        uint256 _value
    );

    

    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint randomness)  internal override {
        randomResult = (randomness % 4) + 1;
        
    }


//there would be 5 trees to be minted at this time right now

    
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }




     /// Redirects 10% of the total transferred funds to the target charity and transfers the rest to the target address.
    /// Whenever a transfer of funds is complete, it emits the event `Donation`.
    ///
    /// @param destinationAddress The target address to send fund to.
    /// @param charityIndex The target index of the charity to send the 10% of the funds.
    function deposit(address payable destinationAddress, uint256 charityIndex) public validateDestination(destinationAddress)
    validateTransferAmount() validateCharity(charityIndex) payable {
        uint256 donationAmount = msg.value / 10;
        uint256 actualDeposit = msg.value - donationAmount;

        charityAddresses[charityIndex].transfer(donationAmount);
        destinationAddress.transfer(actualDeposit);

        emit Donation(msg.sender, donationAmount);

        totalDonationsAmount += donationAmount;

        if (donationAmount > highestDonation) {
            highestDonation = donationAmount;
            highestDonor = msg.sender;
        }
    }

    /// Redirects the specified amount to the target charity and transfers the rest to the target address.
    /// Whenever a transfer of funds is complete, it emits the event `Donation`.
    ///
    /// @param destinationAddress The target address to send fund to.
    /// @param charityIndex The target index of the charity to send the specified amount.
    /// @param donationAmount The amount to send to the target charity.
    function deposit(address payable destinationAddress, uint256 charityIndex, uint256 donationAmount) public
    validateDestination(destinationAddress) validateTransferAmount() validateCharity(charityIndex)
    validateDonationAmount(donationAmount) payable {
        uint256 actualDeposit = msg.value - donationAmount;

        charityAddresses[charityIndex].transfer(donationAmount);
        destinationAddress.transfer(actualDeposit);

        emit Donation(msg.sender, donationAmount);

        totalDonationsAmount += donationAmount;

        if (donationAmount > highestDonation) {
            highestDonation = donationAmount;
            highestDonor = msg.sender;
        }
    }

    /// Returns all the available charity addresses.
    /// @return charityAddresses
    function getAddresses() public view returns (address payable[] memory) {
        return charityAddresses;
    }

    /// Returns the total amount raised by all donations (in wei) towards any charity.
    /// @return totalDonationsAmount
    function getTotalDonationsAmount() public view returns (uint256) {
        return totalDonationsAmount;
    }

    /// Returns the address that made the highest donation, along with the amount donated.
    /// @return (highestDonation, highestDonor)
    function getHighestDonation() public view restrictToOwner() returns (uint256, address payable)  {
        return (highestDonation, highestDonor);
    }

    // Destroys the contract and renders it unusable.
    function destroy() public restrictToOwner() {
        selfdestruct(user);
    }

}
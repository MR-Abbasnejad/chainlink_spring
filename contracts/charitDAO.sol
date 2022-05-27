
// SPDX-License-Identifier: MIT

pragma solidity '0.8.14';

contract DAO {

    address DAOAddress = address(this);

    uint public memberBuyin;
    uint memberCount;
    mapping(address => bool) public members;

    User[] public allUsers;
    mapping(address => bool) public users;
    mapping(address => User) public metamaskAssociatedUser;

    constructor(uint buyin) {
        memberBuyin = buyin;
    }

    function createMember() public payable {
        require(!users[msg.sender]);
        require(!members[msg.sender]);
        require(msg.value == memberBuyin);
        memberCount++;
        members[msg.sender] = true;
    }

    function createUser(string memory name, string memory description, string memory locationAddress, string memory phone, string memory email) public {
        require(!members[msg.sender]);
        require(!users[msg.sender]);
        User newUser = new User(name, description, locationAddress, phone, email, msg.sender, DAOAddress);
        users[msg.sender] = true;
        allUsers.push(newUser);
        metamaskAssociatedUser[msg.sender] = newUser;
    }

    function getAllUsers() public view returns(User[] memory){
        return allUsers;
    }

    function getPoolAmount() public view returns(uint) {
        return address(this).balance;
    }

    function addToPool() public payable {
        require(msg.value > 0);
    }

    function transact(address payable recipient, uint value) public {
        recipient.transfer(value);
    }


    function isAMember(address member) public view returns(bool) {
        bool ans = members[member];
        return ans;
    }

     function isAUser(address user) public view returns(bool) {
        bool ans = users[user];
        return ans;
     }

    function getMemberCount() public view returns(uint) {
        return memberCount;
    }

}


contract User {

    string public name;
    string public description;
    address public userAddress;
    string public phone;
    string public email;
    string public locationAddress;
    uint public approveCount;
    uint public rejectCount;
    bool public isApproved;
    bool public isRejected;
    mapping(address => bool) public approvedMembers;
    mapping(address => bool) public rejectedMembers;

    address DAOAddress;


    struct Campaign {
        string title;
        string description;
        string recipientName;
        string recipientPhone;
        string recipientEmail;
        address payable recipient;
        bool transactionComplete;
        uint value;
        uint approveCount;
        uint rejectCount;
        bool isApproved;
        bool isRejected;
        mapping(address => bool) campaignApprovedMembers;
        mapping(address => bool) campaignRejectedMembers;
    }

    uint public numCampaign;
    mapping(uint => Campaign) public campaigns;

    constructor(string memory _name, string memory _description, string memory _locationAddress, string memory _phone, string memory _email, address _creator, address _DAOAddress) {
        name = _name;
        description = _description;
        phone = _phone;
        email = _email;
        userAddress = _creator;
        DAOAddress = _DAOAddress;
        locationAddress = _locationAddress;
        approveCount = 0;
        rejectCount = 0;
        isApproved = false;
        isRejected = false;
        numCampaign = 0;
    }
    
    function approveUser() public {
        DAO instance = DAO(DAOAddress);
        require(instance.isAMember(msg.sender));
        require(!approvedMembers[msg.sender]);
        require(!rejectedMembers[msg.sender]);
        require(!isApproved);
        require(!isRejected);
        approvedMembers[msg.sender] = true;
        approveCount++;

        if(approveCount > (instance.getMemberCount() / 2)){
            isApproved = true;
        }
    }

    function rejectUser() public {
        DAO instance = DAO(DAOAddress);
        require(instance.isAMember(msg.sender));
        require(!approvedMembers[msg.sender]);
        require(!rejectedMembers[msg.sender]);
        require(!isApproved);
        require(!isRejected);
        rejectedMembers[msg.sender] = true;
        rejectCount++;

        if(rejectCount > (instance.getMemberCount() / 2)){
            isRejected = true;
        }
    }
    
    function createCampaign(string memory _title, string memory _description, string memory _recipientName, string memory _recipientPhone, string memory _recipientEmail, 
    address payable _recipient, uint _value) public {
        DAO instance = DAO(DAOAddress);
        require(instance.isAUser(msg.sender));
        require(!instance.isAMember(msg.sender));
        require(isApproved && !isRejected);

        Campaign storage newCampaign = campaigns[numCampaign++];
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.recipientName = _recipientName;
        newCampaign.recipientPhone = _recipientPhone;
        newCampaign.recipientEmail = _recipientEmail;
        newCampaign.recipient = _recipient;
        newCampaign.value = _value;
        newCampaign.approveCount = 0;
        newCampaign.rejectCount = 0;
        newCampaign.isApproved = false;
        newCampaign.isRejected = false;
    }

    function approveCampaign(uint campaignIndex) public {
        DAO instance = DAO(DAOAddress);
        require(instance.isAMember(msg.sender));
        require(!instance.isAUser(msg.sender));
        require(!campaigns[campaignIndex].campaignApprovedMembers[msg.sender]);
        require(!campaigns[campaignIndex].campaignRejectedMembers[msg.sender]);
        require(!campaigns[campaignIndex].isApproved);
        require(!campaigns[campaignIndex].isRejected);

        campaigns[campaignIndex].approveCount++;
        campaigns[campaignIndex].campaignApprovedMembers[msg.sender] = true;
        
        if(campaigns[campaignIndex].approveCount > (instance.getMemberCount()/2)) {
            campaigns[campaignIndex].isApproved = true;
        }
    }

    function rejectCampaign(uint campaignIndex) public {
        DAO instance = DAO(DAOAddress);
        require(instance.isAMember(msg.sender));
        require(!instance.isAUser(msg.sender));
        require(!campaigns[campaignIndex].campaignApprovedMembers[msg.sender]);
        require(!campaigns[campaignIndex].campaignRejectedMembers[msg.sender]);
        require(!campaigns[campaignIndex].isApproved);
        require(!campaigns[campaignIndex].isRejected);

        campaigns[campaignIndex].rejectCount++;
        campaigns[campaignIndex].campaignRejectedMembers[msg.sender] = true;
        
        if(campaigns[campaignIndex].rejectCount > (instance.getMemberCount()/2)) {
            campaigns[campaignIndex].isRejected = true;
        }
    }

    function finalizeTransaction(uint campaignIndex) public {
        DAO instance = DAO(DAOAddress);
        require(instance.isAUser(msg.sender));
        require(!instance.isAMember(msg.sender));
        require(campaigns[campaignIndex].isApproved);
        Campaign storage campaign = campaigns[campaignIndex];
        instance.transact(campaign.recipient, campaign.value);
        campaign.transactionComplete = true;
    }



}
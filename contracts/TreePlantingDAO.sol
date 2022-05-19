// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

/**
 The contract that allows DAO members to raise funds for planting trees
 Simplifications: owners are sets only in the constructor.
 */
contract TreePlantingDAO {

    /**
     Issue created event
    */
    event IssueCreated(string externalId);

    /**
     Issue started and fund sent event
    */
    event IssueStarted(
        string externalId, 
        address indexed executor
    );

    /**
     Issue executed event
    */
    event IssueExecuted(string externalId);

    /**
     New ethers received
    */
    event Received(address, uint);

    /**
     Minimim confirmations count for send funds
     */
    uint public requiredConfirmationsCount;

    /**
     DAO's owners
     */
    address[] public owners;

    /**
    Issues created by DAO's owners
    @param externalId external identifier of issue
    @param executor executor's address
    @param amount funds for issue executing
    @param description description of issue
    @param isExecuted if the issue exicuted
    @param confirmators confirmators
    */
    struct ThreePlantingIssue {
        string externalId;
        uint amount;
        string description;
        address executor;
        bool isFundsSent;
        bool isExecuted;
        address[] confirmators;
    }

    /**
     Mapping from external identifier of issue to issue
     */
    mapping(string => ThreePlantingIssue) public issues;

    /**
     Modifier checks only one of owners can executes funds sending to executor
     */
    modifier onlyOwner() {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
            }
        }
        require(isOwner, "Only owner can call");
        _;
    }

    /**
     Contract's contructor
     @param _owners list of DAO's owners
     @param _requiredConfirmationsCount minimim confirmations count for send funds
     */
    constructor(address[] memory _owners, uint _requiredConfirmationsCount) {
        require(_owners.length > 0, "Owners required");
        require(
            _requiredConfirmationsCount > 0 && _requiredConfirmationsCount <= _owners.length,
            "Invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            owners.push(owner);
        }

        requiredConfirmationsCount = _requiredConfirmationsCount;
    }

    /**
     Create new issue
     */
    function createIssue(
        string memory externalId,
        uint value,
        string memory description
    ) public onlyOwner {
        uint contractBalance = address(this).balance;
        console.log("Contract balance: %s", contractBalance);
        require(contractBalance > value, "Funds sum should't more than ccontract's balance");

        ThreePlantingIssue memory issue = ThreePlantingIssue(
            externalId,
            value,
            description,
            address(0),
            false,
            false,
            new address[](requiredConfirmationsCount)
        );
        issues[externalId] = issue;
        emit IssueCreated(externalId);
    }

    /**
     Sets issue executor
     @param executor executor's addresss
     */
    function setIssueExecutor(
        string memory externalId,
        address executor
    ) public onlyOwner {
        ThreePlantingIssue storage issue = issues[externalId];
        require(issue.executor == address(0), "Issue already has executor");
        issue.executor = executor;

        emit IssueStarted(externalId, executor);
    }

    /**
     Confirm issue
     */
    function confirmIssue(
        string memory externalId
    ) public onlyOwner {
        ThreePlantingIssue storage issue = issues[externalId];
        require(issue.executor != address(0), "Issue has't executor");
        
        bool alreadySignedBySender = false;
        for (uint i = 0; i < issue.confirmators.length; i++) {
            if (msg.sender == issue.confirmators[i]) {
                alreadySignedBySender = true;
            }
        }
        require(!alreadySignedBySender, "You can confirm this issue one time");
        
        issue.confirmators.push(msg.sender);

        sendFundsIfHasRequiredConfirmation(issue);
    }

    /**
     Check count of confirmations and send funds to executor
     */
    function sendFundsIfHasRequiredConfirmation(
        ThreePlantingIssue storage _issue
    ) private onlyOwner {
        if (_issue.confirmators.length == requiredConfirmationsCount) {
            (bool success, ) = _issue.executor.call{value: _issue.amount}("");
            require(success, "Failed to send Ether");

            _issue.isFundsSent = true;
            emit IssueStarted(_issue.externalId, _issue.executor);
        }
    }

    /**
     Mark issue as executed
     Simplifications: one owner can set issue as executed
     */
    function markAsExecuted(
        string memory externalId
    ) public onlyOwner {
        ThreePlantingIssue storage issue = issues[externalId];
        require(issue.isFundsSent, "Issue not started");

        issue.isExecuted = true;
        emit IssueExecuted(externalId);
    }

    /**
     Read all DAO's owners
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     Return issue with [_externalId]
     */
    function getIssue(string memory _externalId)
        public
        view
        returns (
            string memory externalId,
            uint amount,
            string memory description,
            address executor,
            bool isFundsSent,
            bool isExecuted,
            address[] memory confirmators
        )
    {
        ThreePlantingIssue storage issue = issues[_externalId];

        return (
             issue.externalId,
            issue.amount,
            issue.description,
            issue.executor,
            issue.isFundsSent,
            issue.isExecuted,
            issue.confirmators
        );
    }

    /**
     Contracs receive-function
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

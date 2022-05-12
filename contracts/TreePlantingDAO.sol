// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 The contract that allows DAO members to raise funds for planting trees
 Simplifications: owners are sets only in the constructor.
 */
contract ThreePlantingDAO {

    /**
     Minimim confirmations count for send funds
     */
    uint public requiredConfirmationsCount;

    /**
     DAO's owners
     */
    address[] public owners;
    mapping(address => bool) public isOwner;

    /**
    Issues created by DAO's owners
    @param externalId external identifier of issue
    @param executor executor's address
    @param value funds for issue executing
    @param description description of issue
    @param isExecuted if the issue exicuted
    @param numConfirmations count of confirmations
    */
    struct ThreePlantingIssue {
        string externalId;
        uint value;
        bytes description;
        address executor;
        bool isExecuted;
        uint numConfirmations;
    }

    /**
     Mapping from external identifier of issue to issue
     */
    mapping(string => ThreePlantingIssue) public issues;

    /**
     Modifier checks only one of owners can executes funds sending to executor
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    constructor(address[] memory _owners, uint _requiredConfirmationsCount) {
        require(_owners.length > 0, "Owners required");
        require(
            _requiredConfirmationsCount > 0 && _requiredConfirmationsCount <= _owners.length,
            "Invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredConfirmationsCount = _requiredConfirmationsCount;
    }

    /**
    @return Contract's balance
     */
    function balance() public view returns (uint) {
        return address(this).balance;
    }
}


 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SharedExpense {

    address public creator;
    string public description;
    bool public expenseCreated;

    address[] public participants;

    mapping(address => string) public participantNames;
    mapping(address => uint256) public shares;
    mapping(address => bool) public hasPaid;

    uint256 public totalAmount;
    uint256 public collectedAmount;
    uint256 public totalPaid;

    bool private withdrawing;

    event ExpenseCreated(
        address indexed creator,
        string description,
        uint256 totalAmount
    );

    event ParticipantAdded(
        address indexed participant,
        string name,
        uint256 share
    );

    event SharePaid(
        address indexed participant,
        uint256 amount
    );

    event FundsWithdrawn(
        address indexed creator,
        uint256 amount
    );

    modifier onlyCreator() {
        require(
            msg.sender == creator,
            "Only creator can perform this action"
        );
        _;
    }

    function createExpense(
        string memory _description,
        address[] memory _participants,
        string[] memory _names,
        uint256[] memory _shares
    ) external {

        require(!expenseCreated, "Expense already created");
        require(bytes(_description).length > 0, "Description required");

        require(_participants.length > 0, "Participants required");

        require(
            _participants.length == _names.length &&
            _names.length == _shares.length,
            "Input arrays must have same length"
        );

        uint256 total;

        for (uint256 i = 0; i < _participants.length; i++) {

            address participant = _participants[i];

            require(participant != address(0), "Invalid address");
            require(participant != msg.sender, "Creator cannot join");
            require(shares[participant] == 0, "Duplicate participant");
            require(_shares[i] > 0, "Share must be greater than zero");
            require(bytes(_names[i]).length > 0, "Name required");

            shares[participant] = _shares[i];
            participantNames[participant] = _names[i];

            participants.push(participant);

            total += _shares[i];

            emit ParticipantAdded(
                participant,
                _names[i],
                _shares[i]
            );
        }

        creator = msg.sender;
        description = _description;
        totalAmount = total;
        expenseCreated = true;

        emit ExpenseCreated(msg.sender, _description, total);
    }

    function payShare() external payable {

        require(expenseCreated, "Expense not created");
        require(shares[msg.sender] > 0, "Not a participant");
        require(!hasPaid[msg.sender], "Share already paid");

        require(
            msg.value == shares[msg.sender],
            "Incorrect payment amount"
        );

        hasPaid[msg.sender] = true;
        collectedAmount += msg.value;
        totalPaid += msg.value;

        emit SharePaid(msg.sender, msg.value);
    }

    function withdraw() external onlyCreator {

        require(!withdrawing, "Withdrawal in progress");
        require(collectedAmount > 0, "No funds to withdraw");

        withdrawing = true;

        uint256 amount = collectedAmount;

        collectedAmount = 0;

        (bool success, ) = payable(creator).call{value: amount}("");

        require(success, "Withdrawal failed");

        withdrawing = false;

        emit FundsWithdrawn(creator, amount);
    }

    function getParticipants()
        external
        view
        returns (address[] memory)
    {
        return participants;
    }

    function getParticipantInfo(address participant)
        external
        view
        returns (
            string memory name,
            uint256 share,
            bool paid
        )
    {
        return (
            participantNames[participant],
            shares[participant],
            hasPaid[participant]
        );
    }

    function getExpenseInfo()
        external
        view
        returns (
            address expenseCreator,
            string memory expenseDescription,
            uint256 total,
            uint256 collected,
            uint256 paid,
            bool created
        )
    {
        return (
            creator,
            description,
            totalAmount,
            collectedAmount,
            totalPaid,
            expenseCreated
        );
    }
}

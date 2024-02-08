pragma solidity >= 0.4.22 <= 0.8.17;

contract BankAccount {
    event Deposit(
        address indexed user,
        uint indexed accountId,
        uint value,
        uint timestamp
    );
    event WithdrawRequested(
        address indexed user,
        uint indexed accountId,
        uint indexed withdrawId,
        uint amount,
        uint timestamp
    );
    event Withdraw(
        uint indexed withdrawId,
        uint timestamp
    );
    event AccountCreated(
        address[] owners,
        uint indexed id,
        uint timestamp
    );

    struct Account {
        address[] owners;
        uint balance;
        mapping(uint => WithdrawRequest) withdrawRequests;
    }

    struct WithdrawRequest {
        address user;
        uint amount;
        uint numOfApprovals;
        mapping(address => bool) ownersApproved;
        bool approved;
    }

    mapping(uint => Account) accounts;
    mapping(address => uint[]) userAccounts;

    uint nextAccountId;
    uint nextWithdrawId;

    modifier accountOwner(uint accountId) {
        bool isOwner;
        for (uint idx; idx < accounts[accountId].owners.length; idx++) {
            if (accounts[accountId].owners[idx] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "not a valid account owner");
        _;
    }

    modifier validOwners(address[] calldata owners) {
        require(owners.length + 1 <= 5, "maximum of 5 owners per account");
        for (uint i; i < owners.length; i++) {
            for (uint j = i; j < owners.length; j++) {
                if (owners[i] == owners[j]) {
                    revert("no duplicate owners");
                }
            }
        }
        _;
    }

    function deposit(uint accountId) external payable accountOwner(accountId) {
        accounts[accountId].balance += msg.value;
    }

    function createAccount(address[] calldata otherOwners) external validOwners(otherOwners) {
        address [] memory owners = new address[](otherOwners.length + 1);
        owners[otherOwners.length] = msg.sender;

        uint accountId = nextAccountId;

        for (uint idx; idx < owners.length; idx++) {
            if (idx < owners.length - 1) {
                owners[idx] = otherOwners[idx];
            }

            if (userAccounts[owners[idx]].length > 4) {
                revert("maximum (5) of account reached");
            }
            userAccounts[owners[idx]].push(accountId);
        }

        accounts[id].owners = owners;
        nextAccountId++;

        emit AccountCreated(owners, id, block.timestamp);
    }

    function requestWithdrawal(uint accountId, uint amount) external {

    }

    function approveWithdrawal(uint accountId, uint withdrawId) external {

    }

    function withdraw(uint accountId, uint withdrawId) external {

    }

    function getBalance(uint accountId) public view returns (uint) {
        return 0;
    }

    function getOwners(uint accountId) public view returns (address[] memory) {
        return accounts[accountId].owners;
    }

    function getApprovals(uint accountId, uint withdrawalId) public view returns (uint) {
        return accounts[accountId].withdrawRequests[withdrawalId].numOfApprovals;
    }

    function getAccounts() public view returns (uint[] memory) {
        return userAccounts[msg.sender];
    }
}
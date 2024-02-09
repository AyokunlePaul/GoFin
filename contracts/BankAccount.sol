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
    uint nextWithdrawalId;

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

    modifier checkBalance(uint accountId, uint amount) {
        require(accounts[accountId].balance >= amount, "insufficient balance");
        _;
    }

    modifier canApprove(uint accountId, uint withdrawalId) {
        require(!accounts[accountId].withdrawRequests[withdrawalId].approved, "request already approved");
        require(accounts[accountId].withdrawRequests[withdrawalId].user != msg.sender, "you cannot approve this request");
        require(accounts[accountId].withdrawRequests[withdrawalId].user != address(0), "this request does not exist");
        require(!accounts[accountId].withdrawRequests[withdrawalId].ownersApproved[msg.sender], "you already approve this withdrawal request");
        _;
    }

    modifier canWithdraw(uint accountId, uint withdrawalId) {
        require(accounts[accountId].withdrawRequests[withdrawalId].user == msg.sender, "you did not create this request");
        require(accounts[accountId].withdrawRequests[withdrawalId].approved, "this request is not approved");
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

    function requestWithdrawal(uint accountId, uint amount) external accountOwner(accountId) checkBalance(accountId, amount) {
        uint withdrawalId = nextWithdrawalId;
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[withdrawalId];

        request.user = msg.sender;
        request.amount = amount;

        nextWithdrawalId++;

        emit WithdrawRequested(msg.sender, accountId, id, amount, block.timestamp);
    }

    function approveWithdrawal(uint accountId, uint withdrawalId) external accountOwner(accountId) canApprove(accountId, withdrawalId) {
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[withdrawalId];
        request.numOfApprovals++;
        request.ownersApproved[msg.sender] = true;

        if (request.numOfApprovals == accounts[accountId].owners.length - 1) {
            request.approved = true;
        }
    }

    function withdraw(uint accountId, uint withdrawalId) external canWithdraw(accountId, withdrawalId) {
        uint amount = accounts[accountId].withdrawRequests[withdrawalId].amount;
        require(accounts[accountId].balance >= amount, "insufficient funds");

        accounts[accountId].balance -= amount;
        delete accounts[accountId].withdrawRequests[withdrawalId];

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent);

        emit Withdraw(withdrawalId, block.timestamp);
    }

    function getBalance(uint accountId) public view returns (uint) {
        return accounts[accountId].balance;
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
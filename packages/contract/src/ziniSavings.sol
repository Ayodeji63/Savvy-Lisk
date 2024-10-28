// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {console} from "forge-std/console.sol";

contract ZiniSavings is ReentrancyGuard {
    ///////////////
    // error /////
    //////////////

    error BorrowLimitExceeed();
    error No_OutStandingLoan();
    error OutStandingLoanNotRepaid();

    ///////////////////////////
    // Type of  contract    //
    //////////////////////////
    using SafeERC20 for IERC20;

    struct Member {
        address member;
        uint256 debtAmount;
        bool isMember;
    }
    // TODO:
    // 1. Add loan status
    // 2. display a user group
    struct Group {
        address[] members;
        uint256 monthlyContribution;
        uint256 totalSavings;
        uint256 loanGivenOut;
        uint256 repaidLoan;
        uint256 creationTime;
        bool firstHalfLoanDistributed;
        bool secondHalfLoanDistributed;
        bool loanRepaid;
        uint256 firstBatchRepaidCount;
        string name;
        address admin;
        uint256 memberCount;
        uint256 loanRepaymentDuration;
        uint256 loanCycleCount;
        mapping(address => Member) addressToMember;
        mapping(address => uint) memberSavings;
        mapping(address => bool) hasReceivedLoan;
    }

    struct CreditScore {
        uint256 totalLoans; // Total flex-loans takne
        uint256 repaidLoans; // Number of flex-loans repaid
        uint256 totalSavings; // Total savings contributed
        uint256 loanDefault; // Number of loan defaults
    }

    struct Loan {
        uint256 totalAmount;
        uint256 amountRepaid;
        uint256 monthlyPayment;
        uint256 nextPaymentDue;
        uint256 debt;
        bool fullyRepaid;
        bool isFirstBatch;
        bool isSecondBatch;
    }

    ///////////////////////////
    // State Variables    //
    //////////////////////////
    IERC20 public immutable token;
    mapping(int256 => Group) public groups;
    mapping(address => int256[]) private userGroups;
    mapping(address => uint256) public usersTotalSavings;
    mapping(address => CreditScore) public creditScores;
    mapping(address => uint256) public flexLoans;
    uint256 public groupCount;
    int256[] public groupIds;
    mapping(address => mapping(int256 => Loan)) public loans;
    uint256 public constant LOAN_DURATION = 90 days; // 3 months
    uint256 public constant LOAN_INTEREST_RATE = 5; // 5%
    uint256 public constant LOCK_PERIOD = 365 days; // 12 months
    uint256 public constant LOAN_PRECISION = 3;
    uint256 public constant MAX_CYCLES = 4;
    uint256 public constant MAX_FLEX_LOAN_AMOUNT = 3_000_000 ether;
    uint256 public constant MEDIUM_FLEX_LOAN_AMOUNT = 2_000_000 ether;
    uint256 public constant LOW_FLEX_LOAN_AMOUNT = 1_000_000 ether;

    ///////////////////////////
    // Events               //
    //////////////////////////
    event GroupCreated(int256 indexed groupId, string name, address admin);
    event MemberJoined(int256 indexed groupId, address indexed member);
    event FlexLoanTransferred(
        address indexed recipient,
        uint256 indexed amount
    );
    event FlexLoanRepaid(address indexed sender, uint256 indexed amount);
    event SavingsWithdraw(
        int256 indexed groupId,
        address indexed owner,
        uint256 indexed amount
    );
    event DepositMade(
        int256 indexed groupId,
        address indexed member,
        uint256 indexed amount
    );
    event SavingsDeposited(
        int256 indexed groupId,
        address indexed member,
        uint256 indexed amount
    );
    event LoanDistributed(
        int256 indexed groupId,
        address indexed borrower,
        uint256 indexed amount,
        bool isFirstBatch
    );
    event LoanRepayment(
        int256 indexed groupId,
        address indexed borrower,
        uint256 indexed amount
    );

    ///////////////////////////
    // Functions             //
    //////////////////////////
    constructor(address _token) {
        token = IERC20(_token);
    }

    ///////////////////////////
    // External Functions    //
    //////////////////////////
    function createGroup(
        string memory _name,
        address user,
        int256 _groupId
    ) external {
        Group storage newGroup = groups[_groupId];
        // newGroup.monthlyContribution = _monthlyContribution;
        newGroup.creationTime = block.timestamp;
        newGroup.name = _name;
        newGroup.admin = user;
        _joinGroup(_groupId, user);
        groupCount++;
        groupIds.push(_groupId);

        emit GroupCreated(_groupId, _name, msg.sender);
    }

    function setMonthlyContribution(int256 _groupId, uint256 _amount) external {
        Group storage group = groups[_groupId];
        group.monthlyContribution = _amount;
    }

    function setRepaymentDuration(int256 _groupId, uint256 _time) external {}

    function joinGroup(int256 _groupId, address user) external {
        _joinGroup(_groupId, user);
    }

    function requestFlexLoan(uint256 amount) public {
        uint256 maxAmount = getMaxLoanAmount(msg.sender);
        if (amount > maxAmount) {
            revert BorrowLimitExceeed();
        }
        if (flexLoans[msg.sender] > 0) {
            revert OutStandingLoanNotRepaid();
        }

        uint256 interestRate = getLoanInterestRate(msg.sender);
        uint256 totalRepaymentAmount = amount + ((amount * interestRate) / 100);

        // Track the loan
        flexLoans[msg.sender] += totalRepaymentAmount;
        creditScores[msg.sender].totalLoans += 1;
        token.transfer(msg.sender, amount);

        emit FlexLoanTransferred(msg.sender, amount);
    }

    function repayFlexLoan(uint256 amount) public {
        if (flexLoans[msg.sender] < 0) {
            revert No_OutStandingLoan();
        }
        flexLoans[msg.sender] -= amount;
        creditScores[msg.sender].repaidLoans += 1;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit FlexLoanRepaid(msg.sender, amount);
    }

    function deposit(int256 _groupId) public payable {
        Group storage group = groups[_groupId];
        require(
            token.balanceOf(msg.sender) >= group.monthlyContribution,
            "Insufficient balance"
        );
        token.safeTransferFrom(
            msg.sender,
            address(this),
            group.monthlyContribution
        );
        group.totalSavings += group.monthlyContribution;
        group.memberSavings[msg.sender] = group.memberSavings[
            msg.sender
        ] += group.monthlyContribution;
        usersTotalSavings[msg.sender] = usersTotalSavings[msg.sender] += group
            .monthlyContribution;
        creditScores[msg.sender].totalSavings += group.monthlyContribution;

        emit SavingsDeposited(_groupId, msg.sender, group.monthlyContribution);
    }

    // Follow CEI = Check Effect Interactions
    function withdrawFromGroup(int256 _groupId, uint256 _amount) public {
        Group storage group = groups[_groupId];
        require(group.memberSavings[msg.sender] >= _amount, "Low Savings");
        group.memberSavings[msg.sender] -= _amount;
        emit SavingsWithdraw(_groupId, msg.sender, _amount);
        token.transfer(msg.sender, _amount);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        returns (
            // override
            bool upkeepNeeded,
            bytes memory performData
        )
    {
        int256[] memory eligibleGroups = new int256[](groupCount);
        uint256 eligibleCount = 0;

        for (uint i = 0; i < groupCount; ++i) {
            int256 groupId = groupIds[i];
            Group storage group = groups[groupId];
            if (isGroupEligibleForLoanDistribution(group)) {
                eligibleGroups[eligibleCount] = groupId;
                eligibleCount++;
            }
        }
        upkeepNeeded = eligibleCount > 0;
        performData = abi.encode(eligibleGroups, eligibleCount);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external // override
    {
        (int256[] memory eligibleGroups, uint256 eligibleCount) = abi.decode(
            performData,
            (int256[], uint256)
        );

        for (uint i = 0; i < eligibleCount; i++) {
            int256 groupId = eligibleGroups[i];
            Group storage group = groups[groupId];
            console.log(isGroupEligibleForLoanDistribution(group));

            if (isGroupEligibleForLoanDistribution(group)) {
                distributeLoanForGroup(groupId);
            }
        }
    }

    function distributeLoanForGroup(int256 _groupId) internal {
        Group storage group = groups[_groupId];
        uint256 halfGroupSize = group.memberCount / 2;
        uint256 totalLoanAmount = group.totalSavings;
        uint256 individualLoanAmount = (totalLoanAmount / group.memberCount) *
            LOAN_PRECISION;

        if (!group.firstHalfLoanDistributed) {
            _distributeLoansTERNAL(
                _groupId,
                0,
                halfGroupSize,
                individualLoanAmount,
                true,
                false
            );
            group.firstHalfLoanDistributed = true;
        } else if (group.firstHalfLoanDistributed) {
            _distributeLoansTERNAL(
                _groupId,
                halfGroupSize,
                group.memberCount,
                individualLoanAmount,
                false,
                true
            );
            group.secondHalfLoanDistributed = true;
        }

        group.loanGivenOut += group.monthlyContribution * 3;
    }

    function repayLoan(int256 _groupId, uint256 _amount) external {
        Group storage group = groups[_groupId];
        Loan storage loan = loans[msg.sender][_groupId];
        require(loan.totalAmount > 0, "No active loan");
        require(!loan.fullyRepaid, "Loan already repaid");
        // uint256 amountDue = loan.monthlyPayment;

        token.safeTransferFrom(msg.sender, address(this), _amount);
        loan.amountRepaid += _amount;
        loan.debt = loan.debt - _amount;
        group.repaidLoan += _amount;

        emit LoanRepayment(_groupId, msg.sender, _amount);

        if (loan.amountRepaid >= loan.totalAmount) {
            loan.fullyRepaid = true;
            group.loanRepaid = true;
            creditScores[msg.sender].repaidLoans += 1;

            if (loan.isFirstBatch) {
                group.firstBatchRepaidCount++;
            }
            if (loan.isSecondBatch) {
                if (
                    group.firstHalfLoanDistributed &&
                    group.secondHalfLoanDistributed
                ) {
                    group.loanCycleCount++;
                    group.firstHalfLoanDistributed = false;
                    group.secondHalfLoanDistributed = false;
                    group.firstBatchRepaidCount = 0;
                }
            }
        }
    }

    function getTestTokens() public {
        uint256 AIR_DROP = 50_000 ether;
        token.transfer(msg.sender, AIR_DROP);
    }

    ///////////////////////////
    // Internal Private Functions    //
    //////////////////////////
    function _joinGroup(int256 _groupId, address user) internal {
        Group storage group = groups[_groupId];
        require(
            !groups[_groupId].addressToMember[user].isMember,
            "Already in group"
        );
        group.members.push(user);
        // group.isMember[msg.sender] = true;
        group.addressToMember[user].isMember = true;
        groups[_groupId].memberCount++;
        emit MemberJoined(_groupId, user);
        userGroups[user].push(_groupId);
    }

    function isGroupEligibleForLoanDistribution(
        Group storage group
    ) internal view returns (bool) {
        return
            group.memberCount % 2 == 0 &&
            group.memberCount >= 2 &&
            group.totalSavings >=
            group.monthlyContribution * group.memberCount &&
            group.monthlyContribution != 0 &&
            (!group.firstHalfLoanDistributed ||
                (group.firstHalfLoanDistributed &&
                    !group.secondHalfLoanDistributed &&
                    group.firstBatchRepaidCount == group.memberCount / 2));
    }

    function _distributeLoansTERNAL(
        int256 _groupId,
        uint256 startIndex,
        uint256 endIndex,
        uint256 loanAmount,
        bool isFirstBatch,
        bool isSecondBatch
    ) internal nonReentrant {
        Group storage group = groups[_groupId];

        uint256 totalLoanWithInterest = loanAmount +
            ((loanAmount * LOAN_INTEREST_RATE) / 100);
        uint256 monthlyPayment = totalLoanWithInterest / 3;
        for (uint256 i = startIndex; i < endIndex; i++) {
            address borrower = group.members[i];
            // if (!group.hasReceivedLoan[borrower]) {
            token.transfer(borrower, loanAmount);
            loans[borrower][_groupId] = Loan({
                totalAmount: totalLoanWithInterest,
                amountRepaid: 0,
                monthlyPayment: monthlyPayment,
                nextPaymentDue: block.timestamp + 30 days,
                debt: totalLoanWithInterest,
                fullyRepaid: false,
                isFirstBatch: isFirstBatch,
                isSecondBatch: isSecondBatch
            });
            creditScores[borrower].totalLoans += 1;
            group.hasReceivedLoan[borrower] = true;
            emit LoanDistributed(_groupId, borrower, loanAmount, isFirstBatch);
            // }
        }

        // if (isFirstBatch) {
        //     group.firstHalfLoanDistributed = true;
        //     group.secondHalfLoanDistributed = false;
        // } else {
        //     group.firstHalfLoanDistributed = false;
        //     group.secondHalfLoanDistributed = true;
        // }
    }

    ///////////////////////////
    // Public View Functions    //
    //////////////////////////
    // Add this function to your ZiniSavings contract
    function getFlexLoanMonthlyRepayment(
        address borrower
    ) public view returns (uint256) {
        uint256 loanAmount = flexLoans[borrower];
        console.log("loan amount is %d", loanAmount);
        uint256 interestRate = getLoanInterestRate(borrower);
        uint256 loanTermMonths = 12; // 12 months loan term
        console.log("Interest rate is %d", interestRate);

        // Use higher precision for calculations (multiply by 1e18)
        uint256 precision = 1e18;

        // Calculate monthly interest rate with higher precision
        uint256 monthlyInterestRate = (interestRate * precision) / 12 / 100;
        console.log("Monthly interest rate (x1e18) is %d", monthlyInterestRate);

        // Calculate (1 + r)^n with higher precision
        uint256 base = precision + monthlyInterestRate;
        uint256 exponent = loanTermMonths;
        uint256 basePower = precision;
        // 1054980

        for (uint256 i = 0; i < exponent; i++) {
            basePower = (basePower * base) / precision;
        }

        // Calculate numerator and denominator
        uint256 numerator = loanAmount * monthlyInterestRate * basePower;
        uint256 denominator = (basePower - precision) * precision;

        // Calculate monthly repayment
        uint256 monthlyRepayment = (loanAmount / loanTermMonths);

        return monthlyRepayment;
    }

    function calculateCreditScore(address user) public view returns (uint256) {
        CreditScore memory score = creditScores[user];
        uint256 userBalance = token.balanceOf(user);

        // Base score for all users (20 points)
        uint256 baseScore = 20;

        // Repayment history (max 40 points)
        uint256 repaymentScore;
        if (score.totalLoans == 0) {
            repaymentScore = 20; // Base score for new users
        } else {
            repaymentScore = ((score.repaidLoans * 40) / score.totalLoans);
            // Bonus for no defaults
            if (score.loanDefault == 0 && score.totalLoans > 0) {
                repaymentScore += 5;
            }
        }

        // Savings history (max 25 points)
        uint256 savingsInNaira = score.totalSavings / 1e18;
        uint256 savingsScore;
        if (savingsInNaira > 0) {
            savingsScore = (log2(savingsInNaira + 1) * 25) / 10;
            if (savingsScore > 25) savingsScore = 25;
        }

        // Current balance (max 15 points)
        uint256 balanceInNaira = userBalance / 1e18;
        uint256 balanceScore;
        if (balanceInNaira > 0) {
            balanceScore = (log2(balanceInNaira + 1) * 15) / 10;
            if (balanceScore > 15) balanceScore = 15;
        }

        // Calculate final score
        uint256 creditScore = baseScore +
            repaymentScore +
            savingsScore +
            balanceScore;

        // Cap at 100
        return creditScore > 100 ? 100 : creditScore;
    }

    function log2(uint256 x) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 n = x;

        if (n >= 2 ** 128) {
            n >>= 128;
            result += 128;
        }
        if (n >= 2 ** 64) {
            n >>= 64;
            result += 64;
        }
        if (n >= 2 ** 32) {
            n >>= 32;
            result += 32;
        }
        if (n >= 2 ** 16) {
            n >>= 16;
            result += 16;
        }
        if (n >= 2 ** 8) {
            n >>= 8;
            result += 8;
        }
        if (n >= 2 ** 4) {
            n >>= 4;
            result += 4;
        }
        if (n >= 2 ** 2) {
            n >>= 2;
            result += 2;
        }
        if (n >= 2 ** 1) {
            result += 1;
        }

        return result;
    }

    function getMaxLoanAmount(address user) public view returns (uint256) {
        uint256 score = calculateCreditScore(user);

        if (score > 10000) {
            return MAX_FLEX_LOAN_AMOUNT; // Highest amount for the best credit score
        } else if (score >= 5000) {
            return MEDIUM_FLEX_LOAN_AMOUNT; // Medium amount
        } else {
            return LOW_FLEX_LOAN_AMOUNT; // Lowest amount
        }
    }

    function getLoanInterestRate(address user) public view returns (uint256) {
        uint256 score = calculateCreditScore(user);

        // Reward users with higher scores by reducing interst
        if (score > 80) {
            return 5; // 5% interest
        } else if (score > 50) {
            return 10; // 10% interest
        } else {
            return 15; // 15% interest
        }
    }

    function getCreditScore(address user) public view returns (uint256) {
        return calculateCreditScore(user);
    }

    function getGroupMonthlySavings(
        int256 _groupId
    ) external view returns (uint256) {
        return groups[_groupId].monthlyContribution;
    }

    function getGroupTotalSavings(
        int256 _groupId
    ) public view returns (uint256) {
        return groups[_groupId].totalSavings;
    }

    function getOutStandingLoan(
        int256 _groupId,
        address user
    ) public view returns (uint256) {
        return loans[user][_groupId].totalAmount;
    }

    function getAmountRepaid(
        int256 _groupId,
        address user
    ) public view returns (uint256) {
        return loans[user][_groupId].amountRepaid;
    }

    function getGroupTotalLoanGiveOut(
        int256 _groupId
    ) public view returns (uint256) {
        return groups[_groupId].loanGivenOut;
    }

    function getGroupTotalRepaidLoan(
        int256 _groupId
    ) public view returns (uint256) {
        return groups[_groupId].repaidLoan;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getUserGroups(
        address user
    ) external view returns (int256[] memory) {
        return userGroups[user];
    }

    function getGroupMemebers(
        int256 _groupId,
        uint index
    ) public view returns (address) {
        return groups[_groupId].members[index];
    }

    function getUserDebt(
        int256 _groupId,
        address user
    ) external view returns (uint256) {
        return loans[user][_groupId].debt;
    }

    function getMemeberSavings(
        int256 _groupId,
        address user
    ) public view returns (uint256) {
        return groups[_groupId].memberSavings[user];
    }

    function getMemberCount(int256 _groupId) public view returns (uint256) {
        return groups[_groupId].memberCount;
    }

    function getHasReceivedLoan(
        int256 _groupId,
        address user
    ) public view returns (bool) {
        return groups[_groupId].hasReceivedLoan[user];
    }

    function getGroupIsFirstHalf(int256 _groupId) public view returns (bool) {
        return groups[_groupId].firstHalfLoanDistributed;
    }

    function getGroupIsSecondHalf(int256 _groupId) public view returns (bool) {
        return groups[_groupId].secondHalfLoanDistributed;
    }
}

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
    error InvalidToken();
    error TokenNotSupported();
    error ContributionAlreadySet();
    error GROUP_IS_NOT_ELIGIBLE();

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
        bool isContributionSet; // Added: Track if contribution is set
        IERC20 groupToken; // Will be set when monthly contribution is set
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
        IERC20 loanToken;
    }

    ///////////////////////////
    // State Variables    //
    //////////////////////////
    // IERC20 public immutable token;
    mapping(address => bool) public supportedTokens;
    mapping(int256 => Group) public groups;
    mapping(address => int256[]) private userGroups;
    mapping(address => mapping(address => uint256)) public usersTotalSavings; // Modified: Track savings per token
    mapping(address => CreditScore) public creditScores;
    mapping(address => mapping(address => uint256)) public flexLoans;
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
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event GroupCreated(int256 indexed groupId, string name, address admin);
    event MonthlyContributionSet(int256 indexed groupId, uint256 amount);
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
        address token,
        bool isFirstBatch
    );
    event LoanRepayment(
        int256 indexed groupId,
        address indexed borrower,
        uint256 indexed amount
    );

    ///////////////////////////
    // Constructor & Admin    //
    //////////////////////////
    constructor(address[] memory _initialTokens) {
        for (uint i = 0; i < _initialTokens.length; i++) {
            supportedTokens[_initialTokens[i]] = true;
            emit TokenAdded(_initialTokens[i]);
        }
    }

    function addSupportedToken(address _token) external {
        require(_token != address(0), "Invalid token address");
        supportedTokens[_token] = true;
        emit TokenAdded(_token);
    }

    function removeSupportedToken(address _token) external {
        supportedTokens[_token] = false;
        emit TokenRemoved(_token);
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
        newGroup.isContributionSet = false; // Initialize as false
        _joinGroup(_groupId, user);
        groupCount++;
        groupIds.push(_groupId);

        emit GroupCreated(_groupId, _name, msg.sender);
    }

    function setGroupContributionToken(
        int256 _groupId,
        address _tokenAddress
    ) public {
        if (!supportedTokens[_tokenAddress]) revert TokenNotSupported();

        Group storage group = groups[_groupId];
        group.groupToken = IERC20(_tokenAddress);
    }

    function setMonthlyContribution(int256 _groupId, uint256 _amount) external {
        Group storage group = groups[_groupId];
        if (group.isContributionSet) revert ContributionAlreadySet();
        group.monthlyContribution = _amount;
        group.isContributionSet = true;

        emit MonthlyContributionSet(_groupId, _amount);
    }

    function setRepaymentDuration(int256 _groupId, uint256 _time) external {}

    function joinGroup(int256 _groupId, address user) external {
        _joinGroup(_groupId, user);
    }

    function requestFlexLoan(uint256 amount, address _tokenAddress) public {
        if (!supportedTokens[_tokenAddress]) revert TokenNotSupported();
        IERC20 token = IERC20(_tokenAddress);

        uint256 maxAmount = getMaxLoanAmount(msg.sender);
        if (amount > maxAmount) {
            revert BorrowLimitExceeed();
        }
        if (flexLoans[_tokenAddress][msg.sender] > 0) {
            revert OutStandingLoanNotRepaid();
        }

        uint256 interestRate = getLoanInterestRate(msg.sender);
        uint256 totalRepaymentAmount = amount + ((amount * interestRate) / 100);

        flexLoans[_tokenAddress][msg.sender] += totalRepaymentAmount;
        creditScores[msg.sender].totalLoans += 1;
        token.transfer(msg.sender, amount);

        emit FlexLoanTransferred(msg.sender, amount);
    }

    function repayFlexLoan(uint256 amount, address _tokenAddress) public {
        if (!supportedTokens[_tokenAddress]) revert TokenNotSupported();
        IERC20 token = IERC20(_tokenAddress);

        if (flexLoans[_tokenAddress][msg.sender] < 0) {
            revert No_OutStandingLoan();
        }
        flexLoans[_tokenAddress][msg.sender] -= amount;
        creditScores[msg.sender].repaidLoans += 1;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit FlexLoanRepaid(msg.sender, amount);
    }

    function deposit(int256 _groupId) public payable {
        Group storage group = groups[_groupId];
        require(group.isContributionSet, "Monthly contribution not set");
        IERC20 token = group.groupToken;
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
        usersTotalSavings[address(token)][msg.sender] += group
            .monthlyContribution;
        creditScores[msg.sender].totalSavings += group.monthlyContribution;

        emit SavingsDeposited(_groupId, msg.sender, group.monthlyContribution);
    }

    // Follow CEI = Check Effect Interactions
    function withdrawFromGroup(int256 _groupId, uint256 _amount) public {
        Group storage group = groups[_groupId];

        require(group.memberSavings[msg.sender] >= _amount, "Low Savings");
        IERC20 token = group.groupToken;
        group.memberSavings[msg.sender] -= _amount;
        emit SavingsWithdraw(_groupId, msg.sender, _amount);
        token.transfer(msg.sender, _amount);
    }

    // function checkUpkeep(
    //     bytes calldata /* checkData */
    // )
    //     external
    //     view
    //     returns (
    //         // override
    //         bool upkeepNeeded,
    //         bytes memory performData
    //     )
    // {
    //     int256[] memory eligibleGroups = new int256[](groupCount);
    //     uint256 eligibleCount = 0;

    //     for (uint i = 0; i < groupCount; ++i) {
    //         int256 groupId = groupIds[i];
    //         Group storage group = groups[groupId];
    //         if (isGroupEligibleForLoanDistribution(group)) {
    //             eligibleGroups[eligibleCount] = groupId;
    //             eligibleCount++;
    //         }
    //     }
    //     upkeepNeeded = eligibleCount > 0;
    //     performData = abi.encode(eligibleGroups, eligibleCount);
    //     return (upkeepNeeded, performData);
    // }

    // function performUpkeep(
    //     bytes calldata performData // override
    // ) external {
    //     (int256[] memory eligibleGroups, uint256 eligibleCount) = abi.decode(
    //         performData,
    //         (int256[], uint256)
    //     );

    //     for (uint i = 0; i < eligibleCount; i++) {
    //         int256 groupId = eligibleGroups[i];
    //         Group storage group = groups[groupId];
    //         console.log(isGroupEligibleForLoanDistribution(group));

    //         if (isGroupEligibleForLoanDistribution(group)) {
    //             distributeLoanForGroup(groupId);
    //         }
    //     }
    // }

    function distributeLoanForGroup(int256 _groupId) external {
        Group storage group = groups[_groupId];

        if (!isGroupEligibleForLoanDistribution(group)) {
            revert GROUP_IS_NOT_ELIGIBLE();
        }
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
        IERC20 token = group.groupToken;
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

    // function getTestTokens() public {
    //     uint256 AIR_DROP = 50_000 ether;
    //     token.transfer(msg.sender, AIR_DROP);
    // }

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
        IERC20 token = group.groupToken;

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
                isSecondBatch: isSecondBatch,
                loanToken: token
            });
            creditScores[borrower].totalLoans += 1;
            group.hasReceivedLoan[borrower] = true;
            emit LoanDistributed(
                _groupId,
                borrower,
                loanAmount,
                address(token),
                isFirstBatch
            );
            // }
        }
    }

    ///////////////////////////
    // Public View Functions    //
    //////////////////////////
    // Add this function to your ZiniSavings contract
    function getFlexLoanMonthlyRepayment(
        address borrower,
        address tokenAddress
    )
        public
        view
        returns (
            uint256 monthlyPayment,
            uint256 totalRepayment,
            uint256 totalInterest
        )
    {
        // Get the borrower's outstanding loan amount
        uint256 loanAmount = flexLoans[tokenAddress][borrower];
        require(loanAmount > 0, "No active loan");

        // Get the borrower's interest rate based on credit score
        uint256 annualInterestRate = getLoanInterestRate(borrower);
        uint256 loanTermMonths = 12; // Fixed 12 months term

        // Calculate total interest for the loan duration
        totalInterest =
            (loanAmount * annualInterestRate * loanTermMonths) /
            (100 * 12);

        // Calculate total repayment amount (principal + interest)
        totalRepayment = loanAmount + totalInterest;

        // Calculate fixed monthly payment
        monthlyPayment = totalRepayment / loanTermMonths;

        return (monthlyPayment, totalRepayment, totalInterest);
    }

    // Helper function to get remaining loan details
    function getFlexLoanDetails(
        address borrower,
        address tokenAddress
    )
        public
        view
        returns (
            uint256 remainingBalance,
            uint256 monthlyPayment,
            uint256 remainingMonths,
            uint256 nextPaymentAmount
        )
    {
        // Get the total outstanding loan amount
        remainingBalance = flexLoans[tokenAddress][borrower];
        require(remainingBalance > 0, "No active loan");

        // Get monthly payment details
        (monthlyPayment, , ) = getFlexLoanMonthlyRepayment(
            borrower,
            tokenAddress
        );

        // Calculate remaining months
        remainingMonths =
            (remainingBalance + monthlyPayment - 1) /
            monthlyPayment;

        // Calculate next payment (might be less than monthly payment if it's the final payment)
        nextPaymentAmount = remainingBalance < monthlyPayment
            ? remainingBalance
            : monthlyPayment;

        return (
            remainingBalance,
            monthlyPayment,
            remainingMonths,
            nextPaymentAmount
        );
    }

    function calculateCreditScore(address user) public view returns (uint256) {
        CreditScore memory score = creditScores[user];

        // Base score (30 points max)
        uint256 baseScore = 30;

        // Loan repayment history (40 points max)
        uint256 repaymentScore;
        if (score.totalLoans > 0) {
            // Calculate percentage of loans repaid
            uint256 repaymentRate = (score.repaidLoans * 100) /
                score.totalLoans;

            // Convert repayment rate to score (40 points max)
            repaymentScore = (repaymentRate * 40) / 100;

            // Penalty for defaults
            if (score.loanDefault > 0) {
                uint256 defaultPenalty = (score.loanDefault * 10);
                if (defaultPenalty > repaymentScore) {
                    repaymentScore = 0;
                } else {
                    repaymentScore = repaymentScore - defaultPenalty;
                }
            }
        } else {
            // No loan history - give half of max points
            repaymentScore = 20;
        }

        // Savings history (30 points max)
        uint256 savingsScore;
        uint256 savingsThreshold = 1000 ether; // 1000 tokens as threshold

        if (score.totalSavings > 0) {
            if (score.totalSavings >= savingsThreshold) {
                savingsScore = 30; // Max score for high savers
            } else {
                // Proportional score for smaller savings
                savingsScore = (score.totalSavings * 30) / savingsThreshold;
            }
        }

        // Calculate final score
        uint256 totalScore = baseScore + repaymentScore + savingsScore;

        // Cap at 100
        return totalScore > 100 ? 100 : totalScore;
    }

    // Helper function to get credit rating based on score
    function getCreditRating(
        uint256 score
    ) public pure returns (string memory) {
        if (score >= 80) {
            return "Excellent";
        } else if (score >= 60) {
            return "Good";
        } else if (score >= 40) {
            return "Fair";
        } else {
            return "Poor";
        }
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

    function getGroupSavingToken(
        int256 _groupId
    ) external view returns (IERC20) {
        return groups[_groupId].groupToken;
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

    // function getContractTokenBalance() public view returns (uint256) {
    //     return token.balanceOf(address(this));
    // }

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

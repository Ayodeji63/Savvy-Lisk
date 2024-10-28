// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployZini} from "../script/ziniSavings/DeployZini.s.sol";
import {ZiniSavings} from "../src/ziniSavings.sol";
import {HelperConfig} from "../script/ziniSavings/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract ZiniSavingsTest is Test {
    DeployZini deployer;
    ZiniSavings ziniSavings;
    HelperConfig config;
    address token;
    address usdt;
    address public USER_1 = makeAddr("user1");
    address public USER_2 = makeAddr("user2");
    address public USER_3 = makeAddr("user3");
    address public USER_4 = makeAddr("user4");
    uint256 public constant STARTING_ERC20_BALANCE = 10_000_000 ether;
    uint256 public constant MONTHLY_CONTRIBUTION = 5_000 ether;
    uint256 public constant CONTRACT_BALANCE = 100_000_000_000 ether;
    uint256 public constant MAX_FLEX_LOAN_AMOUNT = 3_000_000 ether;
    uint256 public constant MEDIUM_FLEX_LOAN_AMOUNT = 2_000_000 ether;
    uint256 public constant LOW_FLEX_LOAN_AMOUNT = 1_000_000 ether;
    int256 public constant GROUP_ID = -145899;
    int256 public constant GROUP2_ID = 1234;

    event GroupCreated(int256 indexed groupId, string name, address admin);
    event MemberJoined(int256 indexed groupId, address member);
    event FlexLoanTransferred(
        address indexed recipient,
        uint256 indexed amount
    );

    function setUp() public {
        deployer = new DeployZini();
        (ziniSavings, config) = deployer.run();
        (token, usdt, ) = config.activeNetworkConfig();
        ERC20Mock(token).mint(USER_1, STARTING_ERC20_BALANCE);
        ERC20Mock(token).mint(USER_2, STARTING_ERC20_BALANCE);
        ERC20Mock(token).mint(USER_3, STARTING_ERC20_BALANCE);
        ERC20Mock(token).mint(USER_4, STARTING_ERC20_BALANCE);
        ERC20Mock(token).mint(address(ziniSavings), CONTRACT_BALANCE);

        ERC20Mock(usdt).mint(USER_1, STARTING_ERC20_BALANCE);
        ERC20Mock(usdt).mint(USER_2, STARTING_ERC20_BALANCE);
        ERC20Mock(usdt).mint(USER_3, STARTING_ERC20_BALANCE);
        ERC20Mock(usdt).mint(USER_4, STARTING_ERC20_BALANCE);
        ERC20Mock(usdt).mint(address(ziniSavings), CONTRACT_BALANCE);
    }

    function testuserbalance() public view {
        vm.assertEq(ERC20Mock(token).balanceOf(USER_1), STARTING_ERC20_BALANCE);
        vm.assertEq(ERC20Mock(token).balanceOf(USER_2), STARTING_ERC20_BALANCE);
        vm.assertEq(ERC20Mock(token).balanceOf(USER_3), STARTING_ERC20_BALANCE);
        vm.assertEq(ERC20Mock(token).balanceOf(USER_4), STARTING_ERC20_BALANCE);
        vm.assertEq(
            ERC20Mock(token).balanceOf(address(ziniSavings)),
            CONTRACT_BALANCE
        );

        vm.assertEq(ERC20Mock(usdt).balanceOf(USER_1), STARTING_ERC20_BALANCE);
        vm.assertEq(ERC20Mock(usdt).balanceOf(USER_2), STARTING_ERC20_BALANCE);
        vm.assertEq(ERC20Mock(usdt).balanceOf(USER_3), STARTING_ERC20_BALANCE);
        vm.assertEq(ERC20Mock(usdt).balanceOf(USER_4), STARTING_ERC20_BALANCE);
        vm.assertEq(
            ERC20Mock(usdt).balanceOf(address(ziniSavings)),
            CONTRACT_BALANCE
        );
    }

    modifier _creategroup() {
        vm.startPrank(USER_1);
        ziniSavings.createGroup("Flex", USER_1, GROUP_ID);
        ziniSavings.setMonthlyContribution(GROUP_ID, MONTHLY_CONTRIBUTION);
        ziniSavings.setGroupContributionToken(GROUP_ID, token);

        vm.stopPrank();
        _;
    }

    modifier _creategroupAndDeposit() {
        vm.startPrank(USER_1);
        ziniSavings.createGroup("Flex", USER_1, GROUP_ID);
        ziniSavings.setMonthlyContribution(GROUP_ID, MONTHLY_CONTRIBUTION);
        ziniSavings.setGroupContributionToken(GROUP_ID, token);
        ERC20Mock(token).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();

        vm.startPrank(USER_2);
        ziniSavings.joinGroup(GROUP_ID, address(USER_2));
        ERC20Mock(token).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();

        vm.startPrank(USER_3);
        ziniSavings.joinGroup(GROUP_ID, address(USER_3));
        ERC20Mock(token).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();

        vm.startPrank(USER_4);
        ziniSavings.joinGroup(GROUP_ID, address(USER_4));
        ERC20Mock(token).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();
        _;
    }

    modifier _createGroupAndDepositUsdt() {
        vm.startPrank(USER_1);
        ziniSavings.createGroup("Flex", USER_1, GROUP_ID);
        ziniSavings.setMonthlyContribution(GROUP_ID, MONTHLY_CONTRIBUTION);
        ziniSavings.setGroupContributionToken(GROUP_ID, usdt);
        ERC20Mock(usdt).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();

        vm.startPrank(USER_2);
        ziniSavings.joinGroup(GROUP_ID, address(USER_2));
        ERC20Mock(usdt).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();

        vm.startPrank(USER_3);
        ziniSavings.joinGroup(GROUP_ID, address(USER_3));
        ERC20Mock(usdt).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();

        vm.startPrank(USER_4);
        ziniSavings.joinGroup(GROUP_ID, address(USER_4));
        ERC20Mock(usdt).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();
        _;
    }

    function testcreategroup() public {
        vm.startPrank(USER_1);
        vm.expectEmit(true, false, false, false, address(ziniSavings));
        emit GroupCreated(GROUP_ID, "Flex", address(USER_1));
        ziniSavings.createGroup("Flex", USER_1, GROUP_ID);
        assert(1 == ziniSavings.groupCount());
        vm.stopPrank();
    }

    function testGroupMonthlySavings() public _creategroup {
        uint256 monthlySavings = ziniSavings.getGroupMonthlySavings(GROUP_ID);
        assertEq(monthlySavings, MONTHLY_CONTRIBUTION);
    }

    function test_group_saving_token() public _creategroup {
        address savingToken = address(
            ziniSavings.getGroupSavingToken(GROUP_ID)
        );
        assertEq(savingToken, token);
    }

    function testJoinGroup() public _creategroup {
        vm.startPrank(USER_2);
        vm.expectEmit(true, true, false, false, address(ziniSavings));
        emit MemberJoined(GROUP_ID, USER_2);
        ziniSavings.joinGroup(GROUP_ID, address(USER_2));
        vm.stopPrank();
    }

    function testDeposit() public _creategroup {
        vm.startPrank(USER_1);
        ERC20Mock(token).approve(address(ziniSavings), MONTHLY_CONTRIBUTION);
        ziniSavings.deposit(GROUP_ID);
        uint256 ziniBalance = ERC20Mock(token).balanceOf(address(ziniSavings));
        vm.stopPrank();
        assertEq(ziniBalance, MONTHLY_CONTRIBUTION + CONTRACT_BALANCE);
    }

    function testgroupDeposit() public _creategroupAndDeposit {
        uint256 group1TotalSavings = ziniSavings.getGroupTotalSavings(GROUP_ID);
        assertEq(group1TotalSavings, MONTHLY_CONTRIBUTION * 4);
    }

    function testDistributeLoans() public _createGroupAndDepositUsdt {
        uint256 user1BalanceBefore = ERC20Mock(usdt).balanceOf(USER_1);
        console.log(user1BalanceBefore);

        vm.startPrank(USER_1);
        ziniSavings.distributeLoanForGroup(GROUP_ID);
        vm.stopPrank();
        uint256 user1BalanceAfter = ERC20Mock(usdt).balanceOf(USER_1);
        console.log(user1BalanceAfter);
        uint256 loan = user1BalanceAfter - user1BalanceBefore;
        assert(user1BalanceAfter >= user1BalanceBefore);
        assertEq(loan, MONTHLY_CONTRIBUTION * 3);
    }

    function testGetUserOutStandingLoan() public _creategroupAndDeposit {
        vm.startPrank(USER_1);
        ziniSavings.distributeLoanForGroup(GROUP_ID);
        uint256 USER1_LOAN = ziniSavings.getOutStandingLoan(GROUP_ID, USER_1);
        console.log(USER1_LOAN);
        vm.stopPrank();
    }

    function testGetUserOutStandingLoanUSDT()
        public
        _createGroupAndDepositUsdt
    {
        vm.startPrank(USER_1);
        ziniSavings.distributeLoanForGroup(GROUP_ID);
        uint256 USER1_LOAN = ziniSavings.getOutStandingLoan(GROUP_ID, USER_1);
        console.log(USER1_LOAN);
        vm.stopPrank();
    }

    function testRepayLoan() public _creategroupAndDeposit {
        vm.startPrank(USER_1);
        ziniSavings.distributeLoanForGroup(GROUP_ID);

        ERC20Mock(token).approve(
            address(ziniSavings),
            MONTHLY_CONTRIBUTION * 2
        );
        ziniSavings.repayLoan(GROUP_ID, MONTHLY_CONTRIBUTION);
        vm.stopPrank();
    }

    function testRepayLoanUsdt() public _createGroupAndDepositUsdt {
        vm.startPrank(USER_1);
        ziniSavings.distributeLoanForGroup(GROUP_ID);

        ERC20Mock(usdt).approve(address(ziniSavings), MONTHLY_CONTRIBUTION * 2);
        ziniSavings.repayLoan(GROUP_ID, MONTHLY_CONTRIBUTION);
        vm.stopPrank();
    }

    uint256 public constant LOAN_INTEREST_RATE = 5; // 5%
    uint256 LOAN_AMOUNT = MONTHLY_CONTRIBUTION * 3;
    uint256 LOAN_AMOUNT_TO_REPAY = (LOAN_AMOUNT +
        (LOAN_AMOUNT * LOAN_INTEREST_RATE) /
        100);
    uint256 constant ZERO = 0;

    function testRepayAllLoansAndBorrowForOtherMembers()
        public
        _creategroupAndDeposit
    {
        vm.startPrank(USER_1);
        ziniSavings.distributeLoanForGroup(GROUP_ID);

        ERC20Mock(token).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
        ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
        vm.stopPrank();

        uint256 user2AmountRepaid = ziniSavings.getAmountRepaid(
            GROUP_ID,
            USER_1
        );
        console.log("Amount repaid is ", user2AmountRepaid);

        // vm.stopPrank();
        uint256 user1Debt = ziniSavings.getUserDebt(GROUP_ID, USER_1);
        assertEq(user1Debt, ZERO);

        vm.startPrank(USER_2);
        ERC20Mock(token).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
        ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
        vm.stopPrank();
        uint256 user2Debt = ziniSavings.getUserDebt(GROUP_ID, USER_2);
        assertEq(user2Debt, ZERO);

        uint256 user3BalanceBefore = ERC20Mock(token).balanceOf(USER_3);
        uint256 user4BalanceBefore = ERC20Mock(token).balanceOf(USER_4);

        ziniSavings.distributeLoanForGroup(GROUP_ID);

        uint256 user3BalanceAfter = ERC20Mock(token).balanceOf(USER_3);
        uint256 loan = user3BalanceAfter - user3BalanceBefore;
        assert(user3BalanceAfter >= user3BalanceBefore);
        assertEq(loan, MONTHLY_CONTRIBUTION * 3);

        uint256 user4BalanceAfter = ERC20Mock(token).balanceOf(USER_4);
        uint256 loan2 = user4BalanceAfter - user4BalanceBefore;
        assert(user3BalanceAfter >= user3BalanceBefore);
        assertEq(loan2, MONTHLY_CONTRIBUTION * 3);

        uint256 groupTotalRepaidLoan = ziniSavings.getGroupTotalRepaidLoan(
            GROUP_ID
        );
        console.log("Group total loan repaid: ", groupTotalRepaidLoan);
        uint256 groupTotalLoan = ziniSavings.getGroupTotalLoanGiveOut(GROUP_ID);
        console.log("Group total loan given out: ", groupTotalLoan);
    }

    function testRepayAllLoansAndBorrowForOtherMembersUsdt()
        public
        _createGroupAndDepositUsdt
    {
        vm.startPrank(USER_1);
        ziniSavings.distributeLoanForGroup(GROUP_ID);

        ERC20Mock(usdt).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
        ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
        vm.stopPrank();

        uint256 user2AmountRepaid = ziniSavings.getAmountRepaid(
            GROUP_ID,
            USER_1
        );
        console.log("Amount repaid is ", user2AmountRepaid);

        // vm.stopPrank();
        uint256 user1Debt = ziniSavings.getUserDebt(GROUP_ID, USER_1);
        assertEq(user1Debt, ZERO);

        vm.startPrank(USER_2);
        ERC20Mock(usdt).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
        ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
        vm.stopPrank();
        uint256 user2Debt = ziniSavings.getUserDebt(GROUP_ID, USER_2);
        assertEq(user2Debt, ZERO);

        uint256 user3BalanceBefore = ERC20Mock(usdt).balanceOf(USER_3);
        uint256 user4BalanceBefore = ERC20Mock(usdt).balanceOf(USER_4);

        ziniSavings.distributeLoanForGroup(GROUP_ID);

        uint256 user3BalanceAfter = ERC20Mock(usdt).balanceOf(USER_3);
        uint256 loan = user3BalanceAfter - user3BalanceBefore;
        assert(user3BalanceAfter >= user3BalanceBefore);
        assertEq(loan, MONTHLY_CONTRIBUTION * 3);

        uint256 user4BalanceAfter = ERC20Mock(usdt).balanceOf(USER_4);
        uint256 loan2 = user4BalanceAfter - user4BalanceBefore;
        assert(user3BalanceAfter >= user3BalanceBefore);
        assertEq(loan2, MONTHLY_CONTRIBUTION * 3);

        uint256 groupTotalRepaidLoan = ziniSavings.getGroupTotalRepaidLoan(
            GROUP_ID
        );
        console.log("Group total loan repaid: ", groupTotalRepaidLoan);
        uint256 groupTotalLoan = ziniSavings.getGroupTotalLoanGiveOut(GROUP_ID);
        console.log("Group total loan given out: ", groupTotalLoan);
    }

    modifier groupOfTwo() {
        vm.startPrank(USER_1);
        ziniSavings.createGroup("Flex", USER_1, GROUP_ID);
        ziniSavings.createGroup("Big Things", USER_1, GROUP2_ID);
        ziniSavings.setMonthlyContribution(GROUP_ID, MONTHLY_CONTRIBUTION);
        ziniSavings.setGroupContributionToken(GROUP_ID, token);
        ziniSavings.setMonthlyContribution(GROUP2_ID, MONTHLY_CONTRIBUTION);
        ziniSavings.setGroupContributionToken(GROUP2_ID, token);

        ERC20Mock(token).approve(address(ziniSavings), UINT256_MAX);
        ziniSavings.joinGroup(GROUP_ID, USER_2);
        ziniSavings.joinGroup(GROUP2_ID, USER_2);

        ziniSavings.deposit(GROUP_ID);
        ziniSavings.deposit(GROUP2_ID);

        vm.stopPrank();
        vm.startPrank(USER_2);
        ERC20Mock(token).approve(address(ziniSavings), UINT256_MAX);
        ziniSavings.deposit(GROUP_ID);
        ziniSavings.deposit(GROUP2_ID);
        vm.stopPrank();
        _;
    }

    modifier oneGroup() {
        vm.startPrank(USER_1);
        ziniSavings.createGroup("Flex", USER_1, GROUP_ID);
        ziniSavings.setMonthlyContribution(GROUP_ID, MONTHLY_CONTRIBUTION);
        ziniSavings.setGroupContributionToken(GROUP_ID, token);
        ERC20Mock(token).approve(address(ziniSavings), UINT256_MAX);
        ziniSavings.joinGroup(GROUP_ID, USER_2);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();

        vm.startPrank(USER_2);
        ERC20Mock(token).approve(address(ziniSavings), UINT256_MAX);
        ziniSavings.deposit(GROUP_ID);
        vm.stopPrank();
        _;
    }

    // function test_checkUpkeep() public oneGroup {
    //     bool upkeepNeeded;
    //     bytes memory performData;
    //     int256[] memory eligibleGroup;
    //     uint256 eligibleCount;
    //     uint256 user1Debt;
    //     uint256 user2Debt;

    //     for (uint256 i = 0; i < 10; i++) {
    //         console.log("Cycle", i + 1);

    //         // First half of the cycle
    //         (upkeepNeeded, performData) = ziniSavings.checkUpkeep("0x");
    //         (eligibleGroup, eligibleCount) = abi.decode(
    //             performData,
    //             (int256[], uint256)
    //         );
    //         assert(upkeepNeeded == true);
    //         assert(eligibleCount == 1);
    //         assert(eligibleGroup[0] == GROUP_ID);

    //         ziniSavings.performUpkeep(performData);

    //         user1Debt = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //         user2Debt = ziniSavings.getUserDebt(GROUP_ID, USER_2);
    //         assert(user1Debt == LOAN_AMOUNT_TO_REPAY);
    //         assert(user2Debt == ZERO);

    //         (upkeepNeeded, performData) = ziniSavings.checkUpkeep("0x");
    //         assert(upkeepNeeded == false);

    //         vm.startPrank(USER_1);
    //         ERC20Mock(token).approve(address(ziniSavings), UINT256_MAX);
    //         ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
    //         assertEq(ziniSavings.getUserDebt(GROUP_ID, USER_1), ZERO);
    //         vm.stopPrank();

    //         // Second half of the cycle
    //         (upkeepNeeded, performData) = ziniSavings.checkUpkeep("0x");
    //         assert(upkeepNeeded == true);
    //         ziniSavings.performUpkeep(performData);

    //         user1Debt = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //         user2Debt = ziniSavings.getUserDebt(GROUP_ID, USER_2);
    //         assert(user1Debt == ZERO);
    //         assert(user2Debt == LOAN_AMOUNT_TO_REPAY);

    //         (upkeepNeeded, performData) = ziniSavings.checkUpkeep("0x");
    //         assert(upkeepNeeded == false);

    //         vm.startPrank(USER_2);
    //         ERC20Mock(token).approve(address(ziniSavings), UINT256_MAX);
    //         ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
    //         assertEq(ziniSavings.getUserDebt(GROUP_ID, USER_2), ZERO);
    //         vm.stopPrank();

    //         console.log(
    //             "Group Is First Half",
    //             ziniSavings.getGroupIsFirstHalf(GROUP_ID)
    //         );
    //         console.log(
    //             "Group Is Second Half",
    //             ziniSavings.getGroupIsSecondHalf(GROUP_ID)
    //         );

    //         // Simulate time passing to allow for next cycle
    //         vm.warp(block.timestamp + 90 days);
    //     }

    //     // Final check to ensure the cycle completes as expected
    //     (upkeepNeeded, performData) = ziniSavings.checkUpkeep("0x");
    //     assert(upkeepNeeded == true);

    //     ziniSavings.performUpkeep(performData);

    //     user1Debt = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     user2Debt = ziniSavings.getUserDebt(GROUP_ID, USER_2);
    //     assert(user1Debt == LOAN_AMOUNT_TO_REPAY);
    //     assert(user2Debt == ZERO);

    //     (upkeepNeeded, performData) = ziniSavings.checkUpkeep("0x");
    //     assert(upkeepNeeded == false);
    // }

    // function testGroupOfTwo() public groupOfTwo {
    //     // ziniSavings.distributeLoans(GROUP_ID);
    //     // console.log(ziniSavings.groupCount());

    //     /******* Check Upkeep for the first Group ********/

    //     (bool upkeepNeeded, bytes memory performData) = ziniSavings.checkUpkeep(
    //         "0x"
    //     );
    //     /******* perform Upkeep for the first Group ********/

    //     if (upkeepNeeded) {
    //         ziniSavings.performUpkeep(performData);
    //     }
    //     uint256 user1Debt;
    //     uint256 user2Debt;

    //     user1Debt = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     user2Debt = ziniSavings.getUserDebt(GROUP_ID, USER_2);

    //     /******* Assertions for Group1 ********/
    //     assertEq(user1Debt, LOAN_AMOUNT_TO_REPAY);
    //     assertEq(user2Debt, ZERO);

    //     user1Debt = ziniSavings.getUserDebt(GROUP2_ID, USER_1);
    //     user2Debt = ziniSavings.getUserDebt(GROUP2_ID, USER_2);

    //     /******* Assertions for Group2 ********/
    //     assertEq(user1Debt, LOAN_AMOUNT_TO_REPAY);
    //     assertEq(user2Debt, ZERO);

    //     /******* Check Upkeep for the second Group ********/
    //     bool upkeepNeeded2;
    //     bytes memory performData2;
    //     (upkeepNeeded2, performData2) = ziniSavings.checkUpkeep("0x");
    //     (, uint256 eligibleCount) = abi.decode(
    //         performData2,
    //         (int256[], uint256)
    //     );
    //     console.log(upkeepNeeded2);
    //     assertEq(eligibleCount, 0);

    //     vm.startPrank(USER_1);
    //     ERC20Mock(token).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
    //     ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
    //     uint256 user1DebtAfter = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     assertEq(user1DebtAfter, ZERO);
    //     vm.stopPrank();

    //     (upkeepNeeded2, performData2) = ziniSavings.checkUpkeep("0x");
    //     assert(upkeepNeeded2 == true);
    //     uint256 creditScore = ziniSavings.getCreditScore(USER_1);
    //     console.log("Credit Score is %d", creditScore);

    //     /******* Assert Eligible group is group 2 ********/

    //     // if (upkeepNeeded2) {}
    //     // vm.expectRevert();

    //     // uint256 user1Debt2 = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     // uint256 user2Debt2 = ziniSavings.getUserDebt(GROUP_ID, USER_2);

    //     // (bool _upkeepNeeded, bytes memory _performData3) = ziniSavings
    //     //     .checkUpkeep("0x");

    //     // assert(_upkeepNeeded == false);

    //     // /******* Assertions for second Group ********/
    //     // assertEq(user1Debt2, LOAN_AMOUNT_TO_REPAY);
    //     // assertEq(user2Debt2, ZERO);

    //     // vm.startPrank(USER_1);
    //     // ERC20Mock(token).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
    //     // ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
    //     // uint256 user1DebtAfter = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     // assertEq(user1DebtAfter, ZERO);
    //     // vm.stopPrank();

    //     // /******* Check Upkeep for the first Group ********/
    //     // (bool upkeepNeeded3, bytes memory performData3) = ziniSavings
    //     //     .checkUpkeep("0x");
    //     // (int256[] memory eligibleGroup3, ) = abi.decode(
    //     //     performData3,
    //     //     (int256[], uint256)
    //     // );
    //     // // console.log(eligibleGroup3[0]);
    //     // // console.log(upkeepNeeded3);
    //     // assertEq(eligibleGroup[0], GROUP_ID);

    //     // if (upkeepNeeded3) {
    //     //     ziniSavings.performUpkeep(performData3);
    //     // }

    //     // uint256 user1Debt3 = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     // uint256 user2Debt3 = ziniSavings.getUserDebt(GROUP_ID, USER_2);

    //     // assertEq(user1Debt3, ZERO);
    //     // assertEq(user2Debt3, LOAN_AMOUNT_TO_REPAY);

    //     // vm.startPrank(USER_2);
    //     // ERC20Mock(token).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
    //     // ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
    //     // uint256 user2DebtAfter = ziniSavings.getUserDebt(GROUP_ID, USER_2);
    //     // assertEq(user2DebtAfter, ZERO);
    //     // vm.stopPrank();
    // }

    // function test_upkeepNeeded_is_false() public groupOfTwo {
    //     (bool upkeepNeeded, bytes memory performData) = ziniSavings.checkUpkeep(
    //         "0x"
    //     );

    //     if (upkeepNeeded) {
    //         ziniSavings.performUpkeep(performData);
    //     }
    //     uint256 user1Debt = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     uint256 user2Debt = ziniSavings.getUserDebt(GROUP_ID, USER_2);

    //     address memeber1 = ziniSavings.getGroupMemebers(GROUP_ID, 1);
    //     assertEq(USER_2, memeber1);

    //     assertEq(user1Debt, LOAN_AMOUNT_TO_REPAY);
    //     assertEq(user2Debt, ZERO);

    //     // Repaying Lainds
    //     vm.startPrank(USER_1);
    //     ERC20Mock(token).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
    //     ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
    //     uint256 user1DebtAfter = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     assertEq(user1DebtAfter, ZERO);
    //     vm.stopPrank();

    //     // Checking eligible groups
    //     (bool upkeepNeeded2, bytes memory performData2) = ziniSavings
    //         .checkUpkeep("0x");
    //     console.log(upkeepNeeded2);
    //     int256 eligibleGroup = abi.decode(performData2, (int256));
    //     console.log(eligibleGroup);

    //     assertEq(upkeepNeeded2, true);

    //     // Distributing loans to second group
    //     if (upkeepNeeded) {
    //         ziniSavings.performUpkeep(performData);
    //     }

    //     uint256 user1Debt2 = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     uint256 user2Debt2 = ziniSavings.getUserDebt(GROUP_ID, USER_2);

    //     assertEq(user1Debt2, ZERO);
    //     assertEq(user2Debt2, LOAN_AMOUNT_TO_REPAY);
    // }

    // function testRepayLoanRevert() public _creategroupAndDeposit {
    //     // ziniSavings.distributeLoans(1);
    //     vm.startPrank(USER_1);
    //     vm.expectRevert();
    //     ziniSavings.repayLoan(1, MONTHLY_CONTRIBUTION);
    //     vm.stopPrank();
    // }

    function test_get_max_loan_by_user() public groupOfTwo {
        uint256 creditScore = ziniSavings.getCreditScore(USER_1);
        console.log("Credit Score is %d", creditScore);
    }

    function test_request_flex_loan_emit_event() public oneGroup {
        uint256 BORROW_AMOUNT = 300_000 ether;
        uint256 creditScore = ziniSavings.getCreditScore(USER_1);
        console.log("Credit Score is %d", creditScore);
        vm.expectEmit(true, true, false, false, address(ziniSavings));
        emit FlexLoanTransferred(USER_1, BORROW_AMOUNT);
        vm.startPrank(USER_1);
        ziniSavings.requestFlexLoan(BORROW_AMOUNT, usdt);
        vm.stopPrank();
    }

    // function test_request_flex_loan_revert() public oneGroup {
    //     uint256 BORROW_AMOUNT = 300_000 ether;
    //     uint256 interestRate = ziniSavings.getLoanInterestRate(USER_1);
    //     uint256 INTEREST = BORROW_AMOUNT / interestRate;
    //     console.log("INTEREST Score is %d", INTEREST);
    //     uint256 BORROW_AMOUNT_PLUS_INTEREST = BORROW_AMOUNT + INTEREST;

    //     uint256 creditScore = ziniSavings.getCreditScore(USER_1);
    //     console.log("Credit Score is %d", creditScore);
    //     bool upkeepNeeded2;
    //     bytes memory performData2;
    //     (upkeepNeeded2, performData2) = ziniSavings.checkUpkeep("0x");
    //     console.log(upkeepNeeded2);
    //     // assertEq(eligibleCount, 0);
    //     if (upkeepNeeded2) {
    //         // ziniSavings.performUpkeep(performData2);
    //     }

    //     // vm.expectEmit(true, true, false, false, address(ziniSavings));
    //     // vm.startPrank(USER_1);
    //     // ERC20Mock(token).approve(address(ziniSavings), LOAN_AMOUNT_TO_REPAY);
    //     // ziniSavings.repayLoan(GROUP_ID, LOAN_AMOUNT_TO_REPAY);
    //     // uint256 user1DebtAfter = ziniSavings.getUserDebt(GROUP_ID, USER_1);
    //     // assertEq(user1DebtAfter, ZERO);
    //     // vm.stopPrank();

    //     vm.startPrank(USER_1);
    //     ziniSavings.requestFlexLoan(BORROW_AMOUNT, token);
    //     (uint256 monthlyPayment, , ) = ziniSavings.getFlexLoanMonthlyRepayment(
    //         USER_1,
    //         token
    //     );
    //     console.log("Monthly repayment is %d", monthlyPayment);
    //     ziniSavings.repayFlexLoan(BORROW_AMOUNT_PLUS_INTEREST, token);
    //     uint256 userFlexLoanAmount = ziniSavings.flexLoans(USER_1, token);
    //     vm.stopPrank();
    //     assertEq(userFlexLoanAmount, 0);
    // }
}

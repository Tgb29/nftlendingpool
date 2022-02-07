pragma solidity 0.8.7;
//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import api consumer interface
//maybe implement ierc20 receiver interface

interface IAPIConsumer {
    function get_floor() external view returns(uint256);
    }

contract LendingPool {

    IERC721 public nft_address;
    IERC20 public usdc_address;

    uint256  public nft_pool;
    uint256  public usdc_pool;
    uint256  public reserve;
    uint256  nfts_in_pool;
    address admin;
    uint256  public total_borrowed;

    uint256  public floor_price;
    uint256  blocks_per_year;
    uint256  borrowInterestRate = 20 * 10**16;
    uint256  blocksPerDay = 6570; // 13.15 seconds per block
    uint256  daysPerYear = 365;
    uint256  lenderInterestRate = 10 * 10**16;
 
    uint256  collateral_factor = 3 * 10**17;
    uint256  discount_rate = 85 * 10**16;

    //borrowers
    mapping(address => uint256[]) NftOwnerToIds;
    mapping(address => uint256) NftOwnerToNumStaked;
    mapping(uint256  => address) NftIdToOwner;
    mapping(address => uint256) borrow_balance;
    mapping(address => uint256) borrow_time;

    address[] positions;

    //lenders
    mapping(address => uint256) lend_balance;
    mapping(address => uint256) lend_time;

    constructor(address nft, address ft) {
        nft_address = IERC721(nft);
        //nft allowed for collateral
        usdc_address = IERC20(ft);
        //erc20 ft (fungible token) for lending and borrowing

        admin = msg.sender;
    }


    //nft holder

    function deposit_nft(uint256 token_id) public {
        require(nft_address.ownerOf(token_id) == msg.sender);
        nft_address.safeTransferFrom(msg.sender, address(this), token_id, "");

        nfts_in_pool += 1;
        NftOwnerToIds[msg.sender].push(token_id);
        NftOwnerToNumStaked[msg.sender] += 1;
        NftIdToOwner[token_id] = msg.sender;

        positions.push(msg.sender);

        nft_pool +=1;

     
    }

    function withdraw_nft(uint256 token_id) public {
        require(borrow_balance[msg.sender] == 0); //allow for balance to be less than 1 penny
        nfts_in_pool -=1;
        for (uint i =0; i < NftOwnerToIds[msg.sender].length; i++){
            if (NftOwnerToIds[msg.sender][i] == token_id){
                delete NftOwnerToIds[msg.sender][i];
            }
        }
        NftOwnerToNumStaked[msg.sender] -= 1;
        delete NftIdToOwner[token_id];

        
        nft_address.safeTransferFrom(address(this), msg.sender, token_id, "");

        nft_pool -=1;

    }

    function borrow_usdc(uint256 _amount) public {
        require(NftOwnerToNumStaked[msg.sender] > 0);
        require(borrow_balance[msg.sender] == 0);

        uint256 amount = _amount * 10**18

        uint256 collateral_value = floor_price * NftOwnerToNumStaked[msg.sender];
        uint256 borrow_limit = collateral_value * collateral_factor;
        //borrow_remaining = max_borrow - borrow_balance[msg.sender];
        require(amount < borrow_limit);
        require(amount < usdc_pool);
        usdc_address.transfer(msg.sender, amount);
        borrow_balance[msg.sender] += amount;
        borrow_time[msg.sender] = block.number;
        usdc_pool -= amount;
        total_borrowed += amount;

        updateLenderInterestRate();

    }

    function payback_usdc() public {
        uint256 fee = 5*10**18;
        uint256  interest_due = borrow_balance[msg.sender] * (block.number-borrow_time[msg.sender] / (blocksPerDay*daysPerYear)) * borrowInterestRate;
        uint256  total_due = fee + interest_due + borrow_balance[msg.sender];
        
        usdc_address.transferFrom(msg.sender, address(this), total_due);
        usdc_pool += interest_due + borrow_balance[msg.sender];
        reserve += fee;
        
        total_borrowed -= borrow_balance[msg.sender];
        borrow_balance[msg.sender] = 0;

        updateLenderInterestRate();
        

    }

    //USDC lender

    function lend_usdc(uint256 _amount) public {
        uint256 amount = _amount * 10**18;
        usdc_address.transferFrom(msg.sender, address(this), amount);
        usdc_pool += amount;
        lend_balance[msg.sender] += amount;
        lend_time[msg.sender] = block.number;

        updateLenderInterestRate();

    }

    function withdraw_usdc() public {
        require(lend_balance[msg.sender] >0);
        uint256  interest_earned = lend_balance[msg.sender] * (block.number-lend_time[msg.sender] / (blocksPerDay*daysPerYear)) * lenderInterestRate;
        uint256  total = lend_balance[msg.sender] + interest_earned; 

        usdc_address.transfer(msg.sender, total);
        usdc_pool -= total;
        lend_balance[msg.sender] = 0;
        delete lend_time[msg.sender];

        updateLenderInterestRate();

    }

    function liquidate(address borrower) public {
        uint256  liquidation_price = NftOwnerToNumStaked[borrower] * floor_price * discount_rate;
        require(borrow_balance[borrower] > liquidation_price);
        usdc_address.transferFrom(msg.sender, address(this), borrow_balance[borrower]);
        usdc_pool += borrow_balance[borrower];
        
        total_borrowed -= borrow_balance[borrower];
        borrow_balance[borrower] = 0;
        delete borrow_time[borrower];

        //move nfts from user who was liquidated to liquidator
        NftOwnerToNumStaked[msg.sender] = NftOwnerToNumStaked[borrower];
        NftOwnerToNumStaked[borrower] =0;

        
        for (uint i =0; i < NftOwnerToIds[borrower].length; i++){
            if (NftOwnerToIds[borrower][i] > 0){
                uint256  token_id = NftOwnerToIds[borrower][i];
                NftIdToOwner[token_id] = msg.sender;
                NftOwnerToIds[msg.sender].push(token_id);
                delete NftOwnerToIds[borrower][i];
            }
        }

        updateLenderInterestRate();
    }


    function updateLenderInterestRate() public {
        uint256  apy_forecast = total_borrowed * borrowInterestRate;
        lenderInterestRate = apy_forecast / usdc_pool;

    }

    //helper

    function update_floor() public {
        //call APIConsumer and get floor

        floor_price = IAPIConsumer(0x637D7d8EE6aE0A038EbC8c72DD4D14373A61FAE7).get_floor() * 10**13;

    }

    function updateBorrowInterestRate(uint256 new_interest) public {
        borrowInterestRate = new_interest;

    }

    //admin

    function withdraw_usdc(address ceo) public {
        require(admin == msg.sender, "user not admin");
        usdc_address.transfer(ceo, reserve);
        reserve = 0;

    }

    //getter

    function get_usdc_pool() public view returns(uint256) {
        return usdc_pool;
    }

    function get_total_borrowed() public view returns(uint256) {
        return total_borrowed;
    }

    function get_borrow_time(address borrower) public view returns(uint256) {
        return borrow_time[borrower];
    }

    function get_lend_balance(address lender) public view returns(uint256) {
        return lend_balance[lender];
    }

    function get_lend_time(address lender) public view returns(uint256) {
        return lend_time[lender];
    }

    function get_nft_pool() public view returns(uint256) {
        return nft_pool;
    }

}



/*
come up with a variable way to determine interest rate for usdc lenders.
based on num of nfts staked plus total amount borrowed.
usdc lenders split the rewards earned assuming the interst paid is 15%
*/
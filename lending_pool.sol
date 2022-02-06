pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import api consumer interface
//maybe implement ierc20 receiver interface


contract LendingPool {

    IERC721 public nft_address;
    IERC20 public usdc_address;

    uint public nft_pool;
    uint public usdc_pool;
    uint public reserve;
    uint nfts_in_pool;
    address admin;
    uint public total_borrowed;

    uint floor_price;
    uint blocks_per_year;
    uint nft_interest = 15 * 10**16;
    uint blocksPerDay = 6570; // 13.15 seconds per block
    uint daysPerYear = 365;
    uint usdc_interest_rate = ;

    //borrowers
    mapping(address => uint256[]) NftOwnerToIds;
    mapping(address => uint256) NftOwnerToNumStaked;
    mapping(uint => address) NftIdToOwner;
    mapping(address => uint256) borrow_balance;
    mapping(uint256 => uint256) borrow_time;

    //lenders
    mapping(address => uint256) lend_balance;
    mapping(uint256 => uint256) lend_time;

    constructor(address nft, address ft, address _api_consumer) {
        nft_address = IERC721(nft);
        //nft allowed for collateral
        usdc_address = IERC20(ft);
        //erc20 ft (fungible token) for lending and borrowing
        api_consumer = APIConsumer(_api_consumer);
        //oracle for getting floor price
        admin = msg.sender
    }


    //nft holder

    function deposit_nft(uint256 token_id) public {
        require(nft_address.ownerOf(token_id) == msg.sender);
        nft_address.safeTransferFrom(msg.sender, address(this), token_id, "");

        nfts_in_pool += 1;
        NftOwnerToIds[msg.sender].push(token_id);
        NftOwnerToNumStaked += 1;
        NftIdToOwner[token_id] = msg.sender

     
    }

    function withdraw_nft(uint256 token_id) public {
        require(borrow_balance[msg.sender] == 0); //allow for balance to be less than 1 penny
        nfts_in_pool -=1;
        for (uint i =0; i < NftOwnerToIds[msg.sender].length; i++){
            if (NftOwnerToIds[msg.sender][i] == id){
                delete NftOwnerToIds[msg.sender][i];
            }
        }
        NftOwnerToNumStaked -= 1;
        delete NftIdToOwner[id];

        
        nft_address.safeTransferFrom(address(this), msg.sender, id, "");

    }

    function borrow_usdc(uint256 amount) public {
        require(NftOwnerToNumStaked[msg.sender] > 0);
        require(borrow_balance[msg.sender] == 0);

        collateral_value = floor_price * NftOwnerToNumStaked[msg.sender];
        borrow_limit = collateral_value * 3 * 10**17;
        //borrow_remaining = max_borrow - borrow_balance[msg.sender];
        require(amount < borrow_limit);
        require(amount < usdc_pool);
        usdc_address.transfer(msg.sender, amount);
        borrow_balance[msg.sender] += amount;
        borrow_time[msg.sender] = block.number;
        usdc_pool -= amount;
        total_borrowed += amount;

        update_usdc_rate();

    }

    function payback_usdc(uint256 amount) public {
        fee = 5*10**18
        interest_due = borrow_balance[msg.sender] * (block.number-borrow_time[msg.sender] / (blocksPerDay*daysPerYear)) * 15 * 10**16;
        total_due = fee + interest_due + borrow_balance[msg.sender]
        require(amount-total_due > 1 *10**18);
        
        usdc_address.transferFrom(msg.sender, address(this), amount);
        usdc_pool += interest_due + borrow_balance[msg.sender]
        reserve += (amount - interest_due + borrow_balance[msg.sender];
        
        total_borrowed -= borrow_balance[msg.sender];
        borrow_balance[msg.sender] = 0;

        update_usdc_rate();
        

    }

    //USDC lender

    function lend_usdc(uint256 amount) public {
        usdc_address.transferFrom(msg.sender, address(this), amount);
        usdc_pool += amount;
        lend_balance[msg.sender] += amount;
        lend_time[msg.sender] = block.number;

        update_usdc_rate();

    }

    function withdraw_usdc() public {
        require(lend_balance[msg.sender] >0);
        interest_earned = lend_balance[msg.sender] * (block.number-lend_time[msg.sender] / (blocksPerDay*daysPerYear)) * usdc_interest_rate;
        total = lend_balance[msg.sender] + interest_earned; 

        usdc_address.transfer(msg.sender, total;
        usdc_pool -= total;
        lend_balance[msg.sender] = 0;
        delete lend_time[msg.sender];

        update_usdc_rate();

    }

    function liquidate(uint256 token_id) public {

    }

    function buy(uint256 token_id) public {

    }

    function update_usdc_rate() public {
        uint public usdc_pool;
        uint public total_borrowed;
        uint apy_forecast = total_borrowed * nft_interest;
        uint usdc_interest_rate = apy_forecast / usdc_pool;

    }

    //helper

    function update_floor() public {
        //call APIConsumer and get floor
        floor = api_consumer.get_floor();

    }

    function update_nft_interest(uint256 new_interest) public {
        nft_interest = new_interest;

    }

    //admin

    function withdraw_usdc(address ceo) public {
        require(admin == msg.sender, "user not admin");
        ft_address.transfer(ceo, reserve);
        reserve = 0;

    }

    //getter

    function get_usdc_pool() public view (uint256) {
        return usdc_pool;
    }

    function get_borrow_time(address borrower) public view (uint256) {
        return borrow_time[msg.sender];
    }

    function get_lend_balance(address lender) public view (uint256) {
        return lend_balance[msg.sender];
    }

    function get_lend_time(address lender) public view (uint256) {
        return lend_time[msg.sender];
    }

}



/*
come up with a variable way to determine interest rate for usdc lenders.
based on num of nfts staked plus total amount borrowed.
usdc lenders split the rewards earned assuming the interst paid is 15%
*/
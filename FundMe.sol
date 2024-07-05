// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//引入库合约
import {PriceConverter} from "./PriceConverter.sol"; 

error NotOwner();

contract FundMe{

    using PriceConverter for uint256;  //引入一个操作符重载
    //constant gas优化
    uint256 public constant MINIMUM_USD = 5e18;  //众筹最低金额

    address[] public funders; //众筹者地址列表

    mapping(address => uint256) public addressToAmountFunded;  //众筹者地址=>资金映射

    //immutable gas优化
    address public immutable i_owner;  //部署者地址

    //构造方法,将owner设置为合约部署者地址
    constructor() {
        i_owner = msg.sender;

    }

    //权限控制函数
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if(msg.sender != i_owner) { revert NotOwner(); }
        _;
    }

    //众筹函数
    function fund() public payable{
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enough!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    //资金提取函数,仅owner调用
   function withdraw() public onlyOwner{
    for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
        address funder = funders[funderIndex];
        addressToAmountFunded[funder] = 0;
    }

    funders = new address[](0); //重置众筹者地址数组,将起始长度设置为0;
    // //transfer
    // payable(msg.sender).transfer(address(this).balance);
    // //send
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed");
    //Call
    (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
    require(callSuccess, "Call failed");

   }

   receive() external payable {
        fund();
   }

   fallback() external payable {
        fund();
   }

}

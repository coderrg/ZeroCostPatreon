pragma solidity ^0.8.0;

// We developed and tested this using https://remix.ethereum.org/

contract PatreonVault {
    mapping(address => uint256) public balance;
    MockStake public mockStake;
    address payable public creator;
    
    receive() external payable {
        // React to receiving ether
    }
    
    constructor(address payable _mockState, address payable _creator) {
        mockStake = MockStake(_mockState);
        creator = _creator;
    }
    
    function deposit() payable external{
        balance[msg.sender] += msg.value;
        mockStake.deposit{value: msg.value}();
    }
    
    function withdrawPrincipal(uint256 amount) payable external {
        require(balance[msg.sender] >= amount, "Not enough balance");
        balance[msg.sender] -= amount;
        mockStake.withdrawPrincipal(amount);
        payable(msg.sender).transfer(amount);
    }
    
    function withdrawInterest() payable external {
        require(msg.sender == creator);
        mockStake.withdrawInterest();
        payable(msg.sender).transfer(address(this).balance);
    }
    
}


contract MockStake {
    mapping(address => uint256) public balance;
    mapping(address => uint256) public interest;
    mapping(address => uint256) public lastTime;
    uint256 private yps = 1;

    receive() external payable {
        // React to receiving ether
    }
    
    function calcInterest() internal {
        uint256 last = lastTime[msg.sender];
        uint256 curr = block.timestamp;
        if (last != 0){
            uint256 total = balance[msg.sender] + interest[msg.sender];
            for (uint period = 0; period < curr - last; period++) {
                total = total * (100 + yps) / 100;
            }
            interest[msg.sender] = total - balance[msg.sender];
        }
        lastTime[msg.sender] = curr;
    }

    function withdrawInterest() payable external {
        calcInterest();
        require(interest[msg.sender] > 0);
        payable(msg.sender).transfer(interest[msg.sender]);
        interest[msg.sender] = 0;
    }
    
    function deposit() payable external{
        calcInterest();
        balance[msg.sender] += msg.value;
    }
    
    function withdrawPrincipal(uint256 amount) payable public {
        calcInterest();
        require(balance[msg.sender] >= amount, "Not enough balance");
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
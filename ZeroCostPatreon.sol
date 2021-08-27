pragma solidity ^0.8.0;

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
        uint256 b = address(this).balance;
        mockStake.withdrawInterest();
        b = address(this).balance;
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
        uint256 l = lastTime[msg.sender];
        uint256 curr = block.timestamp;
        if (l != 0){
            uint256 current = balance[msg.sender] + interest[msg.sender];
            for (uint period = 0; period < curr - l; period++) {
                current = current * (100 + yps) / 100;
            }
            interest[msg.sender] = current - balance[msg.sender];
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
        require(balance[msg.sender] >= amount, "Not enough balance");
        calcInterest();
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

}
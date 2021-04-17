// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EthWallet {
    string constant NOT_ENOUGH = 'Not enough wei';
    address payable constant beneficiary = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4); 
    
    uint8 comission = 1;
    event Transfer(address indexed from, address indexed to, uint256 eth);
    
    mapping(address => uint256) balance; // maybe uint128 
    
    function deposit() public payable returns(bool) {
        balance[msg.sender] += msg.value;

        return true;
    }
    
    function withdraw(uint256 amount) external returns(bool) {
        require(balance[msg.sender] >= amount, NOT_ENOUGH);
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        return true;
    }
    
    function balanceOf(address owner) external view returns(uint256) {
        return balance[owner];
    }
    
    function transfer(address to, uint256 amount) external returns(bool) {
        uint256 comissionAmount = (amount * comission) / 100;
        
        require(balance[msg.sender] >= amount + comissionAmount, NOT_ENOUGH);
        
        balance[msg.sender] -= amount + comissionAmount;
        balance[to] += amount;
        
        beneficiary.transfer(comissionAmount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function changeComission(uint8 newComission) external returns(bool) {
        require(msg.sender == beneficiary);
        comission = newComission;
        return true;
    }
}

contract MyBeautifulWallet is EthWallet {
    string constant OVERFLOW = 'Sum overflow';
    string constant NOT_ENOUGH_TOKENS = 'Not enough tokens';
    
    event ApprovalTokens(address indexed token, address indexed tokenOwner, address indexed spender, uint256 tokens);
    event TransferTokens(address indexed token, address indexed from, address indexed to, uint256 tokens);
        
    mapping(address => mapping(address => uint256)) tokensBalance;
    mapping(address => mapping(address => mapping(address => uint256))) tokensAllowance;
    
    function deposit(IERC20 token, uint256 amount) external returns(bool) {
        require(tokensBalance[address(token)][msg.sender] + amount >= amount, OVERFLOW);
        assert(token.transferFrom(msg.sender, address(this), amount));
        
        tokensBalance[address(token)][msg.sender] += amount; 
        return true;
    }
    
    function withdraw(IERC20 token, uint256 amount) external returns(bool) {
        require(tokensBalance[address(token)][msg.sender] >= amount);
        
        tokensBalance[address(token)][msg.sender] -= amount;
        assert(token.transfer(msg.sender, amount));

        return true;
    }
    
    function balanceOf(address token, address owner) external view returns(uint256) {
        return tokensBalance[token][owner];
    }
    
    function transfer(address token, address to, uint256 amount) external returns(bool) {
        require(tokensBalance[token][msg.sender] >= amount, NOT_ENOUGH_TOKENS);
        require(tokensBalance[token][to] + amount >= amount);
        
        
        tokensBalance[token][msg.sender] -= amount;
        tokensBalance[token][to] += amount;
        
        emit TransferTokens(token, msg.sender, to, amount);
        return true;
    }
    
    function approve( address token, address spender, uint256 amount ) external returns(bool) {
        tokensAllowance[token][msg.sender][spender] = amount;
        
        emit ApprovalTokens(token, msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address token, address owner, address delegate) external view returns(uint256) {
        return tokensAllowance[token][owner][delegate];
    }
    
    function transferFrom(IERC20 token, address owner, address to, uint256 amount) external returns(bool) {
        address tokenAddress = address(token);
        require(tokensAllowance[tokenAddress][owner][msg.sender] >= amount, 'Not enough allowed');
        require(tokensBalance[tokenAddress][owner] >= amount, NOT_ENOUGH_TOKENS);
        require(tokensBalance[tokenAddress][to] + amount >= amount , OVERFLOW);
        
        tokensAllowance[tokenAddress][owner][msg.sender] -= amount;
        tokensBalance[tokenAddress][owner] -= amount;
        tokensBalance[tokenAddress][to] += amount;
        
        emit TransferTokens(tokenAddress, owner, to, amount);
        return true;
    }
    
}

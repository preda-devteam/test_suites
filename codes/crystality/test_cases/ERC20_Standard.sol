pragma solidity ^0.8.13;

contract ERC20_Standard
{
    uint public totalSupply;
    mapping(address=>uint) public balance;
    mapping(address=>mapping(address=>uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function mint(address _scope, uint amount) external
    {
        require(msg.sender == _scope);
        balance[_scope] += amount;
        totalSupply += amount;
    }
    
    function _deposit(address _scope, uint256 amount) public
    {
        balance[_scope] += amount;
    }
    
    function transfer(address _scope, address recipient, uint amount) external returns (bool)
    {
        require(msg.sender == _scope);
        balance[_scope] -= amount;
        balance[recipient] += amount;
        emit Transfer(_scope, recipient, amount);
        return true;
    }
    
    function approve(address _scope, address spender, uint amount) external returns (bool)
    {
        require(msg.sender == _scope);
        allowance[_scope][spender] = amount;
        return true;
    }
    
    function transferFrom(address _scope, address sender, address recipient, uint amount) external returns (bool)
    {
        require(sender == _scope);
        allowance[_scope][msg.sender] -= amount;
        balance[_scope] -= amount;
        balance[recipient] += amount;
        return true;
    }
    
    function _addtotalsupply(uint amount) public
    {
        totalSupply += amount;
    }
    
    function _subtotalsupply(uint amount) public
    {
        totalSupply -= amount;
    }
    
    function burn(address _scope, uint amount) external
    {
        require(msg.sender == _scope);
        balance[_scope] -= amount;
        totalSupply -= amount;
    }
}

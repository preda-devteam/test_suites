pragma solidity ^0.8.17;

contract AirDrop
{
    struct Payment
    {
        address to;
        uint amount;
    }
    mapping (address => uint) balance;
    
    function transfer_n(address _scope, Payment[] memory recipients) public returns (bool)
    {
        uint total = 0;
        for (uint i = 0; i < recipients.length; i++)
        {
            require(recipients[i].amount >= 0);
            total += recipients[i].amount;
        }
        if (total <= balance[_scope])
        {
            balance[_scope] -= total;
            for (uint i = 0; i < recipients.length; i++)
            {
                if (recipients[i].amount > 0)
                {
                    address(666).call(
                        abi.encodeWithSignature("_deposit(address,uint256)", recipients[i].to, recipients[i].amount)
                    );
                }
            }
            return true;
        }
        return false;
    }
    
    function _deposit(address _scope, uint amount) public
    {
        balance[_scope] += amount;
    }
}

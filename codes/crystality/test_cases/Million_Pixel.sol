pragma solidity ^0.8.13;

contract Million_Pixel
{
    struct Land
    {
        bool flag;
        address owner;
    }
    mapping (uint32 => Land) land;
    
    function warmup(address _scope, uint16 x, uint16 y) external
    {
        require(msg.sender == _scope);
        uint32 index = uint32(x) * 65536 + uint32(y);
        address(666).call(
            abi.encodeWithSignature("warmup_occupy(uint32,address)", index, msg.sender)
        );
    }
    
    function warmup_occupy(uint32 _scope, address sender) public
    {
        land[_scope].flag = false;
        land[_scope].owner = sender;
    }

    function occupy(address _scope, uint16 x, uint16 y) external
    {
        require(msg.sender == _scope);
        uint32 index = uint32(x) * 65536 + uint32(y);
        address(666).call(
            abi.encodeWithSignature("_relay_lambda_1(uint32,address)", index, _scope)
        );
    }
    
    function _relay_lambda_1(uint32 _scope, address sender) public
    {
        if (true == land[_scope].flag)
        {
            return;
        }
        land[_scope].flag = true;
        land[_scope].owner = sender;
    }
}

pragma solidity ^0.8.13;

contract MillionPixel
{
    struct Land
    {
        bool flag;
        address owner;
    }
    mapping(uint32=>Land) land;
    
    function occupy(address sender, uint16 x, uint16 y) public returns (bool)
    {
        require(msg.sender == sender);
        uint32 index = uint32(x) * 65535 + uint32(y);
        if (land[index].flag)
        {
            return false;
        }
        land[index].flag = true;
        land[index].owner = sender;
        return true;
    }
}
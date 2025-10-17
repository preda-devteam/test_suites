pragma solidity ^0.8.13;

contract Ballot
{
    struct Proposal
    {
        string name;
        uint64 totalVotedWeight;
    }
    struct BallotResult
    {
        string topVoted;
        uint32 caseId;
    }
    address controller;
    uint32 current_case;
    Proposal[] proposals;
    BallotResult last_result;
    uint32 shardGatherRatio;
    uint256[] votedWeights;
    mapping (address => uint256) weight;
    mapping (address => uint32) voted_case;
    
    function set(address _scope, uint256 _weight, uint32 _voted_case) public
    {
    }
    
    function shardGather_reset() internal
    {
        shardGatherRatio = 0;
    }
    
    function shardGather_gather() internal returns (bool)
    {
        shardGatherRatio += uint32(0x80000000) >> getShardOrder();
        return shardGatherRatio == uint32(0x80000000);
    }
    
    function init(address _scope, string[] memory names) public
    {
        require(controller == msg.sender);
        require(last_result.caseId >= current_case);
        address(888).call(
            abi.encodeWithSignature("_init(string[])", names)
        );
    }
    
    function _init(string[] memory names) public
    {
        for (uint32 i = 0; i < names.length; i++)
        {
            Proposal memory proposal;
            proposal.name = names[i];
            proposal.totalVotedWeight = 0;
            proposals.push(proposal);
        }
        current_case++;
        last_result.caseId = 0;
        last_result.topVoted = "";
        address(777).call(
            abi.encodeWithSignature("_initShardVotedWeights()")
        );
    }
    
    function _initShardVotedWeights() public
    {
        while (votedWeights.length < proposals.length)
        {
            votedWeights.push();
        }
    }
    
    function vote(address _scope, uint32 proposal_index, uint32 case_num) public returns (bool)
    {
        votedWeights[proposal_index] += 1;
        return true;
    }
    
    function finalize(address _scope) public
    {
        require(controller == msg.sender);
        require(last_result.caseId < current_case);
        address(888).call(
            abi.encodeWithSignature("_startFinalize()")
        );
    }
    
    function _startFinalize() public
    {
        shardGather_reset();
        address(777).call(
            abi.encodeWithSignature("_shardsFinalize()")
        );
    }
    
    function _shardsFinalize() public
    {
        address(888).call(
            abi.encodeWithSignature("_finalize(uint64[])", votedWeights)
        );
    }
    
    function _finalize(uint64[] memory shardVotes) public
    {
        for (uint32 i = 0; i < shardVotes.length; i++)
        {
            proposals[i].totalVotedWeight += uint64(shardVotes[i]);
        }
        if (shardGather_gather())
        {
            last_result.caseId = current_case;
            uint64 w = 0;
            for (uint32 i = 0; i < proposals.length; i++)
            {
                if (proposals[i].totalVotedWeight > w)
                {
                    last_result.topVoted = proposals[i].name;
                    w = proposals[i].totalVotedWeight;
                }
            }
        }
    }
    
    function getShardOrder() internal returns (uint32)
    {
        (bool success, bytes memory data) = address(555).call(
            abi.encodeWithSignature("getShardOrder()")
        );
        return abi.decode(data, (uint32));
    }
}

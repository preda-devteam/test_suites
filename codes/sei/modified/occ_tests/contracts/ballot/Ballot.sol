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
    uint32 current_case;
    Proposal[] proposals;
    BallotResult last_result;
    uint64[] votedWeights;
    mapping(address=>uint64) weight;
    mapping(address=>uint32) voted_case;
    
    function set(address _scope, uint64 _weight, uint32 _voted_case) public returns (bool)
    {
        weight[_scope] = _weight;
        voted_case[_scope] = _voted_case;
        return true;
    }
    
    function init(address _scope, string[] memory names) public returns (uint32)
    {
        _init(names);
        return current_case;
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
        _initShardVotedWeights();
    }
    
    function _initShardVotedWeights() public
    {
        while (votedWeights.length < proposals.length)
        {
            votedWeights.push(0);
        }
    }
    
    function vote(address _scope, uint32 proposal_index, uint32 case_num) public returns (bool)
    {
        if (case_num == current_case && case_num > voted_case[_scope] && proposal_index < proposals.length)
        {
            votedWeights[proposal_index] += weight[_scope];
            return true;
        }
        return false;
    }
    
    function finalize(address _scope) public
    {
        require(last_result.caseId < current_case);
        _finalize(votedWeights);
    }
    
    function _finalize(uint64[] memory shardVotes) public
    {
        for (uint32 i = 0; i < shardVotes.length; i++)
        {
            proposals[i].totalVotedWeight += uint64(shardVotes[i]);
        }
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
module 0x1::xtl_ballot {

    use std::string::String;
    use std::signer;
    use std::vector;

    struct Proposal has copy,store,drop{
        name: String,
        totalVotedWeight: u64
    }

    struct Proposals has key{
        proposals: vector<Proposal>
    }


    const FORUM_IS_NOT_EXISTED : u64 = 1;

    public entry fun initialize(forum: &signer, names: vector<String>) acquires Proposals{

        move_to<Proposals>(forum, Proposals{
            proposals: vector::empty<Proposal>()
        });

        let addr = signer::address_of(forum);
        let proposal_collections = borrow_global_mut<Proposals>(addr);
        let len = vector::length(&names);

        for( i in 0..len ){
            let proposal_name = vector::borrow<String>(&names,i);
            vector::push_back(&mut proposal_collections.proposals, Proposal{
                name: *proposal_name,
                totalVotedWeight: 0,
            });
        }
    }

    public entry fun vote(forum: address, proposal_index: u64) acquires Proposals {
        assert!(exists<Proposals>(forum), FORUM_IS_NOT_EXISTED);
        let proposal_collections = &mut borrow_global_mut<Proposals>(forum).proposals;
        let p = vector::borrow_mut<Proposal>(proposal_collections,proposal_index);
        p.totalVotedWeight = p.totalVotedWeight + 1;
    }

    #[view]
    public fun finalize(forums: vector<address>): u64 acquires Proposals{
        let forum_nums = vector::length(&forums);
        let res = vector::empty<u64>();
        {
            let tmp_forum = vector::borrow<address>(&forums,0);
            let proposals = borrow_global<Proposals>(*tmp_forum).proposals;
            let proposals_num = vector::length(&proposals);
            for(i in 0..proposals_num){
                vector::push_back(&mut res,0);
            }
        };
        for(i in 0..forum_nums){
            let forum = vector::borrow<address>(&forums,i);
            let proposals = borrow_global<Proposals>(*forum).proposals;
            let proposals_num = vector::length(&proposals);
            for( j in 0..proposals_num){
                let v = vector::borrow_mut<u64>(&mut res,j);
                let w = vector::borrow<Proposal>(&proposals,j);
                *v = w.totalVotedWeight + *v;
            }
        };
        let winer = 0;
        let max_weight = 0;
        let len = vector::length(&res);
        for( i in 0..len){
            let v = vector::borrow<u64>(&res,i);
            if(max_weight > *v){
                winer = i;
                max_weight = *v;
            }
        };
        winer
    }

}
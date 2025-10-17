module 0x1::xtl_kitty_breeding {
    
    use std::signer;
    use aptos_std::table::{Self, Table};
    use std::vector;

    struct Kitty has store,drop{
        id:u64,
        genes: u64,
        m_id: u64,
        s_id: u64,
    }

    struct KittyInfo has store,drop{
        gender: bool,
        owner: address,
    }

    struct MyKitties has key{
        value: Table<u64,Kitty>
    }

    struct AllKitties has key{
        value:vector<KittyInfo>
    }

    struct Newborns has key{
        value: u64
    }

    public entry fun initialize(global: &signer){     
        move_to<AllKitties>(global,AllKitties{
            value: vector::empty<KittyInfo>()
        });
        move_to<Newborns>(global,Newborns{
            value: 0
        });
    }

    public entry fun mint(owner: &signer, global:address, genes:u64, gender:bool)acquires AllKitties,MyKitties{
        let addr = signer::address_of(owner);
        if(!exists<MyKitties>(addr)){
            move_to<MyKitties>(owner,MyKitties{
                value: table::new()
            });
        };
        let id = create(global,gender,addr);
        add_new_kitty(addr,genes,id,((1<<32)-1 as u64), ((1<<32)-1 as u64) );
    }

    public entry fun breed(sender: &signer, global:address, m:u64, s:u64, gender:bool) acquires MyKitties,AllKitties,Newborns{
        let new_owner = signer::address_of(sender);
        let all_kitties = borrow_global_mut<AllKitties>(global);
        let m_owner = vector::borrow_mut<KittyInfo>(&mut all_kitties.value,m).owner;
        let s_owner = vector::borrow_mut<KittyInfo>(&mut all_kitties.value,s).owner;
        let m_genes:u64;
        {
            let _my_kitties_m = borrow_global_mut<MyKitties>(m_owner);
            m_genes = table::borrow_mut(&mut _my_kitties_m.value,m).genes;
        };
        let s_genes:u64;
        {
            let _my_kitties_s = borrow_global_mut<MyKitties>(s_owner);
            s_genes = table::borrow_mut(&mut _my_kitties_s.value,s).genes;
        };
        let new_genes = genes_mix(m_genes,s_genes);
        add_new_kitty(new_owner, new_genes,new_genes, m, s);
        let newborns = &mut borrow_global_mut<Newborns>(global).value;
        *newborns = *newborns + 1;
    }

    fun create(global:address, gender: bool, owner: address):u64 acquires AllKitties{
        let all_kitties = borrow_global_mut<AllKitties>(global);
        let id = vector::length(&all_kitties.value);
        vector::push_back(&mut all_kitties.value, KittyInfo{
            gender,
            owner
        });
        id
    }

    fun add_new_kitty(owner: address, genes:u64, id:u64,m_id:u64, s_id:u64) acquires MyKitties{
        let my_kitties = borrow_global_mut<MyKitties>(owner);
        table::add(&mut my_kitties.value, id, Kitty{
            id,
            genes,
            m_id,
            s_id
        });
    }
    
    fun sqrt(x:u64):u64 {
        let z = (x+1)/2;
        let y = x;
        while (z < y){
            y = z;
            z = (x/z+z)/2;
        };
        y
    }

    fun genes_mix(m_genes:u64, s_genes: u64):u64{
        let _new_genes:u64 = sqrt(m_genes)*sqrt(s_genes);
        _new_genes = sqrt(m_genes)*sqrt(s_genes);
        _new_genes = sqrt(m_genes)*sqrt(s_genes);
        _new_genes = sqrt(m_genes)*sqrt(s_genes);
        _new_genes = sqrt(m_genes)*sqrt(s_genes);
        _new_genes = sqrt(m_genes)*sqrt(s_genes);
        sqrt(m_genes)*sqrt(s_genes)
    }
}
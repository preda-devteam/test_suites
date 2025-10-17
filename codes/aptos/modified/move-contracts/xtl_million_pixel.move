module 0x1::xtl_million_pixel {
    use std::signer;
    use aptos_std::table::{Self, Table};

    struct Land has store,drop{
        flag: bool,
        owner: address
    }

    struct LandStore has key{
        land: Table<u32,Land>
    }

    public entry fun initialize(global_store: &signer){
        move_to(global_store,LandStore{
            land: table::new()
        });
    }

    public entry fun occupy(sender: &signer,global_land: address,x:u16, y:u16) acquires LandStore{
        let addr = signer::address_of(sender);
        let index:u32 = (x as u32) * 65536 + (y as u32);
        let land_mp = borrow_global_mut<LandStore>(global_land);
        if(table::contains(&mut land_mp.land, index) == false){
            table::add(&mut land_mp.land, index, Land{
                flag:true,
                owner:addr
            });
        };
    }
}
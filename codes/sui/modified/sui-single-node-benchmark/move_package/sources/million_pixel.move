#[allow(lint(self_transfer))]
module move_benchmark::MillionPixel {
    use sui::table::{Table, Self};

    public struct Land has key, store {
        id: UID,
        owner: address,
        x: u16,
        y: u16,
    }

    public struct LandRecord has key, store {
        id: UID,
        lands: Table<u32, ID>,
    }

    public fun create_land_records(ctx: &mut TxContext) {
        let land_record = LandRecord {
            id: object::new(ctx),
            lands: table::new<u32, ID>(ctx),
        };
        transfer::share_object(land_record);
    }

    public fun occupy(land_record: &mut LandRecord, x:u16, y:u16, ctx: &mut TxContext) {
        let key: u32 = (x as u32) * 65536 + (y as u32);
        if (!table::contains<u32, ID>(&land_record.lands, key)) {
            let land = Land {
                id:object::new(ctx),
                owner:tx_context::sender(ctx),
                x:x,
                y:y,
            };
            table::add(&mut land_record.lands, key, object::uid_to_inner(&land.id));
            transfer::public_transfer(land, tx_context::sender(ctx));
        };
    }
}
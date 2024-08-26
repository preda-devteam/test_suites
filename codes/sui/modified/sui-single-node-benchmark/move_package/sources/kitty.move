#[allow(lint(self_transfer))]
module move_benchmark::KittyBreeding {
    use sui::address;
    // kitty
    public struct Kitty has key, store {
        id: UID,
        gene: Gene,
        matronId: ID,
        sireId: ID,
    }

    public struct Gene has key, store{
        id: UID,
        gene_id: u128,
    }

    public fun mint(gene_id: u128, ctx: &mut TxContext) {
        let address_0: address = address::from_u256(0);
        let id_0:ID = address_0.to_id();
        let gene = Gene {
            id:object::new(ctx),
            gene_id:gene_id,
        };
        let new_kitty = Kitty {
            id:object::new(ctx),
            gene,
            matronId:id_0,
            sireId:id_0,
        };
       
        transfer::public_transfer(new_kitty, tx_context::sender(ctx));
    }

    fun generate_gene(g0: u128, g1: u128): u128 {
        sqrt(g0) * sqrt(g1);
        sqrt(g0) * sqrt(g1);
        sqrt(g0) * sqrt(g1);
        sqrt(g0) * sqrt(g1);
        sqrt(g0) * sqrt(g1)
    }

    fun sqrt(x: u128): u128 {
        let mut z:u128 = (x + 1) / 2;
        let mut y:u128 = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        };
        y
    }

    public fun provide_gene(kitty:&Kitty, to:address, ctx: &mut TxContext) {
        let gene = Gene {
            id: object::new(ctx),
            gene_id: kitty.gene.gene_id,
        };
        transfer::public_transfer(gene, to);
    }

    public fun breed(gene:Gene, kitty:&Kitty, ctx: &mut TxContext) {
        let Gene {
            id,
            gene_id
        } = gene;
        let new_gene_id = generate_gene(kitty.gene.gene_id, gene_id);
        
        let new_gene = Gene {
            id: object::new(ctx),
            gene_id:new_gene_id,
        };
        let new_kitty = Kitty {
            id:object::new(ctx),
            gene:new_gene,
            matronId:object::uid_to_inner(&kitty.id),
            sireId:object::uid_to_inner(&id),
        };
        
        object::delete(id);
        transfer::public_transfer(new_kitty, tx_context::sender(ctx));
    }
    
}


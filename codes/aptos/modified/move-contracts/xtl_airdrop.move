module 0x1::xtl_airdrop {
    use std::signer;
    use std::vector;

    struct Coin has store {
        value: u64,
    }

    struct CoinStore has key{
        coin: Coin,
    }

    const AIRDROP_AMOUNT: u64 = 100;

    const THE_ACCOUNT_IS_NOT_EXISTED : u64 = 2;
    const INSUFFICIENT_BALANCE : u64 = 3;
    

    public entry fun initialize(addr: &signer ,amount : u64) {
        move_to<CoinStore>(addr, CoinStore{coin: Coin{value:amount}});
    }

    public entry fun transfer_n(from: &signer,recipients: vector<address>) acquires CoinStore {
       
        let len = vector::length(&recipients);
        let from_addr = signer::address_of(from);

        let balance = getBalance(from_addr);

        if(balance >= AIRDROP_AMOUNT * len){
            for(i in 0..len){
                let to = vector::borrow<address>(&recipients,i);
                let coin = withdraw(from_addr, AIRDROP_AMOUNT);
                deposit(*to, coin);
            };
        }
        
    }

    public fun getBalance(owner: address) : u64 acquires CoinStore{
        assert!(exists<CoinStore>(owner), THE_ACCOUNT_IS_NOT_EXISTED);
        borrow_global<CoinStore>(owner).coin.value
    }

    fun deposit(account_addr : address, coin : Coin) acquires CoinStore {
        assert!(exists<CoinStore>(account_addr), THE_ACCOUNT_IS_NOT_EXISTED);
        let balance = getBalance(account_addr);
        let balance_ref = &mut borrow_global_mut<CoinStore>(account_addr).coin.value;
        *balance_ref = balance + coin.value;
        let Coin { value:_ } = coin;
    }

    fun withdraw(account_addr : address, amount : u64) : Coin acquires CoinStore {
        assert!(exists<CoinStore>(account_addr), THE_ACCOUNT_IS_NOT_EXISTED);
        let balance = getBalance(account_addr);
        assert!(balance >= amount, INSUFFICIENT_BALANCE);
        let balance_ref = &mut borrow_global_mut<CoinStore>(account_addr).coin.value;
        *balance_ref = balance - amount;
        Coin { value: amount }
    }

}
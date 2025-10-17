cd src

echo "USDT01 replay job..."
# erc20 replay task
taskset -c 0 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_1_100000.csv" > ../result/USDT_2401_1_100000_1.log
taskset -c 0-1 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_1_100000.csv" > ../result/USDT_2401_1_100000_2.log
taskset -c 0-3 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_1_100000.csv" > ../result/USDT_2401_1_100000_4.log
taskset -c 0-7 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_1_100000.csv" > ../result/USDT_2401_1_100000_8.log
taskset -c 0-15 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_1_100000.csv" > ../result/USDT_2401_1_100000_16.log
taskset -c 0-31 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_1_100000.csv" > ../result/USDT_2401_1_100000_32.log
taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_1_100000.csv" > ../result/USDT_2401_1_100000_64.log


echo "eth02 replay job..."
# erc20 replay task
taskset -c 0 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_100001_200000.csv" > ../result/USDT_2401_100001_200000_1.log
taskset -c 0-1 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_100001_200000.csv" > ../result/USDT_2401_100001_200000_2.log
taskset -c 0-3 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_100001_200000.csv" > ../result/USDT_2401_100001_200000_4.log
taskset -c 0-7 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_100001_200000.csv" > ../result/USDT_2401_100001_200000_8.log
taskset -c 0-15 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_100001_200000.csv" > ../result/USDT_2401_100001_200000_16.log
taskset -c 0-31 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_100001_200000.csv" > ../result/USDT_2401_100001_200000_32.log
taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_100001_200000.csv" > ../result/USDT_2401_100001_200000_64.log

echo "eth03 replay job..."
# erc20 replay task
taskset -c 0 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_200001_300000.csv" > ../result/USDT_2401_200001_300000_1.log
taskset -c 0-1 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_200001_300000.csv" > ../result/USDT_2401_200001_300000_2.log
taskset -c 0-3 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_200001_300000.csv" > ../result/USDT_2401_200001_300000_4.log
taskset -c 0-7 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_200001_300000.csv" > ../result/USDT_2401_200001_300000_8.log
taskset -c 0-15 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_200001_300000.csv" > ../result/USDT_2401_200001_300000_16.log
taskset -c 0-31 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_200001_300000.csv" > ../result/USDT_2401_200001_300000_32.log
taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_200001_300000.csv" > ../result/USDT_2401_200001_300000_64.log

echo "eth04 replay job..."
# erc20 replay task
taskset -c 0 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_300001_400000.csv" > ../result/USDT_2401_300001_400000_1.log
taskset -c 0-1 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_300001_400000.csv" > ../result/USDT_2401_300001_400000_2.log
taskset -c 0-3 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_300001_400000.csv" > ../result/USDT_2401_300001_400000_4.log
taskset -c 0-7 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_300001_400000.csv" > ../result/USDT_2401_300001_400000_8.log
taskset -c 0-15 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_300001_400000.csv" > ../result/USDT_2401_300001_400000_16.log
taskset -c 0-31 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_300001_400000.csv" > ../result/USDT_2401_300001_400000_32.log
taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/USDT_2401_300001_400000.csv" > ../result/USDT_2401_300001_400000_64.log

# echo "eth02 replay job..."
# # erc20 replay task
# taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/ETH_2402_100000.csv" > ../result/02_eth_replay_64.log
# taskset -c 0 cargo run --release -- replay-erc20 --data-path "../data/ETH_2402_100000.csv" > ../result/02_eth_replay_1.log
# taskset -c 0-1 cargo run --release -- replay-erc20 --data-path "../data/ETH_2402_100000.csv" > ../result/02_eth_replay_2.log
# taskset -c 0-3 cargo run --release -- replay-erc20 --data-path "../data/ETH_2402_100000.csv" > ../result/02_eth_replay_4.log
# taskset -c 0-7 cargo run --release -- replay-erc20 --data-path "../data/ETH_2402_100000.csv" > ../result/02_eth_replay_8.log
# taskset -c 0-15 cargo run --release -- replay-erc20 --data-path "../data/ETH_2402_100000.csv" > ../result/02_eth_replay_16.log
# taskset -c 0-31 cargo run --release -- replay-erc20 --data-path "../data/ETH_2402_100000.csv" > ../result/02_eth_replay_32.log
# taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/ETH_2402_100000.csv" > ../result/02_eth_replay_64.log

# echo "eth03 replay job..."
# # erc20 replay task
# taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/ETH_2403_100000.csv" > ../result/03_eth_replay_64.log
# taskset -c 0 cargo run --release -- replay-erc20 --data-path "../data/ETH_2403_100000.csv" > ../result/03_eth_replay_1.log
# taskset -c 0-1 cargo run --release -- replay-erc20 --data-path "../data/ETH_2403_100000.csv" > ../result/03_eth_replay_2.log
# taskset -c 0-3 cargo run --release -- replay-erc20 --data-path "../data/ETH_2403_100000.csv" > ../result/03_eth_replay_4.log
# taskset -c 0-7 cargo run --release -- replay-erc20 --data-path "../data/ETH_2403_100000.csv" > ../result/03_eth_replay_8.log
# taskset -c 0-15 cargo run --release -- replay-erc20 --data-path "../data/ETH_2403_100000.csv" > ../result/03_eth_replay_16.log
# taskset -c 0-31 cargo run --release -- replay-erc20 --data-path "../data/ETH_2403_100000.csv" > ../result/03_eth_replay_32.log
# taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/ETH_2403_100000.csv" > ../result/03_eth_replay_64.log

# echo "eth04 replay job..."
# # erc20 replay task
# taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/ETH_2404_100000.csv" > ../result/04_eth_replay_64.log
# taskset -c 0 cargo run --release -- replay-erc20 --data-path "../data/ETH_2404_100000.csv" > ../result/04_eth_replay_1.log
# taskset -c 0-1 cargo run --release -- replay-erc20 --data-path "../data/ETH_2404_100000.csv" > ../result/04_eth_replay_2.log
# taskset -c 0-3 cargo run --release -- replay-erc20 --data-path "../data/ETH_2404_100000.csv" > ../result/04_eth_replay_4.log
# taskset -c 0-7 cargo run --release -- replay-erc20 --data-path "../data/ETH_2404_100000.csv" > ../result/04_eth_replay_8.log
# taskset -c 0-15 cargo run --release -- replay-erc20 --data-path "../data/ETH_2404_100000.csv" > ../result/04_eth_replay_16.log
# taskset -c 0-31 cargo run --release -- replay-erc20 --data-path "../data/ETH_2404_100000.csv" > ../result/04_eth_replay_32.log
# taskset -c 0-63 cargo run --release -- replay-erc20 --data-path "../data/ETH_2404_100000.csv" > ../result/04_eth_replay_64.log

# echo "eth replay job..."
# # erc20 replay task
# taskset -c 0 cargo run --release -- replay-erc20 > ../result/eth_replay_1.log
# taskset -c 0-1 cargo run --release -- replay-erc20 > ../result/eth_replay_2.log
# taskset -c 0-3 cargo run --release -- replay-erc20 > ../result/eth_replay_4.log
# taskset -c 0-7 cargo run --release -- replay-erc20 > ../result/eth_replay_8.log
# taskset -c 0-15 cargo run --release -- replay-erc20 > ../result/eth_replay_16.log
# taskset -c 0-31 cargo run --release -- replay-erc20 > ../result/eth_replay_32.log
# taskset -c 0-63 cargo run --release -- replay-erc20 > ../result/eth_replay_64.log

# echo "erc20 replay job..."
# # erc20 replay task
# taskset -c 0-63 cargo run --release -- replay-erc20 > ../result/erc20_replay_64.log
# taskset -c 0 cargo run --release -- replay-erc20 > ../result/erc20_replay_1.log
# taskset -c 0-1 cargo run --release -- replay-erc20 > ../result/erc20_replay_2.log
# taskset -c 0-3 cargo run --release -- replay-erc20 > ../result/erc20_replay_4.log
# taskset -c 0-7 cargo run --release -- replay-erc20 > ../result/erc20_replay_8.log
# taskset -c 0-15 cargo run --release -- replay-erc20 > ../result/erc20_replay_16.log
# taskset -c 0-31 cargo run --release -- replay-erc20 > ../result/erc20_replay_32.log


# sleep 5
# echo "erc20 transfer random job..."
# # erc20 random transfer task 10000 acc, 100000 txns
# taskset -c 0 cargo run --release -- param-sweep --num-accounts 10000 --block-sizes 100000 > ../result/erc20_1.log
# taskset -c 0-1 cargo run --release -- param-sweep --num-accounts 10000 --block-sizes 100000 > ../result/erc20_2.log
# taskset -c 0-3 cargo run --release -- param-sweep --num-accounts 10000 --block-sizes 100000 > ../result/erc20_4.log
# taskset -c 0-7 cargo run --release -- param-sweep --num-accounts 10000 --block-sizes 100000 > ../result/erc20_8.log
# taskset -c 0-15 cargo run --release -- param-sweep --num-accounts 10000 --block-sizes 100000 > ../result/erc20_16.log
# taskset -c 0-31 cargo run --release -- param-sweep --num-accounts 10000 --block-sizes 100000 > ../result/erc20_32.log
# taskset -c 0-63 cargo run --release -- param-sweep --num-accounts 10000 --block-sizes 100000 > ../result/erc20_64.log

# sleep 5
# echo "airdrop job..."
# # airdrop task 10000 acc, 100000 txns
# taskset -c 0 cargo run --release -- airdrop --num-accounts 10000 --num-transactions 100000  > ../result/airdrop_1.log
# taskset -c 0-1 cargo run --release -- airdrop --num-accounts 10000 --num-transactions 100000  > ../result/airdrop_2.log
# taskset -c 0-3 cargo run --release -- airdrop --num-accounts 10000 --num-transactions 100000  > ../result/airdrop_4.log
# taskset -c 0-7 cargo run --release -- airdrop --num-accounts 10000 --num-transactions 100000  > ../result/airdrop_8.log
# taskset -c 0-15 cargo run --release -- airdrop --num-accounts 10000 --num-transactions 100000  > ../result/airdrop_16.log
# taskset -c 0-31 cargo run --release -- airdrop --num-accounts 10000 --num-transactions 100000  > ../result/airdrop_32.log
# taskset -c 0-63 cargo run --release -- airdrop --num-accounts 10000 --num-transactions 100000  > ../result/airdrop_64.log


# sleep 5
# echo "ballot job..."
# # ballot task 100000 acc, 100000 txns
# taskset -c 0 cargo run --release -- ballot --num-accounts 100000 --num-transactions 100000  > ../result/ballot_1.log
# taskset -c 0-1 cargo run --release -- ballot --num-accounts 100000 --num-transactions 100000  > ../result/ballot_2.log
# taskset -c 0-3 cargo run --release -- ballot --num-accounts 100000 --num-transactions 100000  > ../result/ballot_4.log
# taskset -c 0-7 cargo run --release -- ballot --num-accounts 100000 --num-transactions 100000 > ../result/ballot_8.log
# taskset -c 0-15 cargo run --release -- ballot --num-accounts 100000 --num-transactions 100000 > ../result/ballot_16.log
# taskset -c 0-31 cargo run --release -- ballot --num-accounts 100000 --num-transactions 100000 > ../result/ballot_32.log
# taskset -c 0-63 cargo run --release -- ballot --num-accounts 100000 --num-transactions 100000 > ../result/ballot_64.log

# # # sleep 5
# echo "ballot sharding job..."
# # ballot sharding task 100000 acc, 100000 txns
# taskset -c 0 cargo run --release -- ballot-sharding --num-accounts 100000 --num-transactions 100000 --num-shardings 1 > ../result/ballot_sharding_1.log
# taskset -c 0-1 cargo run --release -- ballot-sharding --num-accounts 100000 --num-transactions 100000 --num-shardings 2 > ../result/ballot_sharding_2.log
# taskset -c 0-3 cargo run --release -- ballot-sharding --num-accounts 100000 --num-transactions 100000 --num-shardings 4 > ../result/ballot_sharding_4.log
# taskset -c 0-7 cargo run --release -- ballot-sharding --num-accounts 100000 --num-transactions 100000 --num-shardings 8 > ../result/ballot_sharding_8.log
# taskset -c 0-15 cargo run --release -- ballot-sharding --num-accounts 100000 --num-transactions 100000 --num-shardings 16 > ../result/ballot_sharding_16.log
# taskset -c 0-31 cargo run --release -- ballot-sharding --num-accounts 100000 --num-transactions 100000 --num-shardings 32 > ../result/ballot_sharding_32.log
# taskset -c 0-63 cargo run --release -- ballot-sharding --num-accounts 100000 --num-transactions 100000 --num-shardings 64 > ../result/ballot_sharding_64.log


# # # sleep 5
# echo "kitty job..."
# # kitty task 1000 acc, 10000 txns
# taskset -c 0-63 cargo run --release -- kitty --num-accounts 1001 --num-transactions 10000 > ../result/kitty_64.log
# taskset -c 0 cargo run --release -- kitty --num-accounts 1001 --num-transactions 10000  > ../result/kitty_1.log
# taskset -c 0-1 cargo run --release -- kitty --num-accounts 1001 --num-transactions 10000  > ../result/kitty_2.log
# taskset -c 0-3 cargo run --release -- kitty --num-accounts 1001 --num-transactions 10000  > ../result/kitty_4.log
# taskset -c 0-7 cargo run --release -- kitty --num-accounts 1001 --num-transactions 10000 > ../result/kitty_8.log
# taskset -c 0-15 cargo run --release -- kitty --num-accounts 1001 --num-transactions 10000 > ../result/kitty_16.log
# taskset -c 0-31 cargo run --release -- kitty --num-accounts 1001 --num-transactions 10000 > ../result/kitty_32.log
# taskset -c 0-63 cargo run --release -- kitty --num-accounts 1001 --num-transactions 10000 > ../result/kitty_64.log


# # sleep 5
# echo "mp job..."
# # million pixel task 1000 acc, 10000 txns
# taskset -c 0 cargo run --release -- million-pixel --num-accounts 1001 --num-transactions 10000  > ../result/million_pixel_1.log
# taskset -c 0-1 cargo run --release -- million-pixel --num-accounts 1001 --num-transactions 10000  > ../result/million_pixel_2.log
# taskset -c 0-3 cargo run --release -- million-pixel --num-accounts 1001 --num-transactions 10000  > ../result/million_pixel_4.log
# taskset -c 0-7 cargo run --release -- million-pixel --num-accounts 1001 --num-transactions 10000 > ../result/million_pixel_8.log
# taskset -c 0-15 cargo run --release -- million-pixel --num-accounts 1001 --num-transactions 10000 > ../result/million_pixel_16.log
# taskset -c 0-31 cargo run --release -- million-pixel --num-accounts 1001 --num-transactions 10000 > ../result/million_pixel_32.log
# taskset -c 0-63 cargo run --release -- million-pixel --num-accounts 1001 --num-transactions 10000 > ../result/million_pixel_64.log


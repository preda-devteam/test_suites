package main

import (
	"fmt"
	"math/big"
	"math/rand"
	"os"
	"runtime"
	"runtime/pprof"
	"time"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/vm"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/airdrop"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/ballot"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/kitty"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/million_pixel"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/mytoken"
	"github.com/sei-protocol/sei-chain/occ_tests/messages"
	"github.com/sei-protocol/sei-chain/occ_tests/utils"
	utils2 "github.com/sei-protocol/sei-chain/utils"
	"github.com/sei-protocol/sei-chain/x/evm/state"
	xtypes "github.com/sei-protocol/sei-chain/x/evm/types"
	"github.com/tendermint/tendermint/abci/types"
)

var runs = 1

type CaseRun struct {
	name    string
	runs    int
	shuffle bool
	before  func(tCtx *utils.TestContext)
	txs     func(tCtx *utils.TestContext) []*utils.TestMessage
}

func parseResult(res *types.ExecTxResult) xtypes.MsgEVMTransactionResponse {
	var xRes xtypes.MsgEVMTransactionResponse
	var txMsgData sdk.TxMsgData
	txMsgData.Unmarshal(res.Data)
	if len(txMsgData.GetData()) == 0 {
		fmt.Println(res)
	}
	xRes.Unmarshal(txMsgData.GetData()[0].Data)
	return xRes
}

func DeployAirdropContract(tCtx *utils.TestContext) {
	fmt.Println(tCtx.TestAccounts[0].EvmAddress)
	evmkeeper := tCtx.TestApp.EvmKeeper
	db := state.NewDBImpl(tCtx.Ctx, &evmkeeper, false)
	gp := evmkeeper.GetGasPool()
	blockCtx, err := evmkeeper.GetVMBlockContext(tCtx.Ctx, gp)
	if err != nil {
		panic(err)
	}
	cfg := xtypes.DefaultChainConfig().EthereumConfig(evmkeeper.ChainID(tCtx.Ctx))
	evm := vm.NewEVM(*blockCtx, vm.TxContext{}, db, cfg, vm.Config{})

	_, addr, _, err := evm.Create(vm.AccountRef(tCtx.TestAccounts[0].EvmAddress), airdrop.GetBin(), 10000000, utils2.Big0)
	if err != nil {
		panic(err)
	}
	messages.ContractAddress["airdrop"] = addr
	messages.NonceMap[0] = 1
	fmt.Println("deploy airdrop contract finished, address: ", addr, "code hash: ", db.GetCodeHash(addr))
	//deposit
	fmt.Println("deposit for all accounts...")
	contractAbi := airdrop.GetParsedABI()
	for i := 0; i < len(tCtx.TestAccounts); i++ {
		calldata, err := contractAbi.Pack("_deposit", tCtx.TestAccounts[i].EvmAddress, big.NewInt(1000000000))
		if err != nil {
			panic(err)
		}
		// st := time.Now()
		_, _, err = evm.Call(vm.AccountRef(tCtx.TestAccounts[i].EvmAddress), addr, calldata, uint64(1000000), big.NewInt(0))
		// fmt.Println(time.Since(st))
		if err != nil {
			panic(err)
		}
	}
	_, err = db.Finalize()
	if err != nil {
		panic(err)
	}
	fmt.Println("deposit for all accounts finish.")
}

func DeployBallotContract(tCtx *utils.TestContext) {
	fmt.Println(tCtx.TestAccounts[0].EvmAddress)
	evmkeeper := tCtx.TestApp.EvmKeeper
	db := state.NewDBImpl(tCtx.Ctx, &evmkeeper, false)
	gp := evmkeeper.GetGasPool()
	blockCtx, err := evmkeeper.GetVMBlockContext(tCtx.Ctx, gp)
	if err != nil {
		panic(err)
	}
	cfg := xtypes.DefaultChainConfig().EthereumConfig(evmkeeper.ChainID(tCtx.Ctx))
	evm := vm.NewEVM(*blockCtx, vm.TxContext{}, db, cfg, vm.Config{})

	_, addr, _, err := evm.Create(vm.AccountRef(tCtx.TestAccounts[0].EvmAddress), ballot.GetBin(), 10000000, utils2.Big0)
	if err != nil {
		panic(err)
	}
	messages.ContractAddress["ballot"] = addr
	messages.NonceMap[0] = 1
	fmt.Println("deploy ballot contract finished, address: ", addr, "code hash: ", db.GetCodeHash(addr))
	//
	contractAbi := ballot.GetParsedABI()
	fmt.Println("set for all accounts...")
	for i := 0; i < len(tCtx.TestAccounts); i++ {
		calldata, err := contractAbi.Pack("set", tCtx.TestAccounts[i].EvmAddress, uint64(1), uint32(0))
		if err != nil {
			panic(err)
		}
		// st := time.Now()
		_, _, err = evm.Call(vm.AccountRef(tCtx.TestAccounts[i].EvmAddress), addr, calldata, uint64(1000000), big.NewInt(0))
		// fmt.Println(time.Since(st))
		if err != nil {
			panic(err)
		}
	}
	fmt.Println("set for all accounts finish.")
	fmt.Println("init for ballot...")
	proposals := []string{"aaa", "bbb", "ccc"}
	calldata, err := contractAbi.Pack("init", tCtx.TestAccounts[0].EvmAddress, proposals)
	if err != nil {
		panic(err)
	}
	// st := time.Now()
	_, _, err = evm.Call(vm.AccountRef(tCtx.TestAccounts[0].EvmAddress), addr, calldata, uint64(1000000), big.NewInt(0))
	// fmt.Println(time.Since(st))
	if err != nil {
		panic(err)
	}
	_, err = db.Finalize()
	if err != nil {
		panic(err)
	}
	fmt.Println("init for ballot finish.")
}

func DeployMytokenContract(tCtx *utils.TestContext) {
	evmkeeper := tCtx.TestApp.EvmKeeper
	db := state.NewDBImpl(tCtx.Ctx, &evmkeeper, false)
	gp := evmkeeper.GetGasPool()
	blockCtx, err := evmkeeper.GetVMBlockContext(tCtx.Ctx, gp)
	if err != nil {
		panic(err)
	}
	cfg := xtypes.DefaultChainConfig().EthereumConfig(evmkeeper.ChainID(tCtx.Ctx))
	evm := vm.NewEVM(*blockCtx, vm.TxContext{}, db, cfg, vm.Config{})
	_, addr, _, err := evm.Create(vm.AccountRef(tCtx.TestAccounts[0].EvmAddress), mytoken.GetBin(), 10000000, utils2.Big0)
	if err != nil {
		panic(err)
	}
	messages.ContractAddress["mytoken"] = addr
	messages.NonceMap[0] = 1
	fmt.Println("deploy mytoken contract finished, address: ", addr)
	//mint
	fmt.Println("mint for all accounts...")
	contractAbi := mytoken.GetParsedABI()
	mStart := time.Now()
	for i := 0; i < len(tCtx.TestAccounts); i++ {
		calldata, err := contractAbi.Pack("_deposit", tCtx.TestAccounts[i].EvmAddress, big.NewInt(1000000000))
		if err != nil {
			panic(err)
		}
		// st := time.Now()
		_, _, err = evm.Call(vm.AccountRef(tCtx.TestAccounts[i].EvmAddress), addr, calldata, uint64(1000000), big.NewInt(0))
		// fmt.Println(time.Since(st))
		if err != nil {
			panic(err)
		}
	}
	wTime := time.Now()
	_, err = db.Finalize()
	fmt.Println("mint finish: ", time.Since(mStart), "write db: ", time.Since(wTime))
	if err != nil {
		panic(err)
	}
	fmt.Println("mint for all accounts finish.")
}

func DeployKittyContract(tCtx *utils.TestContext) {
	evmkeeper := tCtx.TestApp.EvmKeeper
	db := state.NewDBImpl(tCtx.Ctx, &evmkeeper, false)
	gp := evmkeeper.GetGasPool()
	blockCtx, err := evmkeeper.GetVMBlockContext(tCtx.Ctx, gp)
	if err != nil {
		panic(err)
	}
	cfg := xtypes.DefaultChainConfig().EthereumConfig(evmkeeper.ChainID(tCtx.Ctx))
	evm := vm.NewEVM(*blockCtx, vm.TxContext{}, db, cfg, vm.Config{})

	_, addr, _, err := evm.Create(vm.AccountRef(tCtx.TestAccounts[0].EvmAddress), kitty.GetBin(), 10000000, utils2.Big0)
	if err != nil {
		panic(err)
	}
	messages.ContractAddress["kitty"] = addr
	messages.NonceMap[0] = 1
	fmt.Println("deploy kitty contract finished, address: ", addr)
	//mint
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	fmt.Println("mint for all accounts...")
	contractAbi := kitty.GetParsedABI()
	mStart := time.Now()
	for i := 0; i < len(tCtx.TestAccounts); i++ {
		calldata, err := contractAbi.Pack("mint", tCtx.TestAccounts[i].EvmAddress, big.NewInt(int64(r.Intn(10000))), true)
		if err != nil {
			panic(err)
		}
		// st := time.Now()
		_, _, err = evm.Call(vm.AccountRef(tCtx.TestAccounts[i].EvmAddress), addr, calldata, uint64(1000000), big.NewInt(0))
		// fmt.Println(time.Since(st))
		if err != nil {
			panic(err)
		}
	}
	for i := 0; i < len(tCtx.TestAccounts); i++ {
		calldata, err := contractAbi.Pack("mint", tCtx.TestAccounts[i].EvmAddress, big.NewInt(int64(r.Intn(10000))), false)
		if err != nil {
			panic(err)
		}
		// st := time.Now()
		_, _, err = evm.Call(vm.AccountRef(tCtx.TestAccounts[i].EvmAddress), addr, calldata, uint64(1000000), big.NewInt(0))
		// fmt.Println(time.Since(st))
		if err != nil {
			panic(err)
		}
	}
	wTime := time.Now()
	_, err = db.Finalize()
	fmt.Println("mint finish: ", time.Since(mStart), "write db: ", time.Since(wTime))
	if err != nil {
		panic(err)
	}
	fmt.Println("mint for all accounts finish.")
}

func DeployMillionPixelContract(tCtx *utils.TestContext) {
	evmkeeper := tCtx.TestApp.EvmKeeper
	db := state.NewDBImpl(tCtx.Ctx, &evmkeeper, false)
	gp := evmkeeper.GetGasPool()
	blockCtx, err := evmkeeper.GetVMBlockContext(tCtx.Ctx, gp)
	if err != nil {
		panic(err)
	}
	cfg := xtypes.DefaultChainConfig().EthereumConfig(evmkeeper.ChainID(tCtx.Ctx))
	evm := vm.NewEVM(*blockCtx, vm.TxContext{}, db, cfg, vm.Config{})

	_, addr, _, err := evm.Create(vm.AccountRef(tCtx.TestAccounts[0].EvmAddress), million_pixel.GetBin(), 10000000, utils2.Big0)
	if err != nil {
		panic(err)
	}
	messages.ContractAddress["million_pixel"] = addr
	messages.NonceMap[0] = 1
	_, err = db.Finalize()
	if err != nil {
		panic(err)
	}
	fmt.Println("deploy million_pixel contract finished, address: ", addr)
}

func getCaseRun(name string, count int) (CaseRun, error) {
	switch name {
	case "airdrop":
		return CaseRun{
			name:   "Test airdrop(evm) for random",
			runs:   runs,
			before: DeployAirdropContract,
			txs: func(tCtx *utils.TestContext) []*utils.TestMessage {
				return utils.JoinMsgs(
					messages.AirdropMsgForEVM(tCtx, count),
				)
			},
		}, nil
	case "ballot":
		return CaseRun{
			name:   "Test ballot(evm) for random",
			runs:   runs,
			before: DeployBallotContract,
			txs: func(tCtx *utils.TestContext) []*utils.TestMessage {
				return utils.JoinMsgs(
					messages.BallotMsgForEVM(tCtx, count),
				)
			},
		}, nil
	case "mytoken":
		return CaseRun{
			name:   "Test mytoken(evm) for random",
			runs:   runs,
			before: DeployMytokenContract,
			txs: func(tCtx *utils.TestContext) []*utils.TestMessage {
				return utils.JoinMsgs(
					messages.MytokenMsgForEVM(tCtx, count),
				)
			},
		}, nil
	case "kitty":
		return CaseRun{
			name:   "Test kitty(evm) for random",
			runs:   runs,
			before: DeployKittyContract,
			txs: func(tCtx *utils.TestContext) []*utils.TestMessage {
				return utils.JoinMsgs(
					messages.KittyMsgForEVM(tCtx, count),
				)
			},
		}, nil
	case "million_pixel":
		return CaseRun{
			name:   "Test million pixel(evm) for random",
			runs:   runs,
			before: DeployMillionPixelContract,
			txs: func(tCtx *utils.TestContext) []*utils.TestMessage {
				return utils.JoinMsgs(
					messages.MillionPixelMsgForEVM(tCtx, count),
				)
			},
		}, nil
	case "replay":
		return CaseRun{
			name:   "Test eth replay(evm) for historical",
			runs:   runs,
			before: DeployMytokenContract,
			txs: func(tCtx *utils.TestContext) []*utils.TestMessage {
				return utils.JoinMsgs(
					messages.EthHitoricalMsgReplayForEVM(tCtx, "../data/ETH_202401_10000.csv"),
				)
			},
		}, nil
	default:
		return CaseRun{}, fmt.Errorf("invalid parameters")

	}
}

func getERC20Balance(ctx *utils.TestContext, user common.Address) (int64, error) {
	evmkeeper := ctx.TestApp.EvmKeeper
	db := state.NewDBImpl(ctx.Ctx, &evmkeeper, false)
	gp := evmkeeper.GetGasPool()
	blockCtx, err := evmkeeper.GetVMBlockContext(ctx.Ctx, gp)
	if err != nil {
		panic(err)
	}
	cfg := xtypes.DefaultChainConfig().EthereumConfig(evmkeeper.ChainID(ctx.Ctx))
	evm := vm.NewEVM(*blockCtx, vm.TxContext{}, db, cfg, vm.Config{})

	contractAbi := mytoken.GetParsedABI()
	calldata, err := contractAbi.Pack("balance", user)
	if err != nil {
		panic(err)
	}
	// st := time.Now()
	res, _, err := evm.Call(vm.AccountRef(user), messages.ContractAddress["mytoken"], calldata, uint64(1000000), big.NewInt(0))
	// fmt.Println(time.Since(st))
	if err != nil {
		panic(err)
	}

	var balance *big.Int
	err = contractAbi.UnpackIntoInterface(&balance, "balance", res)
	if err != nil {
		panic(err)
	}
	return balance.Int64(), nil
}

func main() {

	mf, _ := os.OpenFile("mem.profile", os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0644)
	cf, _ := os.OpenFile("cpu.profile", os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0644)
	defer mf.Close()
	defer cf.Close()
	pprof.StartCPUProfile(cf)
	defer pprof.StopCPUProfile()

	args := os.Args
	if len(args) < 2 {
		fmt.Println("parameters must be specified :[airdrop/ballot/erc20/replay/kitty/million_pixel/all]")
		os.Exit(0)
	}

	tcName := args[1]

	accNum := 1000
	debug := false
	sequential := false
	batches := 10
	totalTxCount := 10000

	accts := utils.NewTestAccounts(accNum)
	if tcName == "replay" {
		accts = utils.NewTestAccounts(11000)
	}
	if tcName == "kitty" {
		accts = utils.NewTestAccounts(100)
	}
	//sequential
	var sResults []*types.ExecTxResult
	var sCtx *utils.TestContext
	if sequential {
		fmt.Println("sequential execution...")
		sCtx = utils.NewContext(accts, 1, false)

		tt, err := getCaseRun(tcName, totalTxCount)
		if err != nil {
			panic(err)
		}
		if tt.before != nil {
			tt.before(sCtx)
		}
		txs := tt.txs(sCtx)
		if tt.shuffle {
			txs = utils.Shuffle(txs)
		}
		_, sResults, _, _ = utils.RunWithoutOCC(sCtx, txs)
		if debug {
			for _, res := range sResults {
				xres := parseResult(res)
				fmt.Println("==============================")
				fmt.Println("code:", res.Code)
				fmt.Printf("res data: %+v\n", xres)
				fmt.Println("EvmTxInfo:", res.EvmTxInfo)
				fmt.Println("log:", res.Log)
			}
		}
	}

	//parallel test
	fmt.Println("parallel units: ", runtime.GOMAXPROCS(0))
	ctx := utils.NewContext(accts, runtime.GOMAXPROCS(0), true)

	tt, err := getCaseRun(tcName, totalTxCount/batches)
	if err != nil {
		panic(err)
	}
	if tt.before != nil {
		tt.before(ctx)
	}

	var replayTxs []*utils.TestMessage
	if tcName == "replay"{
		replayTxs = tt.txs(ctx)
	}
	// for i := 0; i < len(ctx.TestAccounts); i++ {
	// 	balance, err := getERC20Balance(ctx, ctx.TestAccounts[i].EvmAddress)
	// 	if err != nil {
	// 		panic(err)
	// 	}
	// 	fmt.Println("addr: ", ctx.TestAccounts[i].EvmAddress, " balance: ", balance)
	// }

	for j := 0; j < batches; j++ {
		//simulate every blocks
		txs := tt.txs(ctx)
		if tcName == "replay" {
			txs = replayTxs[j*totalTxCount/batches:(j+1)*totalTxCount/batches]
		}
		_, pResults, _, _ := utils.RunWithOCC(ctx, txs)
		ctx.Ctx.MultiStore().(sdk.CacheMultiStore).Write()
		if debug {
			for _, res := range pResults {
				xres := parseResult(res)
				fmt.Println("==============================")
				fmt.Println("code:", res.Code)
				fmt.Printf("res data: %+v\n", xres)
				fmt.Println("EvmTxInfo:", res.EvmTxInfo)
				fmt.Println("log:", res.Log)
			}
		}
		// for i := 0; i < len(ctx.TestAccounts); i++ {
		// 	balance, err := getERC20Balance(ctx, ctx.TestAccounts[i].EvmAddress)
		// 	if err != nil {
		// 		panic(err)
		// 	}
		// 	fmt.Println("addr: ", ctx.TestAccounts[i].EvmAddress, " balance: ", balance)
		// }
	}

	pprof.WriteHeapProfile(mf)
}

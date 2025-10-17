package messages

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"math/big"
	"math/rand"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"time"

	"github.com/CosmWasm/wasmd/x/wasm"
	banktypes "github.com/cosmos/cosmos-sdk/x/bank/types"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"
	"github.com/ethereum/go-ethereum/common"
	ethtypes "github.com/ethereum/go-ethereum/core/types"

	"github.com/sei-protocol/sei-chain/occ_tests/contracts/airdrop"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/ballot"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/kitty"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/million_pixel"
	"github.com/sei-protocol/sei-chain/occ_tests/contracts/mytoken"
	"github.com/sei-protocol/sei-chain/occ_tests/utils"
	"github.com/sei-protocol/sei-chain/x/evm/config"
	"github.com/sei-protocol/sei-chain/x/evm/types"
	"github.com/sei-protocol/sei-chain/x/evm/types/ethtx"
)

const instantiateMsg = `{"whitelist": ["sei1h9yjz89tl0dl6zu65dpxcqnxfhq60wxx8s5kag"],
    "use_whitelist":false,"admin":"sei1h9yjz89tl0dl6zu65dpxcqnxfhq60wxx8s5kag",
	"limit_order_fee":{"decimal":"0.0001","negative":false},
	"market_order_fee":{"decimal":"0.0001","negative":false},
	"liquidation_order_fee":{"decimal":"0.0001","negative":false},
	"margin_ratio":{"decimal":"0.0625","negative":false},
	"max_leverage":{"decimal":"4","negative":false},
	"default_base":"USDC",
	"native_token":"USDC","denoms": ["SEI","ATOM","USDC","SOL","ETH","OSMO","AVAX","BTC"],
	"full_denom_mapping": [["usei","SEI","0.000001"],["uatom","ATOM","0.000001"],["uusdc","USDC","0.000001"]],
	"funding_payment_lookback":3600,"spot_market_contract":"sei1h9yjz89tl0dl6zu65dpxcqnxfhq60wxx8s5kag",
	"supported_collateral_denoms": ["USDC"],
	"supported_multicollateral_denoms": ["ATOM"],
	"oracle_denom_mapping": [["usei","SEI","1"],["uatom","ATOM","1"],["uusdc","USDC","1"],["ueth","ETH","1"]],
	"multicollateral_whitelist": ["sei1h9yjz89tl0dl6zu65dpxcqnxfhq60wxx8s5kag"],
	"multicollateral_whitelist_enable": true,
	"funding_payment_pairs": [["USDC","ETH"]],
	"default_margin_ratios":{
		"initial":"0.3",
		"partial":"0.25",
		"maintenance":"0.06"
	}}`

func WasmInstantiate(tCtx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	for i := 0; i < count; i++ {
		msgs = append(msgs, &utils.TestMessage{
			Msg: &wasm.MsgInstantiateContract{
				Sender: tCtx.TestAccounts[0].AccountAddress.String(),
				Admin:  tCtx.TestAccounts[1].AccountAddress.String(),
				CodeID: tCtx.CodeID,
				Label:  fmt.Sprintf("test-%d", i),
				Msg:    []byte(instantiateMsg),
				Funds:  utils.Funds(100000),
			},
			Type: "WasmInstantitate",
		})
	}
	return msgs
}

// ////////////////////////////////////////////////////////////////////////////////////
var (
	NonceMap        = make(map[int]uint64)
	ContractAddress = make(map[string]common.Address)
)

// compare sei-occ with aptos,crystality,sui, here are some transaction builder
func AirdropMsgForEVM(ctx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	contractAbi := airdrop.GetParsedABI()
	type Payment struct {
		To     common.Address
		Amount *big.Int
	}
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for i := 0; i < count; i++ {
		//build msg
		fromIndex := r.Intn(len(ctx.TestAccounts))
		from := ctx.TestAccounts[fromIndex]
		recipients := []Payment{
			{To: ctx.TestAccounts[r.Intn(len(ctx.TestAccounts))].EvmAddress, Amount: big.NewInt(100)},
			{To: ctx.TestAccounts[r.Intn(len(ctx.TestAccounts))].EvmAddress, Amount: big.NewInt(100)},
			{To: ctx.TestAccounts[r.Intn(len(ctx.TestAccounts))].EvmAddress, Amount: big.NewInt(100)},
			{To: ctx.TestAccounts[r.Intn(len(ctx.TestAccounts))].EvmAddress, Amount: big.NewInt(100)},
			{To: ctx.TestAccounts[r.Intn(len(ctx.TestAccounts))].EvmAddress, Amount: big.NewInt(100)},
		}
		calldata, err := contractAbi.Pack("transfer_n", from.EvmAddress, recipients)
		if err != nil {
			log.Fatal(err)
		}
		nonce, ok := NonceMap[fromIndex]
		if ok {
			NonceMap[fromIndex]++
		} else {
			NonceMap[fromIndex] = 1
			nonce = 0
		}
		ca, ok := ContractAddress["airdrop"]
		if !ok {
			panic("contract should deploy first")
		}
		signedTx, err := ethtypes.SignTx(ethtypes.NewTx(&ethtypes.DynamicFeeTx{
			GasFeeCap: new(big.Int).SetUint64(1000000000000),
			GasTipCap: new(big.Int).SetUint64(1000000000000),
			Gas:       1000000,
			ChainID:   big.NewInt(config.DefaultChainID),
			To:        &ca,
			Value:     big.NewInt(0),
			Data:      calldata,
			Nonce:     nonce,
		}), from.EvmSigner, from.EvmPrivateKey)
		if err != nil {
			panic(err)
		}

		txData, err := ethtx.NewTxDataFromTx(signedTx)
		if err != nil {
			panic(err)
		}

		msg, err := types.NewMsgEVMTransaction(txData)
		if err != nil {
			panic(err)
		}
		msgs = append(msgs, &utils.TestMessage{
			Msg:       msg,
			IsEVM:     true,
			EVMSigner: from,
			Type:      "EVM Airdrop",
		})
	}
	return msgs
}

func BallotMsgForEVM(ctx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	contractAbi := ballot.GetParsedABI()
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for i := 0; i < count; i++ {
		//build msg
		calldata, err := contractAbi.Pack("vote", ctx.TestAccounts[i].EvmAddress, uint32(r.Intn(3)), uint32(1))
		if err != nil {
			log.Fatal(err)
		}
		nonce, ok := NonceMap[i]
		if ok {
			NonceMap[i]++
		} else {
			NonceMap[i] = 1
			nonce = 0
		}
		ca, ok := ContractAddress["ballot"]
		if !ok {
			panic("contract should deploy first")
		}
		signedTx, err := ethtypes.SignTx(ethtypes.NewTx(&ethtypes.DynamicFeeTx{
			GasFeeCap: new(big.Int).SetUint64(1000000000000),
			GasTipCap: new(big.Int).SetUint64(1000000000000),
			Gas:       1000000,
			ChainID:   big.NewInt(config.DefaultChainID),
			To:        &ca,
			Value:     big.NewInt(0),
			Data:      calldata,
			Nonce:     nonce,
		}), ctx.TestAccounts[i].EvmSigner, ctx.TestAccounts[i].EvmPrivateKey)
		if err != nil {
			panic(err)
		}

		txData, err := ethtx.NewTxDataFromTx(signedTx)
		if err != nil {
			panic(err)
		}

		msg, err := types.NewMsgEVMTransaction(txData)
		if err != nil {
			panic(err)
		}
		msgs = append(msgs, &utils.TestMessage{
			Msg:       msg,
			IsEVM:     true,
			EVMSigner: ctx.TestAccounts[i],
			Type:      "EVM Ballot",
		})
	}
	return msgs
}

func MytokenMsgForEVM(ctx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	contractAbi := mytoken.GetParsedABI()

	//for profile
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		panic("Error getting current file path")
	}
	currentDir := filepath.Dir(filename)
	filePath := filepath.Join(currentDir, "ERC20.Random.csv")
	file, err := os.OpenFile(filePath, os.O_CREATE|os.O_RDWR|os.O_APPEND, 0644)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for i := 0; i < count; i++ {
		//build msg
		fromIndex := r.Intn(len(ctx.TestAccounts))
		from := ctx.TestAccounts[fromIndex]
		toIndex := r.Intn(len(ctx.TestAccounts))
		to := ctx.TestAccounts[toIndex]
		amount := big.NewInt(1000)
		calldata, err := contractAbi.Pack("transfer", from.EvmAddress, to.EvmAddress, amount)
		if err != nil {
			log.Fatal(err)
		}
		nonce, ok := NonceMap[fromIndex]
		if ok {
			NonceMap[fromIndex]++
		} else {
			NonceMap[fromIndex] = 1
			nonce = 0
		}
		ca, ok := ContractAddress["mytoken"]
		if !ok {
			panic("contract should deploy first")
		}
		signedTx, err := ethtypes.SignTx(ethtypes.NewTx(&ethtypes.DynamicFeeTx{
			GasFeeCap: new(big.Int).SetUint64(1000000000000),
			GasTipCap: new(big.Int).SetUint64(1000000000000),
			Gas:       1000000,
			ChainID:   big.NewInt(config.DefaultChainID),
			To:        &ca,
			Value:     big.NewInt(0),
			Data:      calldata,
			Nonce:     nonce,
		}), from.EvmSigner, from.EvmPrivateKey)
		if err != nil {
			panic(err)
		}

		txData, err := ethtx.NewTxDataFromTx(signedTx)
		if err != nil {
			panic(err)
		}

		msg, err := types.NewMsgEVMTransaction(txData)
		if err != nil {
			panic(err)
		}
		msgs = append(msgs, &utils.TestMessage{
			Msg:       msg,
			IsEVM:     true,
			EVMSigner: ctx.TestAccounts[fromIndex],
			Type:      "EVM Mytoken",
		})

		file.WriteString(fmt.Sprintf("%d,%d,%v\n", fromIndex, toIndex, amount))
	}
	file.WriteString(fmt.Sprintf("txns: %d\n====================================\n", count))
	return msgs
}

func KittyMsgForEVM(ctx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	contractAbi := kitty.GetParsedABI()
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for i := 0; i < count; i++ {
		//build msg
		fromIndex := r.Intn(len(ctx.TestAccounts))
		from := ctx.TestAccounts[fromIndex]
		calldata, err := contractAbi.Pack("breed", from.EvmAddress, big.NewInt(int64(r.Intn(100))), big.NewInt(int64(r.Intn(100)+100)), false)
		if err != nil {
			log.Fatal(err)
		}
		nonce, ok := NonceMap[fromIndex]
		if ok {
			NonceMap[fromIndex]++
		} else {
			NonceMap[fromIndex] = 1
			nonce = 0
		}
		ca, ok := ContractAddress["kitty"]
		if !ok {
			panic("contract should deploy first")
		}
		signedTx, err := ethtypes.SignTx(ethtypes.NewTx(&ethtypes.DynamicFeeTx{
			GasFeeCap: new(big.Int).SetUint64(1000000000000),
			GasTipCap: new(big.Int).SetUint64(1000000000000),
			Gas:       1000000,
			ChainID:   big.NewInt(config.DefaultChainID),
			To:        &ca,
			Value:     big.NewInt(0),
			Data:      calldata,
			Nonce:     nonce,
		}), from.EvmSigner, from.EvmPrivateKey)
		if err != nil {
			panic(err)
		}

		txData, err := ethtx.NewTxDataFromTx(signedTx)
		if err != nil {
			panic(err)
		}

		msg, err := types.NewMsgEVMTransaction(txData)
		if err != nil {
			panic(err)
		}
		msgs = append(msgs, &utils.TestMessage{
			Msg:       msg,
			IsEVM:     true,
			EVMSigner: ctx.TestAccounts[fromIndex],
			Type:      "EVM Kitty",
		})
	}
	return msgs
}

func MillionPixelMsgForEVM(ctx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	contractAbi := million_pixel.GetParsedABI()
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for i := 0; i < count; i++ {
		//build msg
		from := ctx.TestAccounts[i]

		calldata, err := contractAbi.Pack("occupy", from.EvmAddress, uint16(r.Intn(1000)), uint16(r.Intn(1000)))
		if err != nil {
			log.Fatal(err)
		}
		nonce, ok := NonceMap[i]
		if ok {
			NonceMap[i]++
		} else {
			NonceMap[i] = 1
			nonce = 0
		}
		ca, ok := ContractAddress["million_pixel"]
		if !ok {
			panic("contract should deploy first")
		}
		signedTx, err := ethtypes.SignTx(ethtypes.NewTx(&ethtypes.DynamicFeeTx{
			GasFeeCap: new(big.Int).SetUint64(1000000000000),
			GasTipCap: new(big.Int).SetUint64(1000000000000),
			Gas:       1000000,
			ChainID:   big.NewInt(config.DefaultChainID),
			To:        &ca,
			Value:     big.NewInt(0),
			Data:      calldata,
			Nonce:     nonce,
		}), from.EvmSigner, from.EvmPrivateKey)
		if err != nil {
			panic(err)
		}

		txData, err := ethtx.NewTxDataFromTx(signedTx)
		if err != nil {
			panic(err)
		}

		msg, err := types.NewMsgEVMTransaction(txData)
		if err != nil {
			panic(err)
		}
		msgs = append(msgs, &utils.TestMessage{
			Msg:       msg,
			IsEVM:     true,
			EVMSigner: ctx.TestAccounts[i],
			Type:      "EVM MillionPixel",
		})
	}
	return msgs
}

func EthHitoricalMsgReplayForEVM(ctx *utils.TestContext, filepath string) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	contractAbi := mytoken.GetParsedABI()
	f, err := os.Open(filepath)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	reader := csv.NewReader(f)
	for {
		record, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			panic(err)
		}

		fromIndex, err := strconv.Atoi(record[0])
		if err != nil {
			fmt.Println("Error converting from account:", err)
			continue
		}
		from := ctx.TestAccounts[fromIndex]
		toIndex, err := strconv.Atoi(record[1])
		if err != nil {
			fmt.Println("Error converting to account:", err)
			continue
		}
		to := ctx.TestAccounts[toIndex]
		calldata, err := contractAbi.Pack("transfer", from.EvmAddress, to.EvmAddress, big.NewInt(1000))
		if err != nil {
			log.Fatal(err)
		}
		nonce, ok := NonceMap[fromIndex]
		if ok {
			NonceMap[fromIndex]++
		} else {
			NonceMap[fromIndex] = 1
			nonce = 0
		}
		ca, ok := ContractAddress["mytoken"]
		if !ok {
			panic("contract should deploy first")
		}
		signedTx, err := ethtypes.SignTx(ethtypes.NewTx(&ethtypes.DynamicFeeTx{
			GasFeeCap: new(big.Int).SetUint64(1000000000000),
			GasTipCap: new(big.Int).SetUint64(1000000000000),
			Gas:       1000000,
			ChainID:   big.NewInt(config.DefaultChainID),
			To:        &ca,
			Value:     big.NewInt(0),
			Data:      calldata,
			Nonce:     nonce,
		}), from.EvmSigner, from.EvmPrivateKey)
		if err != nil {
			panic(err)
		}

		txData, err := ethtx.NewTxDataFromTx(signedTx)
		if err != nil {
			panic(err)
		}

		msg, err := types.NewMsgEVMTransaction(txData)
		if err != nil {
			panic(err)
		}
		msgs = append(msgs, &utils.TestMessage{
			Msg:       msg,
			IsEVM:     true,
			EVMSigner: ctx.TestAccounts[fromIndex],
			Type:      "EVM Mytoken",
		})
	}
	return msgs
}

///////////////////////////////////////////////////////////////////////////////////////

// EVMTransferNonConflicting generates a list of EVM transfer messages that do not conflict with each other
// each message will have a brand new address
func EVMTransferNonConflicting(tCtx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	for i := 0; i < count; i++ {
		testAcct := utils.NewSigner()
		msgs = append(msgs, evmTransfer(testAcct, testAcct.EvmAddress, "EVMTransferNonConflicting"))
	}
	return msgs
}

// EVMTransferConflicting generates a list of EVM transfer messages to the same address
func EVMTransferConflicting(tCtx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	for i := 0; i < count; i++ {
		testAcct := utils.NewSigner()
		msgs = append(msgs, evmTransfer(testAcct, tCtx.TestAccounts[0].EvmAddress, "EVMTransferConflicting"))
	}
	return msgs
}

// EVMTransferNonConflicting generates a list of EVM transfer messages that do not conflict with each other
// each message will have a brand new address
func evmTransfer(testAcct utils.TestAcct, to common.Address, scenario string) *utils.TestMessage {
	signedTx, err := ethtypes.SignTx(ethtypes.NewTx(&ethtypes.DynamicFeeTx{
		GasFeeCap: new(big.Int).SetUint64(1000000000000),
		GasTipCap: new(big.Int).SetUint64(1000000000000),
		Gas:       21000,
		ChainID:   big.NewInt(config.DefaultChainID),
		To:        &to,
		Value:     big.NewInt(1),
		Nonce:     0,
	}), testAcct.EvmSigner, testAcct.EvmPrivateKey)

	if err != nil {
		panic(err)
	}

	txData, err := ethtx.NewTxDataFromTx(signedTx)
	if err != nil {
		panic(err)
	}

	msg, err := types.NewMsgEVMTransaction(txData)
	if err != nil {
		panic(err)
	}

	return &utils.TestMessage{
		Msg:       msg,
		IsEVM:     true,
		EVMSigner: testAcct,
		Type:      scenario,
	}
}

func BankTransfer(tCtx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	for i := 0; i < count; i++ {
		msg := banktypes.NewMsgSend(tCtx.TestAccounts[0].AccountAddress, tCtx.TestAccounts[1].AccountAddress, utils.Funds(int64(i+1)))
		msgs = append(msgs, &utils.TestMessage{Msg: msg, Type: "BankTransfer"})
	}
	return msgs
}

func GovernanceSubmitProposal(tCtx *utils.TestContext, count int) []*utils.TestMessage {
	var msgs []*utils.TestMessage
	for i := 0; i < count; i++ {
		content := govtypes.NewTextProposal(fmt.Sprintf("Proposal %d", i), "test", true)
		mp, err := govtypes.NewMsgSubmitProposalWithExpedite(content, utils.Funds(10000), tCtx.TestAccounts[0].AccountAddress, true)
		if err != nil {
			panic(err)
		}
		msgs = append(msgs, &utils.TestMessage{Msg: mp, Type: "GovernanceSubmitProposal"})
	}
	return msgs
}

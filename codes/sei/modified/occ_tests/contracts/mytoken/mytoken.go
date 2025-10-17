package mytoken

import (
	"encoding/hex"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/ethereum/go-ethereum/accounts/abi"
)

const filesize = 1 * 1024 * 1024

var cachedBin []byte

var cachedABI *abi.ABI

func GetABI() []byte {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		panic("Error getting current file path")
	}

	currentDir := filepath.Dir(filename)
	filePath := filepath.Join(currentDir, "ERC20.abi")

	f, err := os.Open(filePath)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	bz := make([]byte, filesize)
	count, err := f.Read(bz)
	if err != nil || count > filesize {
		panic("failed to read mytoken contract ABI")
	}
	return bz[:count]
}

func GetParsedABI() *abi.ABI {
	if cachedABI != nil {
		return cachedABI
	}
	parsedABI, err := abi.JSON(strings.NewReader(string(GetABI())))
	if err != nil {
		panic(err)
	}
	cachedABI = &parsedABI
	return cachedABI
}

func GetBin() []byte {
	if cachedBin != nil {
		return cachedBin
	}

	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		panic("Error getting current file path")
	}

	currentDir := filepath.Dir(filename)
	filePath := filepath.Join(currentDir, "ERC20.bin")

	f, err := os.Open(filePath)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	code := make([]byte, filesize)
	count, err := f.Read(code)
	if err != nil || count > filesize {
		panic("failed to read mytoken contract Bin")
	}
	bz, err := hex.DecodeString(string(code[:count]))
	if err != nil {
		panic("failed to decode mytoken contract binary")
	}
	cachedBin = bz
	return bz
}

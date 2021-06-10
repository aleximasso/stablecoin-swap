package stablecoin

import (
	"errors"
	"fmt"

	"github.com/Get-Cache/Privi/contracts/coinb"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/shopspring/decimal"
)

func GetOracleFromAddress(stub shim.ChaincodeStubInterface, address string) (*Oracle, error) {
	oracle := Oracle{
		Address: address,
	}

	// load oracle from global state
	if loaded, err := oracle.LoadState(stub); err != nil {
		return nil, err
	} else if !loaded {
		return nil, errors.New("address not registered as an oracle")
	}

	return &oracle, nil
}

func RegisterOracle(stub shim.ChaincodeStubInterface, request *RegisterOracleRequest) (*Oracle, error) {
	oracle := Oracle{
		Address: request.Address,
		State:   StateAllowed,
		Name:    request.Name,
	}

	// check if address is associated to an oracle
	if found, err := oracle.LoadState(stub); err != nil {
		return nil, err
	} else if found {
		return nil, errors.New("address already registered as an oracle")
	}

	// save oracle state
	if err := oracle.SaveState(stub); err != nil {
		return nil, err
	}

	return &oracle, nil
}

func UpdateOracleState(stub shim.ChaincodeStubInterface, request *UpdateOracleStateRequest) (*Oracle, error) {
	// load oracle from global state
	oracle, err := GetOracleFromAddress(stub, request.Address)
	if err != nil {
		return nil, err
	}

	// update oracle state
	oracle.State = request.State

	// save oracle in global state
	if err := oracle.SaveState(stub); err != nil {
		return nil, err
	}

	return oracle, nil
}

// SubmitPrice saves the prices in buckets of type [Date Duration]
func SubmitPrice(stub shim.ChaincodeStubInterface, request *SubmitPriceRequest) (*PriceBucket, error) {
	// get tx timestamp
	time, err := stub.GetTxTimestamp()
	if err != nil {
		return nil, err
	}

	// get prices from global state
	prices := PriceBucket{
		Token:    request.Token,
		Date:     getPriceDate(time.GetSeconds(), DefaultDuration),
		Duration: DefaultDuration,
		Prices:   make(map[string]decimal.Decimal),
		Volumes:  make(map[string]decimal.Decimal),
	}

	if _, err := prices.LoadState(stub); err != nil {
		return nil, err
	}

	// update price in record
	prices.Volumes[request.Address] = request.Volume
	prices.Prices[request.Address] = request.Price

	// update prices in global state
	if err := prices.SaveState(stub); err != nil {
		return nil, err
	}

	return &prices, nil
}

func GetPriceBucket(stub shim.ChaincodeStubInterface, token string, date, duration int64) (*PriceBucket, error) {
	prices := PriceBucket{
		Date:     getPriceDate(date, duration),
		Duration: duration,
		Token:    token,
	}

	if loaded, err := prices.LoadState(stub); err != nil {
		return nil, err
	} else if !loaded {
		return nil, errors.New("not registered prices in this range")
	}

	return &prices, nil
}

func GetPrice(stub shim.ChaincodeStubInterface, token string, date, duration int64) (decimal.Decimal, error) {
	// load oracle prices from global state
	prices, err := GetPriceBucket(stub, token, date, duration)
	if err != nil {
		return decimal.Zero, err
	}

	// calculate ponderate median from the values.
	var sum, total decimal.Decimal
	for address, value := range prices.Prices {
		volume := prices.Volumes[address]

		sum = sum.Add(value.Mul(volume))
		total = total.Add(volume)
	}

	return sum.Div(total), nil
}

func Exchange(state *coinb.State, request *ExchangeRequest, fees ...decimal.Decimal) (*coinb.Output, error) {
	// get txtimestamp
	// time, err := state.GetStub().GetTxTimestamp()
	// if err != nil {
	// 	return nil, err
	// }

	// // check if address has suficient amount
	// if enough, err := state.CheckBalance(request.AddressFrom, request.TokenFrom, request.Amount); err != nil {
	// 	return nil, err
	// } else if !enough {
	// 	return nil, errors.New("not enough balance to convert")
	// }

	// calculate total fee
	var totalfee decimal.Decimal
	for _, fee := range fees {
		totalfee = totalfee.Add(request.Amount.Mul(fee))
	}

	// send total fees to privi address
	transfer, err := state.Transfer(coinb.TransferRequest{
		Type:   fmt.Sprintf("exchange_fee_%s_%s", request.TokenFrom, request.TokenTo),
		Token:  request.TokenFrom,
		From:   request.AddressFrom,
		To:     coinb.PriviAddress,
		Amount: totalfee,
	})
	if err != nil {
		return nil, err
	}

	// calculate real amount
	request.Amount = request.Amount.Sub(totalfee)

	// get prices of request.TokenFrom and request.TokenTo
	pricefrom, err := GetPrice(state.GetStub(), request.TokenFrom, time.GetSeconds(), DefaultDuration)
	if err != nil {
		return nil, err
	}

	priceto, err := GetPrice(state.GetStub(), request.TokenTo, time.GetSeconds(), DefaultDuration)
	if err != nil {
		return nil, err
	}

	// calculate request.TokenTo amount
	difference := pricefrom.Div(priceto)

	// burn request.TokenFrom tokens from address
	burn, err := state.Burn(&coinb.TransferRequest{
		Type:   fmt.Sprintf("burn_convert_%s_%s", request.TokenFrom, request.TokenTo),
		Token:  request.TokenFrom,
		From:   request.AddressFrom,
		Amount: request.Amount,
	})
	if err != nil {
		return nil, err
	}

	// mint request.TokenTo tokens to address
	mint, err := state.Mint(&coinb.TransferRequest{
		Type:   fmt.Sprintf("mint_convert_%s_%s", request.TokenFrom, request.TokenTo),
		Token:  request.TokenTo,
		To:     request.AddressTo,
		Amount: request.Amount.Mul(difference),
	})
	if err != nil {
		return nil, err
	}

	return transfer.AppendOutput(*burn, *mint), nil
}

func ConvertPriviToPUSD(state *coinb.State, request *ConvertRequest) (*coinb.Output, error) {
	return Exchange(state, &ExchangeRequest{
		TokenFrom:   PriviToken,
		TokenTo:     PUSDToken,
		AddressFrom: request.Address,
		AddressTo:   request.Address,
		Amount:      request.Amount,
	})
}

func ConvertPUSDToPrivi(state *coinb.State, request *ConvertRequest) (*coinb.Output, error) {
	return Exchange(state, &ExchangeRequest{
		TokenFrom:   PUSDToken,
		TokenTo:     PriviToken,
		AddressFrom: request.Address,
		AddressTo:   request.Address,
		Amount:      request.Amount,
	})
}
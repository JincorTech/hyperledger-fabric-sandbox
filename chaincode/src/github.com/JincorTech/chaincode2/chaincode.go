package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

var logger = shim.NewLogger("Chaincode2")

type SimpleChaincode struct {
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Info("########### Init ###########")

	return shim.Success(nil)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Info("########### Invoke ###########")

    logger.Info("<<<<<<<< Get stub params... >>>>>>>>>")
    fn, args := stub.GetFunctionAndParameters()
    logger.Infof("stub.GetFunctionAndParameters() -> [%+v] [%+v]\n", fn, args)
    trn, err := stub.GetBinding()
    logger.Infof("stub.GetBinding() -> [%+v] [%+v]\n", trn, err)
    crt, err := stub.GetCreator()
    logger.Infof("stub.GetCreator() -> [%+v] [%+v]\n", crt, err)
    sp, err := stub.GetSignedProposal()
    logger.Infof("stub.GetSignedProposal() -> [%+v] [%+v]\n", sp, err)
    tr, err := stub.GetTransient()
    logger.Infof("stub.GetTransient() -> [%+v] [%+v]\n", tr, err)
    tid := stub.GetTxID()
    logger.Infof("stub.GetTxID() -> [%+v]\n", tid)
    ts, err := stub.GetTxTimestamp()
    logger.Infof("stub.GetTxTimestamp() -> [%+v] [%+v]\n", ts, err)

    logger.Info("Try to get stored state...")
    value, err := stub.GetState("State")
    logger.Infof("Get state [%+v] [%+v]", value, err)

    if fn == "callcc2" {
        logger.Info("Try to ivoke chaincode3 with same arguments in common channel...")
        resp := stub.InvokeChaincode(args[0], stub.GetArgs(), args[1])
        logger.Infof("Response with [%+v]", resp)
    }

	return shim.Success(nil)
}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		logger.Errorf("Error starting Simple chaincode: %s", err)
	}
}

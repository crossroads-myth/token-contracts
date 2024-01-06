
// ------------------------------------------------------------------------------
// FA2 Storage Types
// ------------------------------------------------------------------------------

type tokenInfoType  is map(string, bytes)
type tokenMetadataInfoType is [@layout:comb] record [
    token_id          : tokenIdNatType;
    token_info        : tokenInfoType;
]
type tokenMetadataType is big_map(tokenIdNatType, tokenMetadataInfoType);

type operatorsType is big_map((ownerType * operatorType * tokenIdNatType), unit)

// ------------------------------------------------------------------------------
// FA2 Action Types
// ------------------------------------------------------------------------------

type transferDestination is [@layout:comb] record[
    to_       : address;
    token_id  : tokenIdNatType;
    amount    : tokenBalanceNatType;
]
type transfer is [@layout:comb] record[
    from_     : address;
    txs       : list(transferDestination);
]
type fa2TransferType is list(transfer)

type balanceOfRequestType is [@layout:comb] record[
    owner       : ownerType;
    token_id    : tokenIdNatType;
]
type balanceOfResponseType is [@layout:comb] record[
    request     : balanceOfRequestType;
    balance     : tokenBalanceNatType;
]
type balanceOfActionType is [@layout:comb] record[
    requests    : list(balanceOfRequestType);
    callback    : contract(list(balanceOfResponseType));
]

type operatorParameterType is [@layout:comb] record[
    owner       : ownerType;
    operator    : operatorType;
    token_id    : tokenIdNatType;
]
type updateOperatorVariantType is 
        Add_operator    of operatorParameterType
    |   Remove_operator of operatorParameterType
type updateOperatorsActionType is list(updateOperatorVariantType)

type assertMetadataActionType is [@layout:comb] record[
    key     : string;
    hash    : bytes;
]
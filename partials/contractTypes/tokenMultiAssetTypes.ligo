
// ------------------------------------------------------------------------------
// Common Types
// ------------------------------------------------------------------------------

type tokenIdNatType           is nat
type tokenBalanceNatType      is nat
type tokenAmountNatType       is nat
type tokenMetadataBytesType   is bytes
type operatorAddressType      is address
type ownerAddressType         is address
type recipientAddressType     is address

// ------------------------------------------------------------------------------
// Metadata Types
// ------------------------------------------------------------------------------

type metadataType is big_map (string, bytes);
type updateMetadataActionType is [@layout:comb] record [
    metadataKey           : string;
    metadataHash          : bytes; 
]

// ------------------------------------------------------------------------------
// Storage Types
// ------------------------------------------------------------------------------

type ledgerKeyType is (ownerAddressType * tokenIdNatType)
type ledgerType is big_map(ledgerKeyType, tokenBalanceNatType);
type totalSupplyType is big_map(tokenIdNatType, tokenBalanceNatType)

// ------------------------------------------------------------------------------
// Action Parameter Types
// ------------------------------------------------------------------------------

// mint token
type mintTokenMultiAssetType is [@layout:comb] record [
    recipient       : recipientAddressType; 
    token_id        : tokenIdNatType; 
    token_metadata  : map(string, bytes);
    amount          : tokenAmountNatType;
]
type mintTokenMultiAssetActionType is list(mintTokenMultiAssetType)

// mint existing token
type mintExistingType is [@layout:comb] record [
    recipient       : recipientAddressType; 
    token_id        : tokenIdNatType; 
    amount          : tokenAmountNatType;
]
type mintExistingActionType is list(mintExistingType);

// burn token
type burnTokenMultiAssetType is [@layout:comb] record [
    owner           : ownerAddressType; 
    token_id        : tokenIdNatType;
    amount          : tokenAmountNatType;
]
type burnTokenMultiAssetActionType is list(burnTokenMultiAssetType)

type setTokenMetadataActionType is [@layout:comb] record [
    token_id        : tokenIdNatType;
    token_metadata  : map(string, bytes);
]

type updateTokenMetadataInfoFieldActionType is [@layout:comb] record [
    token_id               : tokenIdNatType;
    token_metadata_name    : string;
    token_metadata_bytes   : bytes;
]

// ------------------------------------------------------------------------------
// Storage
// ------------------------------------------------------------------------------

type tokenMultiAssetStorageType is record [
    
    superAdmin              : address;
    newSuperAdmin           : option(address);
    admins                  : set(address);
    controllerAddress       : address;
    
    whitelistContracts      : whitelistContractsType;  

    metadata                : metadataType;
    token_metadata          : tokenMetadataType;
    total_supply            : totalSupplyType;
    
    ledger                  : ledgerType;
    operators               : operatorsType;
    
    all_tokens              : tokenIdNatType;
]

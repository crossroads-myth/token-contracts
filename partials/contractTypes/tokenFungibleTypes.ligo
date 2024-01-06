
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

type ledgerType is big_map(ownerAddressType, tokenBalanceNatType);
type totalSupplyType is nat

// ------------------------------------------------------------------------------
// Action Parameter Types
// ------------------------------------------------------------------------------

(* Mint entrypoint inputs *)
type mintTokenFungibleActionType is (ownerAddressType * tokenBalanceNatType)

(* Burn entrypoint inputs *)
type burnTokenFungibleActionType is nat

type setTokenMetadataActionType is [@layout:comb] record [
    token_metadata  : map(string, bytes);
    empty           : unit;
]

// ------------------------------------------------------------------------------
// Storage
// ------------------------------------------------------------------------------

type tokenFungibleStorageType is record [
    
    superAdmin              : address;
    newSuperAdmin           : option(address);
    admins                  : set(address);
    controllerAddress       : address;
    
    metadata                : metadataType;
    token_metadata          : tokenMetadataType;
    total_supply            : totalSupplyType;
    
    ledger                  : ledgerType;
    operators               : operatorsType;

]

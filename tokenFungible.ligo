// ------------------------------------------------------------------------------
// Contract Types
// ------------------------------------------------------------------------------

// Token Fungible type
#include "../partials/contractTypes/tokenFungibleTypes.ligo"

// ------------------------------------------------------------------------------

type action is

        // Admin Entrypoints
        SetSuperAdmin                    of (address)
    |   ClaimSuperAdmin                  of (unit)
    |   SetAdmin                         of setAdminActionType
    |   SetController                    of (address)
    |   UpdateMetadata                   of updateMetadataActionType

        // FA2 Entrypoints
    |   AssertMetadata                   of assertMetadataActionType
    |   Transfer                         of fa2TransferType
    |   Balance_of                       of balanceOfActionType
    |   Update_operators                 of updateOperatorsActionType

        // Admin Entrypoints
    |   Mint                             of mintTokenFungibleActionType
    |   Burn                             of burnTokenFungibleActionType
    |   SetTokenMetadata                 of setTokenMetadataActionType

type return is list (operation) * tokenFungibleStorageType
const noOperations : list (operation) = nil;


// ------------------------------------------------------------------------------
//
// Helper Functions Begin
//
// ------------------------------------------------------------------------------

// ------------------------------------------------------------------------------
// Admin Helper Functions Begin
// ------------------------------------------------------------------------------

// verify sender is super admin
function verifySenderIsSuperAdmin(const superAdminAddress : address) : unit is
block {

    const senderIsSuperAdmin : bool = superAdminAddress = Tezos.get_sender();
    if senderIsSuperAdmin then skip else failwith("ONLY_SUPER_ADMINISTRATOR_ALLOWED");

} with unit


function verifyNoAmountSent(const _p : unit) : unit is
    if Tezos.get_amount() =/= 0tez then failwith("TEZ_NOT_ALLOWED")
    else unit

// ------------------------------------------------------------------------------
// Admin Helper Functions End
// ------------------------------------------------------------------------------



// ------------------------------------------------------------------------------
// FA2 Helper Functions Begin
// ------------------------------------------------------------------------------

function checkTokenId(const tokenId : tokenIdNatType; const s : tokenFungibleStorageType) : unit is 
block {
    const checkTokenExists : unit = case s.token_metadata[tokenId] of [
            Some(_token) -> unit
        |   None         -> failwith("FA2_TOKEN_UNDEFINED")
    ];
} with checkTokenExists



function checkBalance(const spenderBalance : tokenBalanceNatType; const tokenAmount : tokenBalanceNatType): unit is
    if spenderBalance < tokenAmount then failwith("FA2_INSUFFICIENT_BALANCE")
    else unit



function checkOwnership(const owner : ownerType) : unit is
    if Tezos.get_sender() =/= owner then failwith("FA2_NOT_OWNER")
    else unit



function checkOperator(const owner: ownerAddressType; const token_id: tokenIdNatType; const operators : operatorsType): unit is
    if owner = Tezos.get_sender() or Big_map.mem((owner, Tezos.get_sender(), token_id), operators) then unit
    else failwith ("FA2_NOT_OPERATOR")



// mergeOperations helper function - used in transfer entrypoint
function mergeOperations(const first: list (operation); const second: list (operation)) : list (operation) is 
List.fold( 
    function(const operations: list(operation); const operation: operation): list(operation) is operation # operations,
    first,
    second
)



// addOperator helper function - used in update_operators entrypoint
function addOperator(const operatorParameter: operatorParameterType; const operators: operatorsType; const s : tokenFungibleStorageType) : operatorsType is
block{

    const owner     : ownerAddressType     = operatorParameter.owner;
    const operator  : operatorAddressType  = operatorParameter.operator;
    const tokenId   : tokenIdNatType       = operatorParameter.token_id;

    checkTokenId(tokenId, s);
    checkOwnership(owner);

    const operatorKey : (ownerAddressType * operatorAddressType * tokenIdNatType) = (owner, operator, tokenId)

} with (Big_map.update(operatorKey, Some (unit), operators))



// removeOperator helper function - used in update_operators entrypoint
function removeOperator(const operatorParameter: operatorParameterType; const operators: operatorsType; const s : tokenFungibleStorageType): operatorsType is
block{

    const owner     : ownerAddressType     = operatorParameter.owner;
    const operator  : operatorAddressType  = operatorParameter.operator;
    const tokenId   : tokenIdNatType       = operatorParameter.token_id;

    checkTokenId(tokenId, s);
    checkOwnership(owner);

    const operatorKey: (ownerAddressType * operatorAddressType * tokenIdNatType) = (owner, operator, tokenId)

} with (Big_map.remove(operatorKey, operators))

// ------------------------------------------------------------------------------
// FA2 Helper Functions End
// ------------------------------------------------------------------------------

// ------------------------------------------------------------------------------
//
// Helper Functions Begin
//
// ------------------------------------------------------------------------------



// ------------------------------------------------------------------------------
//
// Views Begin
//
// ------------------------------------------------------------------------------


// ------------------------------------------------------------------------------
// TZIP-12 Views Begin
// ------------------------------------------------------------------------------

(* get_balance View *)
[@view] function get_balance(const userAndId : ownerType * nat; const s : tokenFungibleStorageType) : tokenBalanceNatType is
    case Big_map.find_opt(userAndId.0, s.ledger) of [
            Some (_v) -> _v
        |   None      -> 0n
    ]



(* total_supply View *)
[@view] function total_supply(const _token_id : tokenIdNatType; const s : tokenFungibleStorageType) : tokenBalanceNatType is
    s.total_supply



(* all_tokens View *)
[@view] function all_tokens(const _ : unit; const _s : tokenFungibleStorageType) : list(nat) is 
    list[0n]



(* is_operator view *)
[@view] function is_operator(const operator : (ownerAddressType * operatorAddressType * tokenIdNatType); const s : tokenFungibleStorageType) : option(unit) is
    Big_map.find_opt(operator, s.operators)



(* token_metadata view *)
[@view] function token_metadata(const token_id : tokenIdNatType; const s : tokenFungibleStorageType) : option(tokenMetadataInfoType) is
    Big_map.find_opt(token_id, s.token_metadata)

// ------------------------------------------------------------------------------
// TZIP-12 Views Begin
// ------------------------------------------------------------------------------



// ------------------------------------------------------------------------------
// Contract Specific Views Begin
// ------------------------------------------------------------------------------

[@view] function getTokenMetadataOpt(const tokenId : tokenIdNatType; const s : tokenFungibleStorageType) : tokenMetadataInfoType is
    case Big_map.find_opt(tokenId, s.token_metadata) of [
            Some (_tokenMetadataInfo) -> _tokenMetadataInfo
        |   None      -> record[
                token_id    = tokenId;
                token_info  = map[]
            ]
    ]

[@view] function getTokenInfoOpt(const tokenInfoParams : (tokenIdNatType * string); const s : tokenFungibleStorageType) : bytes is
    case Big_map.find_opt(tokenInfoParams.0, s.token_metadata) of [
            Some (_tokenMetadata) -> case _tokenMetadata.token_info[tokenInfoParams.1] of [
                    Some(_tokenInfoBytes) -> _tokenInfoBytes
                |   None                  -> Bytes.pack("0x")
            ]
        |   None      -> Bytes.pack("0x")
    ]

// ------------------------------------------------------------------------------
// Contract Specific Views End
// ------------------------------------------------------------------------------


// ------------------------------------------------------------------------------
//
// Views End
//
// ------------------------------------------------------------------------------



// ------------------------------------------------------------------------------
//
// Entrypoints Begin
//
// ------------------------------------------------------------------------------

// ------------------------------------------------------------------------------
// Admin Entrypoints Begin
// ------------------------------------------------------------------------------

(*  setSuperAdmin entrypoint *)
function setSuperAdmin(const newSuperAdminAddress : address; var s : tokenFungibleStorageType) : return is
block {

    verifySenderIsSuperAdmin(s.superAdmin);
    s.newSuperAdmin := Some(newSuperAdminAddress);

} with (noOperations, s)



(*  claimSuperAdmin entrypoint *)
function claimSuperAdmin(var s : tokenFungibleStorageType) : return is
block {

    // get sender and new super admin address 
    const sender : address = Tezos.get_sender();
    const newSuperAdmin : address = case s.newSuperAdmin of [
            Some(_address) -> _address
        |   None           -> failwith("NO_SUPER_ADMIN_FOUND")
    ];

    // check if sender is not new super admin 
    if sender =/= newSuperAdmin then failwith("SENDER_NOT_NEW_SUPER_ADMIN") else skip;
    s.superAdmin := newSuperAdmin;
    s.newSuperAdmin := (None : option(address));

} with (noOperations, s)



(*  setAdmin entrypoint *)
function setAdmin(const setAdminAction : setAdminActionType; var s : tokenFungibleStorageType) : return is
block {

    verifySenderIsSuperAdmin(s.superAdmin);
    case setAdminAction of [
        |   AddAdmin(adminAddress) -> s.admins := Set.add(adminAddress, s.admins)
        |   RemoveAdmin(adminAddress) -> {
                const currentAdminCount : nat = Set.cardinal(s.admins);
                if currentAdminCount = 1n then failwith(error_AT_LEAST_ONE_ADMIN_REQUIRED) else skip;
                s.admins := Set.remove(adminAddress, s.admins)
            }
    ]

} with (noOperations, s)



(*  setController entrypoint *)
function setController(const newControllerAddress : address; var s : tokenFungibleStorageType) : return is
block {
    
    verifySenderIsSuperAdmin(s.superAdmin);
    s.controllerAddress := newControllerAddress;

} with (noOperations, s)



(*  updateMetadata entrypoint *)
function updateMetadata(const updateMetadataParams : updateMetadataActionType; var s : tokenFungibleStorageType) : return is
block {

    verifySenderIsSuperAdmin(s.superAdmin);
    const metadataKey   : string = updateMetadataParams.metadataKey;
    const metadataHash  : bytes  = updateMetadataParams.metadataHash;
    
    s.metadata[metadataKey] := metadataHash;

} with (noOperations, s)

// ------------------------------------------------------------------------------
// Admin Entrypoints End
// ------------------------------------------------------------------------------



// ------------------------------------------------------------------------------
// FA2 Entrypoints Begin
// ------------------------------------------------------------------------------

(* assertMetadata entrypoint *)
function assertMetadata(const assertMetadataParams : assertMetadataActionType; const s : tokenFungibleStorageType): return is
block{

    const metadataKey  : string  = assertMetadataParams.key;
    const metadataHash : bytes   = assertMetadataParams.hash;
    case Big_map.find_opt(metadataKey, s.metadata) of [
            Some (v)  -> if v =/= metadataHash then failwith("METADATA_HAS_A_WRONG_HASH") else skip
        |    None     -> failwith("METADATA_NOT_FOUND")
    ]

} with (noOperations, s)



(* transfer entrypoint *)
function transfer(const transferParams : fa2TransferType; const s : tokenFungibleStorageType): return is
block{

    function makeTransfer(const account : return; const transferParam : transfer) : return is
        block {

        const owner  : ownerAddressType          = transferParam.from_;
        const txs    : list(transferDestination) = transferParam.txs;
        
        function transferTokens(const accumulator : tokenFungibleStorageType; const destination : transferDestination) : tokenFungibleStorageType is
            block {

                const tokenId            : tokenIdNatType        = destination.token_id;
                const tokenAmount        : tokenBalanceNatType   = destination.amount;
                const receiver           : ownerAddressType      = destination.to_;
                
                const ownerBalance       : tokenBalanceNatType   = get_balance((owner, 0n), accumulator);
                const receiverBalance    : tokenBalanceNatType   = get_balance((receiver, 0n), accumulator);

                // Validate operator
                checkOperator(owner, tokenId, account.1.operators);

                // Validate token type
                checkTokenId(tokenId, s);

                // Validate that sender has enough token
                checkBalance(ownerBalance, tokenAmount);

                // Update users' balances
                var ownerNewBalance     : tokenBalanceNatType   := ownerBalance;
                var receiverNewBalance  : tokenBalanceNatType   := receiverBalance;

                if owner =/= receiver then {
                    ownerNewBalance     := abs(ownerBalance - tokenAmount);
                    receiverNewBalance  := receiverBalance + tokenAmount;
                }
                else skip;

                // update ledger for owner and receiver
                var updatedLedger : ledgerType := Big_map.update(owner, Some (ownerNewBalance), accumulator.ledger);
                updatedLedger := Big_map.update(receiver, Some (receiverNewBalance), updatedLedger);

            } with accumulator with record[ledger = updatedLedger];

            const updatedOperations : list(operation) = list[];
            const updatedStorage : tokenFungibleStorageType = List.fold(transferTokens, txs, account.1);

        } with (mergeOperations(updatedOperations,account.0), updatedStorage)

} with List.fold(makeTransfer, transferParams, ((nil: list(operation)), s))




(* balance_of entrypoint *)
function balanceOf(const balanceOfParams : balanceOfActionType; const s: tokenFungibleStorageType) : return is
block{

    function retrieveBalance(const request: balanceOfRequestType) : balanceOfResponseType is
    block{

        const requestOwner    : ownerAddressType = request.owner;
        const tokenBalance : tokenBalanceNatType = 
            case Big_map.find_opt(requestOwner, s.ledger) of [
                    Some (balance) -> balance
                |   None           -> 0n
            ];
        const response : balanceOfResponseType = record[ 
            request = request;
            balance = tokenBalance
        ];

    } with (response);

    const requests: list(balanceOfRequestType)            = balanceOfParams.requests;
    const callback: contract(list(balanceOfResponseType)) = balanceOfParams.callback;
    const responses: list(balanceOfResponseType)          = List.map(retrieveBalance, requests);
    const operation: operation                            = Tezos.transaction(responses, 0tez, callback);

} with (list[operation],s)



(* update_operators entrypoint *)
function updateOperators(const updateOperatorsParams : updateOperatorsActionType; const s : tokenFungibleStorageType) : return is
block{

    var updatedOperators : operatorsType := List.fold(
        function(const operators : operatorsType; const updateOperatorVariant : updateOperatorVariantType) : operatorsType is
            case updateOperatorVariant of [
                    Add_operator (param)    -> addOperator(param, operators, s)
                |   Remove_operator (param) -> removeOperator(param, operators, s)
            ]
        ,
        updateOperatorsParams,
        s.operators
    )

} with(noOperations,s with record[operators=updatedOperators])



(* mint entrypoint *)
function mint(const mintParams : mintTokenFungibleActionType; var s : tokenFungibleStorageType) : return is
block {

    const recipientAddress  : ownerType             = mintParams.0;
    const mintedTokens      : tokenBalanceNatType   = mintParams.1;

    // Check sender is allowed
    if s.admins contains Tezos.get_sender()
       or Tezos.get_sender() = s.controllerAddress
    then skip else failwith("ONLY_ADMIN_OR_CONTROLLER_ALLOWED");

    // Update sender's balance
    const senderNewBalance : tokenBalanceNatType = get_balance((recipientAddress, 0n), s) + mintedTokens;

    // Update storage and total supply
    s.total_supply := s.total_supply + mintedTokens;
    s.ledger := Big_map.update(recipientAddress, Some(senderNewBalance), s.ledger);

} with (noOperations, s)



(* burn entrypoint *)
function burn(const burnTokenAmount : nat; var s : tokenFungibleStorageType) : return is
block {

    const senderAddress : ownerType = Tezos.get_sender();

    // Get sender's balance
    const senderBalance : tokenBalanceNatType = get_balance((senderAddress, 0n), s);

    // Validate that sender has enough tokens to burn
    checkBalance(senderBalance, burnTokenAmount);

    const senderNewBalance : tokenBalanceNatType = abs(senderBalance - burnTokenAmount);

    // Update storage and total supply
    s.total_supply           := abs(s.total_supply - burnTokenAmount);
    s.ledger[senderAddress] := senderNewBalance;

} with (noOperations, s)



(* setTokenMetadata entrypoint *)
function setTokenMetadata(const setTokenMetadataParams : setTokenMetadataActionType; var s : tokenFungibleStorageType) : return is
    block {

    const tokenMetadata       : tokenInfoType     = setTokenMetadataParams.token_metadata;

    // Check sender is allowed
    if s.admins contains Tezos.get_sender()
       or Tezos.get_sender() = s.controllerAddress
    then skip else failwith("ONLY_ADMIN_OR_CONTROLLER_ALLOWED");

    // get and update token metadata
    const tokenMetadata : tokenMetadataInfoType = case s.token_metadata[0n] of [
                Some(_tokenMetadata) -> record [
                    token_id   = 0n;
                    token_info = tokenMetadata; 
                ]
            |   None                 -> record [
                    token_id   = 0n;
                    token_info = tokenMetadata; 
                ]
    ];

    // update token metadata
    s.token_metadata[0n] := tokenMetadata;

} with (noOperations, s)


// ------------------------------------------------------------------------------
// FA2 Entrypoints End
// ------------------------------------------------------------------------------

// ------------------------------------------------------------------------------
//
// Entrypoints End
//
// ------------------------------------------------------------------------------


(* main entrypoint *)
function main (const action : action; const s : tokenFungibleStorageType) : return is
block{
    
    verifyNoAmountSent(Unit); // Check that sender didn't send any tezos while calling an entrypoint

} with(
    
    case action of [

            // Admin Entrypoints
            SetSuperAdmin(parameters)               -> setSuperAdmin(parameters, s)
        |   ClaimSuperAdmin(_parameters)            -> claimSuperAdmin(s)
        |   SetAdmin(parameters)                    -> setAdmin(parameters, s)
        |   SetController (params)                  -> setController(params, s)
        |   UpdateMetadata (params)                 -> updateMetadata(params, s)

            // FA2 Entrypoints
        |   AssertMetadata (params)                 -> assertMetadata(params, s)
        |   Transfer (params)                       -> transfer(params, s)
        |   Balance_of (params)                     -> balanceOf(params, s)
        |   Update_operators (params)               -> updateOperators(params, s)

            // Admin Entrypoints
        |   Mint (params)                           -> mint(params, s)
        |   Burn (params)                           -> burn(params, s)
        |   SetTokenMetadata(params)                -> setTokenMetadata(params, s)

    ]

)
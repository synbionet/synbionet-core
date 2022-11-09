# Metadata

## Terms
- **Consumer**: a user purchasing synthetic biology assets
- **Producer**: a user the offers data or services on the market
- **Asset**: data, service, or physical material used in synthetic biology
- **Service**: can offer data or a process/functionality that works on data or material 
- **IP**:  intellectual property and associated licenses represented as an ERC-1155 contract
- **Metadata**: information that descibes an asset
- **DID**: globally unique identifier for an asset
- **DDOC**: json formatted document that contains all the information related to IP and it's service(s)

Note: DID and DDOC are based on the [W3C Decentralized Identifier specification](https://www.w3.org/TR/did-core/)

## Use
Every IP contract is associated with metadata.  The metadata is used for several purposes:
- populate the market UI with information about the asset
- associate licensing terms
- help consumers negotiate services and/or the use of the asset
- help authenticate and authorize use of an asset

## Relationships
- An asset is associated with IP and metadata
- IP is used to track, control, transfer, and authorize the use of intellectual property
- Metadata describes the asset 
- DDOC is the format of the metadata  
- DID is the identifier used to track an asset

```text
       [Asset]
   _______|_______
   |             |
  [IP]   [DID & Metadata/DDOC] 
```

## Storing Metadata
Many NFTs use the `tokenURI` method of the contract to contain a URL pointing to metadata stored off-chain, usually on a centralized server.  This can result in link rot and the loss of important information related to the NFT.

SynBioNet stores metadata in the event logs of the IP contract.  This ensures the metadata is stored on-chain and is always (permanently) associated with the contract.

## Indexing
The market will use metadata to populate the UI. However, since metadata is stored in event logs it'll need to be extracted and stored for easy access via a separate process we call the `indexer`, here's how it works:
- Events are emitted from the contracts
- The indexer will listen to the blockchain, extract our events and store in a database
- The market and others can query the indexer over an HTTP based API for metadata.

The indexer will rely on address information from 2 sources (the market and ip contract) to filter and collect data.  Only the metadata coming from IP registered through the market contract will be available in the indexer.  This ensures the market only displays metadata from IP registered through the market

## Basic Flow
1. The UI collects information about the new asset from a producer
2. A new IP contract is deployed belonging to the producer
3. The metadata is submitted to the deployed contract 
4. The contract emits the metadata as an event
5. The producer registered the asset on the market
6. The market contract emits and event about the asset
7. The indexer stores the metadata when it sees an event for the asset from the market and the IP contract.

For now, the market relies on a centralized service (the indexer) for metadata.  However, even if metadata stored in the indexer is deleted, all the information is still available on-chain and can be used to recreate a new indexer.  In the future we'll explore using the [Graph Protocol](https://thegraph.com/en/) for a more decentralized storage and query service.

## Purging bad metadata
In the event the market needs to purge metadata related to bad/banned IP contracts, we can use the SynBioNet DAO and a whitelist to curate the metadata that's made available on the market.


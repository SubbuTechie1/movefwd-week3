module nft::simple_nft {
    use sui::object;
    use sui::tx_context;
    use sui::transfer;
    use sui::event;
    use sui::url;
    use sui::string;
    use std::vector;

    // Errors
    const E_INVALID_NAME: u64 = 1;

    // NFT object (owned)
    public struct SimpleNFT has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: url::Url,
        creator: address,
        created_at: u64,
    }

    // Events
    public struct NFTMinted has copy, drop {
        nft_id: ID,
        name: String,
        creator: address,
        recipient: address,
    }

    public struct NFTTransferred has copy, drop {
        nft_id: ID,
        from: address,
        to: address,
    }

    public struct NFTBurned has copy, drop {
        nft_id: ID,
        burned_by: address,
    }

    // Mint an NFT and transfer it to the sender
    public entry fun mint_nft(name: vector<u8>, description: vector<u8>, image_url: vector<u8>, ctx: &mut TxContext) {
        assert!(!vector::is_empty(&name), E_INVALID_NAME);

        let name_string = string::utf8(name);
        let desc_string = string::utf8(description);
        let url = url::new_unsafe_from_bytes(image_url);

        let sender = tx_context::sender(ctx);

        let nft_uid = object::new(ctx);
        let nft_id = object::uid_to_inner(&nft_uid);

        let nft = SimpleNFT {
            id: nft_uid,
            name: name_string,
            description: desc_string,
            image_url: url,
            creator: sender,
            created_at: tx_context::epoch(ctx),
        };

        event::emit(NFTMinted {
            nft_id,
            name: nft.name,
            creator: sender,
            recipient: sender,
        });

        transfer::public_transfer(nft, sender);
    }

    // Transfer NFT to another address
    public entry fun transfer_nft(nft: SimpleNFT, recipient: address, ctx: &TxContext) {
        let nft_id = object::id(&nft);
        let sender = tx_context::sender(ctx);
        event::emit(NFTTransferred { nft_id, from: sender, to: recipient });
        transfer::public_transfer(nft, recipient);
    }

    // Burn NFT (destroy)
    public entry fun burn_nft(nft: SimpleNFT, ctx: &TxContext) {
        let nft_id = object::id(&nft);
        let sender = tx_context::sender(ctx);
        event::emit(NFTBurned { nft_id, burned_by: sender });
        let SimpleNFT { id, name: _, description: _, image_url: _, creator: _, created_at: _ } = nft;
        object::delete(id);
    }

    // View helpers
    public fun name(nft: &SimpleNFT): &String { &nft.name }
    public fun description(nft: &SimpleNFT): &String { &nft.description }
    public fun image_url(nft: &SimpleNFT): &url::Url { &nft.image_url }
    public fun creator(nft: &SimpleNFT): address { nft.creator }
    public fun created_at(nft: &SimpleNFT): u64 { nft.created_at }
}


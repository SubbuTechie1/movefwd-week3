module nft::nft_tests {
    use sui::test_scenario;
    use nft::simple_nft::{self, SimpleNFT};

    #[test]
    fun test_mint_and_transfer() {
        let owner = @0xA;
        let recipient = @0xB;
        let mut scenario = test_scenario::begin(owner);

        // Mint NFT
        {
            simple_nft::mint_nft(
                b"Test NFT",
                b"A sample nft for testing",
                b"ipfs://QmExample",
                test_scenario::ctx(&mut scenario)
            );
        };

        // Owner transfers to recipient
        test_scenario::next_tx(&mut scenario, owner);
        {
            let nft = test_scenario::take_from_sender<SimpleNFT>(&scenario);
            simple_nft::transfer_nft(nft, recipient, test_scenario::ctx(&mut scenario));
        };

        // Recipient should hold the NFT (creator unchanged)
        test_scenario::next_tx(&mut scenario, recipient);
        {
            let nft = test_scenario::take_from_sender<SimpleNFT>(&scenario);
            assert!(simple_nft::creator(&nft) == owner, 0);
            test_scenario::return_to_sender(&scenario, nft);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_burn_nft() {
        let owner = @0xA;
        let mut scenario = test_scenario::begin(owner);

        // Mint NFT
        {
            simple_nft::mint_nft(
                b"Burnable",
                b"Will be burned",
                b"ipfs://QmBurn",
                test_scenario::ctx(&mut scenario)
            );
        };

        // Burn
        test_scenario::next_tx(&mut scenario, owner);
        {
            let nft = test_scenario::take_from_sender<SimpleNFT>(&scenario);
            simple_nft::burn_nft(nft, test_scenario::ctx(&mut scenario));
        };

        test_scenario::end(scenario);
    }
}

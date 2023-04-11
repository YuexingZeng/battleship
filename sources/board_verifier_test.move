#[test_only]
module battleship::board_verifier_test {
    use battleship::board_verifier;
    use std::debug::print;
    use battleship::shot_verify;
    use std::vector;
    use std::vector::append;
    use sui::bcs::to_bytes;

    #[test]
    fun verify_test(){
        let board_input_bytes: vector<u8> = x"631314AF7FFCAAFF1C958C26C74A6ED9CE5D13738452974AA874E5AD12686D21";
        let board_proof_bytes: vector<u8> = x"cd95c1bc3ae661db04eeeda09d9cc6bcc336aa00bb339316836d76041e3dd589dce63a064e65eb6727ffacf0c2aa36e0edda38e5f05faf8c0483bd340e69c6122a36b4320d966692d2df5f16fcf1e192b2a7777fc8df63ee3a245708c1c50d2561bf61ca1665db04ca5c26e23e7b9ee1f2bcf03e581372a2ead3ab37b332db09";
        print(&board_verifier::verify(board_input_bytes,board_proof_bytes));

        let shot_hash: u256 = 0x14F0C1B598C969DB640E6C3B11E27AFF2FF4961CEE16DA57A6B2282C8979F4F1;
        let shot_x: u256 = 0x1;
        let shot_y: u256 = 0x0;
        let hit: u256 =0x1;
        let shot_input_bytes: vector<u8> = vector::empty();
        append(&mut shot_input_bytes,to_bytes(&shot_hash));
        append(&mut shot_input_bytes,to_bytes(&shot_x));
        append(&mut shot_input_bytes,to_bytes(&shot_y));
        append(&mut shot_input_bytes,to_bytes(&hit));
        let shot_proof_bytes: vector<u8> = x"e23b1e992b083bfd079e26c1ae83b7710589685bfe047b9c2498647d6ef585242d1a9bedca69e2d18beb5cd403baf59fa055b95e41861b042dc446febc774923519efb4075c2c1b09b29f030ecd15c9822b716583e86711baa2dfe547d4c761ba5e43de9ce277bfecd65c7693b5775794fd73b90157dc63b900b77afa9cedd0a";
        print(&shot_verify::verify(shot_input_bytes,shot_proof_bytes));
    }
}

module battleship::board_verifier {
    use std::vector;
    use sui::groth16;

    const VK_BYTES = x"f675d896123954189d34681ef5ce47b5e3260247e4ea6817f19c410b9f6fe3deb086e165056c02216a0e12114a9b410d76805e906193c8cd44b02fcd9d9b34fdb6b275ef5c13e7056fb61aa1870409b8020810f9b29aab6b339fa3f853c0e103";
    const ALPHA_BYTES = x"12168aa38a1ae0360550d0541002b024057ab689d45ce809f8ea36d5286eca9e2f18e70924ac69dcd432228a18036b146aa75a5c17430751f844f686c8ba210c7736adb1851f7afac7fbbc4ac78a01c7ca4508e3d45b5dd31e875c99b0c9d20004f4b3ad8e3c8842b6adc9c3797e3083a31b1ffe654dd4466743cd943b7d3185588a2d81da5f20b36593157c2429b21835964abb93670c81f4a9f230556dcedcc87a5c365613820e225225a650ba7d5a8d283db8317529b37297979ad7576405b26e53f2c162e35557eaf4e59e1b3d456d486291a644fe098f0d29c0435d46e35d114d7357188ed8a8fa26c807fa420e7bff7ce0c2a84a75f189cf6ed039564f36441236720be11bc53850f3700491f50430fe4729676564128f0bf326e67a0038975b396c6fd12c0cd8be75e5985e2841005640b6104b4e1e9817dd3b44e51aa4b0972489ad999bb8143a4e833110057ba32d1ff91c6707b07eab0605b9d6a2745aead54f16a968a4122fa8ca871b70a100b5fd854d4473ec7b519c04547f14b9aba6701e54e737161fc154cc3751f995c0c33d7ef74b893e6bc5514891d73af5543c4ed463e4aebe6cbbd97390bf0bf72075a0649e01a65fa2b7198bedac38406864dc780cb8789df0cb09cf532201d589bc40f84bf6a5816ccbd31ea85d0cf2e06c26037d6970caee38b507450bef282c40366bb4506408f17e331fde3211c0cb021c7858ba83e6a1f1d24bdf550b884d857ff0355ad83cd01346c62dca7197b4d54288ebc982d8228a8403e9a8bd95ef98775bf9c40004e2b5de3e663212";
    const GAMMA_BYTES = x"f63b997d4f3d45ed3e20e5cb0e17b0b962b62e9d64d5bc825fe571ffc15f98b10605758eaf440fe16513386c086c9e0b0bea1c30f8f8bf1667dcc47514a9adc4cd1b2d854c0fd2291e0140b7f6d34f31c3cb6c8ee635b9394821369154dd528a";
    const DELTA_BYTES = x"fdaacd48da6deedb190f27f59d9740c3607bbfcb2c0f8a590b4ee9071a9bda9532217f89aab2fd4e2d505f47cc113c00618849268b140fab6be405649a2d1d074983183287b8ee7a73c4dbb2ab4e7ba3bab7fa005a055a3dd26b4787fe11b505";

    public fun verify(input_bytes: &vector<u8>, proof_bytes: &vector<u8>):bool {
        return verify_groth16_proof(input_bytes, proof_bytes);
    }

    fun verify_groth16_proof(inputs_bytes: &vector<u8>, proof_bytes: &vector<u8>): bool {
        let pvk = groth16::pvk_from_bytes(VK_BYTES, ALPHA_BYTES, GAMMA_BYTES, DELTA_BYTES);
        let inputs = groth16::public_proof_inputs_from_bytes(inputs_bytes);
        let proof = groth16::proof_points_from_bytes(proof_bytes);
        return groth16::verify_groth16_proof(&pvk, &inputs, &proof);
    }

}
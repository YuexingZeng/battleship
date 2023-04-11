module battleship::board_verifier {
    use sui::groth16;
    use sui::groth16::bn254;

    const VK_BYTES: vector<u8> = x"79813d560980b99c9c38065b671cb1efc69f95b9af5b680c36b49413cd2e3daa83fd9406fe24b91cf876be8477e602ea0df3183749dacc902de5359cd290fd07";
    const ALPHA_BYTES: vector<u8> = x"4b2059a131d263819b8afdeba2c7c199e7927340701b1470ce211cb8f70e5c1ca2e8e3b5d21b73ce3087319401bb605e1afb5c0e3d1f49d9fe52bd8ccf80180e73057732b4daee5cf8fc861256c87a312ec5eeb7f13cf6231056094c0da155110a38e314d125ba932758286851945c049c99c35b129da373f15ae208092a321fb40c2286e43982975efd0ebce503ec64d79055120f25ebc5de8029c20fa38b27ec0d0eaee00718083d3cae33bc7b98442ab04cbf1843cb3e6c1c42eba7edcf2e5843ff16d8af4f40c8fc1a95392668fe66fcd1da76000a48c43b5ad5a7660718f223e81b8685964a73bc23eea581d1249f5f0c41cc2e53c9183588e0c0eaee08451f503d07a62b0157a2c47d583d3e2747cf329d088eb70a2fd1f841d6815f03775ec73a0668f9d7fa69443f5d2245ba250c2f81183c7c68aaeb409c571015236cc881ff3badd8203bdbc1b26e82ccdd1d8f45043f45f8758ed4e3aa9d0f4605b17c087ea06422b7243743156d3bbd6e87bbf760f8a54d9062db0e803c7d9b2f";
    const GAMMA_BYTES: vector<u8> = x"edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e99";
    const DELTA_BYTES: vector<u8> = x"129118b4f486852abf7061a21c7c6a1b3f046ff866bce6da47fd9c19a5453707488e471d4a6c023ab7ab2c9790a88a3aa2de6d0d080e04ee0feec13e3a5ab688";

    public fun verify(input_bytes: vector<u8>, proof_bytes: vector<u8>): bool {
        verify_groth16_proof(input_bytes, proof_bytes)
    }

    fun verify_groth16_proof(inputs_bytes: vector<u8>, proof_bytes: vector<u8>): bool {
        let curve = bn254();
        let pvk = groth16::pvk_from_bytes(VK_BYTES, ALPHA_BYTES, GAMMA_BYTES, DELTA_BYTES);
        let inputs = groth16::public_proof_inputs_from_bytes(inputs_bytes);
        let proof = groth16::proof_points_from_bytes(proof_bytes);
        groth16::verify_groth16_proof(&curve, &pvk, &inputs, &proof)
    }
}
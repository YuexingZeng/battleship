# Battleship game on the Sui blockChain
Battleship is a game of naval warfare built on the zero-knowledge proof (Groth16) system. In this game, two players engage in a battle without knowing the exact locations of each other's ships. Each player takes turns selecting a point on the board to fire upon. If a player hits an opponent's ship (the selected point overlaps with the coordinates of the opponent's ship), they score one point. The game is won when a player reaches the target score (maximum number of hits).

The two players in the game interact through the Battleship contract. Since it is necessary to hide some important information (the placement of each player's ships) and to ensure that both players follow the rules of the game, the Groth16 zero-knowledge proof system is introduced.

## Chessboard and Battleship Coordinates
![](./img/battleship.png)
As shown in the picture above, each player needs to place five battleships. The battleships can only be placed when starting the game or joining the game. Once confirmed, the position of the battleship cannot be changed later. The lengths of the five warships are 5, 4, 3, 3, and 2 cells respectively. The coordinates of the warships are composed of three components x, y, and z, where (x, y) can correspond to a certain point on the chessboard, and The value of z is 0 or 1, 0 indicates that the battleship is placed horizontally, and 1 indicates that the battleship is placed vertically. Given the coordinates and length of a battleship, it is possible to calculate which cells the battleship occupies on the chessboard.

## Circuits
In this game, there are two ZKP circuits: `board.circom` and `shot.circom`.

### board.circom
This circuit takes as input the coordinates of the five ships (a 5x3 array, private) and the hash of the ships (public). It verifies that the placement of the ships conforms to the rules of the game, by performing the following checks:

* Verifies that the ships are within the bounds of the chessboard (i.e., that they do not occupy cells outside of the chessboard).
* Ensures that the ships do not overlap with each other (i.e., that no two ships occupy the same cell).
* Checks that the input hash value corresponds to the given ships, i.e., that Hash(ships) = hash.

### shot.circom
This circuit takes as input the ships (same as above, private), the hash of the ships (same as above, public), the coordinates of the shot (x,y, public), and whether or not the shot hit a ship (a value of 1 or 0, public). It verifies whether or not a ship was hit by the shot, according to the following rules:

* Verifies that the shot falls within the bounds of the chessboard.
* Checks that the input hash value corresponds to the given ships, i.e., that Hash(ships) = hash.
* Checks whether the coordinates of the shot are contained in any of the cells occupied by the ships. Based on the result of this check, the circuit evaluates the hit assertion to determine whether or not the shot hit a ship.

## Contracts
The Battleship game contains one main contract and two verification contracts：`battleship.move`、`board_verifier.move`、`shot_verifier.move`

### groth16 in move
The standard library of the SUI Move provides the Groth16 verification algorithm through[groth16.move](https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/crypto/groth16.move),which allows the verification contracts to be considered as the verifiers in the Groth16 protocol. Thus, the verification contracts can be invoked to verify the validity of the proof.

Before deploying the contract, the circuits needs to be compiled and the setup of the Groth16 protocol needs to be executed to generate the proving key and verification key. The following tools can be used for this purpose:

* [circom](https://github.com/iden3/circom)
* [snarkjs](https://github.com/iden3/snarkjs)

After generating the verification key, the `VK_BYTES`, `ALPHA_BYTES`, `GAMMA_BYTES`, and `DELTA_BYTES` in `board_verifier.move` and `shot_verifier.move` need to be replaced with the corresponding parameters in the verification key (serialized to hex string format). Only then can board_verifier.move and shot_verifier.move act as verifiers. It is worth noting that one key in Groth16 can only correspond to one circuit. Therefore, board_verifier and shot_verifier should be different verification keys. The serialization of the parameters can be referenced in the[battleship test on sui blockchain](https://github.com/YuexingZeng/sui-test)

`board_verifier.move` and `shot_verifier.move` verify the corresponding proofs by calling the `verify_groth16_proof` function in `groth16.move`.

### battleship.move
This contract defines the main logic and rules of the battleship game. It includes four functions: `new_game`, `join_game`, `first_turn`, and `turn`. Below we will mainly explain how proof verification is conducted in these four functions, using Alice and Bob as examples:

* new_game: Alice creates the game. Before calling this function, witness and proof need to be generated for the ships she places (using [snarkjs](https://github.com/iden3/snarkjs)).`new_game` verifies the placement of the battleships by calling the `board_verifier` contract, ensuring that the position of the battleships is in compliance with the rules, and will not reveal their placement.

* join_game: Bob joins the game. Similar to new_game, the placement of his battleships is verified by calling the board_verifier contract.

* first_turn: Alice takes the first shot. The first_turn function does not involve proof verification.

* turn: Bob takes a shot. This function calls the shot_verifier to verify if the previous shot (Alice's shot) hit his battleships.

Afterwards, both parties take turns calling turn to interact with the game.

The contract also defines other interaction logic, please refer to [battleship.move](./sources/battleship.move) for details.









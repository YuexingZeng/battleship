module battleship::battleship {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use std::vector;

	struct State has key {
		id: UID,
		game_index: u64,
		games: Table<u64, Game>,
	}

	struct Game has key, store {
		id: UID,
		//nonce: u64,
		participants: vector<address>,
	}

    fun init(ctx: &mut TxContext) {
		let game_state = State {
			id: object::new(ctx),
			game_index: 0,
			games: table::new(ctx),
		};

		transfer::share_object(game_state);
	}

	public entry fun new_game(state: &mut State, ctx: &mut TxContext) {
		// todo: verify proof

		let game = Game {
			id: object::new(ctx),
			participants: vector[tx_context::sender(ctx)],
		};
		state.game_index = state.game_index + 1;
		table::add(&mut state.games, state.game_index, game);

		// todo: emit event
	}
}

module battleship::battleship {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use std::vector;
    use sui::address::from_u256;
    use sui::event;
    use battleship::board_verifier;
    use battleship::shot_verify;
    use std::vector::append;
    use sui::bcs::to_bytes;

    const HIT_MAX: u256 = 17;
    const EGameIndex: u64 = 1;
    const EPlaying: u64 = 2;
    const EFullAccounts: u64 = 3;
    const EGameOver: u64 = 4;
    const EFirstTurn: u64 = 5;
    const ETurn: u64 = 6;
    const ENonce: u64 = 7;
    const EBoardVerify: u64 = 8;
    const EShotVerify: u64 = 9;

    struct State has key {
        id: UID,
        game_index: u256,
        games: Table<u256, Game>,
        playing: Table<address, u256>,
    }

    struct Game has key, store {
        id: UID,
        nonce: u64,
        shots: Table<u64, vector<u256>>,
        hits: Table<u64, u256>,
        participants: vector<address>,
        boards: vector<vector<u8>>,
        hit_nonce: vector<u256>,
        winner: address
    }

    fun init(ctx: &mut TxContext) {
        let game_state = State {
            id: object::new(ctx),
            game_index: 0,
            games: table::new(ctx),
            playing: table::new(ctx),
        };

        transfer::share_object(game_state);
    }

    struct StartedEvent has copy, drop {
        nonce: u256,
        by: address,
    }

    struct JoindEvent has copy, drop {
        nonce: u256,
        by: address,
    }

    struct ShotEvent has copy, drop {
        x: u256,
        y: u256,
        game_index: u256,
    }

    struct ReportEvent has copy, drop {
        hit: u256,
        game_index: u256,
    }

    struct WonEvent has copy, drop {
        winner: address,
        nonce: u256,
        by: address,
    }

    public entry fun new_game(
        state: &mut State,
        board_hash: vector<u8>,
        proof: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(!table::contains(&mut state.playing, tx_context::sender(ctx)), EPlaying);
        assert!(board_verifier::verify(board_hash, proof) == true, EBoardVerify);
        let game = Game {
            id: object::new(ctx),
            participants: vector::empty<address>(),
            boards: vector::empty<vector<u8>>(),
            nonce: 0,
            shots: table::new(ctx),
            hits: table::new(ctx),
            hit_nonce: vector[0x0, 0x0],
            winner: from_u256(0),
        };
        vector::push_back<address>(&mut game.participants, tx_context::sender(ctx));
        vector::push_back<vector<u8>>(&mut game.boards, board_hash);
        state.game_index = state.game_index + 1;
        table::add(&mut state.playing, tx_context::sender(ctx), state.game_index);
        table::add(&mut state.games, state.game_index, game);

        event::emit(StartedEvent {
            nonce: state.game_index,
            by: tx_context::sender(ctx)
        });
    }

    public entry fun join_game(
        state: &mut State,
        game_index: u256,
        board_hash: vector<u8>,
        proof: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(!table::contains(&mut state.playing, tx_context::sender(ctx)), EPlaying);
        assert!(table::contains(&mut state.games, game_index), EGameIndex);
        assert!(vector::length(&table::borrow_mut(&mut state.games, game_index).participants) == 1, EFullAccounts);
        assert!(board_verifier::verify(board_hash, proof) == true, EBoardVerify);
        let game = table::borrow_mut(&mut state.games, game_index);
        vector::push_back<address>(&mut game.participants, tx_context::sender(ctx));
        vector::push_back<vector<u8>>(&mut game.boards, board_hash);
        table::add(&mut state.playing, tx_context::sender(ctx), game_index);

        event::emit(JoindEvent {
            nonce: game_index,
            by: tx_context::sender(ctx)
        })
    }

    public entry fun first_turn(state: &mut State, game_index: u256, shot_x: u256, shot_y: u256, ctx: &mut TxContext) {
        assert!(table::contains(&mut state.games, game_index), EGameIndex);
        let game: &mut Game = table::borrow_mut(&mut state.games, game_index);
        assert!(*table::borrow(&state.playing, tx_context::sender(ctx)) == game_index, EPlaying);
        assert!(game.winner == from_u256(0), EGameOver);
        assert!(game.nonce == 0, EFirstTurn);
        let shot: vector<u256> = vector[shot_x, shot_y];
        table::add(&mut game.shots, game.nonce, shot);
        game.nonce = game.nonce + 1;

        event::emit(ShotEvent {
            x: shot_x,
            y: shot_y,
            game_index
        });
    }

    public entry fun turn(
        state: &mut State,
        game_index: u256,
        hit: u256,
        next_x: u256,
        next_y: u256,
        proof: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(table::contains(&mut state.games, game_index), EGameIndex);
        let game: &mut Game = table::borrow_mut(&mut state.games, game_index);
        assert!(*table::borrow(&state.playing, tx_context::sender(ctx)) == game_index, EPlaying);
        assert!(game.winner == from_u256(0), EGameOver);
        let current: address;
        if (game.nonce % 2 == 0) {
            current = *vector::borrow(&game.participants, 0);
        } else {
            current = *vector::borrow(&game.participants, 1);
        };
        assert!(tx_context::sender(ctx) == current, ETurn);
        assert!(game.nonce != 0, ENonce);
        let board_hash: vector<u8> = *vector::borrow(&game.boards,game.nonce%2);
        let shot: vector<u256> = *table::borrow(&game.shots,game.nonce-1);
        let shot_input_bytes: vector<u8> = vector::empty();
        append(&mut shot_input_bytes,board_hash);
        append(&mut shot_input_bytes,to_bytes(vector::borrow(&shot,0)));
        append(&mut shot_input_bytes,to_bytes(vector::borrow(&shot,1)));
        append(&mut shot_input_bytes,to_bytes(&hit));
        assert!(shot_verify::verify(shot_input_bytes,proof)==true,EShotVerify);
        table::add(&mut game.hits, game.nonce - 1, hit);
        if (hit>0) {
            *vector::borrow_mut(&mut game.hit_nonce, (game.nonce - 1) % 2) = *vector::borrow_mut(&mut game.hit_nonce, (game.nonce - 1) % 2) + 1;
        } ;
        event::emit(ReportEvent {
            hit,
            game_index
        });

        if (*vector::borrow(&game.hit_nonce, (game.nonce - 1) % 2) >= HIT_MAX) {
            game_over(state, game_index);
        } else {
            let next: vector<u256> = vector[next_x, next_y];
            table::add(&mut game.shots, game.nonce, next);
            game.nonce = game.nonce + 1;
            event::emit(ShotEvent {
                x: next_x,
                y: next_y,
                game_index
            })
        }
    }

    public fun game_over(state: &mut State, game_index: u256) {
        let game: &mut Game = table::borrow_mut(&mut state.games, game_index);
        assert!(
            *vector::borrow(&game.hit_nonce, 0) == HIT_MAX || *vector::borrow(&game.hit_nonce, 1) == HIT_MAX,
            EGameOver
        );
        assert!(game.winner == from_u256(0), EGameOver);
        if (*vector::borrow(&game.hit_nonce, 0) == HIT_MAX) {
            game.winner = *vector::borrow(&game.participants, 0);
        } else {
            game.winner = *vector::borrow(&game.participants, 1);
        };
        event::emit(WonEvent {
            winner: game.winner,
            nonce: game_index,
            by: game.winner
        });
    }
}

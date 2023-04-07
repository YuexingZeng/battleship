module battleship::battleship {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use std::vector;
    use sui::address::from_u256;
    use sui::event;

    const HIT_MAX: u256 = 17;
    const EGameIndex: u64 = 1;
    const EPlaying: u64 = 2;
    const EFullAccounts: u64 = 3;
    const EGameOver: u64 = 4;
    const EFirstTurn: u64 = 5;
    const ETurn: u64 = 6;
    const ENonce: u64 = 7;

    struct State has key {
        id: UID,
        game_index: u256,
        games: Table<u256, Game>,
        playing: Table<address, u256>,
    }

    struct Game has key, store {
        id: UID,
        nonce: u256,
        shots: Table<u256, vector<u256>>,
        hits: Table<u256, bool>,
        participants: vector<address>,
        boards: vector<u256>,
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

    struct StartedEvent has copy,drop{
        nonce: u256,
        by: address,
    }

    struct JoindEvent has copy,drop{
        nonce: u256,
        by: address,
    }

    struct ShotEvent has copy,drop{
        x: u256,
        y: u256,
        game_index: u256,
    }

    struct ReportEvent has copy,drop{
        hit: bool,
        game_index: u256,
    }

    struct WonEvent has copy,drop{
        winner: address,
        nonce: u256,
        by: address,
    }

    public entry fun new_game(state: &mut State, board_hash: u256, ctx: &mut TxContext) {
        // todo: verify proof
        assert!(!table::contains(&mut state.playing, tx_context::sender(ctx)), EPlaying);
        let game = Game {
            id: object::new(ctx),
            participants: vector::empty<address>(),
            boards: vector::empty<u256>(),
            nonce: 0,
            shots: table::new(ctx),
            hits: table::new(ctx),
            hit_nonce: vector[0x0,0x0],
            winner: from_u256(0),
        };
        vector::push_back<address>(&mut game.participants, tx_context::sender(ctx));
        vector::push_back<u256>(&mut game.boards, board_hash);
        state.game_index = state.game_index + 1;
        table::add(&mut state.playing, tx_context::sender(ctx), state.game_index);
        table::add(&mut state.games, state.game_index, game);

        event::emit(StartedEvent {
            nonce: state.game_index,
            by: tx_context::sender(ctx)
        });
    }

    public entry fun join_game(state: &mut State, game_index: u256, board_hash: u256, ctx: &mut TxContext) {
        assert!(!table::contains(&mut state.playing, tx_context::sender(ctx)), EPlaying);
        assert!(table::contains(&mut state.games, game_index), EGameIndex);
        assert!(vector::length(&table::borrow_mut(&mut state.games, game_index).participants) == 1, EFullAccounts);
        // todo: verify proof
        let game = table::borrow_mut(&mut state.games, game_index);
        vector::push_back<address>(&mut game.participants, tx_context::sender(ctx));
        vector::push_back<u256>(&mut game.boards, board_hash);
        table::add(&mut state.playing, tx_context::sender(ctx), game_index);

        event::emit(JoindEvent{
            nonce: game_index,
            by:tx_context::sender(ctx)
        })
    }

    public entry fun first_turn(state: &mut State, game_index: u256, shot_x: u256,shot_y:u256,ctx: &mut TxContext) {
        assert!(table::contains(&mut state.games, game_index), EGameIndex);
        let game: &mut Game = table::borrow_mut(&mut state.games, game_index);
        assert!(*table::borrow(&state.playing, tx_context::sender(ctx)) == game_index, EPlaying);
        assert!(game.winner == from_u256(0), EGameOver);
        assert!(game.nonce == 0, EFirstTurn);
        let shot: vector<u256> = vector[shot_x,shot_y];
        table::add(&mut game.shots, game.nonce, shot);
        game.nonce = game.nonce + 1;
        // todo: emit event
        event::emit(ShotEvent{
            x: shot_x,
            y: shot_y,
            game_index
        });
    }

    public entry fun turn(state: &mut State, game_index: u256, hit: bool, next_x: u256,next_y: u256, ctx: &mut TxContext) {
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
        // todo: verify proof
        table::add(&mut game.hits, game.nonce - 1, hit);
        let i: u64;
        if ((game.nonce - 1) % 2 == 0) {
            i = 0;
        } else {
            i = 1;
        };
        if (hit) {
            *vector::borrow_mut(&mut game.hit_nonce, i) = *vector::borrow_mut(&mut game.hit_nonce, i) + 1;
        } ;
        event::emit(ReportEvent {
            hit,
            game_index
        });

        if (*vector::borrow(&game.hit_nonce, i) >= HIT_MAX) {
            game_over(state, game_index);
        } else {
            let next: vector<u256> = vector[next_x,next_y];
            table::add(&mut game.shots, game.nonce, next);
            game.nonce = game.nonce + 1;
            event::emit(ShotEvent{
                x: next_x,
                y: next_y,
                game_index
            })
        }
    }

    // public fun game_state(state: &mut State, game_index: u256){
    //
    // }

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
        event::emit(WonEvent{
            winner: game.winner,
            nonce: game_index,
            by: game.winner
        });
    }
}

module challenge::arena {

use challenge::hero::{Self, Hero};
use sui::event;
use sui::object::{Self, UID, ID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};

// ========= STRUCTS =========

public struct Arena has key, store {
    id: UID,
    warrior: Hero, // Gelen Hero objesi bu alanda tüketilecek.
    owner: address,
}

// ========= EVENTS =========

public struct ArenaCreated has copy, drop {
    arena_id: ID,
    timestamp: u64,
}

public struct ArenaCompleted has copy, drop {
    winner_hero_id: ID,
    loser_hero_id: ID,
    timestamp: u64,
}

// ========= FUNCTIONS =========

// create_arena fonksiyonu: Gelen Hero objesini tüketerek bir Arena objesi oluşturur ve bunu herkesle paylaşır (share).
public fun create_arena(hero: Hero, ctx: &mut TxContext) {
    // Arena objesi oluşturuluyor
    let arena = Arena {
        id: object::new(ctx),
        warrior: hero, // Hero objesi burada tüketiliyor (Consume)
        owner: tx_context::sender(ctx),
    };

    // ArenaCreated event'i yayınlanıyor
    event::emit(ArenaCreated {
        arena_id: object::id(&arena),
        timestamp: tx_context::epoch_timestamp_ms(ctx),
    });

    // Arena objesi publicly tradeable yapmak için paylaşılıyor
    transfer::share_object(arena);
}

// battle fonksiyonu: İki Hero'yu karşılaştırır, kazananı Arena sahibine veya çağırana transfer eder ve Arena'yı siler.
#[allow(lint(self_transfer))]
public fun battle(hero: Hero, arena: Arena, ctx: &mut TxContext) {

    // Arena objesi yapılandırılıyor (destructure)
    let Arena { id, warrior, owner: arena_owner } = arena;
    
    // Güç karşılaştırması yapılıyor
    let challenger_power = hero::hero_power(&hero);
    let warrior_power = hero::hero_power(&warrior);

    // Kazananın alacağı adres (Battle'ı kimin başlattığı)
    let challenger_address = tx_context::sender(ctx);

    // Geçici ID'ler event için alınıyor (objeler transfer edilmeden önce)
    let challenger_hero_id = object::id(&hero);
    let warrior_hero_id = object::id(&warrior);

    if (challenger_power > warrior_power) {
        // CHALLENGER (hero) KAZANIRSA:
        // İki hero da çağırana (challenger) geri gönderilir.
        transfer::transfer(hero, challenger_address);
        transfer::transfer(warrior, challenger_address);

        // ArenaCompleted event'i yayınlanıyor
        event::emit(ArenaCompleted {
            winner_hero_id: challenger_hero_id,
            loser_hero_id: warrior_hero_id,
            timestamp: tx_context::epoch_timestamp_ms(ctx),
        });

    } else {
        // WARRIOR (arena'daki hero) KAZANIRSA veya BERABERE KALIRSA:
        // İki hero da Arena sahibine geri gönderilir.
        transfer::transfer(hero, arena_owner);
        transfer::transfer(warrior, arena_owner);
        
        // ArenaCompleted event'i yayınlanıyor
        event::emit(ArenaCompleted {
            winner_hero_id: warrior_hero_id,
            loser_hero_id: challenger_hero_id,
            timestamp: tx_context::epoch_timestamp_ms(ctx),
        });
    };
    
    // Battle sona erdiği için Arena objesi siliniyor (UID'yi tüketerek)
    object::delete(id);
}
}

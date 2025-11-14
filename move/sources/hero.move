module challenge::hero {

use sui::object::{Self, UID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};
use sui::bcs;
use std::string::String;

// ========= STRUCTS =========

// Hero objesi, bir Arena'da savaşçı olarak kullanılacağı için 'drop' yeteneği yoktur.
public struct Hero has key, store {
    id: UID,
    name: String,
    image_url: String,
    power: u64,
}

// ========= FUNCTIONS =========

// Yeni bir Hero objesi oluşturur ve transfer eder.
public fun create_hero(name: String, image_url: String, power: u64, ctx: &mut TxContext) {
    let hero = Hero {
        id: object::new(ctx),
        name: name,
        image_url: image_url,
        power: power,
    };
    
    // Oluşturulan Hero objesi, onu çağıran adrese transfer edilir.
    transfer::public_transfer(hero, tx_context::sender(ctx));
}

// Hero'nun güç değerini döndürür.
public fun hero_power(hero: &Hero): u64 {
    hero.power
}

// Hero objesinin ID'sini döndürür.
public fun hero_id(hero: &Hero): ID {
    object::id(hero)
}

// Hero objesini siler (Bu genellikle kullanılmaz, ancak kaynak temizliği için gerekebilir.)
public fun destroy_hero(hero: Hero) {
    let Hero { id, name: _, image_url: _, power: _ } = hero;
    object::delete(id);
}

// Hero objesini bir adresin sahip olduğu ID'ye göre transfer eder
public fun transfer_hero(hero: Hero, recipient: address) {
    transfer::public_transfer(hero, recipient);
}
}

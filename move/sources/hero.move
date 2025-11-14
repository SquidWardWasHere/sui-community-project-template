module challenge::hero {

use sui::object::{Self, UID, ID}; // ID'yi burada tutalım, Hero ID döndürmede kullanılacak.
use sui::transfer;
use sui::tx_context::{Self, TxContext};
use std::string::String;

// ========= STRUCTS =========

public struct Hero has key, store {
    id: UID,
    name: String,
    image_url: String,
    power: u64,
}

// ========= FUNCTIONS =========

// Yeni bir Hero objesi oluşturur ve Hero objesini geri döndürür.
// Artık transfer işlemi çağıran (front-end) tarafından yapılmalıdır.
public fun create_hero(name: String, image_url: String, power: u64, ctx: &mut TxContext): Hero {
    Hero {
        id: object::new(ctx),
        name: name,
        image_url: image_url,
        power: power,
    }
    // NOT: Artık burada transfer::public_transfer yok. Objeyi döndürerek,
    // çağıranın programlanabilir işlemlerde onu kullanmasına olanak tanıyoruz.
}

// Hero'nun güç değerini döndürür.
public fun hero_power(hero: &Hero): u64 {
    hero.power
}

// Hero objesinin ID'sini döndürür.
public fun hero_id(hero: &Hero): ID {
    object::id(hero)
}

// Hero objesini siler
public fun destroy_hero(hero: Hero) {
    let Hero { id, name: _, image_url: _, power: _ } = hero;
    object::delete(id);
}

// Hero objesini bir adrese transfer eder (Bu fonksiyon, programlanabilir işlemler dışındaki senaryolar için tutulabilir)
public fun transfer_hero(hero: Hero, recipient: address) {
    transfer::public_transfer(hero, recipient);
}
}

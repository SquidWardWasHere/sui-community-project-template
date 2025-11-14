module challenge::marketplace {

use challenge::hero::{Self, Hero, transfer_hero};
use sui::object::{Self, UID, ID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};
use sui::coin::{Self, Coin, from_balance}; // coin::from_balance fonksiyonunu doğrudan çağırabilmek için from_balance eklendi
use sui::sui::SUI;
use sui::event;
use sui::balance;

// ========= ERROR CODES =========

const EInvalidPayment: u64 = 1;

// ========= STRUCTS =========

public struct ListHero has key, store {
    id: UID, // DÜZELTME: ListHero objesi "key" yeteneğine sahip olduğu için ilk alan zorunlu olarak 'id: UID' olmalı
    nft: Hero,
    price: u64,
    seller: address,
}

public struct AdminCap has key, store {
    id: UID, // DÜZELTME: AdminCap objesi "key" yeteneğine sahip olduğu için zorunlu olarak 'id: UID' eklendi
}

// ========= EVENTS (Aynı kaldı) =========

public struct HeroListed has copy, drop {
    list_hero_id: ID,
    price: u64,
    seller: address,
    timestamp: u64,
}

public struct HeroBought has copy, drop {
    list_hero_id: ID,
    price: u64,
    buyer: address,
    seller: address,
    timestamp: u64,
}

// ========= FUNCTIONS =========

// Marketplace'in ilk başlatılması
fun init(ctx: &mut TxContext) {
    // AdminCap objesi oluşturuluyor (ID'si object::new(ctx) ile atanır)
    let admin_cap = AdminCap { id: object::new(ctx) };
    // AdminCap objesi oluşturulur ve göndericiye transfer edilir
    transfer::transfer(admin_cap, tx_context::sender(ctx));
}

// Bir Hero objesini Marketplace'e listeler
public fun list_hero(nft: Hero, price: u64, ctx: &mut TxContext) {
    let seller = tx_context::sender(ctx);

    // ListHero objesi oluşturuluyor (Hero objesi tüketiliyor)
    let list_hero = ListHero {
        id: object::new(ctx),
        nft: nft,
        price: price,
        seller: seller,
    };

    // HeroListed event'i yayınlanıyor
    event::emit(HeroListed {
        list_hero_id: object::id(&list_hero), // DÜZELTME: Struct'ın tamamı key olduğu için object::id(&list_hero) kullanılabilir
        price: price,
        seller: seller,
        timestamp: tx_context::epoch_timestamp_ms(ctx),
    });

    // Marketplace'te herkesin görebilmesi için obje paylaşılıyor
    transfer::share_object(list_hero);
}

// Listelenen bir Hero objesini satın alır
public fun buy_hero(list_hero: ListHero, payment: Coin<SUI>, ctx: &mut TxContext) {
    // ListHero objesini yapılandırıyoruz (tüketiliyor)
    let ListHero { id, nft, price, seller } = list_hero;
    let buyer = tx_context::sender(ctx);

    // Ödeme kontrolü: Yeterli para var mı?
    assert!(coin::value(&payment) >= price, EInvalidPayment);

    // 1. NFT'yi alıcıya gönder
    transfer_hero(nft, buyer);

    // 2. Parayı satıcıya gönder
    let balance = coin::into_balance(payment); // Coin'i Balance'a çeviriyoruz
    let mut balance_mut = balance; // balance'ı mut olarak tanımla
    let change = balance::split(&mut balance_mut, price); // Fiyat kadarını ayırıyoruz

    // Fiyatı satıcının adresine transfer ediyoruz
    // DÜZELTME: from_balance artık 2. argüman olarak ctx: &mut TxContext gerektiriyor
    transfer::public_transfer(from_balance(balance_mut, ctx), seller);

    // Fazlalığı (change) alıcıya geri gönderiyoruz
    if (balance::value(&change) > 0) {
        // DÜZELTME: from_balance artık 2. argüman olarak ctx: &mut TxContext gerektiriyor
        transfer::public_transfer(from_balance(change, ctx), buyer);
    };

    // HeroBought event'i yayınlanıyor
    event::emit(HeroBought {
        list_hero_id: object::id(&id),
        price: price,
        buyer: buyer,
        seller: seller,
        timestamp: tx_context::epoch_timestamp_ms(ctx),
    });

    // Liste kaydını siliyoruz
    object::delete(id);
}

// Bir Hero objesini listelemeden kaldırır (Yönetici yetkisi gerekir)
public fun delist(_: &AdminCap, list_hero: ListHero, ctx: &mut TxContext) {
    // ListHero objesini yapılandırıyoruz (tüketiliyor)
    let ListHero { id, nft, price: _, seller: _ } = list_hero;
    let sender = tx_context::sender(ctx);

    // NFT'yi listeleme sahibine geri gönder
    transfer_hero(nft, sender);

    // Liste kaydını siliyoruz
    object::delete(id);
}

// Listelenen bir Hero objesinin fiyatını günceller (Yönetici yetkisi gerekir)
public fun change_the_price(_: &AdminCap, list_hero: &mut ListHero, new_price: u64) {
    list_hero.price = new_price;
}
}

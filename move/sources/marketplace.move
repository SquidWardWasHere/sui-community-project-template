module challenge::marketplace {

use challenge::hero::{Self, Hero, transfer_hero}; // Hero transfer fonksiyonunu kullanmak için içe aktarıldı
use sui::object::{Self, UID, ID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use sui::event;
use sui::balance;

// ========= ERROR CODES =========

const EInvalidPayment: u64 = 1;

// ========= STRUCTS =========

public struct ListHero has key, store {
    id: UID,
    nft: Hero,
    price: u64,
    seller: address,
}

public struct AdminCap has key, store {}

// ========= EVENTS =========

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
fun init(_ctx: &mut TxContext) {
    // AdminCap objesi oluşturulur ve göndericiye transfer edilir
    transfer::transfer(AdminCap {}, tx_context::sender(_ctx));
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
        list_hero_id: object::id(&list_hero),
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
    let change = balance::split(&mut balance, price); // Fiyat kadarını ayırıyoruz

    // Fiyatı satıcının adresine transfer ediyoruz
    transfer::public_transfer(coin::from_balance(balance), seller);

    // Fazlalığı (change) alıcıya geri gönderiyoruz
    if (balance::value(&change) > 0) {
        transfer::public_transfer(coin::from_balance(change), buyer);
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

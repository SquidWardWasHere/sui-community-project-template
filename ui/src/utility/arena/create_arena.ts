import { Transaction } from "@mysten/sui/transactions";

export const createArena = (packageId: string, heroId: string) => {
  const tx = new Transaction();
  
  // TODO: Add moveCall to create a battle place
  tx.moveCall({
    target: `${packageId}::arena::create_arena`,
    arguments: [
      // 1. Argüman: heroId
      // heroId bir Object ID olduğu için tx.object() ile referans edilmelidir.
      tx.object(heroId),
    ],
  });
  
  return tx;
};

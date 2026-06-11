import { db } from "../config/db.js";
import { birds } from "../db/schema.js";
import { birdsData } from "../seed/birds.js";
import { eq } from "drizzle-orm";
async function seedBirds() {
  try {
    for (const bird of birdsData) {
  await db
    .update(birds)
    .set({
      scientific_name: bird.scientific_name,
      description: bird.description,
      habitat: bird.habitat,
      conservation_status: bird.conservation_status
    })
    .where(eq(birds.name, bird.name));
}
    console.log(`Inserted ${birdsData.length} birds`);
    process.exit(0);
    } 
    catch (error) {
    console.error("Seeding failed:",error);
    process.exit(1);
  }
}
seedBirds();
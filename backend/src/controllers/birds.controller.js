import {db} from "../config/db.js";
import {birds} from "../db/schema.js";
import {eq,and} from 'drizzle-orm';

export const getAllBirds = async (req, res) => {
    try {
        const { bird_id } = req.params;
        if (!bird_id) {
            return res.status(400).json({ message: "Bird ID is required" });
        }
        const birdDetails = await db.select().from(birds).where(eq(birds.id, bird_id));
        if (birdDetails.length === 0) {
            return res.status(404).json({ message: "Bird not found" });
        }
        res.status(200).json(birdDetails[0]);
    } catch (error) {
        console.error("Error fetching bird details:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
};
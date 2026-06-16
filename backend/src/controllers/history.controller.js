import {db} from "../config/db.js";
import {history,birds} from "../db/schema.js";
import {eq,and,desc} from 'drizzle-orm';
import { enrichBird,enrichBirds } from "../utils/birdResponse.js";
export const getHistory = async (req, res) => {
    try {
        const user_id = req.user.id;
        if (!user_id) {
            return res.status(401).json({ message: "Unauthorized" });
        }
    const historyBirdsRaw = await db.select({
    history_id: history.id,
    bird_id: birds.id,
    name: birds.name,
    aws_image_key: birds.aws_image_key,
    habitat: birds.habitat ,
    confidence: history.confidence,
    predicted_at: history.predicted_at,
  }).from(history).innerJoin(
    birds,
    eq(history.bird_id, birds.id)
  ).where(eq(history.user_id, user_id))
  .orderBy(desc(history.predicted_at));
        if (historyBirdsRaw.length === 0) {
            return res.status(200).json([]);
        }
        const historyBirds = await enrichBirds(historyBirdsRaw);
        return res.status(200).json(historyBirds);
    }
    catch (error) {
        console.error("Error fetching history:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
};

export const deleteAllHistory = async (req, res) => {
    try {
        const user_id = req.user.id;
        if (!user_id) {
            return res.status(401).json({ message: "Unauthorized" });
        }
        await db.delete(history).where(eq(history.user_id, user_id));
        res.status(200).json({ message: "History removed successfully" });
    } catch (error) {
        console.error("Error removing history:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
};
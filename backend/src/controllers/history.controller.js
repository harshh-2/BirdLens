import {db} from "../config/db.js";
import {history,birds} from "../db/schema.js";
import {eq,and} from 'drizzle-orm';

export const addHistory = async (req,res)=>{
    try{
        const{user_id,bird_id}=req.body;
        if(!user_id || !bird_id){
            return res.status(400).json({message:"Not Identified"});
        }
        const newHistory = await db.insert(history).values({
            user_id,
            bird_id,
        }).returning();
        res.status(201).json(newHistory[0]);
    }
    catch(error){
        console.error("Error adding to history:",error);
        res.status(500).json({message:"Error connecting to database",error:error.message});
    }
};

export const getHistory = async (req, res) => {
    try {
        const {user_id} = req.params;
        if (!user_id) {
            return res.status(400).json({ message: "User ID is required" });
        }
        const userHistory = await db.select().from(history).where(eq(history.user_id, user_id));
        const historyBirds = await db.select({history_id: history.id,bird_id: birds.id,name: birds.name,image_url: birds.image_url,viewed_at: history.viewed_at,}).from(history).innerJoin(birds,eq(history.bird_id, birds.id)).where(eq(history.user_id, user_id));
        if (historyBirds.length === 0) {
            return res.status(200).json([]);
        }
        res.status(200).json(historyBirds);
    }
    catch (error) {
        console.error("Error fetching history:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
};

export const deleteAllHistory = async (req, res) => {
    try {
        const { user_id } = req.body;
        if (!user_id) {
            return res.status(400).json({ message: "User ID is required" });
        }
        await db.delete(history).where(eq(history.user_id, user_id));
        res.status(200).json({ message: "History removed successfully" });
    } catch (error) {
        console.error("Error removing history:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
};
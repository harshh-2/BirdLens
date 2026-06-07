import {db} from "../config/db.js";
import {favorites,birds} from "../db/schema.js";
import {eq,and} from 'drizzle-orm';

export const addFavorite = async (req,res)=> {
    try{
        const user_id = req.user.id;
        if (!user_id) {
            return res.status(401).json({ message: "Unauthorized" });
        }
        const{bird_id}=req.body;
        if(!user_id || !bird_id){
            return res.status(400).json({message:"Not Identified"});
        }
        const newFavorite = await db.insert(favorites).values({
            user_id,
            bird_id,
        }).returning();
        res.status(201).json(newFavorite[0]);
    }
    catch(error){
        console.error("Error adding to favorites:",error);
        res.status(500).json({message:"Error connecting to database",error:error.message});
    }
};

export const getFavorites = async (req, res) => {
    try {
        const user_id = req.user.id;
        if (!user_id) {
            return res.status(400).json({ message: "User ID is required" });
        }
        const favoriteBirds = await db.select({bird_id: birds.id,name: birds.name,image_url: birds.image_url,created_at: favorites.created_at,}).from(favorites).innerJoin(birds,eq(favorites.bird_id, birds.id)).where(eq(favorites.user_id, user_id));
        if (favoriteBirds.length === 0) {
        return res.status(200).json([]);
        }
        res.status(200).json(favoriteBirds);
    }
    catch (error) {
        console.error("Error fetching favorites:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
}

export const deleteFavorite = async (req, res) => {
    try {
        const user_id = req.user.id;
        if (!user_id) {
            return res.status(401).json({ message: "Unauthorized" });
        }
        const { bird_id } = req.body;
        if (!bird_id) {
            return res.status(400).json({ message: "User ID and Bird ID are required" });
        }
        await db.delete(favorites).where(and(eq(favorites.user_id, user_id), eq(favorites.bird_id, bird_id)));
        res.status(200).json({ message: "Favorite removed successfully" });
    } catch (error) {
        console.error("Error removing favorite:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
};
import express from 'express';
import cors from 'cors';
import {ENV} from "./config/env.js";
import { favorites, history,birds } from "./db/schema.js";
import {db} from "./config/db.js";
import {and,eq,inArray} from 'drizzle-orm';
import {job} from './config/cron.js';

const app=express();
const PORT= ENV.PORT;
app.use(cors());
app.use(express.json());
if(ENV.NODE_ENV === 'production'){
    job.start();
}
app.get('/api/health',(req,res)=>{
    res.status(200).json({message:"Server is running successfully"});
});

//send to favorites endpoint 
app.post('/api/favorites', async (req,res)=>{
    try{
        const{user_id,bird_id}=req.body;
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
});

//send to history endpoint
app.post('/api/history', async (req,res)=>{
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
});

//get bird details endpoint
app.get('/api/bird_details/:bird_id', async (req, res) => {
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
});

//get favorites endpoint
app.get('/api/favorites/:user_id', async (req, res) => {
    try {
        const {user_id} = req.params;
        if (!user_id) {
            return res.status(400).json({ message: "User ID is required" });
        }
        const userFavorites = await db.select().from(favorites).where(eq(favorites.user_id, user_id));
        const birdIds = userFavorites.map(fav => fav.bird_id);
        if (birdIds.length === 0) {
            return res.status(200).json([]);
        }
        const favoriteBirds = await db.select({bird_id: birds.id,name: birds.name,image_url: birds.image_url,created_at: favorites.created_at,}).from(favorites).innerJoin(birds,eq(favorites.bird_id, birds.id)).where(eq(favorites.user_id, user_id));
        res.status(200).json(favoriteBirds);
    }
    catch (error) {
        console.error("Error fetching favorites:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
});

//get history endpoint
app.get('/api/history/:user_id', async (req, res) => {
    try {
        const {user_id} = req.params;
        if (!user_id) {
            return res.status(400).json({ message: "User ID is required" });
        }
        const userHistory = await db.select().from(history).where(eq(history.user_id, user_id));
        const birdIds = userHistory.map(hist => hist.bird_id);
        if (birdIds.length === 0) {
            return res.status(200).json([]);
        }
        const historyBirds = await db.select({history_id: history.id,bird_id: birds.id,name: birds.name,image_url: birds.image_url,viewed_at: history.viewed_at,}).from(history).innerJoin(birds,eq(history.bird_id, birds.id)).where(eq(history.user_id, user_id));
        res.status(200).json(historyBirds);
    }
    catch (error) {
        console.error("Error fetching history:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
});


//delete from favorites endpoint
app.delete('/api/favorites', async (req, res) => {
    try {
        const { user_id, bird_id } = req.body;
        if (!user_id || !bird_id) {
            return res.status(400).json({ message: "User ID and Bird ID are required" });
        }
        await db.delete(favorites).where(and(eq(favorites.user_id, user_id), eq(favorites.bird_id, bird_id)));
        res.status(200).json({ message: "Favorite removed successfully" });
    } catch (error) {
        console.error("Error removing favorite:", error);
        res.status(500).json({ message: "Error connecting to database", error: error.message });
    }
});

//delete all history endpoint
app.delete('/api/history', async (req, res) => {
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
});

app.listen(PORT, () => {
    console.log("Server is running on port " + PORT);
});

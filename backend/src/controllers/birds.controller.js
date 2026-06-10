import {db} from "../config/db.js";
import {birds,history} from "../db/schema.js";
import {eq} from 'drizzle-orm';
import { predictFromML } from "../services/ml.service.js";

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



export const predictBirds = async(req,res)=>{
    try{
        if(!req.file){
            return res.status(400).json({
                message:"Image is required"
            });
        }
        const prediction =
            await predictFromML(req.file);
        const bird = await db.select().from(birds).where(eq(birds.name,prediction.bird));
        if (bird.length === 0) {
            return res.status(404).json({
            message: "Bird not found"
            });
        }
        const birdRecord = bird[0];
        if (req.user?.id) {
            await db.insert(history).values({
                    user_id: req.user.id,
                    bird_id: birdRecord.id,
                    confidence:
                        prediction.confidence.toString(),
                    uploaded_image_url: null
                });
        }
        return res.status(200).json({
        ...prediction,
         bird:birdRecord
         
});
}
    catch(error){
        console.error(error);
        return res.status(500).json({
            message:"Prediction failed",
            error:error.message
        });
    }
}
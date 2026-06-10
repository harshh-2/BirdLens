import express from 'express';
import {getAllBirds, predictBirds} from '../controllers/birds.controller.js';
import { upload } from '../middleware/upload.middleware.js';
import { protectRoute } from '../middleware/auth.middleware.js';
const router=express.Router();

router.get('/:bird_id', getAllBirds);
router.post('/predict',protectRoute,upload.single('image'),predictBirds)

export default router;
import express from 'express';
import {getAllBirds} from '../controllers/birds.controller.js';

const router=express.Router();

router.get('/', getAllBirds);

export default router;
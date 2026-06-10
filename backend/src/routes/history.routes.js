import express from 'express';
import {getHistory, deleteAllHistory} from '../controllers/history.controller.js';
import { protectRoute } from '../middleware/auth.middleware.js';
const router=express.Router();

router.get('/', protectRoute, getHistory);
router.delete('/', protectRoute, deleteAllHistory);

export default router;
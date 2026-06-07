import express from 'express';
import {addFavorite, getFavorites, deleteFavorite} from '../controllers/favorites.controller.js';
import { protectRoute } from '../middleware/auth.middleware.js';
const router=express.Router();

router.post('/', protectRoute, addFavorite);
router.get('/', protectRoute, getFavorites);
router.delete('/', protectRoute, deleteFavorite);

export default router;

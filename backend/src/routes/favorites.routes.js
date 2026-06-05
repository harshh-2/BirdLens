import express from 'express';
import {addFavorite, getFavorites, deleteFavorite} from '../controllers/favorites.controller.js';

const router=express.Router();

router.post('/', addFavorite);
router.get('/:user_id', getFavorites);
router.delete('/', deleteFavorite);

export default router;
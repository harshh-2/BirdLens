import express from 'express';
import {addHistory, getHistory, deleteAllHistory} from '../controllers/history.controller.js';

const router=express.Router();

router.post('/', addHistory);
router.get('/:user_id', getHistory);
router.delete('/', deleteAllHistory);

export default router;
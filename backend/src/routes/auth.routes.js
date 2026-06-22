import express from 'express';
import { signup,login, getCurrentUser } from '../controllers/auth.controller.js';
import { protectRoute } from '../middleware/auth.middleware.js';
import {signupLimiter , loginLimiter} from '../middleware/rateLimit.middleware.js'
const router=express.Router();

router.post("/signup", signupLimiter, signup);
router.post("/login", loginLimiter, login);
router.get("/me", protectRoute, getCurrentUser);
export default router;
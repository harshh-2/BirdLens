import express from 'express';
import cors from 'cors';
import {ENV} from "./config/env.js";
import job from './config/cron.js';
import favoritesRoutes from './routes/favorites.routes.js';
import historyRoutes from './routes/history.routes.js';
import birdsRoutes from './routes/birds.routes.js';
import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js'
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

//send to favorites router
app.use('/api/favorites', favoritesRoutes);
//send to history router
app.use('/api/history', historyRoutes);
//send to birds router
app.use('/api/birds', birdsRoutes);
//send to auth router
app.use('/api/auth',authRoutes);
//send to userinfo router
app.use('/api/user',userRoutes);

app.listen(PORT, () => {
    console.log("Server is running on port " + PORT);
});

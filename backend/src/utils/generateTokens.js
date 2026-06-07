import jwt from 'jsonwebtoken';
import {ENV} from '../config/env.js'
export const generateToken=(id)=>{
    return jwt.sign({id}, ENV.JWT_SECRET, {expiresIn: '7d'});
}
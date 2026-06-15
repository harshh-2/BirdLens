import bcrypt from "bcryptjs";
import { db } from "../config/db.js";
import { users } from "../db/schema.js";
import { eq } from "drizzle-orm";
import { generateToken } from "../utils/generateTokens.js";

const passwordRegex =/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d@-]{6,25}$/;
const emailRegex =/^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const SALT_ROUNDS = 10;

export const signup = async (req, res) => {
    try{
        const email = req.body.email?.trim().toLowerCase();
        const username = req.body.username?.trim();
        const password = req.body.password;

        if(!email || !password || !username){
            return res.status(400).json({message:"Please provide email, password and username"});
        }
        const existingUser = await db.select().from(users).where(eq(users.email, email));
        if(username.length < 3 || username.length > 20){
            return res.status(400).json({message:"Username must be between 3 and 20 characters"});
        }
        if (!passwordRegex.test(password)) {
         return res.status(400).json({message:"Password must be 6-25 chars with uppercase, lowercase, number, and only @ or -."});
        }
        if (!emailRegex.test(email) || email.length > 254) {
            return res.status(400).json({message: "Invalid email format"});
        }
        if(existingUser.length > 0){
            return res.status(409).json({message:"Email already in use"});
        }
        const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
        const newUser = await db.insert(users).values({email, password_hash: hashedPassword, username}).returning();
        const token = generateToken(newUser[0].id);
        res.status(201).json({message: "User created successfully", token, user: {id: newUser[0].id, email: newUser[0].email, username: newUser[0].username}});
    }
    catch(error){
        console.error("Error during signup:", error);
        res.status(500).json({message: "Error occurred while signing up"});
    }
};

export const login = async (req, res) => {
    try{
        const email = req.body.email?.trim().toLowerCase();
        const password = req.body.password;
        if(!email || !password){
            return res.status(400).json({message:"Please provide email and password"});
        }
        const user = await db.select().from(users).where(eq(users.email, email));
        if(user.length === 0){
            return res.status(401).json({message:"Invalid Credentials"});
        }
        const isMatch = await bcrypt.compare(password, user[0].password_hash);
        if(!isMatch){
            return res.status(401).json({message:"Invalid Credentials"});
        }
        const token = generateToken(user[0].id);
        res.status(200).json({message: "Login successful", token, user: {id: user[0].id, email: user[0].email, username: user[0].username}});
    }
    catch(error){
        console.error("Error during login:", error);
        res.status(500).json({message: "Error occurred while logging in"});
    }
};

export const getCurrentUser = async (req, res) => {
  try {
    const user = await db.select({id: users.id,username: users.username,email: users.email,}).from(users).where(eq(users.id, req.user.id));
    if (user.length === 0) {
        return res.status(404).json({message: "User not found",
        });
    }
    res.status(200).json(user[0]);
  } catch (error) {
    res.status(500).json({message: "Server Error",});
  }
};
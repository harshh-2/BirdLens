import { db } from "../config/db.js";
import {users,history,favorites} from "../db/schema.js";
import {eq} from "drizzle-orm";

export const getUserProfile =async (req, res) => {
    try {
      const userId = req.user.id;
      if (!userId) {
        return res.status(401).json({
          message: "Unauthorized",
        });
      }
      const user = await db.query.users.findFirst({
          where: eq(
            users.id,
            userId,
          ),
        });
      if (!user) {
        return res.status(404).json({
          message: "User not found",
        });
      }
      const scans =await db.select().from(history).where(
            eq(history.user_id,userId, ),
          );
      const favs =await db.select().from(favorites).where(
            eq(favorites.user_id,userId,),
          );
      const species =await db.selectDistinct({
            bird_id:
                history.bird_id,
          })
          .from(history)
          .where(
            eq(
              history.user_id,
              userId,
            ),
          );
      return res.status(200).json({
        username: user.username,
        email: user.email,
        created_at: user.created_at,
        stats: {
          total_scans:
              scans.length,
          favorites:
              favs.length,
          unique_species:
              species.length,
        },
      });

    } catch (error) {
      console.error(error);
      return res.status(500).json({
        message:
            "Internal Server Error",
      });
    }
  };
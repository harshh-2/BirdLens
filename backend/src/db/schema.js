import { pgTable, serial, text, timestamp , uuid, primaryKey,real} from 'drizzle-orm/pg-core';

export const users= pgTable("users",{
id: uuid("id").defaultRandom().primaryKey(),
username: text("username").notNull(),
email: text("email").notNull().unique(),
created_at: timestamp("created_at").defaultNow().notNull(),
updated_at: timestamp("updated_at").defaultNow().notNull(),
password_hash: text("password_hash").notNull(),
});

export const birds= pgTable("birds",{
id: uuid("id").defaultRandom().primaryKey(),
name: text("name").notNull().unique(),
description: text("description"),
image_url: text("image_url"),
scientific_name: text("scientific_name"),
habitat: text("habitat"),
conservation_status: text("conservation_status"),
})

export const favorites = pgTable("favorites",{
    user_id: uuid("user_id").notNull().references(() => users.id),
    bird_id: uuid("bird_id").notNull().references(() => birds.id),
    created_at: timestamp("created_at").defaultNow().notNull(),
  },
  (table) => ({ pk: primaryKey({
    columns: [table.user_id, table.bird_id],
    }),
  }));

export const history =pgTable("history",{
    id:serial("id").primaryKey(),
    user_id: uuid("user_id").notNull().references(() => users.id),
    bird_id: uuid("bird_id").notNull().references(() => birds.id),
    confidence: real("confidence").notNull(),
    uploaded_image_url: text("uploaded_image_url"),
    predicted_at: timestamp("predicted_at").defaultNow().notNull(),
})
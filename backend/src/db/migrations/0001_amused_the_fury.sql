ALTER TABLE "history" RENAME COLUMN "viewed_at" TO "predicted_at";--> statement-breakpoint
ALTER TABLE "history" ADD COLUMN "confidence" real NOT NULL;--> statement-breakpoint
ALTER TABLE "history" ADD COLUMN "uploaded_image_url" text;
ALTER TABLE "birds" RENAME COLUMN "image_url" TO "aws_image_key";--> statement-breakpoint
ALTER TABLE "history" RENAME COLUMN "uploaded_image_url" TO "aws_user_image_key";--> statement-breakpoint
CREATE INDEX "history_user_idx" ON "history" USING btree ("user_id");
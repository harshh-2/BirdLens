import { ENV } from "../config/env.js";
import {S3Client,GetObjectCommand} from "@aws-sdk/client-s3";
import {getSignedUrl} from "@aws-sdk/s3-request-presigner";

export const s3 = new S3Client({
  region: ENV.AWS_REGION,
  credentials: {
    accessKeyId: ENV.AWS_ACCESS_KEY_ID,
    secretAccessKey: ENV.AWS_SECRET_ACCESS_KEY,
  },
});

export async function getImageUrl(key) {

  const command = new GetObjectCommand({
    Bucket: ENV.AWS_BUCKET_NAME,
    Key: key,
  });

  return await getSignedUrl(
    s3,
    command,
    { expiresIn: 3600 }
  );
}
import "dotenv/config";

export const ENV={
    DB_URL: process.env.DB_URL,
    PORT: process.env.PORT || 5001 ,
    NODE_ENV: process.env.NODE_ENV || "development",
    API_URL: process.env.API_URL ,
    JWT_SECRET: process.env.JWT_SECRET ,
    ML_SERVICE: process.env.ML_SERVICE ,
    AWS_BUCKET_NAME: process.env.AWS_BUCKET_NAME ,
    AWS_REGION: process.env.AWS_REGION ,
    AWS_SECRET_ACCESS_KEY: process.env.AWS_SECRET_ACCESS_KEY ,
    AWS_ACCESS_KEY_ID: process.env.AWS_ACCESS_KEY_ID
}
import { getImageUrl } from "../services/s3.service.js";

export async function enrichBird(bird) {
    if (!bird) return null;
    const imageUrl = bird.aws_image_key? await getImageUrl(bird.aws_image_key): null;
    const { aws_image_key, ...safeBird } = bird;
    return {
        ...safeBird,
        image_url: imageUrl
    };
}

export async function enrichBirds(birds) {
  return Promise.all(
    birds.map(async (bird) => {
      const imageUrl = bird.aws_image_key ? await getImageUrl(bird.aws_image_key): null;
      const { aws_image_key, ...safeBird } = bird;
      return {
        ...safeBird,
        image_url: imageUrl
      };
    })
  );
}
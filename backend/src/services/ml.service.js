import axios from "axios";
import FormData from "form-data";
import {ENV} from "../config/env.js"
export const predictFromML = async(file)=>{
    const form = new FormData();
    form.append("file",file.buffer,file.originalname);
    const response = await axios.post(
        `${ENV.ML_SERVICE}/api/predict/`,
        form,{ headers: form.getHeaders()}
    );
    return response.data;
}
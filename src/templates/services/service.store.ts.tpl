import { {{Model}} } from "@prisma/client";
import prisma from "../../database";
import AppError from "../../error/AppError";

export type Store{{Model}} = {
  {{fields}}
};

const Store{{Model}}Service = async (data: Store{{Model}}): Promise<{{Model}}> => {
  const {{model}} = await prisma.{{model}}.create({
    data: data
  }).catch((err: any) => {
    throw new AppError("{{MODEL}}_Store_ERROR", 400);
  });

  return {{model}};
}

export default Store{{Model}}Service;

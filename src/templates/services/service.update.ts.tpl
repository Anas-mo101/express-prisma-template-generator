import AppError from "../../error/AppError";
import prisma from "../../database";

interface Request {
  data: Partial<{{Model}}>;
  id: number;
}

const Update{{Model}}Service = async ({
  data,
  id
}: Request): Promise<{{Model}}> => {
  const toUpdate: any = {};

  for (const key in data) {
    if (data[key] !== undefined) {
      toUpdate[key] = data[key];
    }
  }

  if (Object.keys(toUpdate).length === 0) {
    throw new AppError("ERR_{{MODEL}}_DATA_TO_UPDATE", 400);
  }

  const {{model}} = await prisma.{{model}}.update({
    where: { id },
    data: toUpdate
  }).catch((err: any) => {
    throw new AppError("{{MODEL}}_Update_ERROR", 400);
  });

  return {{model}};
};

export default Update{{Model}}Service;

import AppError from "../../error/AppError";
import prisma from "../../database";
import {{Model}}Emitter from "../../events/{{Model}}Event";
import { {{Model}}, Prisma } from "@prisma/client";

interface Request {
  data: Prisma.{{Model}}UpdateInput;
  id: number;
}

const Update{{Model}}Service = async ({
  data,
  id
}: Request): Promise<{{Model}}> => {
  const toUpdate: any = {};

  const keysToUpdate: (
    keyof Prisma.{{Model}}UpdateInput
  )[] = Object.keys(data) as (keyof Prisma.{{Model}}UpdateInput)[];

  for (const key of keysToUpdate) {
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

  {{Model}}Emitter.emit("{{model}}_updated", id, data);

  return {{model}};
};

export default Update{{Model}}Service;

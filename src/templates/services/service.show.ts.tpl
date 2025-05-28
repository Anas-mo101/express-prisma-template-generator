import AppError from "../../error/AppError";
import prisma from "../../database";
import { {{Model}} } from "@prisma/client";

const Show{{Model}}Service = async (id: number): Promise<{{Model}}> => {
  const {{model}} = await prisma.{{model}}.findUnique({
    where: {
      id
    }
  });

  if (!{{model}}) {
    throw new AppError("ERR_NO_{{MODEL}}_FOUND", 404);
  }

  return {{model}};
};

export default Show{{Model}}Service;

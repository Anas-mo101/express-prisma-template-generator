import AppError from "../../error/AppError";
import prisma from "../../database";

const Delete{{Model}}Service = async (id: number): Promise<void> => {
  const {{model}} = await prisma.{{model}}.delete({
    where: { id }
  }).catch((err: any) => {
    throw new AppError("ERR_NO_{{MODEL}}_FOUND", 400);
  });

  if (!{{model}}) {
    throw new AppError("ERR_NO_{{MODEL}}_FOUND", 400);
  }
};

export default Delete{{Model}}Service;

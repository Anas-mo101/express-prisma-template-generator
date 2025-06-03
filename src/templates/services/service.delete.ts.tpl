import AppError from "../../error/AppError";
import prisma from "../../database";
import {{Model}}Emitter from "../../events/{{Model}}Event";

const Delete{{Model}}Service = async (id: number): Promise<void> => {
  const {{model}} = await prisma.{{model}}.delete({
    where: { id }
  }).catch((err: any) => {
    throw new AppError("ERR_NO_{{MODEL}}_FOUND", 400);
  });

  if (!{{model}}) {
    throw new AppError("ERR_NO_{{MODEL}}_FOUND", 400);
  }

  {{Model}}Emitter.emit("{{model}}_deleted", {{model}});
};

export default Delete{{Model}}Service;

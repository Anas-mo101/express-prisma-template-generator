import { {{Model}} } from "@prisma/client";
import prisma from "../../database";

export type List{{Model}}Request = {
  pageNumber: string;
} & Partial<{{Model}}>;

interface Response {
  {{models}}: {{Model}}[];
  count: number;
  hasMore: boolean;
}

const List{{Model}}sService = async (data: List{{Model}}Request): Promise<Response> => {
  let whereCondition: any = {};

  for (const key in data) {
    if (data[key] !== undefined) {
      whereCondition[key] = data[key];
    }
  }

  const take = 20;
  const skip = take * (+(data.pageNumber ?? "1") - 1);

  const {{models}} = await prisma.{{model}}.findMany({
    where: whereCondition,
    take,
    skip,
    orderBy: {
      createdAt: "desc"
    }
  }).catch((err: any) => {
    throw new AppError("{{MODEL}}_List_ERROR", 400);
  });

  const count = await prisma.{{model}}.count({
    where: whereCondition
  }).catch((err: any) => {
    throw new AppError("{{MODEL}}_Count_ERROR", 400);
  });

  const hasMore = count > skip + {{models}}.length;

  return {
    {{models}},
    count,
    hasMore
  };
}

export default List{{Model}}sService;

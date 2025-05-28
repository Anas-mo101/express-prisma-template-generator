import { Request, Response } from "express";
import AppError from "../error/AppError";

import Store{{Model}}Service from "../services/{{ModuleServicesPath}}/Store{{Model}}Service";
import Update{{Model}}Service from "../services/{{ModuleServicesPath}}/Update{{Model}}Service";
import Show{{Model}}Service from "../services/{{ModuleServicesPath}}/Show{{Model}}Service";
import Delete{{Model}}Service from "../services/{{ModuleServicesPath}}/Delete{{Model}}Service";
import List{{Model}}Service from "../services/{{ModuleServicesPath}}/List{{Model}}Service";

type IndexQuery = {
  searchParam?: string;
  pageNumber?: string;
};

export const index = async (req: Request, res: Response): Promise<Response> => {
  const { searchParam, pageNumber } = req.query as IndexQuery;

  const { {{modelPlural}}, count, hasMore } = await List{{Model}}Service({
    searchParam,
    pageNumber
  });

  return res.json({ {{modelPlural}}, count, hasMore });
};

export const store = async (req: Request, res: Response): Promise<Response> => {
  const data = req.body;

  const {{model}} = await Store{{Model}}Service(data);

  return res.status(200).json({{model}});
};

export const show = async (req: Request, res: Response): Promise<Response> => {
  const { id } = req.params;

  const {{model}} = await Show{{Model}}Service(+id);

  return res.status(200).json({{model}});
};

export const update = async (req: Request, res: Response): Promise<Response> => {
  const { id } = req.params;
  const data = req.body;

  const {{model}} = await Update{{Model}}Service({ data, id: parseInt(id) });

  return res.status(200).json({{model}});
};

export const remove = async (req: Request, res: Response): Promise<Response> => {
  const { id } = req.params;
  await Delete{{Model}}Service(+id);

  return res.status(200).json({ message: "{{Model}} deleted" });
};

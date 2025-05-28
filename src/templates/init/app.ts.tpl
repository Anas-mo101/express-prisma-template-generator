import "reflect-metadata";
import "express-async-errors";
import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import cookieParser from "cookie-parser";

import "./database";
import AppError from "./error/AppError";
import routes from "./routes";
import { logger } from "./utils/logger";
import dotenv from "dotenv";
import path from "path";

dotenv.config({path: process.env.NODE_ENV === "test" ? ".env.test" : ".env"});

const app = express();

app.use(
  cors({
    credentials: true,
    origin: [
      process.env.FRONTEND_URL!,
    ]
  })
);

app.use(cookieParser());
app.use(express.json());
app.use(routes);

app.use(async (err: Error, req: Request, res: Response, _: NextFunction) => {
  if (err instanceof AppError) {
    logger.warn(err);
    return res.status(err.statusCode).json({ error: err.message });
  }

  logger.error(err);
  return res.status(500).json({ error: "Internal server error" });
});

export default app;

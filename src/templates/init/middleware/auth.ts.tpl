import { verify } from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";

import AppError from "../error/AppError";
import authConfig from "../config/auth";

interface TokenPayload {
  id: string;
  username: string;
  role: string;
  iat: number;
  exp: number;
}

const isAuth = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    throw new AppError("ERR_SESSION_EXPIRED", 401);
  }

  const [, token] = authHeader.split(" ");

  try {
    const decoded = verify(token, authConfig.secret);
    const { id, role } = decoded as TokenPayload;

    req.user = {
      id,
      role
    };
  } catch (err) {
    throw new AppError(
      "Invalid token. We'll try to assign a new one on next request",
      403
    );
  }

  return next();
};

export default isAuth;

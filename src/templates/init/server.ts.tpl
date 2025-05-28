import gracefulShutdown from "http-graceful-shutdown";
import app from "./app";
import { logger } from "./utils/logger";

const server = app.listen(process.env.PORT, () => {
  logger.info(`Server started on port: ${process.env.PORT}`);
});

gracefulShutdown(server);

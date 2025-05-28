generator client {
  provider      = "prisma-client-js"
  binaryTargets = ["native"]
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}
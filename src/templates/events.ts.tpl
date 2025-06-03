import { {{Model}}, Prisma } from "@prisma/client";
import { EventEmitter } from "../utils/events";
import { logger } from "../utils/logger";

interface {{Model}}Events {
  '{{model}}_created': [data: {{Model}}];
  '{{model}}_updated': [id: number, changes: Prisma.{{Model}}UpdateInput];
  '{{model}}_deleted': [data: {{Model}}];
}

const {{Model}}Emitter = new EventEmitter<{{Model}}Events>();


{{Model}}Emitter.on("{{model}}_created", ({{model}}: {{Model}}) => {
    logger.info("{{model}}_created", "Invoked");
});

{{Model}}Emitter.on("{{model}}_updated", (id: number, changes: Prisma.{{Model}}UpdateInput) => {
    logger.info("{{model}}_updated", "Invoked");
});

{{Model}}Emitter.on("{{model}}_deleted", ({{model}}: {{Model}}) => {
    logger.info("{{model}}_deleted", "Invoked");
});


export default {{Model}}Emitter;
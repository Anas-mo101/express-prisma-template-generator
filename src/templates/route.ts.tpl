import { Router } from "express";
import * as {{Model}}Controller from "../controllers/{{Model}}Controller";

const {{model}}Routes = Router();

const basePath = "/{{model}}";

{{model}}Routes.get(basePath, {{Model}}Controller.index);
{{model}}Routes.post(basePath, {{Model}}Controller.store);
{{model}}Routes.put(`${basePath}/:id`, {{Model}}Controller.update);
{{model}}Routes.get(`${basePath}/:id`, {{Model}}Controller.show);
{{model}}Routes.delete(`${basePath}/:id`, {{Model}}Controller.remove);

export default {{model}}Routes;
